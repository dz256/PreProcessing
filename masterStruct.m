% this file create the master structure for analysis. 

% 2/23/2018 - at this point only contains movement + LFPs + no Pre
% sessions... 

fileList = dir('Z:\Data\DanaTemp\ExtractedEphys\ePhys_*_day*.mat'); %don't do any of the pre session, because have no movment... 
MStruct = createStruct(fileList(1));
for f = 2:numel(fileList)
	file = fileList(f);
    MStruct(f) = createStruct(fileList(f));
end

save('Z:\Data\DanaTemp\ExtractedEphys\masterStruct','MStruct')


function [s,k] = createStruct(file)
    load(file.folder+"\"+file.name)
    load(file.folder+"\"+"mo"+file.name(6:end))
    s.lfp = lfp10(FramesTS(1):end);
    s.Fs = SampFreq;
    s.mNum = file.name(7:10);
    s.tvals = t;
    s.speed = speed;
    s.ro = rotation;
    s.phi = phi;
    s.k = sum((size(FramesTS)~=size(speed)))
        
    if numel(regexp(file.name,'(Pre6)'))==1
        s.day=0;
    else
        s.day = file.name(regexp(file.name,'(day)')+3:regexp(file.name,'(.mat)')-1);
    end
     clearvars -except f fileList MStruct s
end