function r_out=extract_trace(r_in, GUIpick,filelist,Rdir)
    %GUI pick is a logical (0 or 1).  1 if you'd like to select files via
    %GUI, or 0 if it should autoselect *.tif files with m_ as a prefix in 
    %the pwd as the tifs to use.
    
    if GUIpick
        [selected_files,selected_dir] = uigetfile('*.tif','MultiSelect','on');
    else
        selected_dir = Rdir;
        selected_struct = filelist;
        temp_cell = struct2cell(selected_struct);
        selected_files = temp_cell(1,:);
    end
        
    
    whole_tic = tic;
    
    if class(selected_files)=='char'
        file_list(1).name = fullfile(selected_dir,selected_files);
    else
        file_list = cell2struct(fullfile(selected_dir,selected_files),'name',1);
    end
    
    for file_idx=1:length(file_list)
        
        
        filename = file_list(file_idx).name;
        disp(['Processing ',filename,'....\n']);
        
        InfoImage = imfinfo(filename);
        NumberImages=length(InfoImage);

        f_matrix = zeros(InfoImage(1).Height,InfoImage(1).Width,NumberImages,'uint16');
        for i=1:NumberImages
            f_matrix(:,:,i) = imread(filename,'Index',i,'Info',InfoImage);
        end
        
        f_matrix = double(reshape(f_matrix,InfoImage(1).Height*InfoImage(1).Width,NumberImages));
        
        for roi_idx=1:numel(r_in)
            current_mask = zeros(1,InfoImage(1).Height*InfoImage(1).Width);
            try
                current_mask(r_in(roi_idx).pixel_idx) = 1;
                r_out(roi_idx).pixel_idx = r_in(roi_idx).pixel_idx;
            catch
                current_mask(r_in(roi_idx).pixel_idx) = 1;
                r_out(roi_idx).pixel_idx = r_in(roi_idx).pixel_idx;
            end
            
            current_trace = (current_mask*f_matrix)/sum(current_mask);
            r_out(roi_idx).file(file_idx).filename = filename;
            r_out(roi_idx).file(file_idx).trace = current_trace;
            
            if file_idx==1
                r_out(roi_idx).trace = current_trace;
            else
                r_out(roi_idx).trace = cat(2,r_out(roi_idx).trace,current_trace);
            end
            
        end
        
    end
    
    for roi_idx=1:numel(r_in)
        r_out(roi_idx).color = rand(1,3);
    end
        
    fprintf(['Total loading time: ',num2str(round(toc(whole_tic),2)),' seconds.\n']);
    
end