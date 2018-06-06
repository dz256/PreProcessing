%% Extract all 6OOHDA LFPs from folder
clearvars -except tankList j skipFolders saveDir pathways

skipFolders = [".",".."];
%tankList = dir('Z:\Data\DanaTemp\6OHDA_ephys_newData');
tankList = dir('Z:\Data\DanaTemp\PreProcessing\enow');
saveDir = 'Z:\Data\DanaTemp\PreProcessing\ExtractedEphys\';

for j=1:numel(pathways)
    if(pathways(j).ePhys==1)
        continue
    end
    suffix = [num2str(pathways(j).mouse),'_',pathways(j).type];
    tankList = dir(['Z:\Data\DanaTemp\PreProcessing\Ephys_6OHDA\*_',...
        suffix]);
    if(numel(tankList) == 0)
        continue
    end
    openName = tankList(1).folder+"\"+tankList(1).name;
    %mNum = tankList(j).name(8:11);
    %dayNum = regexp(tankList(j).name,'(day|Day|Bas)');
    %savName = "ePhys_"+mNum+"_"+tankList(j).name(dayNum:end);
    savName = "ePhys_"+suffix;
    
    blocks = dir(char(openName+"\*Block-*"));
    if numel(blocks)==0
         blocks = dir(char(openName));
         if numel(blocks)<4
            continue
         else
           blocks = blocks(3)
         end
    end
    
    data = TDTbin2mat(fullfile(char(openName),blocks(end).name),...
        'TYPE',4,'STORE','Wave');
    Fs=data.streams.Wave.fs;
    [B,A] = butter(2,(2*150)/Fs,'low');
    % channel 10 is signal, channle 2 is ground
    lfp10 =filtfilt(B, A, double(data.streams.Wave.data(10,:)));
    lfp2 =filtfilt(B, A, double(data.streams.Wave.data(2,:)));
    lfp10 = downsample(lfp10,8);
    lfp2 = downsample(lfp2,8);
    epoch = TDTbin2mat(fullfile(char(openName),blocks(end).name),...
        'TYPE',2);
    SampFreq=Fs/8;
    Frames=epoch.epocs.Valu.onset;
    for l=1:length(Frames)
        FramesTS=(Frames*Fs/8);
    end
    clear A B 
    data.streams.Wave.data([1,3:9,11:16],:) = [];
    save (saveDir+savName)
    
    pathways(j).ePhys=1;
    clearvars -except tankList j skipFolders saveDir pathways
end
