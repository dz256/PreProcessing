function motion_correction_6OHDA_gpu(filename, suffix, savedir) %modified by michael romano and then Dana Zemel

% motion correct each file and save it with 'm_' at the beginning for raw
% data and 'm_f_' for homomorphic filtered version
    g = gpuDevice(1);
    whole_tic = tic;
    if nargin < 1 || isempty(filename)
        [fname,fdir] = uigetfile('*.tif','MultiSelect','on');
        cd(fdir)
        switch class(fname)
            case 'char'
                filename{1} = fname;
            case 'cell'
                filename = cell(numel(fname),1);
                for n = 1:numel(fname)
                    filename{n} = fname{n};
                end
        end
    end

    %if nargin < 3        %all my vidoes need to be processed from first frame....
        framestart = 1;   % remember to add to argumaent list if needed.
    %end
    
 %   fprintf(['Extracting Time Stemps']);
 %   tiffTs = getAllTimeStamps(filename);
 %   save([savedir,'tiffTs_',suffix],'tiffTs')
    tiffTs = [];
    short_fname = filename;
    nFiles = numel(filename);
    fprintf(['Total file number: ',num2str(nFiles),'\n']);
    tifFile = struct(...
        'fileName',filename(:),...
        'tiffTags',repmat({struct.empty(0,1)},nFiles,1),...
        'nFrames',repmat({0},nFiles,1),...
        'frameSize',repmat({[1024 1024]},nFiles,1));
    for n = 1:nFiles
        fprintf(['Getting info from ',short_fname{n},'\n']);
    %     tifFile(n).fileName = fname{n};
        tifFile(n).fileName = filename{n};
 %       tifFile(n).tiffTags = imfinfo(filename{n});
 %       tifFile(n).nFrames = numel(tifFile(n).tiffTags);
 %       tifFile(n).frameSize = [tifFile(n).tiffTags(1).Height tifFile(n).tiffTags(1).Width];
    end

    for n = 1:nFiles
        single_tic = tic;
        fprintf(['Processing ',short_fname{n},'\n']);
        fname = tifFile(n).fileName;

        % LOAD FILE
        [data, info, ~] = tiff2matrix(fname);
        for tif= 1:numel(info)
             currtime = getTimeStamp(info(tif));
             tiffTs = cat(1,tiffTs,currtime.seconds);
        end
      
        %data = gpuArray(uint16(data));

        if n==1 % for files with messed up time stamps
            data = data(:,:,framestart:end);
        end
        % ------------------------------------------------------------------------------------------
        % FILTER & NORMALIZE VIDEO, AND SAVE AS UINT8
        % ------------------------------------------------------------------------------------------


        % PRE-FILTER TO CORRECT FOR UNEVEN ILLUMINATION (HOMOMORPHIC FILTER)
        if n==1
            [data_m_f, procstart_m_f.hompre] = homomorphicFilter(data);
        else
            [data_m_f, procstart_m_f.hompre] = homomorphicFilter(data, procstart_m_f.hompre,n,g);
        end
        
        
       %data = gather(data);
        
        
        
       

        % CORRECT FOR MOTION (IMAGE STABILIZATION)
        if n ==1
            [data_m_f, procstart_m_f.xc,procstart_m_f.prealign] = correctMotion_std(data_m_f);
            %minI = gather(min(data_m_f,[],3));
            %maxI = gather(max(data_m_f,[],3));
            minI = min(data_m_f,[],3);
            maxI = max(data_m_f,[],3);
        else
            [data_m_f, procstart_m_f.xc,procstart_m_f.prealign] = correctMotion_std(data_m_f,procstart_m_f.prealign);
            %minI = gather(cat(3,minI,max(data_m_f,[],3)));
            %maxI = gather(cat(3,maxI,min(data_m_f,[],3)));
            minI = cat(3,minI,max(data_m_f,[],3));
            maxI = cat(3,maxI,min(data_m_f,[],3));
        end
        % to make sure it is actually cleared...
         data_m_f = gpuArray([]);
         clear data_m_f 
         
        
         
         [data, ~] = apply_correctMotion(data, procstart_m_f.prealign);
         if n == 1
             [data_m_f, procstart_mf.norm] = normalizeData(data);
         else
             [data_m_f, procstart_mf.norm] = normalizeData(data, procstart_mf.norm);
         end
                  
         fprintf(['Saving ',short_fname{n},'\n']);
         save_filename = [savedir,'Processed_tifs/m_n_',suffix,'_',num2str(n)];
         matrix2tiff(data_m_f, save_filename, 'w');
         % save the frame shifts:
         sh = procstart_m_f.prealign;
         save([savedir,'shifts_',suffix,'_',num2str(n)],'sh');
         fprintf(['\t',num2str(round(toc(single_tic)/60,2)),' minutes.\n']);
         
        
         
         

    end
    fprintf('Saving max-min and time stemps')
    I = max(maxI,[],3) - min(minI,[],3);
    %I = gather(I);
    %save([savedir,'minmax_matlab/MaxMin_',suffix],'I')
    matrix2tiff(I,[savedir,'min_max/MaxMin_',suffix], 'w');
    save([savedir,'tiffTs/tiffTs_',suffix],'tiffTs')
    clear I
    fprintf(['Total processing time: ',num2str(round(toc(whole_tic)/60,2)),' minutes.\n']);
    reset(g)

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

