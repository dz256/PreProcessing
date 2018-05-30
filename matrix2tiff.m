% file written by Hua-an and Kyle
function matrix2tiff(f_matrix, filename, method)

    % if ~isempty(dir(filename))
    %     overwrite = input('File already exists. Overwrite (0-no/1-yes)?');
    %     if isempty(overwrite) || overwrite==0
    %         load(fnmat)
    %         return
    %     end
    % end



    if isempty(strfind(filename,'.tif'))
        filename = [filename,'.tif'];
    end

    NumberImages = size(f_matrix,3);

    switch method
        case 'w'
            FileOut = Tiff('temp_file','w');

        case 'w8'
            FileOut = Tiff('temp_file','w8');
    end

    tags.ImageLength = size(f_matrix,1);
    tags.ImageWidth = size(f_matrix,2);
    tags.Photometric = Tiff.Photometric.MinIsBlack;
    tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tags.BitsPerSample = 16;
    setTag(FileOut, tags);
    FileOut.write(f_matrix(:,:,1));
    for i=2:NumberImages
        FileOut.writeDirectory();
        setTag(FileOut, tags);
        FileOut.write(f_matrix(:,:,i));
    end
    FileOut.close()

    movefile('temp_file',filename);

end