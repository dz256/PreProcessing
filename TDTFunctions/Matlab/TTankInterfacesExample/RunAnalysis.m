% This is the analysis function
% This is called by the TTank Interface 'Run Analysis' button

function RunAnalysis()
    global CurrentServer;
    global CurrentTank;
    global CurrentBlock;
    global CurrentEvent;
    global data;
    
    data = TDT2mat(CurrentTank, CurrentBlock);
    
end