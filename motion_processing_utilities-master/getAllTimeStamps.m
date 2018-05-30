% pass in a cell array of tiff files, or nothing and select the tiff files
% manually. returns a vector of time stamps in seconds.
function t = getAllTimeStamps(fi)
if nargin < 1
fi = uigetfile('*.tif','multiselect','on');
end

t = [];
for f=1:numel(fi)
a = imfinfo(fi{f});
for i=1:numel(a);
    currtime = getHcTimeStamp(a(i));
    t = cat(1,t,currtime.seconds);
end
end
end
