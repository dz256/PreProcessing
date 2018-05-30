% create max-min maps
% import the pathways file
tic;
 %pathways = table2struct( readtable('Z:\Data\DanaTemp\Movement_files6OHDA\pathways.xlsx') );
  pathways = table2struct( readtable('Z:\Data\DanaTemp\new_data\pathways.xlsx') );
 savedir = 'Z:\Data\DanaTemp\maxMean\';
for f=1:size(pathways,1)
    if(pathways(f).skip==1)
        continue
    end
  %vidList = dir(['Z:\Data\DanaTemp\processedVids_6OHDA\m_f_n_',num2str(pathways(f).mouse),'_day',num2str(pathways(f).day),'*']);
    vidList = dir(['Z:\Data\DanaTemp\new_data\Processed\m_f_n_',num2str(pathways(f).mouse),'_',pathways(f).type,'*']);    data = [];
    sizeV = 0;
    tot = zeros(1024,1024);
    for vid=1:numel(vidList)
        file = [vidList(vid).folder,'\',vidList(vid).name];
        data2 = tiff2matrix(file);
        data = cat(3,data,max(data2,[],3));
        tot = tot + sum(data2,3);
        sizeV = sizeV + size(data2,3); 
        clear data2
    end
    I = double(max(data,[],3)) - double(tot/sizeV);
    save([savedir,'MaxMean_',num2str(pathways(f).mouse),...
        '_',pathways(f).type],'I')%'_day',num2str(pathways(f).day)],'I')
    clear I
    clear data
    toc
end
toc