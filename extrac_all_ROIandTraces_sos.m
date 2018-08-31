% extract all ROIs, Simon
pathways = table2struct( readtable('Z:\Data\DanaTemp\PreProcessing\new_data\pathways.xlsx') );
imageDir = 'Z:\Data\DanaTemp\PreProcessing\minmax\MaxMin_';
%tifdir = 'Z:\Data\DanaTemp\processedVids_6OHDA\';
tifdir = 'Z:\Data\DanaTemp\PreProcessing\new_data\Processed\';
sdavedir =  'Z:\Data\DanaTemp\PreProcessing\ROIandTraces\';
for im = 1:numel(pathways)
    if(pathways(im).hs_t==1)
        continue
    end
    suffix = [num2str(pathways(im).mouse),'_',pathways(im).type];   
    Name = [sdavedir,'ROI_manual_',suffix,'.mat'];
    if (exist(Name, 'file') ~= 2)
       continue
   end
%    a =load(Name); 
%    I = a.I;
%    a = []
%    %I(I>2000)=2000;
    
%    [R,~] =  SimonROI(double(I));
%    %R = SemiSeg(I, []);
%    disp(suffix)
%    if sum(size(R) == [1,1])==2
%        continue
%    end
    R = load(Name);
    R = R.R;
   trList = dir([tifdir,'m_f_n_',suffix,'_*.tif']);
   [~,idx] = sort(cellfun(@(x) str2num(char(regexp(x,'(?<=_)(\d*)(?=\.)','match'))),{trList.name}));
   trList = trList(idx);
   r_out=extract_trace(R, 0,trList,tifdir);
   save([sdavedir,'trace_manual_',suffix],'r_out')
  % parsave([sdavedir,'ROI_',suffix],R,[sdavedir,'trace_',suffix],r_out)
   [R,r_out] = deal([]);
   %pathways(im).ROI=1;
   pathways(im).hs_t=1;
   T = struct2table(pathways);
   writetable(T,'Z:\Data\DanaTemp\PreProcessing\new_data\pathways.xlsx')
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