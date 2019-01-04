button = questdlg('',...
            'Would you like to see bad ROIs on video before removal?','Yes','No','Yes');
        if strcmp(button,'Yes')
            % find how many tif files are there:
            tifdir = '/home/dana_z/HD1/Processed_tifs/';
            vids = dir([tifdir,'m_n_',suffix,'_*.tif']);
            if numel(vids)==0
                tifdir = '/home/dana_z/HD2/Processed_tifs2/';;
                vids = dir([tifdir,'m_n_',suffix,'_*.tif']);
            end
            Qstr = ['Which videos? (total available ',num2str(numel(vids)),')'];
            answer = inputdlg({['vid numbers',Qstr]}, Qstr,1,{num2str(1)});
            vi = str2num(char(answer));
            for v = 1:numel(vi)
                