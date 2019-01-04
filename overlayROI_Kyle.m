function overlayROI_Kyle(Im, CellList)
NumMinPixels = 5; 
pixel_list = 'PixelIdxList';
sz = size(Im);

figure; 
imagesc(Im)
hold on

for idx = 1:numel(CellList)
            binmask = zeros(sz);
            binmask(CellList(idx).(pixel_list)) = 1;
            binmask = bwareaopen(binmask, NumMinPixels);
            binmask = imfill(binmask,'holes');
            b = bwboundaries(binmask);
            if isempty(b)
                fprintf('Empty Pixel Indicies for %f\n',idx)
            else
                outline = plot(b{1}(:,2),b{1}(:,1),'r');
            end
end