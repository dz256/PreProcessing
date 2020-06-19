 % This script cleans "bad" ROIs based on traces, than match TD maps with
% ROIs ans save final structs (note - rejected ROIs are not erased, just marked)

% open connection to server and find which sessions already have traces and
% TD maps:

   
conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');


% define importent paths:
greendir = '/home/dana_z/HD2/green/';
tracedir = '/home/dana_z/HD2/traces/';
mmdir = '/home/dana_z/HD1/min_max/MaxMin_';
transdir = '/home/dana_z/HD2/Ired_Transforms/';
ROIdir = '/home/dana_z/HD1/ROIs/';

sizei = [1024,1024];
orange = cat(3, ones(sizei), ones(sizei), zeros(sizei));
red = cat(3, ones(sizei), zeros(sizei), zeros(sizei));
green = cat(3, zeros(sizei), ones(sizei), zeros(sizei));


mouseList = ["1793"];
for m = mouseList
    % Get sessions with and without TD cells
    TDSess =  table2array(select(conn, sprintf("select t2.Suffix from stats left join data_final t2 using (Suffix) where numTD > 0 and t2.mouse_num =  '%s';",m)));
    Sess =  table2array(select(conn, 'select t2.Suffix from stats left join data_final t2 using (Suffix) where mouse_num in ("8803") and numTD = 0;'));
    % Go over all sessions with TD cells and display:
    for s = 1:numel(TDSess)
         suffix = char(TDSess(s));
         load([tracedir,'trace_',suffix,'.mat']);
         load([greendir,'Ired_',suffix,'.mat']);
         load([greendir,'redROI_',suffix,'.mat']);
         load([transdir,'redTform_',suffix,'.mat']);
          
         IredT = imwarp(Ired,tform,'OutputView',imref2d(size(Ired)));
         [Rt, RcTD, Rc] = deal(zeros(size(Ired)));
         for r = 1:numel(R)
            Rt = Rt + R(r).perimeter;
         end
         Rt = imwarp(Rt,tform,'OutputView',imref2d(size(Ired)));
         
         for r = 1:numel(r_out)
            if r_out(r).TD_H
                RcTD = RcTD+r_out(r).perimeter;
            else
                Rc = Rc+r_out(r).perimeter;
            end
         end
         
         rrI(s) = figure;
         Min = 15000; Max = 25000;
         H = imshow(IredT, [Min Max]); title('Adjust gCamp Contrast');       
         while(true) %Adjust Contrast
              answer = inputdlg({'Min','Max'}, 'Contrast',1,{num2str(Min),num2str(Max)});
              Min = str2double(answer{1});
              Max = str2double(answer{2});
              H = imshow(IredT, [Min Max]); title('Adjust gCamp Contrast');
              button = questdlg('Is this okay?',...
                  'Select this Contrast Level?','Yes','No','Yes');
              if strcmp(button,'Yes')
                  break
              else
                  continue
              end
         end
         hold on 
         pause
         rrI(s)
         l =imshow(red);
         set(l, 'AlphaData', Rt)
         l2 =imshow(green);
         set(l2, 'AlphaData', Rc)
         l3 =imshow(orange);
         set(l3, 'AlphaData', RcTD)
         hold off
         title(suffix)
         pause
    end
   
    % for each session: 
    for s = 2:numel(Sess)
        suffix = char(Sess(s))
        load([tracedir,'trace_',suffix,'.mat']);
        load([greendir,'Ired_',suffix,'.mat']);
        load([greendir,'redROI_',suffix,'.mat']);
        load([transdir,'redTform_',suffix,'.mat']);
        I = imread([mmdir,suffix,'.tif']);

        IredT = imwarp(Ired,tform,'OutputView',imref2d(size(Ired)));
        [Rt, RcTD, Rc] = deal(zeros(size(Ired)));
        for r = 1:numel(R)
           Rt = Rt + R(r).perimeter;
        end
        Rt = imwarp(Rt,tform,'OutputView',imref2d(size(Ired)));
         
        for r = 1:numel(r_out)
           Rc = Rc+r_out(r).perimeter;
        end
        
        [~, newTd] = SemiSeg_TD2(IredT, r_out, Rt,Rc,I) 
        if numel(newTd)>0
         [r_out(newTd).TD_H] =deal(1);
         save([tracedir,'trace_',suffix,'.mat'],'r_out')
        end

    end
    close all;
end

  