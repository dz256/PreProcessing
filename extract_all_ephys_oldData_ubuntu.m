%% Extract all 6OOHDA LFPs from folder
skipFolders = [".","..","desktop.ini"];
conn = database('preProcess','auto_processing','dz_preProcess', ...
    'Vendor','MySQL', ...
    'Server','localhost');

Sess =  table2array(select(conn, 'Select Suffix from data where Ephys=0 and mouse_num in (4539,7909,7584);'));

saveDir = '/home/dana_z/HD1/extracted_ephys_matlab/';

for j=1:numel(Sess)
    suffix = char(Sess(j));
    mouse = suffix(1:4);
    
    tankList = dir(['/home/dana_z/handata2/Dana_Zemel/',mouse,...
        '/ePhys/*',suffix(6:end)]);
    if(numel(tankList) == 0)
        continue
    end
    openName = tankList(1).folder+"/"+tankList(1).name;
    %mNum = tankList(j).name(8:11);
    %dayNum = regexp(tankList(j).name,'(day|Day|Bas)');
    %savName = "ePhys_"+mNum+"_"+tankList(j).name(dayNum:end);
    savName = "ePhys_"+suffix;
    
    blocks = dir(char(openName+"/*Block-*"));
    if numel(blocks)==0
         blocks = dir(char(openName));
         if numel(blocks)<4
            continue
         else
           blocks = blocks(4)
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
    save (saveDir+savName, '-regexp', '^(?!(conn)).*$')
    
    update(conn,'data','Ephys',1,sprintf("Where Suffix= '%s'",suffix))
    clearvars -except conn j Sess saveDir skipFolders
end
