function [data, pre] = normalizeDataMC2(data, pre)
fprintf('Normalizing Fluorescence Signal \n')
% assignin('base','dataprenorm',data);
%fprintf('\t Input MINIMUM: %i\n',min(data(:)))
%fprintf('\t Input MAXIMUM: %i\n',max(data(:)))
%fprintf('\t Input RANGE: %i\n',range(data(:)))
%fprintf('\t Input MEAN: %i\n',mean(data(:)))

if nargin < 2
	pre.fmin = min(data,[],3);
	pre.fmean = single(mean(data,3));
	pre.fmax = max(data,[],3);
	pre.minval = min(data(:));
end
N = size(data,3);

% SEPARATE ACTIVE CELLULAR AREAS FROM BACKGROUND (NEUROPIL)
if nargin < 2
	activityImage = imfilter(range(data,3), fspecial('average',101), 'replicate'); % get average max minus min (filter averages data)
	pre.npMask = double(activityImage) < mean2(activityImage); %find places where activity is less than average
	pre.npPixNum = sum(pre.npMask(:)); %find number of pixels where activity is less than average
	pre.cellMask = ~pre.npMask; %find pixels where activity is greater than or equal to average
	pre.cellPixNum = sum(pre.cellMask(:));
end
pre.npBaseline = sum(sum(bsxfun(@times, data, cast(pre.npMask,'like',data)), 1), 2) ./ pre.npPixNum; %average of pixels in mask
pre.cellBaseline = sum(sum(bsxfun(@times, data, cast(pre.cellMask,'like',data)), 1), 2) ./ pre.cellPixNum;

% % REMOVE BASELINE SHIFTS BETWEEN FRAMES (TODO: untested, maybe move to subtractBaseline)


pre.baselineOffset = 0;
data = cast( bsxfun(@minus,...
	single(data), single(pre.npBaseline)),... % + pre.baselineOffset, ...
	'like', data);


end