% This is a sample program which uses OpenDeveloper calls to access the data
% in a tank and then display it in two different ways with respect to an
% epoch event. 

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

% Set global parameters 
TTX.SetGlobalV('Channel',0);
TTX.SetGlobalStringV('Options','FILTERED');

% Set a filter so we get only event data 
% for the condition Freq=2000.
% Reset all filters previously set as a precaution
TTX.ResetFilters;
TTX.SetFilterWithDescEx('Freq=2000 and Levl=0')

% Read the event Snip from all the channels but occuring 
% only during Freq=2000 and Lvl=0
% Returns the events in a matrix with each column representing
% a channel and the length of each column being the length of the signal
filtSpikes = TTX.ReadWavesV('Snip');

% Set the global parameter which specifies what to use as filler in the
% variant. In this case we set the filler to be the fixed number which is
% also specified as 0.0004
% The sampling frequency is selected as that of the
% Snip event so that they can be plotted on the same X-axis
TTX.SetGlobals('FillItem=FixedNum;FillValue=0.0004');
TTX.SetGlobalV('WaveSF',24414)

% Read the event Freq occuring only during Freq=2000
% Returns the events in a matrix with a single column representing
% the single channel of epoch data
filtFreqs = TTX.ReadWavesV('Freq');

% Build a matrix containing zeroes to hold the time axis. The number of
% points returned in filtSpikes is 1200604. Hence we need an array with
% that length to accomodate the time values of each of those points.
filtsizeSP=size(filtSpikes);
filtsizeFr=size(filtFreqs);
time1=(1:filtsizeSP(1))/24414;

% Create the time axis by dividing by the sampling frequency which is 24414


% Plot each column of filtSpikes (each of the 6 channels of Snip) in 
% a subplot against the constructed time axis. Superimposed upon that plot
% is a plot of the occurances of filtFreqs (epoch freq) in red.
for j=1:6
   subplot(6,1,j)
   text(1,200,'chan1');
   plot(time1,filtSpikes(:,j))
    
    hold on;
    plot(time1(1:filtsizeFr(1)),filtFreqs,'r')
end;


% Set the parameter FillItem to DataPoints because it had been set to
% FixedNum earlier
TTX.SetGlobals('FillItem=DataPoints');

% Get the time ranges for which the set filters are valid. A variant is
% returned in which each column is one valid time range. In each column the
% top value is the starting point of that time range and the bottom value
% is the end point. 

Ranges = TTX.GetValidTimeRangesV

% Get the epochs that are valid after filtration.
TimeRanges = TTX.GetEpocsExV('Freq',0)

% Read the events in the valid time ranges returned above
% A variant is returned with each column representing one valid time range
% The following commands read data from Chan 1,2 and 3.
Chan1 = TTX.ReadWavesOnTimeRangeV('Snip',1);
Chan2 = TTX.ReadWavesOnTimeRangeV('Snip',2);
chansize=size(Chan1);

% Build a time axis for the Chan1 which has 146484 points
time=(1:chansize(1))/24414;
% New figure
figure;

% Plot the first column of Chan1 (the first of the valid time ranges during 
% which Freq=2000) in a subplot against the constructed time axis. Also
% superimpose data from the same time range from Chan2 in a different color 
% on the same subplot. Then do the same thing for the remaining time ranges in the
% other subplots. The resulting plots will each have 2 channels of data each in 
% a different color.

for j=1:chansize(2)
    subplot(chansize(2),1,j);
    plot(time,Chan2(:,j),'r');
    hold on;
    plot(time,Chan1(:,j));
end;

% Close the tank when you're done and release the server connection
TTX.CloseTank
TTX.ReleaseServer

