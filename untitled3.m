clear all
suffix = '8430_BaselineA';
greendir = '/home/dana_z/HD2/green/';
tracedir = '/home/dana_z/HD2/traces/';
ROIdir = '/home/dana_z/HD1/ROIs/';
TSdir = '/home/dana_z/HD1/tiffTs/';
mmdir = '/home/dana_z/HD1/min_max/MaxMin_';
load([tracedir,'trace_',suffix,'.mat']);
load([TSdir,'tiffTs_',suffix,'.mat']);
tracedir = '/home/dana_z/HD2/processPipelineTests/';
r_out2 =load([tracedir,'traceMC4_',suffix,'.mat']);
r_out2 = r_out2.r_out;
TS = 1/20; %sample frequency to match traces
t = 0:TS:max(tiffTs);
rawTraces = zeros(size(tiffTs,1),numel(r_out));
for r = 1:numel(r_out)
rawTraces(:,r) = r_out(r).trace;
end
rawTraces2 = zeros(size(tiffTs,1),numel(r_out2));
for r = 1:numel(r_out)
rawTraces2(:,r) = r_out2(r).trace;
end
traces = interp1(tiffTs,rawTraces,t,'pchip');
traces2 = interp1(tiffTs,rawTraces2,t,'pchip');
dff =  bsxfun(@rdivide, bsxfun(@minus,traces, nanmean(traces)), nanmean(traces));
dff2 =  bsxfun(@rdivide, bsxfun(@minus,traces2, nanmean(traces2)), nanmean(traces2));
tPre = find(t<=600,1,'last');
nhat = median(max(dff(1:tPre,:)));
figure;
for val=1:numel(r_out)
plot(t,dff(:,val)+nhat*(val-1),'color',r_out(val).color);
hold on
end
xlim([0,600])
ylim([0,1000])
nhat2 = median(max(dff2(1:tPre,:)));
figure;
for val=1:numel(r_out)
plot(t,dff2(:,val)+nhat2*(val-1),'color',r_out(val).color);
hold on
end
xlim([0,600])
ylim([0,50])

tPost = find(t>900,1,'first');