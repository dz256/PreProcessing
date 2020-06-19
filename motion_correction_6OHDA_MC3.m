function motion_correction_6OHDA_MC2(filename, suffix, savedir,R) %modified by michael romano and then Dana Zemel

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
        [data, ~, ~] = tiff2matrix(fname);     

        if n==1 % for files with messed up time stamps
            data = data(:,:,framestart:end);
        end
        % ------------------------------------------------------------------------------------------
        % FILTER & NORMALIZE VIDEO, AND SAVE AS UINT8
        % ------------------------------------------------------------------------------------------
         
         load(['/home/dana_z/HD1/shifts/shifts_',suffix,'_',num2str(n),'.mat'])      
         [data, ~] = apply_correctMotion(data, sh);
         if n == 1
             [data_m_f, procstart_mf.norm] = normalizeDataMC3(data);
             r_out=extract_traceMC2(R, data_m_f);
         else
             [data_m_f, procstart_mf.norm] = normalizeDataMC3(data, procstart_mf.norm);
             r_temp=extract_traceMC2(R,data_m_f);
             for r = 1:numel(R)
                r_out(r).trace = cat(2,r_out(r).trace,r_temp(r).trace);
             end
         end
         fprintf(['\t',num2str(round(toc(single_tic)/60,2)),' minutes.\n']);                  
    end
    fprintf('Saving new traces')
    save([savedir,'traceMC3_',suffix],'r_out')
    fprintf(['Total processing time: ',num2str(round(toc(whole_tic)/60,2)),' minutes.\n']);
    reset(g)

end


function r_out=extract_traceMC2(r_in, data)
% edited version of Kyles extract trace function to re-extract from loaded
% data
        NumberImages=size(data,3);
        InfoImage(1).Height = size(data,1);
        InfoImage(1).Width = size(data,2);

        f_matrix = data;
        f_matrix = double(reshape(f_matrix,InfoImage(1).Height*InfoImage(1).Width,NumberImages));
        
        for roi_idx=1:numel(r_in)
            current_mask = zeros(1,InfoImage(1).Height*InfoImage(1).Width);
            try
                current_mask(r_in(roi_idx).PixelIdxList) = 1;
                r_out(roi_idx).PixelIdxList = r_in(roi_idx).PixelIdxList;
            catch
                current_mask(r_in(roi_idx).PixelIdxList) = 1;
                r_out(roi_idx).PixelIdxList = r_in(roi_idx).PixelIdxList;
            end
            
            current_trace = (current_mask*f_matrix)/sum(current_mask);                 
            r_out(roi_idx).trace = current_trace;

        end
    
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
