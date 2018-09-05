% close all
isTableCol = @(t, thisCol) ismember(thisCol, t.Properties.VariableNames);
if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<OR2>
        PathName = [pwd '\']; 
end
[FileName, PathName, ~] = uigetfile([PathName, '*.tdms'],'Pick File','MultiSelect','on');
if(~iscell(FileName))
    FileName = {FileName}; end
if(FileName{1} == 0)
    return; 
end
if(exist([PathName 'sensor_configuration.txt'], 'file'))
    sensor_config = readtable([PathName 'sensor_configuration.txt'], ...
        'Format','%d%s%s', 'Delimiter', '\t', 'MultipleDelimsAsOne', 1);
    %trim table if too large
    sensor_config = sensor_config(1:min(height(sensor_config),8),:);
else
    %default config
    sensor_config = table((1:8)', cellstr(strcat('s',num2str((1:8)'))), ...
        cellstr(repmat('xyz',8,1)), ...
        'VariableNames',{'Ch','Name','Components'});
end

active_ids = find(~strcmp(sensor_config.Name,'0'))';
sensor_names = sensor_config.Name(active_ids);
components = sensor_config.Components(active_ids);
number_of_sensors = length(active_ids);

%figure out the order of channels and components
data_channels = zeros(1, 3*number_of_sensors);
for sensor = 1:1:number_of_sensors
    chan = active_ids(sensor);
    comps = cell2mat(components(sensor));
    %column numbers for the given channel
    cn = (chan*3-2):(chan*3);
    %reorder based on comps
    comp_set = [cn(comps == 'x') cn(comps == 'y') cn(comps == 'z')];
    %add one to skip over time column and append to final vector
    data_channels((sensor*3-2):(sensor*3)) = comp_set + 1;
end
sensor_config = [sensor_config(active_ids,:) ...
    table(reshape(data_channels,3,[])', 'VariableNames', {'ColumnsUsed'})];
names = cellfun(@(c)strcat({'X_';'Y_';'Z_'},c), sensor_names, 'uni', 0);
names = vertcat(names{:})';

disp('Using Sensor Configuration:');
disp(sensor_config);
%% 
for idx = 1:1:length(FileName)
    datfile = FileName{idx};
    disp('===============================================================');
    disp(datfile)
    TDMSStruct = TDMS_getStruct([PathName datfile],6);
    Dtable = TDMSStruct.DATA;
    datfile = datfile(1:find(datfile=='.', 1, 'last')-1);
        
    %extract data from data file
    t = Dtable{:,1}; Fs = 1/(t(2)-t(1));
    data = Dtable{:,data_channels};
    D = [t data-ones(length(data),1)*mean(data);];
    %Extract confguration information
    config = Dtable{:,26:end};
    FILTERS = [32,64,128];
    SCALES_STR1 = {'0.1mm/s', 'Calibration', '100mm/s', '10mm/s', '1mm/s'};
    SCALES_STR2 = {'Calibration', '100mm/s', '10mm/s', '1mm/s', '0.1mm/s', '0.01mm/s'};
    
    if(~isTableCol(TDMSStruct.Properties, 'DAQVersion'))
        oldDAQ = strcmpi('Y', input('OldDaqData [Y]:','s'));
    else
        oldDAQ = strcmp(TDMSStruct.Properties.DAQVersion, '1.0');
    end
    if(oldDAQ)
        scale_selected = round(mean(config(:,end)))+1;
        SCALE = SCALES_STR1{scale_selected};
    else
        scale_selected = round(mean(config(:,end)));
        SCALE = SCALES_STR2{scale_selected};
    end
    filt_selected = round(mean(config(:,end-1)))-1;
    
    disp(['Filter Selected: ', num2str(FILTERS(filt_selected)), ...
        'Hz || Scale Selected: ', SCALE]);
    disp(['Sample Rate: ', num2str(Fs), 'Hz ', ...
        '|| Signal Duration: ', num2str(t(end)-t(1)+1/Fs),'s']);

    %decimate to 100Hz
%     if(Fs ~= 100)
%         downsample_factor = ceil(Fs/100);
%         DD = myDecimate([t data], downsample_factor, 45);
%         t = DD(:,1);
%         data = DD(:,2:end);
%         Fs = 1/(t(2)-t(1));
%     end

    %remove offset
    data = (data-ones(length(data),1)*mean(data));
    %secondary filter based on recording filter cutoff
    filter_cutoff = FILTERS(filt_selected);
    [fnum, fden] = butter(8, filter_cutoff*2/Fs, 'low');
    data = filtfilt(fnum, fden, data);
    
    %gather and display statistics of signals
    STATS = signal_stats(D, names); 
    disp(STATS);
    
    %plot signals
    fig_name = datfile;
    fig = plot_sensor_data(D, fig_name, names, idx);
    
    %build result table and display/save results
	Dtable = array2table(D, 'VariableNames', [{'Time'}, names]);
    save_data = 'N'; %#ok<NASGU>
%     save_data = upper(input('Save Data Y/N [Y]:','s'));
    if isempty(save_data)
        save_data = 'Y'  %#ok<NOPTS>
    end
    if(~strcmp(save_data,'N'))
        mat_file = [PathName datfile '.mat'];
        csv_file = [PathName datfile '.csv'];
        png_file = [PathName datfile '.png'];
        
        save(mat_file, 'D', 'STATS', 'sensor_config');
        writetable(Dtable, csv_file, 'WriteVariableNames', 1);
        export_fig(png_file, '-c[0 0 0 0]', fig);
    end
end