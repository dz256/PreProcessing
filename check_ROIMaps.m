% go over all ROI maps..

pathways = table2struct( readtable('Z:\Data\DanaTemp\PreProcessing\new_data\pathways.xlsx') );
imageDir = 'Z:\Data\DanaTemp\PreProcessing\minmax\MaxMin_';
ROIdir =  'Z:\Data\DanaTemp\PreProcessing\ROIandTraces\';
tifdir = 'Z:\Data\DanaTemp\PreProcessing\new_data\Processed\';


for im = 1:numel(pathways)
    if(~isnan(pathways(im).ROI_check))
        continue
    end
    
    Name =[imageDir,num2str(pathways(im).mouse),'_',pathways(im).type,'.mat'];
    a =load(Name); 
    I = a.I;
    a = [];
    suffix = [num2str(pathways(im).mouse),'_',pathways(im).type];
    R = load([ROIdir,'ROI_',suffix,'.mat']);
    R = R.R;
    %remove unwanted ROIs
    [R,badROI] = SemiSeg_Remove(I,R);
    trace = load([ROIdir,'trace_',suffix,'.mat']);
    trace = trace.r_out;
    b = zeros(size(trace));
    b(badROI) = 1;
    trace = trace(~b);
    clear b badROI
    nROI = size(R,1);
    % add undetected ROIs
    R = SemiSeg(I,R);
    r_out = trace;
    save([ROIdir,'ROI_',suffix],'R')
    save([ROIdir,'trace_',suffix],'r_out')
    clear r_out
    pathways(im).ROI_check = nROI;
    close all
    button = questdlg('Would yo like to do another session?',...
            'more sessions?','Yes','No','Yes');
   if button == "No"
       break
   end
end
T = struct2table(pathways);
writetable(T,'Z:\Data\DanaTemp\PreProcessing\new_data\pathways.xlsx')
