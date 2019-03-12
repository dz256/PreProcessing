
% This script cleans "bad" ROIs based on traces, than match TD maps with
% ROIs ans save final structs (note - rejected ROIs are not erased, just marked)

% open connection to server and find which sessions already have traces and
% TD maps:

   
conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');

Sess =  table2array(select(conn, 'Select Suffix from data where green=1 and trace_extract=1 and red_match=0;'));

% define importent paths:
greendir = '/home/dana_z/HD2/green/';
tracedir = '/home/dana_z/HD2/traces/';
ROIdir = '/home/dana_z/HD1/ROIs/';
TSdir = '/home/dana_z/HD1/tiffTs/';
mmdir = '/home/dana_z/HD1/min_max/MaxMin_';

% for each session:
for s = 1:numel(Sess)
    suffix = char(Sess(s));
    
    %load trace, TD maps, and ROI:
    load([tracedir,'trace_',suffix,'.mat']);
    load([ROIdir,'ROI_manual_',suffix,'.mat']);
    load([greendir,'Ired_',suffix,'.mat']);
    load([TSdir,'tiffTs_',suffix,'.mat']);
    
    
    %------------------
    % TODO: earse? maybe just save a struct that can be open with the hdf5
    %-----------------
    % add perimeter field to the trace stuct (so don't have to update
    % things in both ROI mat and trace mat... +  add skip field and TD
    % field:
    
    [r_out(:).perimeter] = R(:).perimeter;
    [r_out(:).skip] = deal(0);
    [r_out(:).TD] = deal(0);
    
    % calc delta f over f, detrend traces, and interpolate time stemps:
    
    TS = 1/20; %sample frequency to match traces
    t = 0:TS:max(tiffTs);
    if min(tiffTs>1)
        disp('missing first tiff? look at session menually')
        update(conn,'data','red_match',63,sprintf("Where Suffix= '%s'",suffix))
        continue
    end
            
    rawTraces = zeros(size(tiffTs,1),numel(r_out));
    
    for r = 1:numel(r_out)
        rawTraces(:,r) = r_out(r).trace;
    end
    
    try
    traces = interp1(tiffTs,rawTraces,t,'pchip');
    catch em
        update(conn,'data','red_match',64,sprintf("Where Suffix= '%s'",suffix))
        continue
    end
    
    dff =  bsxfun(@rdivide, bsxfun(@minus,traces, nanmean(traces)), nanmean(traces));
%     dff = [];
%     for j = 1:floor(size(traces,1)/12000)
%         jj = 12000*(j-1)+1;
%         jjj = min(12000*j,size(traces,1));
%         dff_n =bsxfun(@rdivide, bsxfun(@minus,traces(jj:jjj,:), nanmean(traces(jj:jjj,:))), nanmean(traces(jj:jjj,:)));
%         dff = vertcat(dff, dff_n);
%     end
        
    %dff =  bsxfun(@rdivide, bsxfun(@minus,traces, movmean(traces,[1200,1200],1,'omitnan')), movmean(traces,[1200,1200],1,'omitnan'));
    % plot traces for first 10 min:
    tPre = find(t<=600,1,'last');
     nhat = median(max(dff(1:tPre,:)));
    [~, badIndices] =markBadTraces(t(1:tPre), dff(1:tPre,:), nhat*2, r_out);
    
    tPost = find(t>900,1,'first');
    % plot traces for post infusion period for "bad indeces" to make sure these aren't real indicies:
    if numel(badIndices)>0 && numel(tPost)>0
        
        %nhat = max(max(dff(tPost:end,badIndices)));
        %[~, realbadInd] =markBadTraces(t(tPost:end), dff(tPost:end,badIndices), abs(nhat)*10, r_out(badIndices));
        nhat = median(max(traces(tPost:end,badIndices)));
        [~, realbadInd] =markBadTraces(t(tPost:end), traces(tPost:end,badIndices), abs(nhat)*3, r_out(badIndices));

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
    if strcmp(button,'Yes')
        update(conn,'data','goOverVid',1,sprintf("Where Suffix= '%s'",suffix))
    end
    clear R2
    close all
    
    % mark "bad traces on trace list:
    [r_out(badIndices).skip] = deal(1);
    
    % match red cells on reducted list:
    R_s = markRedCells(Ired,I,R);
    close all
    if numel(R_s)>0
     [r_out(R_s).TD] =deal(1);
    end
    
    save([tracedir,'trace_',suffix,'.mat'],'r_out');
    update(conn,'data','red_match',1,sprintf("Where Suffix= '%s'",suffix))
       
    
    
end




  