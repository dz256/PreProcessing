%protocol 1 for 48 channel lfp recordings
%Change block and file name before running

%clear all
clc
close all

file='Z:\Data\DanaTemp\9-7-16 mouse 4003 AMPH'
blocknum=2;
frst_chan=1;
last_chan=16;%16
num=num2str(blocknum);

 for n=frst_chan:last_chan
    data = TDT2mat(file, strcat('Block-',num),'TYPE',4,'STORE','Wave','Channel',n); 
    %data = TDT2mat(file, strcat('12-14-16 7909 systemic AMPH-1'),'TYPE',4,'STORE','Wave','Channel',n);
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
data = TDT2mat(file, strcat('Block-',num), 'Type',2);
%data = TDT2mat(file, strcat('12-14-16 7909 systemic AMPH-1'), 'Type',2);
SampFreq=Fs/8;
%SampFreq=Fs/6;
Frames=data.epocs.Valu.onset;

for j=1:length(Frames)
    FramesTS=(Frames*Fs/8);
end


%clearvars -except SampFreq FramesTS lfp10 lfp2 file
save ('ePhys_4003_amph')

%%


 