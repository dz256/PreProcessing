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
