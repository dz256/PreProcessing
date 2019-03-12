% set "gloabl" parameters:
savedir = '/home/dana_z/HD2/tracesMC2/';

% Set up an SQL connection and get all already Processed sessions:
conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');
skipSess =  table2array(select(conn, 'Select Suffix from data where MC2=1 or skip=1;'));
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
    % get all sessions in mouse folder:
    sessNames = dir(fullfile(miceN(m).folder,miceN(m).name));
    idx = find(not(cellfun(@isempty, regexp({sessNames.name}, '(_day|_Baseline)','match'))));
    sessNames = sessNames(idx);
    for s = 1:numel(sessNames)
        sType = sessNames(s).name(cell2mat(regexp({sessNames(s).name}, '(_day|_Baseline)')):end);
        suffix = [miceN(m).name,sType]
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
        load(['/home/dana_z/HD1/ROIs/ROI_manual_',suffix,'.mat'])    
        motion_correction_6OHDA_MC2(filename, suffix, savedir,R)
        cd /home/dana_z/ssd_2TB/PreProcessing
        update(conn,'data','MC2',1,sprintf("Where Suffix= '%s'",suffix))
        catch em
            continue 
        end
        
    end


end





