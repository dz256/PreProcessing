
% This script cleans "bad" ROIs based on traces, than match TD maps with
% ROIs ans save final structs (note - rejected ROIs are not erased, just marked)

% open connection to server and find which sessions already have traces and
% TD maps:

   
conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');

Sess =  table2array(select(conn, 'Select Suffix from data where green=1 and redTform=0 and mouse_num not in ("2976","2980","2981");'));

% define importent paths:
greendir = '/home/dana_z/HD2/green/';
mmdir = '/home/dana_z/HD1/min_max/MaxMin_';
savedir = '/home/dana_z/HD2/Ired_Transforms/';

% for each session:
for s = 1:numel(Sess)
    suffix = char(Sess(s))
    if suffix == "8430_day13"
        continue
    end
    
    %load Ired and Iminmax:
    load([greendir,'Ired_',suffix,'.mat']);
    I = imread([mmdir,suffix,'.tif']);
    
    % add curve by curve to a mask: 
    %--------------------------------
    
    % Adjust contrast of the 2 images:
    Min = 0; Max = 5000;
    H = figure;
    imshow(I,[Min,Max])
    title('gCamp')
    while(true) %Adjust Contrast
        answer = inputdlg({'Min','Max'}, 'Contrast',1,{num2str(Min),num2str(Max)});
        Min = str2double(answer{1});
        Max = str2double(answer{2});
        H = imshow(I, [Min Max]); title('Adjust gCamp Contrast');
        button = questdlg('Is this okay?',...
            'Select this Contrast Level?','Yes','No','Yes');
        if strcmp(button,'Yes')
            break
        else
            continue
        end
    end
    close(ancestor(H, 'figure'))
    minc = Min;
    maxc = Max;
    
    Min = 0; Max = 25000;
    h = figure;
    imshow(Ired,[Min,Max])
    title('tdTomato')
    while(true) %Adjust Contrast
        answer = inputdlg({'Min','Max'}, 'Contrast',1,{num2str(Min),num2str(Max)});
        Min = str2double(answer{1});
        Max = str2double(answer{2});
        H = imshow(Ired, [Min Max]); title('Adjust gCamp Contrast');
        button = questdlg('Is this okay?',...
            'Select this Contrast Level?','Yes','No','Yes');
        if strcmp(button,'Yes')
            break
        else
            continue
        end
    end
    close(h)
    
    %show both images side by side:
    figure;
    pc = subplot(1,2,1)
    imshow(I,[minc,maxc])
    title('gCamp')
    pr = subplot(1,2,2)
    imshow(Ired,[Min,Max])
    title('tdTomato')
    
    green = cat(3, zeros(size(I)), ones(size(I)), zeros(size(I)));
    Imask = zeros(size(I));
    redMask = zeros(size(Ired));
   while(true) 
        pc;
        mb = msgbox('Zoom to desired area and pick landmark on the **gCamp** image');
        zoom on;
        pause
        h = impoly(pc,'closed',false);
        xsys = getPosition(h);
        xs = xsys(:,1);
        ys = xsys(:,2);
        hold on 
        % erase the impoly lines:
        N = LineNormals2D(xsys); %Dirk-Jan!!!! This rocks!
        thicknessMultiplier = 2;
        delete(h);
        while(true)
            % plot the line we just calculated: 
            posn = [xs-thicknessMultiplier*N(:,1) ys-thicknessMultiplier*N(:,2);
            flipud(xs+thicknessMultiplier*N(:,1)) flipud(ys+thicknessMultiplier*N(:,2))];
            posn(isnan(posn(:,1)),:)=[];
            lt= figure;
            lt2 = subplot(1,1,1);
            imshow(I)
            h = impoly(lt2,posn);
            tempMask = createMask(h);
            delete(h)
            close(lt)
            pc
            hold on 
            l = imshow(green);
            set(l, 'AlphaData', tempMask)
            button = questdlg('Do you want to change line thickness?',...
                'Is this o.k','Yes','No','Yes');
            if strcmp(button,'Yes')
                answer = inputdlg({'thickness'}, 'Thickness',1,{num2str(thicknessMultiplier)});
                thicknessMultiplier = str2double(answer{1}); 
                children = get(pc, 'children');
                delete(children(1));
            else
                Imask = Imask + tempMask;
                break
            end
        end
        
        % repeate for pr:
        pr
        mb = msgbox('Zoom to desired area and pick landmark on the **TD** image');
        zoom on;
        pause
        h = impoly(pr,'closed',false);
        xsys = getPosition(h);
        xs = xsys(:,1);
        ys = xsys(:,2);
        hold on 
        % erase the impoly lines:
        N = LineNormals2D(xsys); %Dirk-Jan!!!! This rocks!
        thicknessMultiplier = 2;
        delete(h);
        while(true)
            % plot the line we just calculated: 
            posn = [xs-thicknessMultiplier*N(:,1) ys-thicknessMultiplier*N(:,2);
            flipud(xs+thicknessMultiplier*N(:,1)) flipud(ys+thicknessMultiplier*N(:,2))];
            posn(isnan(posn(:,1)),:)=[];
            lt= figure;
            lt2 = subplot(1,1,1);
            imshow(I)
            h = impoly(lt2,posn);
            tempMask = createMask(h);
            delete(h)
            close(lt)
            pr
            hold on 
            l = imshow(green);
            set(l, 'AlphaData', tempMask)
            button = questdlg('Do you want to change line thickness?',...
                'Is this o.k','Yes','No','Yes');
            if strcmp(button,'Yes')
                answer = inputdlg({'thickness'}, 'Thickness',1,{num2str(thicknessMultiplier)});
                thicknessMultiplier = str2double(answer{1}); 
                children = get(pr, 'children');
                delete(children(1)); 
            else
                redMask = redMask + tempMask;
                break
            end
        end
        
        button = questdlg('Would you  like to add more landmarks?','More rois?','Yes','No','Yes');
        if ~strcmp(button,'Yes')
            break
        end

   end
 
  % motion correction on Imask and redMask
  [optimizer, metric] = imregconfig('monomodal');
  tform = imregtform(redMask,Imask, 'translation', optimizer, metric);
  movingRegistered = imwarp(redMask,tform,'OutputView',imref2d(size(Imask)));
  redRegistered = imwarp(Ired,tform,'OutputView',imref2d(size(Imask)));
  % overlay to make sure make sense, if user is happy save everything and
  % update database
   
  figure; 
  subplot(1,2,1)
  imshowpair(Imask,movingRegistered)
  subplot(1,2,2)
  imshowpair(I,redRegistered,'Scaling','joint')
  pause
  button = questdlg('Are you happy with this transformation?',...
                'Is this o.k','Yes','No','Yes');
  if ~strcmp(button,'Yes')
     disp('O.K, lets start over later...')
     close all
     continue
  end
  close all
  save([savedir,'redTform_',suffix],'tform','Imask','redMask');  
  update(conn,'data','redTform',1,sprintf("Where Suffix= '%s'",suffix))
  disp(numel(Sess)-s)
end




  