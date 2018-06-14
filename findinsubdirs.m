function list_out = findinsubdirs(start_dir, specifier)
    list_out = {};
    list = dir([start_dir, '\', specifier]);
    if(~isempty(list))
        list = struct2cell(list); list = list(1,:);
        list_out = [list_out; strcat([start_dir, '\'], list')];
    end
    
    dirs = dir(start_dir); dirs = dirs([dirs.isdir]);
    for i =1:1:length(dirs)
        d = dirs(i).name;
        if(~strcmp(d, '.') && ~strcmp(d, '..'))
            list_out = [list_out; findinsubdirs([start_dir, '\', d], specifier)]; %#ok<AGROW>
        end
    end
end