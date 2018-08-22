function result = offset(data, window_size, overlap, threshold)
    Nw = length(data)*window_size;
    Nframes = round((1-window_size)/((1-overlap)*window_size))+1;
    result = zeros(Nframes,size(data,2)+1);
    for n=1:1:Nframes
        start_id = floor((n-1)*Nw*(1-overlap))+1;
        end_id = start_id+Nw-1;
        sub_data = data(start_id:1:end_id,:);
        result(n,:) = [start_id + Nw/2 mean(sub_data)];
    end
end