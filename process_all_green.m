% process all videos (only save filtered-Normalize copy)
pathways = dir('green\*.tif');
savedir = 'Z:\Data\DanaTemp\green\';

for f=1:size(pathways,1)
    filename={pathways(f).name};
    cd(pathways(1).folder)
    suffix = pathways(f).name(8:end-17);
    motion_correction_6OHDA_gpu(filename, suffix, savedir)
    vidList = dir(['Z:\Data\DanaTemp\green\m_f_n_',suffix,'*']);
    data = [];
    for vid=1:numel(vidList)
        file = [vidList(vid).folder,'\',vidList(vid).name];
        data2 = tiff2matrix(file);
        data = cat(3,data,max(data2,[],3));
        data = cat(3,data,min(data2,[],3));
        clear data2
    end
    Ired = max(data,[],3) - min(data,[],3);
    save([savedir,'Ired_',suffix],'Ired')%'_day',num2str(pathways(f).day)],'I')
    cd Z:\Data\DanaTemp\
end