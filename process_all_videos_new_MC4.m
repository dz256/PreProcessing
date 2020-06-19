% RE-process vids... new vids will need altering to this code. 
% This is because correct_motion_MC4 require ROI struct and does not save 
% max-min vid... 


% set "gloabl" parameters:
savedir1 = '/home/dana_z/HD1/';
savedir2 = '/home/dana_z/HD2/';
ROIdir = '/home/dana_z/HD1/ROIs/ROI_manual_';
tiffDir = '/home/dana_z/handata2/dana/';
% Set up an SQL connection and get all already Processed sessions:
conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');
skipSess =  table2array(select(conn, 'Select Suffix from data_final where MC=1 or skip=1;'));
Sess = table2array(select(conn, 'Select Suffix from data where ROI=1;'));

% iterate over all sessionsin Handata2 and create a list of sessions to be
% processed:

for s = 1:numel(Sess)
    suffix = char(Sess(s));   
    % if session was already prcessed - skip...
    if (~isempty(skipSess)) && ismember(suffix,skipSess)
       continue
    end
    sessName = suffix(6:end);
    mouseNum = suffix(1:4);
    % else - process motion+ minmax+tiffTS
    vidList = dir([tiffDir,mouseNum,'/*_',sessName,'/*.tif']);
    greens = 1:numel(vidList);
   for r=1:numel(vidList)
       if numel(vidList(r).name(cell2mat(regexp({vidList(r).name}, '(green)')):end))~=0
        greens(r) = -1;
       end
   end
   vidList = vidList(greens~=-1);
   clear r greens
    % if no videos continue
    if(numel(vidList) == 0)
         continue
    end
    filename={vidList(:).name};
    cd(vidList(1).folder)
    try
    load([ROIdir,suffix,'.mat']);
    startFrame =  table2array(select(conn,['Select skipFrames from data where Suffix="',suffix,'";']));
    if isempty(startFrame)
        startFrame = 1;
    else
        startFrame = max(startFrame,1);
    end

    if str2double(mouseNum)<2000
        savedir = savedir1;
    else 
        savedir = savedir2;
    end

    motion_correction_6OHDA_MC4(filename, suffix, savedir,R)
    cd /home/dana_z/ssd_2TB/PreProcessing
    t = datetime('now');
    DateString = datestr(t);
    try
        datainsert(conn,'data_final',{'mouse_num','session','Suffix','MC','ROI','date'},...
            {str2double(mouseNum),sessName,suffix,1,1,DateString}) 
    catch 
        update(conn,'data_final',{'mouse_num','session','Suffix','MC','ROI','date'},...
            {str2double(mouseNum),sessName,suffix,1,1,DateString},sprintf("Where Suffix= '%s'",suffix));
    end
    catch em
        disp([suffix, ' failed with error: ',em.message])
         %datainsert(conn,'data',{'mouse_num','session','Suffix','MC','skip'},...
        %{str2double(miceN(m).name),sType(2:end),suffix,0,1}) 
        datainsert(conn,'MC_errors ',{'mcEr','Suffix'},...
            {em.message,suffix}) 

    end

end





