function R_r = MarkRedCell_howard(Ired,Ic,R, Rc, tform)
    %This function help identify which cells are PV/Chol
    %Input:
    %   Ired - The tdTomato image
    %   Ic - max or mean image of the vidoes where you can see the
    %   vesculature for bench marking
    %   R - list of picked ROIs on TD map
    %   Rc - list of picked ROIs on Gcamp map 
    % Output:
    %   R_s - same as R with extra true falsse column named isPV or isChol
    
    % get contrast for both images:
    red = cat(3, ones(size(Ic)), zeros(size(Ic)), zeros(size(Ic)));
    green = cat(3, zeros(size(Ic)), ones(size(Ic)), zeros(size(Ic)));
    blue = cat(3, zeros(size(Ic)), zeros(size(Ic)), ones(size(Ic)));
    
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
    
    % transform TD image and TD ROIs:
    IredT = imwarp(Ired,tform,'OutputView',imref2d(size(Ired)));
    [Rt, RcaSkip, Rca] = deal(zeros(size(Ired)));
    for r = 1:numel(R)
        Rt = Rt + R(r).perimeter;
    end
    Rt = imwarp(Rt,tform,'OutputView',imref2d(size(Ired)));
    
    
    % draw Ca ROI on Ic (green for good, blue for skipped)
    
    if isfield(Rc, 'skip')
        for r = 1:numel(Rc)
            if Rc(r).skip
                RcaSkip = RcaSkip+Rc(r).perimeter;
            else
                Rca = Rca+Rc(r).perimeter;
            end
        end
    else
        for r = 1:numel(Rc)
            Rca = Rca+Rc(r).perimeter;
        end
    end
        
    rrI = figure;
    imshow(IredT,[Min,Max])
    hold on 
    pause
    rrI
    l =imshow(red);
    set(l, 'AlphaData', Rt)
    l2 =imshow(green);
    set(l2, 'AlphaData', Rca)
    l3 =imshow(blue);
    set(l3, 'AlphaData', RcaSkip)
      hold off
    pause
    cccI =figure;
    pause
    imshow(Ic,[minc,maxc])
    hold on 
    cccI;
    l =imshow(red);
    set(l, 'AlphaData', Rt)
    l2 =imshow(green);
    set(l2, 'AlphaData', Rca)
    l3 =imshow(blue);
    set(l3, 'AlphaData', RcaSkip)
    
    IIc = double(Ic);
    IIc(IIc>maxc) = maxc;
    IIc = (IIc -minc)./(maxc-minc);
    
    I = cat(3,Rt,IIc./3,RcaSkip);
%    figure;
%    imshow(I)
    pause
   
%     mb = msgbox('Please remove any ROIs that are marked with tdTomato');
    [~, R_r] = SemiSeg_Remove_H(I,Rc)

end