% This program launches the TTank Interface and creates the global variables

% Declare global variables
global CurrentServer;
global CurrentTank; 
global CurrentBlock; 
global CurrentEvent; 
global TT;

% Create GUI
h = TTankInterfacesExample;

% Add TTankX object to GUI
TT = actxcontrol('TTank.X', [0 0 5 5], h);

