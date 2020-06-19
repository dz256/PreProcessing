figure;
for d = 1:numel(D)
    data = D(d);
    Fs = data.streams.Wave.fs;
    Fast = lfp10; % data.streams.Wave.data(10,:);
    T = 1/Fs;             % Sampling period       
    L = numel(Fast);             % Length of signal
    t = (0:L-1)*T;  
    Y = fft(Fast);
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(L/2))/L;
    subplot(2,2,d)
    plot(f,P1)
    title(sprintf('block %d',d))
    xlim([0,20])
end