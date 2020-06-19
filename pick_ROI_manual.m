% define save dir + establish database connection: 
savedir = '/home/dana_z/HD1/';
imageDir = '/home/dana_z/HD1/min_max/MaxMin_';
ROIdir = '/home/dana_z/HD1/ROIs/ROI_manual_';
% Set up an SQL connection and get all already Processed sessions:
conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');

% list of sesions where motion corrected, but ROI not selected:
Sess =  table2array(select(conn, 'Select Suffix from data_final where MC=1 AND ROI<>1;'));

for im = 1:numel(Sess)
    suffix = char(Sess(im));
    %open max-min map:
    Name =[imageDir,suffix,'.tif'];
    I = imread(Name);
    
    if isfile([ROIdir,suffix,'.mat'])
        % Overlay image, and give oppertonity to remove, and add ROIs
        R = load([ROIdir,suffix,'.mat']);
        R = R.R;
        [R,badROI] = SemiSeg_Remove(I,R);
        R = SemiSeg(I,R);
        save([ROIdir,suffix],'R')
    else
        % manually pick ROIs
        R = SemiSeg(I,[]);
        save([ROIdir,suffix],'R')
    end
    update(conn,'data','ROI',1,sprintf("Where Suffix= '%s'",suffix))
    close all;
end