% This is a sample program which uses OpenDeveloper calls to access the data
% in a tank and then display it in a grid of stimulus frequencies, and also
% a grid of channels

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
TTX.SetGlobals('Channel=1; MaxReturn=10000; Options=FILTERED');

% Here we set up an array of filters by giving each filter an ID along a
% dimension. Later we will make use of these IDs to plot the events in a
% grid, with each cell of the grid representing the conditions set by a
% filter.

% Set a filter with the condition Freq=1000 and give it ID 1 along the 0th
% dimension. The first number in the arguments specifies the dimension, the
% second number specifies the ID of the filter along that dimension,
% followed by the filter itself. The filter is of the SetFilterWithDescEx
% type. It can contain boolean operators such as 'and' and 'or'. The last
% number if 1 specifies exclusivity, so that an event which is common to 
% two filters, appears only in that cell of the grid which has the lower 
% ID number.
a = TTX.SetFilterArray(0,1,'Freq=1000',0)
b = TTX.SetFilterArray(0,2,'Freq=2000',0)
c = TTX.SetFilterArray(0,3,'Freq=4000',0)
d = TTX.SetFilterArray(0,4,'Freq=8000',0)
e = TTX.SetFilterArray(1,1,'Levl=0',0)

% Read the filtered events in 'Snip' from channel 1. This is a simpler 
% version of the call ReadEventsV. Note that this call is affected by 
% the global parameters set earlier. Returns the number of events read
x  = TTX.ReadEventsSimple('Snip');

% Loop through each event obtained by the previous call
for t = 1:double(x)
    
    % Extract the ID of each event along the 0th dimension
    xid  = TTX.ParseEvInfoV(t-1,1,11);
    
    % Extract the event itself
    data = TTX.ParseEvV(t-1,0);

    % Form a grid of plots with the 1 column and 4 rows. Then plot each
    % event in that cell of the grid which denotes its ID. For e.g. If an
    % event has ID 2 along the 0th dimension, then plot it in subplot 2.
    % At the end of the loop, subplot 2 will have only those events which
    % have 0th dimension ID as 2, or which fulfil the filter Freq=2000
    subplot(4,1,xid)
    plot(data)
    hold on;
end

% Reset the filters 
TTX.ResetFilters;

%Set the global parameters again, this time with channel being 0 or 'all'
TTX.SetGlobals('Channel=0; MaxReturn=10000; Options=FILTERED');

% Set the filter Freq=2000
TTX.SetFilterWithDescEx('Freq=2000')

% Again set up a filter array this time according to channels. Note that
% each of these will be anded with the previous filter Freq=2000
a = TTX.SetFilterArray(0,1,'Chan=1',0)
b = TTX.SetFilterArray(0,2,'Chan=2',0)
c = TTX.SetFilterArray(0,3,'Chan=3',0)

% Plot a new figure
figure;

% Read the filtered events in 'Snip' from all channels
x  = TTX.ReadEventsSimple('Snip');

% Loop through each event obtained
for t = 1:double(x)
    
    % Extract the 0th dimension ID for each of the events
    xid  = TTX.ParseEvInfoV(t-1,1,11);
    
    % Extract the waveform itself
    data = TTX.ParseEvV(t-1,0);

    % Form a grid of plots with the 1 column and 3 rows. Then plot each
    % event in that cell of the grid which denotes its ID. At the end of 
    % the loop, each subplot will have only those events which have 0th 
    % dimension ID corresponding to that subplot number
    subplot(1,3,xid)
    plot(data)
    hold on;
end

% Close the tank when you're done and release the server connection
TTX.CloseTank;
TTX.ReleaseServer;
