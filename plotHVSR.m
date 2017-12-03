function figures = plotHVSR(D, Fs, frame_size , spot1 , spot2 , sensor_types, sys_type, linetype)

num_rows = 9;

freq = Fs*(1:frame_size/2)'/frame_size;

data_mean = [];
data_std = [];
test_names = {};

n_positions = 0;
for i=1:1:length(D)
    n_positions = n_positions + length(D{i}.HVSR.HighSources);
end

next_position = 0;
for i=1:1:length(D)
    L4s = D{i}.L4s;
    nsensors = length(D{i}.HVSR.HighSources);
    test_num = num2str(D{i}.TestNumber);
    RTCs = ones(1,nsensors);
    RTCs(L4s) = 0; RTCs = find(RTCs);
    for sensor=1:1:nsensors
        ml = D{i}.HVSR.LowSource(sensor).mean;
        mh = D{i}.HVSR.HighSources(sensor).mean;
        stdl = D{i}.HVSR.LowSource(sensor).std;
        stdh = D{i}.HVSR.HighSources(sensor).std;
        
        type = any(L4s == sensor) + 1;
        if(length(L4s)>1)
            positionID = 1 + any(sensor>=L4s(2));
        else 
            positionID = 1;
        end
        if(any(sensor == L4s))
            next_position = next_position + 1;
        end
        if length(L4s) == 1
            name = strcat(test_num, ' ', sensor_types{type}); 
        elseif D{i}.TestNumber == 20
            name = strcat(test_num, spot2{positionID}, ...
                ' ', sensor_types{type}); 
        else
            name = strcat(test_num, spot1{positionID}, ...
                ' ', sensor_types{type});
        end
        test_names{type, next_position} = name;  %#ok<AGROW>
        data_mean(type, :, next_position)= ml + mh;  %#ok<AGROW>
        data_std(type, :, next_position) = sqrt(stdl.^2+stdh.^2);  %#ok<AGROW>
    end
end
num_figures = ceil(length(test_names)/num_rows);
for fid = 1:1:num_figures
    figures(fid) = figure(fid); %#ok<AGROW>
    if fid == num_figures
        n = rem(length(test_names),num_rows);
        n = n +(n == 0) * num_rows;
    else
        n = num_rows;
    end
    for id = 1:1:n
        did = (fid-1)*num_rows+id;
        
        ax = subaxis(n,1,1,id,'ML',0.03,'SV',0,'MB',0.03);
        pname = strcat(test_names(:, did), '-', sys_type);
        if(~isempty(test_names{1, did}))
            loglog(freq, data_mean(1, :, did), ...
                'Color', 'red', 'LineStyle', linetype, ...
                'DisplayName', pname{1}); 
        end
        hold on;
        if(~isempty(test_names{2, did}))
            loglog(freq, data_mean(2, :, did), ...
                'Color', 'blue', 'LineStyle', linetype, ...
                'DisplayName', pname{2});
        end
        hold on;
        
        grid on; grid minor
                
        ax.XScale = 'log';
        ax.YScale = 'log';
        ax.XTick = [0.5 1 2 5 10 15 20 30];
        ax.YTick = [1 2 5 10 15 20];
        xlim([0.2 32])
        ylim([1 20])
        xlabel('Frequency[Hz]')
        
        legend('off')
        l=legend('show','Location','northwest');
        l.FontSize = 6;
    end
end