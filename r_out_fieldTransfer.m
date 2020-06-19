conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');

Sess =  table2array(select(conn, "Select Suffix from data_final where mouse_num in ('2981','2980','2976');"));
tracedir = '/home/dana_z/HD2/traces/';
ROIdir = '/home/dana_z/HD1/ROIs/';


for s = 1:numel(Sess)
    suffix = char(Sess(s));
    load([tracedir,'trace_',suffix,'.mat']);
    if ~isfield(r_out, 'perimeter')
        suffix
        T  = load([ROIdir,'ROI_manual_',suffix,'.mat']);
        T = T.R;
        [r_out(:).perimeter] = T(:).perimeter;
        save([tracedir,'trace_',suffix,'.mat'],'r_out');
        clear T
    end
end
    