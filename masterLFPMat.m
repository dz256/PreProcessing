% Unify the lfps into 1 master lfp struct (for prelimenary 6OHDA)
fileList = dir('Z:\Data\DanaTemp\ExtractedEphys\*.mat');
MasterStruct = createStruct(fileList(1));

for f =2:numel(fileList)
    file = fileList(f);
    load(file.folder+"\"+file.name)
    MasterStruct(f) = createStruct(fileList(f))
end

save('Z:\Data\DanaTemp\ExtractedEphys\masterStruct','MasterStruct')

function s = createStruct(file)
    load(file.folder+"\"+file.name)
    s.lfp = lfp10(FramesTS(1):end);
    s.Fs = SampFreq;
    s.mNum = file.name(7:10);
    
    if numel(regexp(file.name,'(Pre6)'))==1
        s.day=0
    else
        s.day = file.name(regexp(file.name,'(day)')+3:regexp(file.name,'(.mat)')-1)
    end
     clearvars -except f fileList MasterStruct s
end