 % This script cleans "bad" ROIs based on traces, than match TD maps with
% ROIs ans save final structs (note - rejected ROIs are not erased, just marked)

% open connection to server and find which sessions already have traces and
% TD maps:

   
conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');
mice = table2array(select(conn, 'Select distinct(mouse_num) from data where mouse_num not in ("2976","2980","2981","0761");'));
%Sess =  table2array(select(conn, 'Select Suffix from data where green=1 and redTform=1;'));
Sess =  table2array(select(conn, 'Select Suffix from data where mouse_num not in ("2976","2980","2981");'));
% define importent paths:
greendir = '/home/dana_z/HD2/green/';
tracedir = '/home/dana_z/HD2/traces/';
ROIdir = '/home/dana_z/HD1/ROIs/';
TSdir = '/home/dana_z/HD1/tiffTs/';
mmdir = '/home/dana_z/HD1/min_max/MaxMin_';

for m = 1:numel(mice)
    mouse_num = mice(m);
    Sess =  (select(conn, sprintf("select data.Suffix, tdpicked from data left join newTDMatch using (Suffix)  where data.mouse_num =  '%s';",num2str(mouse_num))));
    if sum(Sess.tdpicked)== numel(Sess.Suffix)
        continue
    end
    Sess = Sess.Suffix; 
    % for each session:
    for s =1:numel(Sess)
        suffix = char(Sess(s))
            if suffix == "8430_day15A" 
                continue
            end
        a = table2array(select(conn, sprintf("Select tdpicked from newTDMatch where Suffix= '%s';",suffix)));
        if a==1
            load([greendir,'Ired_',suffix,'.mat']);
            load([greendir,'redROI_',suffix,'.mat']);
             Rt = deal(zeros(size(Ired))); 
             if isfield(R, 'perimeter')
                 for r = 1:numel(R)
                    Rt = Rt + R(r).perimeter;
                 end
             end
             red = cat(3, ones(size(Ired)), zeros(size(Ired)), zeros(size(Ired)));
             figure
             imshow(Ired)
             caxis([12500,20000])
             hold on 
             l =imshow(red);
             set(l, 'AlphaData', Rt)
             hold off
             pause
            continue
        end
        mouse_num = suffix(1:4);


        %load trace, TD maps, and ROI:  
        load([greendir,'Ired_',suffix,'.mat']);

        R = SemiSeg(Ired,[]); 
        save([greendir,'redROI_',suffix],'R')
        try
        datainsert(conn,'newTDMatch',{'Suffix','tdpicked'},{suffix,1})
        catch 
            continue
        end
       %  close all;   


    end
    close all;
end




  