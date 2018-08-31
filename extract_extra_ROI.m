%extract additional ROI traces

pathways = table2struct( readtable('Z:\Data\DanaTemp\PreProcessing\new_data\pathways.xlsx') );
tifdir = 'Z:\Data\DanaTemp\PreProcessing\new_data\Processed\';
ROIdir =  'Z:\Data\DanaTemp\PreProcessing\ROIandTraces\';


for im = 1:numel(pathways)
    if(isnan(pathways(im).ROI_check)|| pathways(im).re_extract==1)
        continue
    end
    suffix = [num2str(pathways(im).mouse),'_',pathways(im).type];
    nROI = pathways(im).ROI_check;
    R = load([ROIdir,'ROI_',suffix,'.mat']);
    R = R.R;
    trList = dir([tifdir,'m_f_n_',suffix,'_*.tif']);
    [~,idx] = sort(cellfun(@(x) str2num(char(regexp(x,'(?<=_)(\d*)(?=\.)','match'))),{trList.name}));
    trList = trList(idx);
    r_out=extract_trace(R((nROI+1):end), 0,trList,tifdir); 
    trace = load([ROIdir,'trace_',suffix,'.mat']);
    trace = trace.r_out;
    % combine traces, save, and update pathways
    r_out = [trace,r_out];
    save([ROIdir,'trace_',suffix],'r_out')
    clear r_out
    pathways(im).re_extract =1;
end

T = struct2table(pathways);
writetable(T,'Z:\Data\DanaTemp\PreProcessing\new_data\pathways.xlsx')
