function list_out = subdirlist(start_dir)
    list = dir(start_dir);
    list_out = {};
    for i =1:1:length(list)
        if(list(i).isdir && ~strcmp(list(i).name,  '.') && ~strcmp(list(i).name,  '..'))
            item = [start_dir '\' list(i).name];
            list_out{length(list_out)+1,1} = item;%#ok<AGROW>
            list_out = [list_out; subdirlist(item)]; %#ok<AGROW>
        else
            continue
        end
    end
end