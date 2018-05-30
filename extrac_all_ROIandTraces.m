% extract all ROIs, Simon
images = dir('Z:\Data\DanaTemp\minmax\M*');
%tifdir = 'Z:\Data\DanaTemp\processedVids_6OHDA\';
tifdir = 'Z:\Data\DanaTemp\new_data\Processed\';
sdavedir =  'Z:\Data\DanaTemp\ROIandTraces\';
parfor im = 1:numel(images)
   a =load([images(im).folder,'\',images(im).name]);
   I = a.I;
   a = []
   %I(I>2000)=2000;
   suffix = images(im).name(7:end)
   [R,~] =  SimonROI(double(I));
   %R = SemiSeg(I, []);
   disp(suffix)
   if sum(size(R) == [1,1])==2
       continue
   end
   R = ROItoStruct(I, R);
   trList = dir([tifdir,'m_f_n',suffix(1:end-4),'_*.tif']);
   [~,idx] = sort(cellfun(@(x) str2num(char(regexp(x,'(?<=_)(\d*)(?=\.)','match'))),{trList.name}));
   trList = trList(idx);
   r_out=extract_trace(R, 0,trList,tifdir);
   parsave([sdavedir,'ROI',suffix],R,[sdavedir,'trace',suffix],r_out)
   [R,r_out,I] = deal([])
end


function R2 = ROItoStruct(Im, CellList)
NumMinPixels = 5; 
pixel_list = 'pixel_idx';
sz = size(Im);

figure; 
imagesc(Im)
hold on

R2 = CellList;
[R2.centroid] = deal([0,0]);
[R2.BoundaryTrace] = deal([]);
delIdx = [];
for idx = 1:numel(CellList)
        if  isempty(CellList(idx).iteration)
            continue
        end
        if size(CellList(idx).(pixel_list),1)>500
            delIdx = [delIdx idx];
            continue
        end
        binmask = zeros(sz);
        binmask(CellList(idx).(pixel_list)) = 1;
        binmask = bwareaopen(binmask, NumMinPixels);
        binmask = imfill(binmask,'holes');
        b = bwboundaries(binmask);
        if  isempty(b)
            delIdx = [delIdx idx];
            continue
        end
        R2(idx).BoundaryTrace = struct('x',b{1}(:,1),'y',b{1}(:,1));
        c = regionprops(binmask,'Centroid');
        R2(idx).centroid = c.Centroid;
        if isempty(b)
            fprintf('Empty Pixel Indicies for %f\n',idx)
        else
            outline = plot(b{1}(:,2),b{1}(:,1),'r');
        end
end
R2(delIdx) = [];
end