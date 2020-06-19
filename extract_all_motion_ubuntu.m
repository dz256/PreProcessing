% Extract all motion files in folder

saveDir = '/home/dana_z/HD1/extracted_ephys_matlab/'; 
homeDir = '/home/dana_z/ssd_2TB/PreProcessing/';

conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');
Sess =  table2array(select(conn, 'Select Suffix from data where mvmt=0;'));


for j=1:numel(Sess)
   suffix = char(Sess(j));
    
    mdir = dir(['/home/dana_z/handata2/Dana_Zemel/',num2str(suffix(1:4)),'/*_',num2str(suffix(6:end)),'/']);
    mdir = mdir([mdir(:).isdir] ==1);
    mdir = mdir(~ismember({mdir(:).name},[".","..","take-1"])); 
    if numel(mdir) ~= 1
        continue  
    end
    cd([mdir.folder,'/',mdir(1).name])
    savName = "mo_"+suffix;
    % load verfile
    mat = dir('*.mat');
    load(mat(1).name);
    % extract bdata and bInfo
   [bData, bInfo] = getData(vrffiles);
   % get movement components: 
   if ~ismember(suffix(1:4),["7909","7584","4539"]) 
       [~, rel_direction, dxdy, rotation] = getMovement(bData);
   else
       [~, rel_direction, dxdy, rotation] = getMovement_bad(bData);
   end
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
   update(conn,'data','mvmt',1,sprintf("Where Suffix= '%s'",suffix))

   clearvars -except motionFiles j saveDir homeDir conn Sess
end
    
    
