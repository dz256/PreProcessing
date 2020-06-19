%%% This scripts collect the processed data from Gcamp, ePhys, and movment
%%% and compile it to HDF5 file that can be read in python. The file
%%% structure is documented under 6OHDA repository in github. Script meant
%%% for data structure in the linux machine.

%%% written by: Dana Zemel, on 1/28/2019
%% useful directories:
tracedir = '/home/dana_z/HD2/traces/';
TSdir = '/home/dana_z/HD1/tiffTs/';
mvmtdir = '/home/dana_z/HD1/extracted_ephys_matlab/';
ephysdir = '/home/dana_z/HD1/extracted_ephys_matlab/';
Tprelim = 'trace_';
Lprelim = 'ePhys_raw_';



%% open connection, insure that there is new data, and set up file preferences
fileName = 'Data_6OHDA_longLFP.h5'; %to be changed by user
includeSkip = false;
packTable = 'h5_Prog_longLFP_temp';

conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');

Sess =  table2array(select(conn, 'Select Suffix from data_final where Ephys_raw =1;'));
%Sess =  table2array(select(conn, "Select Suffix from data_final where mouse_num in ('2981','2980','2976');"));

try 
    fid = H5F.open(fileName,'H5F_ACC_RDWR','H5P_DEFAULT');
catch er
    if er.message == "The filename specified was either not found on the MATLAB path or it contains unsupported characters."
        disp(['Creating a new data file: ',fileName])
        fid  = H5F.create(fileName);
    else
        disp("Can't open or create file with this name. Failed with error: ")
        disp(er.message)
    end
end

%% Go through each seesion that needs to be added, and get available data: 

