
% This script cleans "bad" ROIs based on traces, than match TD maps with
% ROIs ans save final structs (note - rejected ROIs are not erased, just marked)

% open connection to server and find which sessions already have traces and
% TD maps:

   
conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');

Sess =  table2array(select(conn, 'Select Suffix from data_final where MC=1 and MC6=1 and Quality_MC6 <> 1;'));

% define importent paths:
tracedir = '/home/dana_z/HD2/traces_MC6/';
tracePrefix = 'trace_';
tracedir2 = '/home/dana_z/HD2/traces_MC6/';
tracePrefix2 = 'traceH_';


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
    load([greendir,'Ired_',suffix,'.mat']);
    load([TSdir,'tiffTs_',suffix,'.mat']);
    
    
    %------------------
    % TODO: earse? maybe just save a struct that can be open with the hdf5
    %-----------------
    % add perimeter field to the trace stuct (so don't have to update
    % things in both ROI mat and trace mat... +  add skip field and TD
    % field:
    
    
    % calc delta f over f, detrend traces, and interpolate time stemps:
    
    TS = 1/20; %sample frequency to match traces
    t = 0:TS:max(tiffTs);
    if min(tiffTs>1)
        disp('missing first tiff? look at session menually')
        update(conn,'data_final','skip',2,sprintf("Where Suffix= '%s'",suffix))
        continue
    end
            
    rawTraces = zeros(size(tiffTs,1),numel(r_out));
    rawTracesH = zeros(size(tiffTs,1),numel(r_outH));
    
    for r = 1:numel(r_out)
        rawTraces(:,r) = r_out(r).trace;
        rawTracesH(:,r) = r_outH(r).trace;
    end
    
    try
    
    traces = interp1(tiffTs,rawTraces,t,'pchip');   
    traces = traces + abs(min(traces,[],1));
    catch em
        update(conn,'data_final','skip',3,sprintf("Where Suffix= '%s'",suffix))
        continue
    end
    
    try
    tracesH = interp1(tiffTs,rawTracesH,t,'pchip');
    tracesH = tracesH + abs(min(tracesH,[],1));
    catch em
        update(conn,'data_final','skip',4,sprintf("Where Suffix= '%s'",suffix))
        continue
    end
    
    dff =  bsxfun(@rdivide, bsxfun(@minus,traces, nanmean(traces)), nanmean(traces));
    dffH =  bsxfun(@rdivide, bsxfun(@minus,tracesH, nanmean(tracesH)), nanmean(tracesH));
        
    %dff =  bsxfun(@rdivide, bsxfun(@minus,traces, movmean(traces,[1200,1200],1,'omitnan')), movmean(traces,[1200,1200],1,'omitnan'));
    % plot traces for first 10 min:
    tPre = find(t<=600,1,'last');
    nhat = median(max(dff(1:tPre,:)));
    nhat2 = median(max(dffH(1:tPre,:)));
    [~, badIndices] =markBadTraces2(t(1:tPre), dff(1:tPre,:), nhat*2, dffH(1:tPre,:), nhat2);
    close all
    tPost = find(t>900,1,'first');
    % plot traces for post infusion period for "bad indeces" to make sure these aren't real indicies:
    if numel(badIndices)>0 && numel(tPost)>0
        
        %nhat = max(max(dff(tPost:end,badIndices)));
        %[~, realbadInd] =markBadTraces(t(tPost:end), dff(tPost:end,badIndices), abs(nhat)*10, r_out(badIndices));
        nhat = median(max(dff(tPost:end,badIndices)));
        nhat2 = max(max(dffH(tPost:end,badIndices)));
        [~, realbadInd] =markBadTraces2(t(tPost:end), dff(tPost:end,badIndices), abs(nhat)*3, dffH(tPost:end,badIndices), nhat2);
        close all
        if numel(realbadInd)>0
            ind = 1:numel(badIndices);
            ind = ind(~ismember(ind,realbadInd));
            badIndices = badIndices(ind);
        end
    end
    
    %show ROI on minMax, ask user if want to see vids later:
    I = imread([mmdir,suffix,'.tif']);
    R2 = R(badIndices);
    overlayROI_Kyle(I, R2)
    button = questdlg('Is this okay?',...
            'Mark this session to watch on video later?','Yes','No','Yes');
    if strcmp(button,'No')
        update(conn,'data','goOverVid',1,sprintf("Where Suffix= '%s'",suffix))
    end
    clear R2
    close all
    
    % mark "bad traces on trace list:
    [r_out(:).skip] = deal(0);
    [r_out(badIndices).skip] = deal(1);
    save([tracedir,tracePrefix,suffix,'.mat'],'r_out');
    
    if isfield(r_out,'TD_H')
        [r_outH(:).TD_H] = deal(0);
        [r_outH(:).TD_H] = r_out(:).TD_H;
    end
     r_out = r_outH;
     [r_out(:).skip] = deal(0);
     [r_out(badIndices).skip] = deal(1);
     save([tracedir2,tracePrefix2,suffix,'.mat'],'r_out');
    
    update(conn,'data_final','Quality_MC6',1,sprintf("Where Suffix= '%s'",suffix))
    clear r_out r_outH dff dffH traces tracesH nhat nhat2 rawTraces rawTracesH tPost tPre badIndices tiffTs     
    
    
end




  