% This is a sample program which uses OpenDeveloper calls to access the data
% in a tank. It then computes the Inter-Spike Intervals of a block, and
% plots a histogram of them.

% Clear all variables and functions from memory
clear all;

% Specify the tank to be opened
MyTank = 'C:\TDT\OpenEx\Tanks\DemoTank';

% Specify the block to be accessed
MyBlock = '~Block-2';

% First instantiate a variable for the ActiveX wrapper interface
TTX = actxcontrol('TTank.X')

% Then connect to a server
TTX.ConnectServer('Local','Me')

% Now open the tank for reading
TTX.OpenTank(MyTank,'R')

% Access the block specified earlier
TTX.SelectBlock(MyBlock)

% Reset all filters previously set as a precaution
TTX.ResetFilters;

% Set global parameters
TTX.SetGlobalV('Channel',1);
TTX.SetGlobalStringV('Options','FILTERED');

% Build an array with 3500 zeroes to hold the 3500 bins of the histogram
cache1 = zeros(1,3500);

% Use the simplified version of the ReadEvents call to read the event Snip
% from channel one according to the filter set above 
% Will return the number of events read
a = TTX.ReadEventsSimple('Snip');

% Get the timestamp for each of the events
tstamps = TTX.ParseEvInfoV(0,10000,6);

% Start a loop from 1 to the number of events just obtained
for i = 1:a-1
    
    % compute the difference bewteen each successive spike
    delta(i) = tstamps(i+1)-tstamps(i); 
    
    % Multiple by 1000 and round off so that the values are all in
    % milliseconds and the bin width is 1 ms.
    bin = ceil(delta(i)*1000);
    
    % Increment the value of that element of cache1 which the timestamp
    % falls into. For example, if bin=40, then increment the 40th element
    % of cache1
    cache1(1,bin) = cache1(1,bin) + 1;
end

% Plot a histogram of the first 100 values of cache, so that it plots ISIs
% of 100 ms and less. 
bar(cache1(1:100));

% Close the tank when you're done and release the server connection
TTX.CloseTank;
TTX.ReleaseServer;