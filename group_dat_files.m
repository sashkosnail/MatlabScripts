if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<OR2>
        PathName = [pwd '\']; 
end
[FileName, PathName, ~] = uigetfile(PathName, 'Geode DIRs','MultiSelect','on');
out_dir = 'D:\Documents\PhD\FieldStudies\Summer\Wilmont_HVSR_GEODE\';
for did = 1:1:length(FileName)
    current_dir = FileName{did};%strcat(PathName, FileName);
    suffix = [current_dir(regexp(current_dir,'\d*'):end) '_'];
    files = dir([current_dir,'*.dat']);
    for fid = 1:1:length(files)
        copyfile([current_dir '\' files(fid)], [outdir suffix files(fid)])
    end
end
