
% This script cleans "bad" ROIs based on traces, than match TD maps with
% ROIs ans save final structs (note - rejected ROIs are not erased, just marked)

% open connection to server and find which sessions already have traces and
% TD maps:

   
conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');

Sess =  table2array(select(conn, 'Select Suffix from data_final where QC2 =0;'));

% define importent paths:
tracedir = '/home/dana_z/HD2/traces_MC6/';
tracePrefix = 'trace_';
tracedir2 = '/home/dana_z/HD2/traces_MC6/';
tracePrefix2 = 'traceH_';
tracedir_ori = '/home/dana_z/HD2/traces/';




greendir = '/home/dana_z/HD2/green/';
ROIdir = '/home/dana_z/HD1/ROIs/';
TSdir = '/home/dana_z/HD1/tiffTs/';
mmdir = '/home/dana_z/HD1/min_max/MaxMin_';

% for each session:
for s = 1:numel(Sess)
    suffix = char(Sess(s))
    
    %load trace, TD maps, and ROI:
    load([tracedir,tracePrefix,suffix,'.mat']);
    r_outH = load([tracedir2,tracePrefix2,suffix,'.mat']);
    r_outH = r_outH.r_out;
    load([ROIdir,'ROI_manual_',suffix,'.mat']);
%    load([greendir,'Ired_',suffix,'.mat']);
    load([TSdir,'tiffTs_',suffix,'.mat']);

    
    
    %------------------
    % TODO: earse? maybe just save a struct that can be open with the hdf5
    %-----------------
    % add perimeter field to the trace stuct (so don't have to update
    % things in both ROI mat and trace mat... +  add skip field and TD
    % field:
    I = [r_out(:).skip];
    
    if sum(I) == 0
        update(conn,'data_final','QC2',1,sprintf("Where Suffix= '%s'",suffix))
        continue
    end
    colors = rand(numel(r_out),3);
    ActualInd = 1:numel(r_out);
    PotentialInd = ActualInd(logical(I));
    
    I =logical(I);
    if isfield(r_out,'TD_H')
        colors(logical([r_out(:).TD_H]),:) = deal(0);
    end
    % calc delta f over f, detrend traces, and interpolate time stemps:
    
    TS = 1/20; %sample frequency to match traces
    t = 0:TS:max(tiffTs);
    
    rawTraces = zeros(size(tiffTs,1),numel(r_out));
    rawTracesH = zeros(size(tiffTs,1),numel(r_outH));
       for r = 1:numel(r_out)
           rawTraces(:,r) = r_out(r).trace;
           rawTracesH(:,r) = r_outH(r).trace;
       end
               
    startF = find(tiffTs ==0,1,'last');
    if isempty(startF)
        startF = 1;
        t = 0:TS:(max(tiffTs)-tiffTs(startF));
    end

    if suffix == "7584_day1"
        startF = find(tiffTs ==0,2,'first');
        startF = startF(2);
    end
      
    if startF < 11000  
        traces = interp1(tiffTs(startF:end)-tiffTs(startF),rawTraces(startF:end,:),t,'pchip');
        tracesH = interp1(tiffTs(startF:end)-tiffTs(startF),rawTracesH(startF:end,:),t,'pchip');
    else
        traces = interp1(tiffTs(1:startF-1),rawTraces(1:startF-1,:),t,'pchip');
        tracesH = interp1(tiffTs(1:startF-1),rawTracesH(1:startF-1,:),t,'pchip');
    end
    traces = traces + abs(min(traces(:)));
    tracesH = tracesH + abs(min(tracesH(:)));
    
    dff =  bsxfun(@rdivide, bsxfun(@minus,traces, nanmean(traces)), nanmean(traces));
    dffH =  bsxfun(@rdivide, bsxfun(@minus,tracesH, nanmean(tracesH)), nanmean(tracesH));
        
    % plot traces for first 10 min:
    tPre = find(t<=600,1,'last');
    nhat =  max(1,median(max(dff(1:tPre,:))));
    nhat2 =  max(1,median(max(dffH(1:tPre,:))));
    [badIndices, goodIndices] =markBadTraces3(t(1:tPre), dff(1:tPre,I), nhat*2, dffH(1:tPre,I), nhat2,colors(PotentialInd,:));
    keep = PotentialInd(goodIndices);
    close all
    tPost = find(t>900,1,'first');
    

    
    % plot traces for post infusion period for "bad indeces" to make sure these aren't real indicies:
    if numel(badIndices)>0 && numel(tPost)>0
        Tbatch = [tPost,find(t>1500,1,'first'),find(t>2100,1,'first'),numel(t)];
        Opbad = PotentialInd(badIndices);
        for b = 1:numel(Tbatch)-1
            nhat = max(1,median(max(dff(Tbatch(b):Tbatch(b+1),Opbad))));
            nhat2 =max(1, max(max(dffH(Tbatch(b):Tbatch(b+1),Opbad))));
        
            [realbadInd, realgoodInd] =markBadTraces3(t(Tbatch(b):Tbatch(b+1)), dff(Tbatch(b):Tbatch(b+1),Opbad), abs(nhat)*3, dffH(Tbatch(b):Tbatch(b+1),Opbad), nhat2,colors(Opbad,:));
            if ~isempty(realgoodInd)
                keep = cat(2,keep,Opbad(realgoodInd))
            end
            Opbad = Opbad(realbadInd)
            close all
        end
    end
    
    %show ROI on minMax, ask user if want to see vids later:
    I(keep) = deal(0);
    
    
     if ~isempty(keep)
        [r_out(keep).skip] = deal(0);
        [r_outH(keep).skip] = deal(0);
        
        save([tracedir,tracePrefix,suffix,'.mat'],'r_out');
        r_out = r_outH;
        save([tracedir2,tracePrefix2,suffix,'.mat'],'r_out');
     end
    % mark "bad traces on trace list:
   
    
    update(conn,'data_final','QC2',1,sprintf("Where Suffix= '%s'",suffix))
    clear r_out r_outH dff dffH traces tracesH nhat nhat2 rawTraces rawTracesH tPost tPre badIndices tiffTs keep Opbad PotentialInd ActualInd goodIndices realbadInd realgoodInd colors Tbatch startF  
    
    
end




  