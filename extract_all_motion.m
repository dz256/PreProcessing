% Extract all motion files in folder

homeDir = 'Z:\Data\DanaTemp\PreProcessing\mvmt';
motionFiles = 'Z:\Data\DanaTemp\PreProcessing\mvmt\';
saveDir = 'Z:\Data\DanaTemp\PreProcessing\ExtractedEphys\'; %save in same folder as e_phys - easier to combine
skipFolders = [".","..","pathways.xlsx","~$pathways.xlsx"];

for j=1:numel(pathways)
    if(pathways(j).mvmt==1)
        continue
    end
    mdir = dir([motionFiles,'*',num2str(pathways(j).mouse),'_',pathways(j).type]);
    if numel(mdir) == 0
        continue
    end
    cd([motionFiles,mdir(1).name])
    savName = "mo_"+mdir(1).name(8:end);
    % load verfile
    mat = dir('*.mat');
    load(mat(1).name);
    % extract bdata and bInfo
   [bData, bInfo] = getData(vrffiles);
   % get movement components: 
   [~, rel_direction, dxdy, rotation] = getMovement(bData);
   % process movement and save
   dy = dxdy(:,2); 
   dx = dxdy(:,1);
   t = bInfo.Time-bInfo.Time(1);
   dt = bInfo.Dt;
   speed = sqrt((dy).^2+(dx).^2);
   phi = rel_direction; % direction a.k.a angle from Y axis
   %save
   save (saveDir+savName,'rotation','t','speed','phi')
   cd(homeDir) 
   pathways(j).mvmt=1;
   clearvars -except motionFiles j skipFolders saveDir homeDir pathways
end
    
    