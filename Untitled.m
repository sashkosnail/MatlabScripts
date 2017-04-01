if((PathName == 0) | (~exist('PathName', 'var'))) %#ok<OR2>
        PathName = ''; end
[FileName, PathName, ~] = uigetfile([PathName, '*.mat'],'Pick File','MultiSelect','on');
if(~iscell(FileName))
    FileName = {FileName}; end
if(FileName{1} == 0)
    return; end
for idx = 1:1:length(FileName)
    D = csvread(FileName{idx});
    mat_file = [PathName FileName(1:end-4) '.mat'];
    save(mat_filename, 'D');
end