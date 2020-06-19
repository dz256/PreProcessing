% set "gloabl" parameters:
savedir = '/home/dana_z/HD2/processPipelineTests/';
    
% load the test sesssion:
load('filelist.mat')
suffix = '8430_BaselineA';
% else - process motion+ minmax+tiffTS
filename=fname;
cd(fdir)
try
load(['/home/dana_z/HD1/ROIs/ROI_manual_',suffix,'.mat'])    
motion_correction_6OHDA_MC4(filename, suffix, savedir,R)
cd /home/dana_z/ssd_2TB/PreProcessing
catch em

end









