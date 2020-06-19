
% This script cleans "bad" ROIs based on traces, than match TD maps with
% ROIs ans save final structs (note - rejected ROIs are not erased, just marked)

% open connection to server and find which sessions already have traces and
% TD maps:

conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');

Sess =  table2array(select(conn, 'Select Suffix from data_final where redTform=1 and trace_extract=1 and redPicked = 1 and red_match=0;'));

% define importent paths:
greendir = '/home/dana_z/HD2/green/';
tracedir = '/home/dana_z/HD2/traces/';
mmdir = '/home/dana_z/HD1/min_max/MaxMin_';
transdir = '/home/dana_z/HD2/Ired_Transforms/';
ROIdir = '/home/dana_z/HD1/ROIs/';

% for each session:   

for s = 1:numel(Sess)
    suffix = char(Sess(s));
    
    %load trace, TD maps, and ROI:
    load([tracedir,'trace_',suffix,'.mat']);
    load([greendir,'Ired_',suffix,'.mat']);
    load([greendir,'redROI_',suffix,'.mat']);
    load([transdir,'redTform_',suffix,'.mat']);
    
    I = imread([mmdir,suffix,'.tif']);
    
    if ~isfield(r_out, 'perimeter')
        T  = load([ROIdir,'ROI_manual_',suffix,'.mat']);
        T = T.R;
        [r_out(:).perimeter] = T(:).perimeter;
        clear T
    end
          
    if ~isfield(R,'PixelIdxList')
        [r_out(:).TD_H] = deal(0);
         t = datetime('now');
         DateString = datestr(t);
        save([tracedir,'trace_',suffix,'.mat'],'r_out');
        update(conn,'data_final',{'red_match','date_redMatch'},{1,DateString},sprintf("Where Suffix= '%s'",suffix))
        disp('no red cells')
        disp(numel(Sess)-s)
        continue
    end
        
    % match red cells on reducted list:
    R_s = MarkRedCell_howard(Ired,I,R, r_out, tform);
    close all
    [r_out(:).TD_H] = deal(0);
    if numel(R_s)>0
     [r_out(R_s).TD_H] =deal(1);
    end
    
    t = datetime('now');
    DateString = datestr(t);
    save([tracedir,'trace_',suffix,'.mat'],'r_out');
    update(conn,'data_final',{'red_match','date_redMatch'},{1,DateString},sprintf("Where Suffix= '%s'",suffix))
       
    disp(numel(Sess)-s)
    
end




  