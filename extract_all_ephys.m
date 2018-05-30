%% Extract all 6OOHDA LFPs from folder
clear all 

skipFolders = [".","..","pre_6OHDA","1-10-2017-2220-post6OHDA-day4"];
tankList = dir('Z:\Data\DanaTemp\Ephys_6OHDA');
saveDir = 'Z:\Data\DanaTemp\ExtractedEphys\';

for j=1:numel(tankList)
    if(ismember(tankList(j).name,skipFolders))
        continue
    end
    openName = tankList(j).folder+"\"+tankList(j).name;
    mNum = regexp(tankList(j).name,'(7909|4539|7584)');
   dayNum = regexp(tankList(j).name,'(day|Day)');
   savName = "ePhys_"+tankList(j).name(mNum:mNum+3)+"_"+...
         tankList(j).name(dayNum:end);
%    savName = "ePhys_"+tankList(j).name(mNum:mNum+3)+"_Pre6OHDA_"+...
%        int2str(j);
    
    blocks = dir(char(openName+"\*Block-*"));
    if numel(blocks)==0
         blocks = dir(char(openName));
         if numel(blocks)<4
            continue
         else
           blocks = blocks(3)
         end
    end
    frst_chan=1;
    last_chan=16;
    for n=frst_chan:last_chan
        data = TDT2mat(openName,  blocks(end).name,'TYPE',4,'STORE','Wave','Channel',n); 
        lfp_temp=double(data.streams.Wave.data);
        Fs=data.streams.Wave.fs;
        [B,A] = butter(2,(2*150)/Fs,'low');
        clear data
        lfp{n-(frst_chan-1)} = filtfilt(B, A, lfp_temp);
        lfp{n-(frst_chan-1)}=downsample(lfp{n-(frst_chan-1)},8);
        clear lfp_temp
    end
    lfp10 =lfp{10};
    lfp2 =lfp{2};
    data = TDT2mat(openName,  blocks(end).name, 'Type',2);
    SampFreq=Fs/8;
    Frames=data.epocs.Valu.onset;
    for l=1:length(Frames)
        FramesTS=(Frames*Fs/8);
    end
    save (saveDir+savName)

    clearvars -except tankList j skipFolders saveDir
end
