function data = TDTtankfilter(data, input, varargin)
%TDTTANKFILTER  TDT tank data filter.
%   data = TDTtankfilter(DATA, INPUT, VALUES), where DATA is the output of
%   TDT2mat, INPUT is the epoc filter data, and VALUES is an array of 
%   allowed values. Filters the data so only time ranges where INPUT 
%   value is in filter array are used.
%
%   data    contains all store data with filter applied
%
%   data = TDTtankfilter(DATA, INPUT, T1, T2), where T1 and T2 are scalar.  
%   Filters data from T1 to T1+T2 relative to INPUT onset. 
%
%   data = TDTtankfilter(DATA, INPUT, T1, T2, TIMEREF), where TIMEREF is 
%   boolean. Filters data from T1 to T1+T2 relative to INPUT onset. If 
%   TIMEREF is true, sets snip timestamps relative to INPUT onset.
%

TIMEREF = 0;
time_ranges = [;];

if nargin == 5
    filter_type = 'TIME';
    TIMEREF = varargin{3};
elseif nargin == 4
    filter_type = 'TIME';
elseif nargin == 3
    filter_type = 'VALUE';
    VALUES = varargin{1};
end

t1 = 0;
if strcmp(filter_type, 'TIME')
    % get T1, T2
    [t1, t2] = varargin{1:2};
    
    % preallocate
    time_ranges = zeros(2, length(input.onset));
    
    % find valid time ranges
    for j = 1:length(input.onset)
        time_ranges(:, j) = [input.onset(j)+t1; input.onset(j)+t1+t2];
    end
    
    % create filter string
    filter_string = sprintf('%s: %s [%.1f:%.1f];', filter_type, input.name, t1, t2);        
end

% VALUE FILTER, only use time ranges where INPUT value is in filter array
if strcmp(filter_type, 'VALUE')
    % get array of allowed values
    
    % preallocate
    time_ranges = zeros(2, length(input.data)); 
    
    % find valid time ranges
    time_range_ind = 0;
    for i = 1:length(VALUES)
        for j = 1:length(input.data)
            if input.data(j) == VALUES(i)
                time_range_ind = time_range_ind + 1;
                time_ranges(:, time_range_ind) = [input.onset(j); input.offset(j)];
            end
        end
    end
    
    % truncate
    time_ranges = time_ranges(:,1:time_range_ind); 
    
    % create filter string
    filter_string = sprintf('%s: %s in [', filter_type, input.name);
    for i = 1:length(VALUES)
        filter_string = strcat(filter_string, sprintf('%.1f,', VALUES(i)));
    end
    filter_string(end:end+1) = '];';
end

% set filter string
if isfield(data, 'filter')
    data.filter = strcat(data.filter, filter_string);
else
    data.filter = filter_string;
end

% check for time range overlap
for i = 1:size(time_ranges, 2)
    start = time_ranges(1, i);
    stop = time_ranges(2, i);
    for j = 1:size(time_ranges, 2)
        if time_ranges(1, j) > start && time_ranges(1, j) < stop || ...
                time_ranges(2, j) > start && time_ranges(2, j) < stop
            warning(sprintf('time range overlap [%.3f, %.3f] [%.3f, %.3f]', ...
                start, stop, time_ranges(1, j), time_ranges(2, j)));
        end
    end
end

% FILTER ALL EXISTING DATA ON THESE TIME RANGES
% filter streams
n = fieldnames(data.streams);
for i = 1:length(n)
    eval(['fs = data.streams.' n{i} '.fs;'])
    eval(['data.streams.' n{i} '.filtered = [];'])
    eval(['max_ind = max(size(data.streams.' n{i} '.data));']);
    for j = 1:size(time_ranges,2)
        onset = min(max(round(time_ranges(1,j)*fs),0)+1, max_ind);
        offset = min(max(round(time_ranges(2,j)*fs),0)+1, max_ind);
        eval(['data.streams.' n{i} '.filtered{' num2str(j) '} = data.streams.' n{i} '.data(:,onset:offset);']);
    end
end

% filter snips
n = fieldnames(data.snips);
for i = 1:length(n)
    eval(['ts = data.snips.' n{i} '.ts;']);
    
    % preallocate
    keep = [];
    diffs = []; % for relative timestamps
    
    for j = 1:size(time_ranges,2)
        
        % get this set of time ranges
        onset = time_ranges(1,j);
        offset = time_ranges(2,j);
        
        % determine if time stamp falls in this range and keep track of
        % valid indicies
        valid = find(ts >= onset & ts <= offset);
        keep = [keep; valid];
        diffs = [diffs; ts(valid) - onset + t1];
            
    end
    % truncate
    eval(['data.snips.' n{i} '.data = data.snips.' n{i} '.data(keep);'])
    if TIMEREF
        eval(['data.snips.' n{i} '.ts = diffs;'])
    else
        eval(['data.snips.' n{i} '.ts = data.snips.' n{i} '.ts(keep);'])
    end
    eval(['data.snips.' n{i} '.chan = data.snips.' n{i} '.chan(keep);'])
end

% filter epocs, include if onset falls in valid time range
n = fieldnames(data.epocs);
for i = 1:length(n)
   
    eval(['ts = data.epocs.' n{i} '.onset;']);
    keep = [];
    for j = 1:size(time_ranges,2)
        
        % get this set of time ranges
        onset = time_ranges(1,j);
        offset = time_ranges(2,j);
        
        % determine if time stamp falls in this range and keep track of
        % valid indicies
        keep = [keep find(ts >= onset & ts <= offset)];
        
    end
    keep = unique(keep);
    eval(['data.epocs.' n{i} '.data = data.epocs.' n{i} '.data(keep);'])
    eval(['data.epocs.' n{i} '.onset = data.epocs.' n{i} '.onset(keep);'])
    eval(['data.epocs.' n{i} '.offset = data.epocs.' n{i} '.offset(keep);'])
end
