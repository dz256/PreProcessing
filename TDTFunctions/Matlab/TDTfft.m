function fft_data = TDTfft(data, channel, bPlot)
%TDTFFT  performs a frequency analysis of the data stream
%   fft_data = TDTfft(DATA, CHANNEL), where DATA is a stream from the 
%   output of TDT2mat and CHANNEL is an integer.
%
%   fft_data    contains power spectrum array
%
%   fft_data = TDTfft(DATA, CHANNEL, BPLOT) where BPLOT is boolean.  If 
%   BPLOT is 0 the plot is not generated.
%
%   Example
%      data = TDT2mat('DEMOTANK2', 'Block-1');
%	   TDTfft(data.streams.Wave, 1);

if nargin < 3, bPlot = 1; end

y = data.data(channel,:);
Fs = data.fs;
fprintf('Fs = %f\n', Fs);

T = 1/Fs;  % Sample time
L = numel(y);   % Length of signal
t = (0:L-1)*T;  % Time vector

NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = fft(y,NFFT)/L;
f = Fs/2*linspace(0,1,NFFT/2+1);

fft_data = 2*abs(Y(1:NFFT/2+1));
 
if bPlot
    figure;
    subplot(3,1,1);
    plot(1000*t,y)
    
    r = rms(y);
    if round(r*1e6) == 0
        r = r*1e9;
        units = 'nV';
    elseif round(r*1e3) == 0
        r = r*1e6;
        units = 'uV';
    elseif round(r) == 0
       r = r*1000;
       units = 'mV';
    else
       units = 'V';
    end 
    title(sprintf('Raw Signal (%.2f %srms)', r, units))
    
    xlabel('Time (ms)')
    axis([0 1000*t(end) min(y)*1.05 max(y)*1.05]);

    % Plot single-sided amplitude spectrum.
    subplot(3,1,2);
    plot(f, fft_data)
    title('Single-Sided Amplitude Spectrum of y(t)')
    xlabel('Frequency (Hz)')
    ylabel('|Y(f)|')
    axis([0 f(end) 0 max(fft_data)*1.05]);
    
    subplot(3,1,3)
    fft_data = 20*log10(fft_data);
    plot(f, fft_data)
    title('Power Spectrum')
    xlabel('Hz')
    ylabel('dBV')
    axis([0 f(end) min(fft_data)*1.05 0]);
    
end