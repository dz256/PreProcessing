function mouseData = loadAndFormatDana(suffix, type)
% suffix is mouse number + session (ex. '7909_SysPre6OHDA')
% type is type of preprocessing (clean, filtered, filteredNormalized)

%Written by Mike Romano, edited by Dana Zemel

%TODO - incorperte ephys

load([ 'traces_' suffix '_' type '.mat'])   % load session traces
load(['movement_' suffix '.mat']);        % this is the output of [data, info] = getData(vrffile);
load(['tiffTs_' suffix '.mat']);                   % these are the time stamps from the tiff files
load(['ROI_' suffix '.mat']);                      % load ROIs
load(['ePhys_' suffix '.mat']);                  % load ePhys data.. 

%sometimes time stemp restart in the first few min of recordings - find the
%last t==0 point and start look at files from that point on.
t = tiffTs(find(tiffTs == 0,1,'last'):end); 

origTimeFluor = t-t(1); % remove first time points from tiff time stamps

[~, ~, dxdy, rotation] = getMovement(bData); %load movement information

dt = 0.0469; % set the desired sampling interval

% get the raw traces
rawTraces = zeros(numel(r_out),size(r_out(1).trace,2));
for r = 1:numel(r_out)
    rawTraces(r,:) = r_out(r).trace;
end

origDt = bInfo.Dt;

origTimeMvmt = bInfo.Time-bInfo.Time(1); % remove first time point from motion time stamps

dy = dxdy(:,2); %should be obvious

dx = dxdy(:,1);

mouseData.dt = dt;
mouseData.tvals = [0:dt:origTimeFluor(end)]'; % set the times we want to interpolate (in our case, preinfusion)
dyInterp =  interp1(origTimeMvmt, dy./origDt, mouseData.tvals,'pchip'); %interpolate the dy and dx "speeds"
dxInterp =  interp1(origTimeMvmt, dx./origDt, mouseData.tvals,'pchip');

mouseData.speed = sqrt(dyInterp.^2+dxInterp.^2); % find net speed
mouseData.phi = atan2(dyInterp*mouseData.dt, dxInterp*mouseData.dt); % find net direction of linear speed

%redo the rotation here
mouseData.rot =interp1(origTimeMvmt, rotation./origDt, mouseData.tvals,'pchip'); % interpolate rotational velocity in radians/sec

%interpolate ePhys data
l = lfp10(FramesTS(1):end);
dlt = 1/SampFreq;
lt = 0:dlt:((size(l,1)-1)*dlt);

mouseData.lfpAtFrame = interp1(lt, l, mouseData.tvals,'pchip');
mouseData.lfp = l;
mouseData.lfpFs = SampFreq;
mouseData.lfpFrameTS = FramesTS;

rawTraces = interp1(origTimeFluor,rawTraces',mouseData.tvals,'pchip'); % interpolate fluorescence using fluorescence time stamps
mouseData.f = rawTraces;
mouseData.dff = bsxfun(@rdivide, bsxfun(@minus,rawTraces, nanmean(rawTraces)), nanmean(rawTraces)); %compute deltaF/F, nan prefix not necessary

% detrend traces  - make sure I understand what it does before marging with
% dff....
%               THIS FUNCTION DOES NOT EXSITS
%mouseData.dff_detrend = detrendpoly(mouseData.dff,2); %incorporate a polynomial detrend

mouseData.dyInterp = dyInterp;
mouseData.dxInterp = dxInterp;

% Add centroids of cells just in case.. 
centroid = [];
for r = 1:numel(R2) %change to R for subsequant mice
     s = regionprops(R2(r).perimeter,'centroid');
     centroid= cat(1, centroid,s.Centroid);
end
mouseData.centroids = centroid;

save(['fullData_' suffix '_' type],'mouseData')

end