for s = 1:numel(Sess)
    suffix = char(Sess(s));
    
    dataStat = table2array(select(conn,sprintf("Select mvmt,Ephys_raw,red_match,mouse_num  from data_final where Suffix = '%s';",suffix)));
    %dataStat = table2array(select(conn,sprintf("Select mvmt,Ephys,red_match,mouse_num  from data where Suffix = '%s';",suffix)));
    h5Stat = table2array(select(conn,sprintf("Select mvmt,lfp,Ca  from %s where Suffix = '%s';",packTable,suffix)));
    
    if isempty(h5Stat)
        h5Stat = [0,0,0];
    end
    %=================
    %addCa = dataStat(3)==1 & h5Stat(3)==0;
    addCa = h5Stat(3)==0;
    addEphys = dataStat(2)& h5Stat(2)==0;
    addMvmt = dataStat(1)& h5Stat(1)==0;
    mouseNum = sprintf('%04d',dataStat(4));
    %=================
    % if nothing to add, skip
    if addCa+addEphys+addMvmt == 0
        continue
    end
    % else get the attributes: 
     session = suffix(6:end); %session name
     switch session(end)      % drug name
         case 'A'
             drug = 'Amphetamin';
         case 'L'
             drug = 'L-Dopa';
         case 'S'
             drug = 'Saline';
         otherwise
             drug = 'NA';
     end
         
    type = char(table2array(select(conn,sprintf("Select cre from mice where mouse_num = '%s';",mouseNum))));
    
     if session(1) =='B'     % drug name
         day = 0;
     else
         day = str2num(char(regexp(session,'\d+','match')));
     end
    %% If decided that data needs to be added to struct - load and create proper data to add
    TS = 1/20; % sample frequency to save all data - change here if neeeded
    
    % if red_matched and have ready Ca data:
    if addCa
        try 
            load([tracedir,Tprelim,suffix,'.mat'])
            load([TSdir,'tiffTs_',suffix,'.mat']);
            t = 0:TS:max(tiffTs);
            
            % sort by TD first, than MSN:
            [~,I] = sort(arrayfun (@(x) x.TD_H, r_out),'descend');
            r_out = r_out(I);
            clear I
            
            % take out all skiped session if needed:
            if ~includeSkip && isfield(r_out, 'skip')
                I = ~[r_out(:).skip];
                r_out = r_out(I);
                clear I
            end
            
            numTD = sum([r_out(:).TD_H]);
            % turn traces into matrix
            rawTraces = zeros(size(tiffTs,1),numel(r_out));
            for r = 1:numel(r_out)
                rawTraces(:,r) = r_out(r).trace;
            end
            
            % count red cell, define pre/post period
            num_red = sum([r_out(:).TD_H]);
            t_pre = [find(t<=5,1,'last'),find(t<=600,1,'last')];
            Pre = [':,',num2str(t_pre(1)),':',num2str(t_pre(2))];
            
            if drug=="NA"
                Post = 'null';
            else
                t_post = [find(t<=15*60,1,'last'),find(t<=45*60,1,'last')];
                Post = [':,',num2str(t_post(1)),':',num2str(t_post(2))];
            end 
            startF = find(tiffTs ==0,1,'last');
            traces = interp1(tiffTs(startF:end),rawTraces(startF:end,:),t,'pchip');
            dff =  bsxfun(@rdivide, bsxfun(@minus,traces, nanmean(traces)), nanmean(traces));
            
            % get centroids from pixle index:
            for r = 1:numel(r_out)
                c = regionprops(r_out(r).perimeter,'centroid');
                ROIinds(r,:) = floor(c.Centroid)-1;
            end
                
            
            % actually add session to hdf5 struct:
            %----------------------------------------
            % make sure mouse and session group exsits:
            try
                mID = H5G.open(fid,mouseNum);
            catch er
                mID = H5G.create(fid,mouseNum,'H5P_DEFAULT','H5P_DEFAULT','H5P_DEFAULT');
                h5writeatt(fileName,['/',mouseNum],'type',type);
          
            end
            try
                sID = H5G.open(mID,session);
            catch er
                sID = H5G.create(mID,session,'H5P_DEFAULT','H5P_DEFAULT','H5P_DEFAULT');
                h5writeatt(fileName,['/',mouseNum,'/',session],'type',type);
                h5writeatt(fileName,['/',mouseNum,'/',session],'day',day);
                h5writeatt(fileName,['/',mouseNum,'/',session],'drug',drug);
                
            end
            try
                tID = H5G.open(sID,'traces');
            catch er
                tID = H5G.create(sID,'traces','H5P_DEFAULT','H5P_DEFAULT','H5P_DEFAULT');
            end
            
            % general HDF5 stuff needed for all databases:
            dcpl = H5P.create('H5P_DATASET_CREATE');
            type_id = H5T.copy('H5T_NATIVE_DOUBLE');
            % add ROIs centers:
                % define dimentions:
                dims = fliplr([numel(r_out),2]);
                maxdims = fliplr([H5ML.get_constant_value('H5S_UNLIMITED'),2]);
                space_id = H5S.create_simple(2,dims,maxdims);
                % define data chunks:
                chunk_dims = [1 2];
                h5_chunk_dims = fliplr(chunk_dims);
                H5P.set_chunk(dcpl,h5_chunk_dims);
                % create the dataset
                ROId = H5D.create(tID,'ROI',type_id,space_id,dcpl);
                % write the dataset
                H5D.write(ROId,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',ROIinds);
                % write attributes
                h5writeatt(fileName,['/',mouseNum,'/',session,'/traces/ROI'],'description','Centers of each ROI ([x,y], 0 indexed)')
           
           % add dff: 
               % define dimentions:
                [tLen,numN] = size(dff);
               
                dims = fliplr([tLen,numN]);
                maxdims = fliplr([tLen,H5ML.get_constant_value('H5S_UNLIMITED')]);
                space_id = H5S.create_simple(2,dims,maxdims);
                % define data chunks:
                chunk_dims = [tLen 1];
                h5_chunk_dims = fliplr(chunk_dims);
                H5P.set_chunk(dcpl,h5_chunk_dims);
                % create the dataset
                dffid = H5D.create(tID,'dff',type_id,space_id,dcpl);
                % write the dataset
                H5D.write(dffid,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',dff);
                % write attributes
                h5writeatt(fileName,['/',mouseNum,'/',session,'/traces/dff'],'description','delta f/f. sorted by td-tomato labed cells first')
                h5writeatt(fileName,['/',mouseNum,'/',session,'/traces/dff'],'Post',Post)
                h5writeatt(fileName,['/',mouseNum,'/',session,'/traces/dff'],'Pre',Pre)
                h5writeatt(fileName,['/',mouseNum,'/',session,'/traces/dff'],'numMSN',numN-numTD)
                h5writeatt(fileName,['/',mouseNum,'/',session,'/traces/dff'],'creType',type)
                h5writeatt(fileName,['/',mouseNum,'/',session,'/traces/dff'],'numRed',numTD)
                h5writeatt(fileName,['/',mouseNum,'/',session,'/traces/dff'],'dt',TS)
                
           % add rawTraces: 
                % create the dataset
                dffid = H5D.create(tID,'rawTraces',type_id,space_id,dcpl);
                % write the dataset
                H5D.write(dffid,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',traces);
                % write attributes
                h5writeatt(fileName,['/',mouseNuinm,'/',session,'/traces/dff'],'description','Raw traces. sorted by td-tomato labed cells first')
                h5writeatt(fileName,['/',mouseNum,'/',session,'/traces/dff'],'Post',Post)
                h5writeatt(fileName,['/',mouseNum,'/',session,'/traces/dff'],'Pre',Pre)
                h5writeatt(fileName,['/',mouseNum,'/',session,'/traces/dff'],'numMSN',numN-numTD)
                h5writeatt(fileName,['/',mouseNum,'/',session,'/traces/dff'],'creType',type)
                h5writeatt(fileName,['/',mouseNum,'/',session,'/traces/dff'],'numRed',numTD)
                h5writeatt(fileName,['/',mouseNum,'/',session,'/traces/dff'],'dt',TS)
 
            % add skip list: 
             if includeSkip && isfield(r_out, 'skip')
                dims = fliplr([numN]);
                maxdims = fliplr([H5ML.get_constant_value('H5S_UNLIMITED')]);
                space_id = H5S.create_simple(1,dims,maxdims);
                % define data chunks:
                chunk_dims = [1];
                h5_chunk_dims = fliplr(chunk_dims);
                H5P.set_chunk(dcpl,h5_chunk_dims);
                % create the dataset
                skipid = H5D.create(tID,'skipList',type_id,space_id,dcpl);
                % write the dataset
                H5D.write(skipid,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',[r_out(:).skip]);
                % write attributes
                h5writeatt(fileName,['/',mouseNum,'/',session,'/traces/ROI'],'description','Which cells were marked as skip')
             end
       % update the database that Ca info has been added:
       try
           datainsert(conn,packTable,{'Ca','lfp','mvmt','Suffix'},...
                {1,0,0,suffix}) 
       catch er
            update(conn,packTable,'Ca',1,sprintf("Where Suffix= '%s'",suffix))
       end
               
        catch dff_error
            disp("Can't calculate  dff")
            addCa = 0;
            disp(suffix)
            disp(dff_error.message)
            update(conn,'h5Errs','dffEr',{dff_error.message},sprintf("Where Suffix= '%s'",suffix))
        end
    end
    % if mvmt data available
    if addMvmt
        try
            mvmt = load([mvmtdir,'mo_',suffix,'.mat']);
            try
                tiffTS = load([TSdir,'tiffTs_',suffix,'.mat']);
                perfctAlign = uint8(max(size(mvmt.t))== max(size(tiffTS.tiffTs)));
            catch er
                perfctAlign = 0;
            end
            update(conn,'data','perfectAlign_mvmt',{perfctAlign},sprintf("Where Suffix= '%s'",suffix))
            
            % interp all motion data:
            t = 0:TS:max(mvmt.t);
            phi = interp1(mvmt.t,mvmt.phi,t,'pchip')';
            rotation = interp1(mvmt.t,mvmt.rotation,t,'pchip')';
            speed = interp1(mvmt.t,mvmt.speed,t,'pchip')';
            
            % actually add to hdf5 file
             % make sure mouse and session group exsits:
            try
                mID = H5G.open(fid,mouseNum);
            catch er
                mID = H5G.create(fid,mouseNum,'H5P_DEFAULT','H5P_DEFAULT','H5P_DEFAULT');
                h5writeatt(fileName,['/',mouseNum],'type',type);
          
            end
            try
                sID = H5G.open(mID,session);
            catch er
                sID = H5G.create(mID,session,'H5P_DEFAULT','H5P_DEFAULT','H5P_DEFAULT');
                h5writeatt(fileName,['/',mouseNum,'/',session],'type',type);
                h5writeatt(fileName,['/',mouseNum,'/',session],'day',day);
                h5writeatt(fileName,['/',mouseNum,'/',session],'drug',drug);
                
            end
            try
                mvmtID = H5G.open(sID,'mvmt');
            catch er
                mvmtID = H5G.create(sID,'mvmt','H5P_DEFAULT','H5P_DEFAULT','H5P_DEFAULT');
                h5writeatt(fileName,['/',mouseNum,'/',session,'/mvmt'],'dt',TS)
            end
           
            % add to file: 
              % general HDF5 stuff needed for all databases:
                dcpl = H5P.create('H5P_DATASET_CREATE');
                type_id = H5T.copy('H5T_NATIVE_DOUBLE');
             % add ROIs centers:
                % define dimentions:
                dims = fliplr(size(phi));
                maxdims = dims;
                space_id = H5S.create_simple(2,dims,maxdims);             
                % create the datasets
                speedid = H5D.create(mvmtID,'speed',type_id,space_id,dcpl);
                phiid = H5D.create(mvmtID,'phi',type_id,space_id,dcpl);
                rotationid = H5D.create(mvmtID,'rotation',type_id,space_id,dcpl);
                % write the datasets
                H5D.write(speedid,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',speed);
                H5D.write(phiid,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',phi);
                H5D.write(rotationid,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',rotation);
                % write global attribute:
                h5writeatt(fileName,['/',mouseNum,'/',session,'/mvmt'],'perfectly_aligned',perfctAlign)
           try
               datainsert(conn,packTable,{'Ca','lfp','mvmt','Suffix'},...
                    {0,0,1,suffix}) 
           catch er
                update(conn,packTable,'mvmt',1,sprintf("Where Suffix= '%s'",suffix))
           end
           
        catch mvmt_error
            disp("Can't calculate/load mvmt")
            disp(suffix)
            addMvmt = 0;
            update(conn,'h5Errs','mvmtEr',{mvmt_error.message},sprintf("Where Suffix= '%s'",suffix))

        end 
    end
    
    % if Ephys data available
    if addEphys
        try
            
            lfpData = load([mvmtdir,Lprelim,suffix,'.mat']);
            try
                tiffTS = load([TSdir,'tiffTs_',suffix,'.mat']);
                perfctAlign = uint8(max(size(lfpData.Frames))== max(size(tiffTS.tiffTs)));
            catch er
                perfctAlign = 0;
            end 
            update(conn,'data','perfectAlign_lfp',{perfctAlign},sprintf("Where Suffix= '%s'",suffix))
            
            lfp = lfpData.lfp10;
            lfp = lfp(lfpData.FramesTS(1):end); 
            
            
            
                     % actually add session to hdf5 struct:
            %----------------------------------------
            % make sure mouse and session group exsits:
            try
                mID = H5G.open(fid,mouseNum);
            catch er
                mID = H5G.create(fid,mouseNum,'H5P_DEFAULT','H5P_DEFAULT','H5P_DEFAULT');
                h5writeatt(fileName,['/',mouseNum],'type',type);
          
            end
            try
                sID = H5G.open(mID,session);
            catch er
                sID = H5G.create(mID,session,'H5P_DEFAULT','H5P_DEFAULT','H5P_DEFAULT');
                h5writeatt(fileName,['/',mouseNum,'/',session],'type',type);
                h5writeatt(fileName,['/',mouseNum,'/',session],'day',day);
                h5writeatt(fileName,['/',mouseNum,'/',session],'drug',drug);
                
            end
            try
                lID = H5G.open(sID,'ePhys');
            catch er
                lID = H5G.create(sID,'ePhys','H5P_DEFAULT','H5P_DEFAULT','H5P_DEFAULT');
            end
            
                     % add to file: 
              % general HDF5 stuff needed for all databases:
                dcpl = H5P.create('H5P_DATASET_CREATE');
                type_id = H5T.copy('H5T_NATIVE_DOUBLE');
             % add ROIs centers:
                % define dimentions:
                dims = fliplr(size(lfp));
                maxdims = dims;
                space_id = H5S.create_simple(2,dims,maxdims);             
                % create the datasets
                lfpid = H5D.create(lID,'lfp',type_id,space_id,dcpl);
                  % write the datasets
                H5D.write(lfpid,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',lfp);
                  % write attribute:
                h5writeatt(fileName,['/',mouseNum,'/',session,'/ePhys/lfp'],'FS',lfpData.SampFreq)
                h5writeatt(fileName,['/',mouseNum,'/',session,'/ePhys/lfp'],'dt',1/lfpData.SampFreq)

           try
               datainsert(conn,packTable,{'Ca','lfp','mvmt','Suffix'},...
                    {0,1,0,suffix}) 
           catch er
                update(conn,packTable,'lfp',1,sprintf("Where Suffix= '%s'",suffix))
           end

        catch lfp_error
            disp("Can't calculate/load lfp")
            disp(suffix)
            addEphys = 0;
            update(conn,'h5Errs','lfpEr',{lfp_error.message},sprintf("Where Suffix= '%s'",suffix))
        end 
    end
  
    clearvars -except tracedir TSdir mvmtdir ephysdir fileName conn Sess fid s packTable includeSkip Tprelim Lprelim
end
%% close file
H5F.close(fid);
    
    
    