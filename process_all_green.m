% process all videos (only save filtered-Normalize copy)
pathways = dir('Z:\Data\DanaTemp\PreProcessing\green\m_f_n*.tif');
savedir = 'Z:\Data\DanaTemp\PreProcessing\green\';

for f=1:size(pathways,1)
    %filename={pathways(f).name};
    %cd(pathways(1).folder)
    %suffix = pathways(f).name(8:end-17);
    suffix = pathways(f).name(7:end-6);
    %motion_correction_6OHDA_gpu(filename, suffix, savedir)
    vidList = dir(['Z:\Data\DanaTemp\PreProcessing\green\m_f_n_',suffix,'*']);
    data = [];
    for vid=1:numel(vidList)
        file = [vidList(vid).folder,'\',vidList(vid).name];
        data2 = tiff2matrix(file);
        data = cat(3,data,max(data2,[],3));
        clear data2
    end
    Ired = max(data,[],3);
    save([savedir,'Ired_',suffix],'Ired')%'_day',num2str(pathways(f).day)],'I')
    cd Z:\Data\DanaTemp\
end