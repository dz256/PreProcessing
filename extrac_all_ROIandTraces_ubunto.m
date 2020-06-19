% This script exrtact traces using the ubntu pipeline + updating SQL

% define save dir + establish database connection: 
savedir = '/home/dana_z/HD2/traces/';
ROIdir = '/home/dana_z/HD1/ROIs/ROI_manual_';
% Set up an SQL connection and get all already Processed sessions:
conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');

% list of sesions where motion corrected, but ROI not selected:
Sess =  table2array(select(conn, 'Select Suffix from data where MC=1 AND ROI=1 and trace_extract=0;'));

tifdir = '/home/dana_z/HD1/Processed_tifs/';
tifdir2 = '/home/dana_z/HD2/Processed_tifs2/';


% do maximum of 3 sessions in parallel
for im = 1:numel(Sess)
    suffix = char(Sess(im));
    % Double check that has same amount of Processed vids as raw vids, 
    % decided if tifs saved on HD1 or HD2:
    trList = dir([tifdir,'m_n_',suffix,'_*.tif']);
    if numel(trList)==0
         trList = dir([tifdir2,'m_n_',suffix,'_*.tif']);
         Tifdir = tifdir2;
    else
        Tifdir = tifdir;
    end
    rawFiles = dir(['/home/dana_z/handata2/Dana_Zemel/',suffix(1:4),'/*',suffix(5:end),'/*.tif']);
    raws = 0;
    for r= 1:numel(rawFiles)
        if numel(rawFiles(r).name(cell2mat(regexp({rawFiles(r).name}, '(green)')):end))==0
            raws = raws + 1;
        end
    end
    clear rawFiles r
    %[rawFiles, r] = deal([]);
    
    if numel(trList) ~= raws
        update(conn,'data','skip',43,sprintf("Where Suffix= '%s'",suffix))
    end
    
    % load ROI
    Name = [ROIdir,suffix,'.mat'];
    if (exist(Name, 'file') ~= 2)
       continue
    end
   R = load(Name);
   R = R.R;
   
   
   [~,idx] = sort(cellfun(@(x) str2num(char(regexp(x,'(?<=_)(\d*)(?=\.)','match'))),{trList.name}));
   trList = trList(idx);
   r_out=extract_trace(R, 0,trList,Tifdir);
   % save and update the sql
   save([savedir,'trace_',suffix],'r_out')
   update(conn,'data','trace_extract',1,sprintf("Where Suffix= '%s'",suffix))
   
   %clear space on CPU
   [R,r_out] = deal([]);
   
end


