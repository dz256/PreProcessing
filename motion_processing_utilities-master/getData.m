function data = getData(fname) % from Mark? navigate to directory with vrffile. Load it. 
if iscell(fname)
	for k=1:numel(fname)
		dataCell{k} = readBinaryData(fname{k});
	end
	data = cat(3,dataCell{:});
else
	data = readBinaryData(fname);
end
end