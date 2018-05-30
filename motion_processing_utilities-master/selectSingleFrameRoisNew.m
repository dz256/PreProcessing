 % Pass this function a max minus min projection. Allows you to
% manually select ROIs based on maximum values for each pixel in data.
function roi = selectSingleFrameRoisNew(singleFrame)
%     singleFrame = log(cast(singleFrame,'double'));
    sz = size(singleFrame);
    roiList = cell(0);
    Min = 0; Max = 100;
    currFig = figure;
    H = imshow(singleFrame, [Min Max]); title('Select rois for this video'); 
    while(true)
        answer = inputdlg({'Min','Max'}, 'Contrast',1,{num2str(Min),num2str(Max)});
        Min = str2double(answer{1});
        Max = str2double(answer{2});
        figure(currFig)
        H = imshow(singleFrame, [Min Max]); title('Select rois for this video'); 
        button = questdlg('Is this okay?',...
                'Keep ROI','Yes','No','Yes');
        if strcmp(button,'Yes')
            break
        else
            continue
        end
    end
    hold on
    
    
    while(true)
        mb = msgbox('Zoom to desired area');
        zoom
        pause
        [xList,yList] = getpts;
        for inputs=1:length(xList)
            % next few lines modified from MATLAB forums: https://www.mathworks.com/matlabcentral/newsreader/view_thread/146031
            cx=xList(inputs);cy=yList(inputs);ix=size(singleFrame,2);iy=size(singleFrame,1);r=6;
            [x,y]=meshgrid(-(cx-1):(ix-cx),-(cy-1):(iy-cy));
            c_mask=((x.^2+y.^2)<=r^2);
            b = bwboundaries(c_mask);
            circ = plot(b{1}(:,2),b{1}(:,1),'r');
                delete(circ)
                plot(b{1}(:,2),b{1}(:,1),'g');
                roiList{end+1} = regionprops(c_mask,...
                  'Centroid', 'BoundingBox','Area',...
                  'Eccentricity', 'PixelList','PixelIdxList','Perimeter');
                roiList{end}.BoundaryTrace.x = b{1}(:,2);
                roiList{end}.BoundaryTrace.y = b{1}(:,1);
        end
        button = questdlg('Would you  like to add more rois?','More rois?','Yes','No','Yes');
        if ~strcmp(button,'Yes')
            break
        end
    end
    roi = cat(1,roiList{:});
    
end
