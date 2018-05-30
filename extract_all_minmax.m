% create max-min maps
% import the pathways file
tic;
fprintf('extracting max-min mpas');
 %pathways = table2struct( readtable('Z:\Data\DanaTemp\new_data\pathways.xlsx') );
 savedir = 'Z:\Data\DanaTemp\minmax\';
for f=1:size(pathways,1)
    if(pathways(f).I_minmax==1)
        continue
    end
    %vidList = dir(['Z:\Data\DanaTemp\processedVids_6OHDA\m_f_n_',num2str(pathways(f).mouse),'_day',num2str(pathways(f).day),'*']);
    vidList = dir(['Z:\Data\DanaTemp\new_data\Processed\m_f_n_',num2str(pathways(f).mouse),'_',pathways(f).type,'*']);
    data = [];
    for vid=1:numel(vidList)
        file = [vidList(vid).folder,'\',vidList(vid).name];
        data2 = tiff2matrix(file);
        data = cat(3,data,max(data2,[],3));
        data = cat(3,data,min(data2,[],3));
        clear data2
    end
    I = max(data,[],3) - min(data,[],3);
    save([savedir,'MaxMin_',num2str(pathways(f).mouse),...
        '_',pathways(f).type],'I')%'_day',num2str(pathways(f).day)],'I')
    clear I
    clear data
    toc
    pathways(f).I_minmax=1;
end
toc