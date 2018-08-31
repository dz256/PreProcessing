% create max-min maps
% import the pathways file
tic;
fprintf('extracting max-loc mpas');
 pathways = table2struct( readtable('Z:\Data\DanaTemp\PreProcessing\new_data\pathways.xlsx') );
 savedir = 'Z:\Data\DanaTemp\PreProcessing\minmax\';
for f=1:size(pathways,1)
    if(pathways(f).maxloc==1)
        continue
    end
    %vidList = dir(['Z:\Data\DanaTemp\processedVids_6OHDA\m_f_n_',num2str(pathways(f).mouse),'_day',num2str(pathways(f).day),'*']);
    vidList = dir(['Z:\Data\DanaTemp\PreProcessing\new_data\Processed\m_f_n_',num2str(pathways(f).mouse),'_',pathways(f).type,'*']);
    if(numel(vidList) == 0)
        continue
    end
    for vid=1:numel(vidList)
        file = [vidList(vid).folder,'\',vidList(vid).name];
        data2 = tiff2matrix(file);
        if vid ==1
            [maxVid,mloc] = max(data2,[],3);
        else
            [newMax,newloc] = max(data2,[],3);
            mloc(newMax>maxVid)  = newloc(newMax>maxVid) + (vid-1)*2047;
            maxVid(newMax>maxVid) = newMax(newMax>maxVid);
        end
        clear data2 newMax newloc
    end
    
    save([savedir,'Maxloc_',num2str(pathways(f).mouse),...
        '_',pathways(f).type],'mloc')%'_day',num2str(pathways(f).day)],'I')
    toc
    pathways(f).maxloc=1;
end
toc