function [data, prealign] = apply_correctMotion(data, prealign)
fprintf('Applying Correcting Motion \n')
nFrames = size(data,3);


% ESTIMATE IMAGE DISPLACEMENT USING NORMXCORR2 (PHASE-CORRELATION)
    parfor k = 1:nFrames

        maxOffset = prealign.offset(k).maxOffset;
        yPadSub_dy = prealign.offset(k).yPadSub_dy;
        xPadSub_dx = prealign.offset(k).xPadSub_dx;

        % APPLY OFFSET TO FRAME
        padFrame = padarray(data(:,:,k), [maxOffset maxOffset], 'replicate', 'both');
        data(:,:,k) = padFrame(yPadSub_dy, xPadSub_dx);



    end


end

function matrix2tiff(f_matrix, filename, method)

    % if ~isempty(dir(filename))
    %     overwrite = input('File already exists. Overwrite (0-no/1-yes)?');
    %     if isempty(overwrite) || overwrite==0
    %         load(fnmat)
    %         return
    %     end
    % end



    if isempty(strfind(filename,'.tif'))
        filename = [filename,'.tif'];
    end

    NumberImages = size(f_matrix,3);

    switch method
        case 'w'
            FileOut = Tiff('temp_file','w');

        case 'w8'
            FileOut = Tiff('temp_file','w8');
    end

    tags.ImageLength = size(f_matrix,1);
    tags.ImageWidth = size(f_matrix,2);
    tags.Photometric = Tiff.Photometric.MinIsBlack;
    tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tags.BitsPerSample = 16;
    setTag(FileOut, tags);
    FileOut.write(f_matrix(:,:,1));
    for i=2:NumberImages
        FileOut.writeDirectory();
        setTag(FileOut, tags);
        FileOut.write(f_matrix(:,:,i));
    end
    FileOut.close()

    movefile('temp_file',filename);

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

function ts = getTimeStamp(info)  %Mark wrote this function, but doesn't like documenting his code
 imDes = info.ImageDescription;

[idLines,~] = strsplit(imDes,'\r\n');
tfsLine = idLines{strncmp(' Time_From_Start',idLines,12)};
tfsNum = sscanf(tfsLine,' Time_From_Start = %d:%d:%f');
ts.hours = tfsNum(1) + tfsNum(2)/60 + tfsNum(3)/3600;
ts.minutes = tfsNum(1)*60 + tfsNum(2) + tfsNum(3)/60;
ts.seconds = tfsNum(1)*3600 + tfsNum(2)*60 + tfsNum(3);
end
