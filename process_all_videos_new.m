% set "gloabl" parameters:
savedir = '/home/dana_z/HD1/';

% Set up an SQL connection and get all already Processed sessions:
conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');
skipSess =  table2array(select(conn, 'Select Suffix from data where MC=1 or skip=1;'));
dmice = table2array(select(conn, 'Select mouse_num from mice;'));

% iterate over all sessionsin Handata2 and create a list of sessions to be
% processed:

miceN = dir('/home/dana_z/handata2/Dana/');
%miceN = dir('/home/dana_z/HD2');
idx = find(not(cellfun(@isempty, regexp({miceN.name}, '\d{4,}$','match'))));
miceN = miceN(idx);

for m = 1:numel(miceN)
    if miceN(m).isdir ~=1
        continue
    end
    
    %if a new mouse, add to mice table:
    if ~ismember(str2double(miceN(m).name),dmice)
        disp('new mouse detected - adding to table')
        datainsert(conn,'mice','mouse_num',str2double(miceN(m).name)) 
    end
    
    % get all sessions in mouse folder:
    sessNames = dir(fullfile(miceN(m).folder,miceN(m).name));
    idx = find(not(cellfun(@isempty, regexp({sessNames.name}, '(_day|_Baseline)','match'))));
    sessNames = sessNames(idx);
    for s = 1:numel(sessNames)
        sType = sessNames(s).name(cell2mat(regexp({sessNames(s).name}, '(_day|_Baseline)')):end)
        suffix = [miceN(m).name,sType];
        % if session was already prcessed - skip...
        if ismember(suffix,skipSess)
           continue
        end
        % else - process motion+ minmax+tiffTS
       vidList = dir([sessNames(s).folder,'/',sessNames(s).name,'/*.tif']);
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
        startFrame =  table2array(select(conn,['Select skipFrames from data where Suffix="',suffix,'";']));
        if isempty(startFrame)
            startFrame = 1;
        else
            startFrame = max(startFrame,1);
        end
        motion_correction_6OHDA_gpu(filename, suffix, savedir,startFrame)
        cd /home/dana_z/ssd_2TB/PreProcessing
        try
            datainsert(conn,'data',{'mouse_num','session','Suffix','MC'},...
                {str2double(miceN(m).name),sType(2:end),suffix,1}) 
        catch 
            update(conn,'data',{'mouse_num','session','Suffix','MC'},...
                {str2double(miceN(m).name),sType(2:end),suffix,1},sprintf("Where Suffix= '%s'",suffix));
        end
        catch em
            disp([suffix, ' failed with error: ',em.message])
             %datainsert(conn,'data',{'mouse_num','session','Suffix','MC','skip'},...
            %{str2double(miceN(m).name),sType(2:end),suffix,0,1}) 
            datainsert(conn,'MC_errors ',{'mcEr','Suffix'},...
                {em.message,suffix}) 
       
        end
        
    end


end





