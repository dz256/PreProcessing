lfpDir = "/home/dana_z/handata2/Dana/LFP filter test/Filter_ch/";
lfpData= ["FilterTest_2178","FilterTest_2178_noSF"]
F = [1:0.5:6, 10,20];

for tdt = lfpData
    openName = lfpDir+"/"+tdt;
    figure
    for f = 1:numel(F)
        %load the lfp block
        blockN = dir(openName);
        data = TDTbin2mat(fullfile(char(openName),blockN(f+2).name),...
        'TYPE',4,'STORE','Wave');
        Fs=data.streams.Wave.fs;
        
        Fast = data.streams.Wave.data(11,:);
        T = 1/Fs;             % Sampling period
        L = numel(Fast);             % Length of signal
        t = (0:L-1)*T;
        Y = fft(Fast);
        P2 = abs(Y/L);
        P1 = P2(1:L/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        fs = Fs*(0:(L/2))/L;
        plot(fs,P1,'DisplayName',num2str(F(f)))
        hold on
    end
    xlim([0,20])
    hold off 
    figure;
    data = TDTbin2mat(fullfile(char(openName),blockN(14).name),...
        'TYPE',4,'STORE','Wave');
    Fs=data.streams.Wave.fs;

    Fast = data.streams.Wave.data(10,:);
    T = 1/Fs;             % Sampling period
    L = numel(Fast);             % Length of signal
    t = (0:L-1)*T;
    Y = fft(Fast);
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    fs = Fs*(0:(L/2))/L;
    plot(fs,P1)
    title('mixed')
end