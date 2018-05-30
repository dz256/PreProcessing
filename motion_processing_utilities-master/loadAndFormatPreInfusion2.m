function mouseData = loadAndFormatPreInfusion2(suffix)
load(['roi_trace_' suffix '_rigid_normalized.mat']) % output of roi selection file
% load mouse data
load(['movement_data_' suffix '.mat']); % this is the output of [data, info] = getData(vrffile);
load(['tiff_ts_' suffix '.mat']); % these are the time stamps from the tiff files
t = t(find(t == 0,1,'last'):end);

origTimeFluor = t-t(1); % remove first time points from tiff time stamps

[~, ~, dxdy, rotation] = getMovement(data); %load movement information

fsiIndices = find([R.isPVI]);
chiIndices = find([R.isChI]); %find indices for both of these guys

dt = 0.0469; % set the desired sampling interval

rawtraces = [R.Trace]; % get the raw traces

origDt = info.Dt;

origTimeMvmt = info.Time-info.Time(1); % remove first time point from motion time stamps

dy = dxdy(:,2); %should be obvious

dx = dxdy(:,1);

mouseData.chiIndices = chiIndices;
mouseData.fsiIndices = fsiIndices;

mouseData.dt = dt;
mouseData.tvals = [0:dt:600]'; % set the times we want to interpolate (in our case, preinfusion)

% interpolate and get binaryActivityTrace
dyInterp = interpolateStriatum(origTimeMvmt, dy./origDt, mouseData.tvals); %interpolate the dy and dx "speeds"
dxInterp = interpolateStriatum(origTimeMvmt, dx./origDt, mouseData.tvals);

mouseData.dydt = sqrt(dyInterp.^2+dxInterp.^2); % find net speed
mouseData.phi = atan2(dyInterp*mouseData.dt, dxInterp*mouseData.dt); % find net direction of linear speed

%redo the rotation here

mouseData.rot = interpolateStriatum(origTimeMvmt, rotation./origDt, mouseData.tvals); % interpolate rotational velocity in radians/sec

rawtraces = interpolateStriatum(origTimeFluor,rawtraces,mouseData.tvals); % interpolate fluorescence using fluorescence time stamps
mouseData.f = rawtraces;
mouseData.dff = bsxfun(@rdivide, bsxfun(@minus,rawtraces, nanmean(rawtraces)), nanmean(rawtraces)); %compute deltaF/F, nan prefix not necessary

%new line: detrend traces
mouseData.dff = detrendpoly(mouseData.dff,2); %incorporate a polynomial detrend

mouseData.dyInterp = dyInterp;
mouseData.dxInterp = dxInterp;

mouseData.centroids = cat(1, R.Centroid); % concatenate centroids
% mouseData.boundary = cat(1, R.boundaryTrace);

end