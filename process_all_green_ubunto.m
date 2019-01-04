% process all videos (only save filtered-Normalize copy)

savedir = '/home/dana_z/HD2/green/';
conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');

% list of sesions where motion corrected, but ROI not selected:
Sess =  table2array(select(conn, 'Select Suffix from data where green<>1;'));
for s = 1:numel(Sess)
     timeLoop = tic;
    suffix = char(Sess(s));
    
    % find the green video:
    vidList = dir(['/home/dana_z/handata2/Dana/',suffix(1:4),'/*',suffix(5:end),'/*.tif']);
    greens = 1:numel(vidList);
    for r=1:numel(vidList)
         if numel(vidList(r).name(cell2mat(regexp({vidList(r).name}, '(green)')):end))~=0
           greens(r) = -1;
         end
    end
    vidList = vidList(greens==-1);
    clear r greens
    
    % error catching and old mice handling:
    if numel(vidList) ==0
        % no green tif, skip with code 56
        update(conn,'data','green',56,sprintf("Where Suffix= '%s'",suffix));
        continue
    elseif numel(vidList)>1
        greens = 1:numel(vidList);
        for r=1:numel(vidList)
             if numel(vidList(r).name(cell2mat(regexp({vidList(r).name}, '(200)')):end))~=0
               greens(r) = -1;
             end
        end
        vidList = vidList(greens==-1);
        clear r greens
        if numel(vidList) ==0
             update(conn,'data','green',57,sprintf("Where Suffix= '%s'",suffix));
             continue
        end
    end
    % error catching and old mice handling:  
    fname = [vidList.folder,'/',vidList.name];
    [data, info, ~] = tiff2matrix(fname); 
    [data_m_f, procstart_m_f.hompre] = homomorphicFilter(data);
    [data_m_f, procstart_m_f.xc,procstart_m_f.prealign] = correctMotion_std(data_m_f);
    Ired = max(data_m_f,[],3);
    save([savedir,'Ired_',suffix],'Ired')
    update(conn,'data','green',1,sprintf("Where Suffix= '%s'",suffix));
    disp(['finished Ired for ',suffix, '. total time: ',num2str(toc(timeLoop)),'s'])
    
end  

function [data, pre] = homomorphicFilter(data,pre,verb,g)
% Implemented by Mark Bucklin 6/12/2014 edited by Dana 5/17/2018+ 3/11/2018
% More info HERE: http://www.cs.sfu.ca/~stella/papers/blairthesis/main/node35.html
%% DEFINE PARAMETERS and PROCESS INPUT
% gpu = gpuDevice(1);
% CONSTRUCT HIGH-PASS (or Low-Pass) FILTER
sigma = 50;
filtSize = 2 * sigma + 1;
hLP = fspecial('gaussian',filtSize,sigma);
% GET RANGE FOR CONVERSION TO FLOATING POINT INTENSITY IMAGE
if nargin < 2
	%    pre.dmax = getNearMax(data); %TODO: move into file as subfunction
	%    pre.dmin = getNearMin(data);
	pre.dmax = max(data(:));
	pre.dmin = min(data(:));
    verb= 1;
end
inputScale = single(pre.dmax - pre.dmin);
inputOffset = single(pre.dmin);
outputRange = [0 65535];
outputScale = outputRange(2) - outputRange(1);
outputOffset = outputRange(1);
% PROCESS FRAMES IN BATCHES TO AVOID PAGEFILE SLOWDOWN??TODO?
sz = size(data);
N = sz(3);
nPixPerFrame = sz(1) * sz(2);
nBytesPerFrame = nPixPerFrame * 2;


% multiWaitbar('Applying Homomorphic Filter',0);
ioLast= nan;
disp('start loop')
for k=1:N
    
    %im = data(:,:,k);
    il = gpuArray(uint16(data(:,:,k)));
    im = medfilt2(il);
    %im = medfilt2(data(:,:,k));
    %add median filter to pipeline
    imGray =  (single(im) - inputOffset)./inputScale   + 1;					% {1..2}
		% USE MEAN TO DETERMINE A SCALAR BASELINE ILLUMINATION INTENSITY IN LOG DOMAIN
        mK = median(imGray(:));
        io = log( mean(imGray(imGray<mK))); % mean of lower 50% of pixels		% {0..0.69}
        if isnan(io)
			if ~isnan(ioLast)
				io = ioLast;
			else
				io = .1;
            end
        end
        ioLast = io;
		% LOWPASS-FILTERED IMAGE (IN LOG-DOMAIN) REPRESENTS UNEVEN ILLUMINATION
		imGray = log(imGray);																				% log(imGray) -> {0..0.69}
		imLp = imfilter( imGray, hLP, 'replicate');														%  imLp -> ?
		% SUBTRACT LOW-FREQUENCY "ILLUMINATION" COMPONENT
		imGray = exp( imGray - imLp + io) - 1;			% {0..2.72?} -> {-1..1.72?}
		% RESCALE FOR CONVERSION BACK TO ORIGINAL DATATYPE
		imGray = imGray .* outputScale  + outputOffset;
		im = uint16(imGray);
	data(:,:,k) = gather(im);
    [im, imGray, imLp] = deal(gpuArray([]));
end

end

function [data, xc, prealign] = correctMotion_std(data, prealign)
fprintf('Correcting Motion \n')
sz = size(data);
nFrames = sz(3);
if nargin < 2
	prealign.cropBox = selectWindowForMotionCorrection(data,round(sz(1:2)./2));
	prealign.n = 0;
