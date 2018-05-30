% In this demo we'll show how epocs can be used to access 
% data in special ways and query data using filters.
% This demo assumes you've looked at OXDemo1.

% Do basic stuff to get ready to access data
TTX = actxcontrol('TTank.X')
TTX.ConnectServer('Local', 'Me')
TTX.OpenTank('C:\TDT\OpenEx\Tanks\DemoTank', 'R')
TTX.SelectBlock('Block-3')

% Then make a call to tell TTank to build epoc indexes
% This allows us to access data relative to epocs etc.
TTX.CreateEpocIndexing

% Now we can do two things: 1) query data relative to epocs
% and 2) quickly get epoc information relative to some 
% event data.  In our demo tank there are three epochs
% saved they are SwpN, Freq and Levl

% Suppose we want to get back all of the event data for channel-1 and then find out 
% what the stim freq was when a particular event occurred.

N = TTX.ReadEventsV(10000, 'Snip', 1, 0, 0.0, 0.0, 'ALL')
TS = TTX.ParseEvInfoV(0, N, 6);

% Now for any event (say the 13th) we can find out what the Freq
% was by calling:
F = TTX.QryEpocAtV('Freq', TS(13), 0)

% The last param (=0) is used to indicate what information about the 
% epoc you want returned.  Most commonly you will use 0 indicating
% that you want the epoch's value returned.  Pass 1 to get the epoch's
% start time or 2 to get the epoch's stop time.  Pass 3 if you 
% want the epocs filter status.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% You can also issue filter commands before asking for data 

% First I'll clear any filtering just to be safe
TTX.ResetFilters

% This lets issue a filter so we get only event data 
% for the Freq=4000.
TTX.SetFilterWithDesc('Freq=4000')

% Now a call to ReadEvents returnes only events that
% occur when the Freq is 4000 not I've changed the last param from
% ALL to FILTERED. 
N = TTX.ReadEventsV(10000, 'Snip', 1, 0, 0.0, 0.0, 'FILTERED')

% Call SetFilter mulitple times to create ORed logic for the same epoch name.  
% For example, if I now call:
TTX.SetFilterWithDesc('Freq=1000')
% Any events at Freq=1000 or 4000 will be returned (now N=46)
N = TTX.ReadEventsV(10000, 'Snip', 1, 0, 0.0, 0.0, 'FILTERED')

% Filter set for different epochs are ANDed.  So if I call:
TTX.SetFilterWithDesc('SwpN=13')
% Now only events that have Freq=1000 or Freq=4000 and SwpN=13
% wll be returned by:
N = TTX.ReadEventsV(10000, 'Snip', 1, 0, 0.0, 0.0, 'FILTERED')
% N returns 0 meaning that no events fit the criteria.

% Close the tank when you're done and release the server connection
TTX.CloseTank
TTX.ReleaseServer