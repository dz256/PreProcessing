%%
%To run ephys data: Place tank in C:TDT/Tanks folder. Register tank in
%scope. Add TDT Tanks to path. Add hgritton/msarter29/documents/matlab to
%path. Run extract_tdt_3_LFPOnly - change file name and block to what you
%want. Once you have lfp10 in workspace you can run this script.


figure 

    Fast = lfp10; 
    [y,f,t,p] = spectrogram(Fast, 140, 120, 1200, SampFreq, 'yaxis'); % (Fast, 150, 120, 1200, 1500, 'yaxis')
      surf(t,f,10*log10(abs(p)),'EdgeColor','none');   
      axis xy; axis tight; colormap(jet); view(0,90); colorbar;
      
      %%
 
   
%lfp2 =lfp{2}; 
range = (1:length(lfp(10)));
%range = (434057:648498);
subplot (3,1,1)      
params.tapers=[1 2]; 
params.Fs= SampFreq
params.trialave = 0; 
params.pad = 1;
params.fpass = [0 100];
movingwin = [0.50 0.05];
time=[1/SampFreq:1/SampFreq:length(lfp10(range))/SampFreq]; 
    [S,t,f]=mtspecgramc(lfp10(range),movingwin,params);
    plot_matrix(S,t,f); xlabel('Time (Seconds)'); ylabel('Hz'); colorbar('off') 
    
    
subplot (3,1,2)
plot (time, lfp10(range))
xlim ([0 max(time)])
  
subplot (3,1,3)
i=zeros(1,length(FramesTS));
plot (FramesTS,i,'.')
xlim ([0 length(time)])
    
    %%
