% process all videos (only save filtered-Normalize copy)
%pathways = table2struct( readtable('Z:\Data\DanaTemp\Movement_files6OHDA\pathways.xlsx') );
pathways = table2struct( readtable('Z:\Data\DanaTemp\new_data\pathways.xlsx') );
savedir = 'Z:\Data\DanaTemp\new_data\Processed\';

for f=1:size(pathways,1)
    if(pathways(f).Motion_correction==1)
        continue
    end
    %vidList = dir(['Z:\Data\DanaTemp\videos\',pathways(f).name,'*']);
    vidList = dir(['Z:\Data\DanaTemp\new_data\',num2str(pathways(f).mouse),'\*_',pathways(f).cond,'\*',pathways(f).type,'(*.tif']);
    filename={vidList(:).name};
    cd(vidList(1).folder)
    suffix = [num2str(pathways(f).mouse),'_',num2str(pathways(f).type)];
    motion_correction_6OHDA_gpu(filename, suffix, savedir)
    cd Z:\Data\DanaTemp\
    pathways(f).Motion_correction=1;
end

% update excle to keep track on stuff. 
T = struct2table(pathways);
writetable(T,'Z:\Data\DanaTemp\new_data\pathways.xlsx')
% extract max-min and update file:
extract_all_minmax
T = struct2table(pathways);
writetable(T,'Z:\Data\DanaTemp\new_data\pathways.xlsx')
% extract autoROI and traces and update file:
extrac_all_ROIandTraces
T = struct2table(pathways);
writetable(T,'Z:\Data\DanaTemp\new_data\pathways.xlsx')