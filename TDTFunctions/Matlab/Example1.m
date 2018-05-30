% This is a sample bit of matlab code for accessing data in a Tank
% and displaying it on a couple of plots.  Most calls return 1
% if they are successful else they return 0.  If a variant is returned
% then a -1 means Empty variant or a NULL return.

%First instantiate a variable for the ActiveX wrapper interface
TTX = actxcontrol('TTank.X')

% Then connect to a server.
TTX.ConnectServer('Local', 'Me')

% Now open a tank for reading.
TTX.OpenTank('C:\TDT\OpenEx\Tanks\DemoTank', 'R')

% Select the block to access
TTX.SelectBlock('Block-3')

% Get all of the Snips across all time for channel-1
% after this call they are stored localing within the ActiveX
% wrapper code.  N will equal the number of events read.
N = TTX.ReadEventsV(10000, 'Snip', 1, 0, 0.0, 0.0, 'ALL')

% To parse out elements of the returned data use the
% ParseEvV and ParseEvInfoV calls as follow.

% To get all waveform data for all the events read just call
% the first 0 is the index offset into the list returned above
% the second arg is the number you would like parsed out and returned
W = TTX.ParseEvV(0, N);

% To get other information about the record events returned call
% ParseEvInfoV.  This call has the same two parameters as ParseEvV
% with one more param to indicate which bit of information you
% want returned.  The following are valid values for the 3rd 
% parameter:
%   1  = Amount of waveform data in bytes
%   2  = Record Type (see TCommon.h)
%   3  = Event Code Value
%   4  = Channel No.
%   5  = Sorting No.
%   6  = Time Stamp
%   7  = Scalar Value (only valid if no data is attached)
%   8  = Data format code (see TCommon.h)
%   9  = Data sample rate in Hz. (not value unless data is attached)
%   10 = Not used returns 0.
%   0  = Returns all values above
TS = TTX.ParseEvInfoV(0, N, 6);

subplot(2,1,1); plot(W)
subplot(2,1,2); hist(TS, 30) % Create a subplot of both displays

% Any single value (in this case chan no.) can be returned like this:
chan = TTX.ParseEvInfoV(35, 0, 4)

% The same can be done to return single waveforms like:
onewave = TTX.ParseEvV(35, 0)

% Finally the ParseEvV call can be used to return the value(s)
% for a bunch of scalar events:
N = TTX.ReadEventsV(10000, 'Freq', 0, 0, 0.0, 0.0, 'ALL')
freqlist = TTX.ParseEvV(0, N);

% Or a single value can be returned:
onefreq = TTX.ParseEvV(3, 0)

% Close the tank when you're done
TTX.CloseTank

%Disconnect from the tank server
TTX.ReleaseServer