end
ySubs = round(prealign.cropBox(2): (prealign.cropBox(2)+prealign.cropBox(4)-1)');
xSubs = round(prealign.cropBox(1): (prealign.cropBox(1)+prealign.cropBox(3)-1)');
croppedVid = data(ySubs,xSubs,:);
cropSize = size(croppedVid);
maxOffset = floor(min(cropSize(1:2))/10);
ysub = maxOffset+1 : cropSize(1)-maxOffset;
xsub = maxOffset+1 : cropSize(2)-maxOffset;
yPadSub = maxOffset+1 : sz(1)+maxOffset;
xPadSub = maxOffset+1 : sz(2)+maxOffset;
if ~isfield(prealign, 'template')
	vidMean = im2single(croppedVid(:,:,1));
	templateFrame = vidMean(ysub,xsub);
else
	templateFrame = prealign.template;
end
offsetShift = min(size(templateFrame)) + maxOffset;
validMaxMask = [];
N = nFrames;
xc.cmax = zeros(N,1);
xc.xoffset = zeros(N,1);
xc.yoffset = zeros(N,1);

% ESTIMATE IMAGE DISPLACEMENT USING NORMXCORR2 (PHASE-CORRELATION)
for k = 1:N
	movingFrame = im2single(croppedVid(:,:,k));
    % Hua-an
    movingFrame_std = (movingFrame-mean(movingFrame(:)))/std2(movingFrame(:));
    templateFrame_std = (templateFrame-mean(templateFrame(:)))/std2(templateFrame(:));
	c = normxcorr2(templateFrame_std, movingFrame_std);

	% RESTRICT VALID PEAKS IN XCORR MATRIX
	if isempty(validMaxMask)
		validMaxMask = false(size(c));
		validMaxMask(offsetShift-maxOffset:offsetShift+maxOffset, offsetShift-maxOffset:offsetShift+maxOffset) = true;
	end
	c(~validMaxMask) = false;
	c(c<0) = false;

	% FIND PEAK IN CROSS CORRELATION
	[cmax, imax] = max(abs(c(:)));
	[ypeak, xpeak] = ind2sub(size(c),imax(1));
	xoffset = xpeak - offsetShift;
	yoffset = ypeak - offsetShift;

	% APPLY OFFSET TO TEMPLATE AND ADD TO VIDMEAN
	adjustedFrame = movingFrame(ysub+yoffset , xsub+xoffset);
	nt = prealign.n / (prealign.n + 1);
	na = 1/(prealign.n + 1);
	templateFrame = templateFrame*nt + adjustedFrame*na;
	prealign.n = prealign.n + 1;
	xc.cmax(k) = gather(cmax);
	dx = xoffset;
	dy = yoffset;
	xc.xoffset(k) = gather(dx);
	xc.yoffset(k) = gather(dy);

	% APPLY OFFSET TO FRAME
	padFrame = padarray(data(:,:,k), [maxOffset maxOffset], 'replicate', 'both');
	data(:,:,k) = padFrame(yPadSub+dy, xPadSub+dx);

    prealign.offset(k).maxOffset = maxOffset;
    prealign.offset(k).yPadSub_dy = yPadSub+dy;
    prealign.offset(k).xPadSub_dx = xPadSub+dx;

end
prealign.template = templateFrame;

end

function winRectangle = selectWindowForMotionCorrection(data, winsize)
    if numel(winsize) <2
        winsize = [winsize winsize];
    end
    sz = size(data);
    win.edgeOffset = round(sz(1:2)./4);
    win.rowSubs = win.edgeOffset(1):sz(1)-win.edgeOffset(1);
    win.colSubs =  win.edgeOffset(2):sz(2)-win.edgeOffset(2);
    stat.Range = range(data, 3);
    stat.Min = min(data, [], 3);
    win.filtSize = min(winsize)/2;
    imRobust = double(imfilter(rangefilt(gather(stat.Min)),fspecial('average',win.filtSize))) ./ double(imfilter(stat.Range, fspecial('average',win.filtSize)));
    % gaussmat = gauss2d(sz(1), sz(2), sz(1)/2.5, sz(2)/2.5, sz(1)/2, sz(2)/2);
    gaussmat = fspecial('gaussian', size(imRobust), 1);
    gaussmat = gaussmat * (mean2(imRobust) / max(gaussmat(:)));
    imRobust = imRobust .*gaussmat;
    imRobust = imRobust(win.rowSubs, win.colSubs);
    [~, maxInd] = max(imRobust(:));
    [win.rowMax, win.colMax] = ind2sub([length(win.rowSubs) length(win.colSubs)], maxInd);
    win.rowMax = win.rowMax + win.edgeOffset(1);
    win.colMax = win.colMax + win.edgeOffset(2);
    win.rows = win.rowMax-winsize(1)/2+1 : win.rowMax+winsize(1)/2;
    win.cols = win.colMax-winsize(2)/2+1 : win.colMax+winsize(2)/2;
    winRectangle = [win.cols(1) , win.rows(1) , win.cols(end)-win.cols(1) , win.rows(end)-win.rows(1)];
end

function [f_matrix, InfoImage,a] = tiff2matrix(filename)

    InfoImage = imfinfo(filename);
    NumberImages=length(InfoImage);

    f_matrix = zeros(InfoImage(1).Height,InfoImage(1).Width,NumberImages,'uint16');

    %multiWaitbar(['Loading file: ',filename], 0 );
    a=5;

    for i=1:NumberImages
        f_matrix(:,:,i) = imread(filename,'Index',i,'Info',InfoImage);
        %multiWaitbar(['Loading file: ',filename], i/NumberImages );
    end
    %multiWaitbar('CLOSEALL');

end
