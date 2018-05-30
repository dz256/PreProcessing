% Extract all motion files in folder

homeDir = 'Z:\Data\DanaTemp\mvmt';
motionFiles = dir('Z:\Data\DanaTemp\mvmt');
saveDir = 'Z:\Data\DanaTemp\ExtractedEphys\'; %save in same folder as e_phys - easier to combine
skipFolders = [".","..","pathways.xlsx","~$pathways.xlsx"];

for j=1:numel(motionFiles)
    if(ismember(motionFiles(j).name,skipFolders))
        continue
    end
    cd(motionFiles(j).name)
    savName = "mo_"+motionFiles(j).name;
    % load verfile
    mat = dir('*.mat');
    load(mat(1).name);
    % extract bdata and bInfo
   [bData, bInfo] = getData(vrffiles);
   % get movement components: 
   [~, ~, dxdy, rotation] = getMovement(bData);
   % process movement and save
   dy = dxdy(:,2); 
   dx = dxdy(:,1);
   t = bInfo.Time-bInfo.Time(1);
   dt = bInfo.Dt;
   speed = sqrt((dy./dt).^2+(dx./dt).^2);
   phi = atan2(dy,dx);
   %save
   save (saveDir+savName,'rotation','t','speed','phi')
   cd(homeDir) 
   
   clearvars -except motionFiles j skipFolders saveDir homeDir
end
    
    