function [goodIndices, badIndices, badIndicesH] = markBadTraces3(t, dff, nhat, dffH,nhatH,colors)
    badIndices = [];
%    badIndicesH = [];
    % following function modified from https://gist.github.com/cholland29/3107790
    function OnClickAxes(hax, evt)
        point1 = get(hax,'CurrentPoint'); % corner where rectangle starts ( initial mouse down point )
        rbbox
        point2 = get(hax,'CurrentPoint'); % corner where rectangle stops ( when user lets go of mouse )

        % Now lets iterate through all lines in the axes and extract the data that lies within the selected region
        allLines = findall(hax,'type','line');
        allLines = flipud(allLines);
       dataInd = getDataInRect(point1(1,1:2), point2(1,1:2), allLines); % not interested in z-coord

%        tempCell = {allLines.YData};
       badIndices = [badIndices; dataInd(:)];
    end
        % code heavily modified from https://gist.github.com/cholland29/3107790

    function dataInd = getDataInRect(point1, point2, line)
        startX = min(point1(1),point2(1));
        finX = max(point1(1), point2(1));

        startY = min(point1(2),point2(2));
        finY = max(point1(2),point2(2));
        
        xDataInd = ((line(1).XData(1,:) >= startX) & (line(1).XData(1,:) <= finX));
        dataInd = [];
        for l=1:numel(line)
            yDataInd = ((line(l).YData(1,:) >= startY) & (line(l).YData(1,:) <= finY));
            if any(yDataInd & xDataInd)
                dataInd(end+1) = l;
                fprintf('#%.0f;\n',dataInd);
            end
        end
    end
    
    h = figure;
    for val=1:size(dff,2)
        plot(t,dff(:,val)+nhat*(val-1),'Color',colors(val,:));
        hold on
    end
    hold off
    k = figure;
    for val=1:size(dffH,2)
        plot(t,dffH(:,val)+nhatH*(val-1),'Color',colors(val,:));
        hold on
    end
    hold off
    
    set(h.Children(1), 'ButtonDownFcn',@OnClickAxes);
    for l_n = 0:3:size(dff,2)
        lim=nhat*l_n;
        lim2=nhatH*l_n;
        figure(1)
        ylim([lim-nhat lim+nhat*3]);
        figure(2)
        ylim([lim2-nhatH lim2+nhatH*3]);
        pause
    end
    badIndices = unique(badIndices);
%    badIndicesH = unique(badIndicesH);
    goodIndices = setdiff(1:size(dff,2), badIndices);
%    close all
end



