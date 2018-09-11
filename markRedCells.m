function R_s = markRedCells(Ired,Ic,R,PV)
    %This function help identify which cells are PV/Chol
    %Input:
    %   Ired - The tdTomato image
    %   Ic - max or mean image of the vidoes where you can see the
    %   vesculature for bench marking
    %   R - list of picked ROIs
    %   PV - are the marked cells PV? if not will call the field Chol
    % Output:
    %   R_s - same as R with extra true falsse column named isPV or isChol
    
    
    % get contrast for both images:
    Min = 0; Max = 5000;
    h = figure;
    imshow(Ic,[Min,Max])
    title('gCamp')
    while(true) %Adjust Contrast
        answer = inputdlg({'Min','Max'}, 'Contrast',1,{num2str(Min),num2str(Max)});
        Min = str2double(answer{1});
        Max = str2double(answer{2});
        H = imshow(Ic, [Min Max]); title('Adjust gCamp Contrast');
        button = questdlg('Is this okay?',...
            'Select this Contrast Level?','Yes','No','Yes');
        if strcmp(button,'Yes')
            break
        else
            continue
        end
    end
    close(h)
    minc = Min;
    maxc = Max;
    
    Min = 0; Max = 5000;
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
    imshow(Ic,[minc,maxc])
    title('gCamp')
    pr = subplot(1,2,2)
    imshow(Ired,[Min,Max])
    title('tdTomato')
    
   [xc,yc,xr,yr] = deal([]); 
   while(true) 
        pc
        mb = msgbox('Zoom to desired area and pick landmark on the **gCamp** image');
        zoom on;
        pause
        [x,y] = getpts(pc)
        xc = [xc;x];
        yc = [yc;y];
        hold on 
        dc = 1/length(xc);
        c =[[0:dc:dc*(length(xc)-1)]',zeros(size(xc)),[(length(xc)-1)*dc:-dc:0]'];
        scatter(xc,yc,[],c,'filled')
        mb = msgbox('now pick the same points on the **tdTomato** image IN SAME ORDER');
        pr
        zoom on;
        pause
        [x,y] = getpts(pr)
        xr = [xr;x];
        yr = [yr;y];
        button = questdlg('Would you  like to add more landmarks?','More rois?','Yes','No','Yes');
        if ~strcmp(button,'Yes')
            break
        end
        hold on
        scatter(xr,yr,[],c,'filled')
   end
   zoom reset
   outputView = imref2d(size(Ired));
   tform = estimateGeometricTransform([xr,yr],[xc,yc],'similarity')
   Ir = imwarp(Ired,tform,'OutputView',outputView);
   figure;
   subplot(2,2,1)
   imshow(Ic,[minc,maxc])
   subplot(2,2,2)
   imshowpair(Ired, [Min,Max])
   subplot(2,2,[3,4])
   imshowpair(Ic,Ir)


   overlayROI_Kyle(Ic,R)
   overlayROI_Kyle(Ired,R)
   pause
   
   mb = msgbox('Please remove any ROIs that are marked with tdTomato');
   [~, R_r] = SemiSeg_Remove(Ir,R)
   R_s = R;
   if PV
    [R_s.isPV] = deal(0);
    [R_s(R_r).isPV] = deal(1);
   else
    [R_s.isChol] = deal(0);
    [R_s(R_r).isChol] = deal(1); 
   end
end