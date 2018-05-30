
function ax = overlayROIsMike(ax, R)
for i=1:numel(R)
%     if ~R(i).isChI && ~R(i).isPVI
%         plot(ax,R(i).BoundaryTrace.x,R(i).BoundaryTrace.y,'r');
%         hold(ax,'on');
%     else
 %       plot(ax,R(i).BoundaryTrace.x,R(i).BoundaryTrace.y,'y');
   %     hold on
%    end
       plot(ax,R(i).BoundaryTrace.x,R(i).BoundaryTrace.y,'Color','none','Marker','.','MarkerEdgeColor','y','MarkerSize',7);
       hold on
end

end