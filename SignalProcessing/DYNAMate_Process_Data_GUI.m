function DYNAMate_Process_Data_GUI(varargin)
global PathName tab_group   
    if(~exist('PathName', 'file'))
        PathName = [pwd '\']; 
    end
    
    fig = figure(1111); clf
    pause(0.00001);
    set(fig, 'ToolBar', 'none', 'Units', 'Normalized', ...
        'OuterPosition', [0 0 1 1]);
    
    tab_group = uitabgroup('Parent', fig, 'Units', 'normalized', ...
        'Position', [0 0, 1, 1], 'SelectionChangedFcn', @tab_changed_callback);
    open_button = uicontrol('Parent', tab_group, 'Style', 'pushbutton', ...
        'Units', 'normalized', 'Position', [0.95 0.95 0.05 0.05], ...
        'Callback', open_file_callback, 'String', 'Open', ...
        'ToolTipString', 'Open'); %#ok<NASGU>
end

function read_sensor_config()
global PathName OUTPUT
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
    names = cellfun(@(c,i) strcat(num2str(i), {'_X_';'_Y_';'_Z_'}, c), ...
        sensor_names, num2cell(active_ids)', 'uni', 0);
    names = vertcat(names{:})';
    
    OUTPUT.Sensor_configuration.Table = sensor_config;
    OUTPUT.Sensor_configuration.Names = names;
    OUTPUT.Sensor_configuration.DataChannels = data_channels;
    
    disp('Using Sensor Configuration:');
    disp(sensor_config);
end

function read_Data()
global PathName OUTPUT
    isTableCol=@(t, thisCol) ismember(thisCol, t.Properties.VariableNames);
    OUTPUT.Data = cell(length(OUTPUT.Source_FileName),1);
    for idx = 1:1:length(OUTPUT.Source_FileName)
        datfile = OUTPUT.Source_FileName{idx};        
        TDMSStruct = TDMS_getStruct([PathName datfile],6);
        Dtable = TDMSStruct.DATA;

        %extract data from data file
        Fs = 1/(Dtable{2,1}-Dtable{1,1});
        duration = Dtable{end,1}-Dtable{1,1}+1/Fs;
        DATA = Dtable(:,[1 OUTPUT.Sensor_configuration.DataChannels]);
        CONFIG = Dtable(:,26:end);
        
        %Extract confguration information
        FILTERS = [32,64,128];
        FILTERS_str = {'32','64','128'};
        SCALES_1 = [0.1, 0, 100, 10, 1];
        SCALES_str1 = {'0.1mm/s', 'Calibration', '100mm/s', '10mm/s', '1mm/s'};
        SCALES_2 = [0, 100, 10, 1, 0.1, 0.01];
        SCALES_str2 = {'Calibration', '100mm/s', '10mm/s', '1mm/s', '0.1mm/s', '0.01mm/s'};

        if(~isTableCol(TDMSStruct.Properties, 'DAQVersion'))
            oldDAQ = strcmpi('Y', input('OldDaqData [Y]:','s'));
        else
            oldDAQ = strcmp(TDMSStruct.Properties.DAQVersion, '1.0');
        end
        scale_selected = round(mean(CONFIG(:,end)));
        filter_selected = round(mean(CONFIG(:,end-1)))-1;
        if(oldDAQ)
            scale_selected = scale_selected + 1;
            SCALE_str = SCALES_str1{scale_selected};
            SCALE = SCALES_1(scale_selected);
        else
            SCALE_str = SCALES_str2{scale_selected};
            SCALE = SCALES_2(scale_selected);
        end
        
        SWVersion = TDMSStruct.Properties.Software_Version;
        DAQVersion = TDMSStruct.Properties.DAQVersion;
        
        OUTPUT.Data{idx}.Filename = datfile;
        OUTPUT.Data{idx}.SW_version = SWVersion;
        OUTPUT.Data{idx}.DAQ_version = DAQVersion;
        OUTPUT.Data{idx}.Fs = Fs;
        OUTPUT.Data{idx}.SignalDuration = duration;
        OUTPUT.Data{idx}.SignalNSamples = length(DATA);
        OUTPUT.Data{idx}.DATA.Velocity = DATA(:,2:end);
        OUTPUT.Data{idx}.DATA.Acceleration = zeros(size(DATA(:,2:end)));
        OUTPUT.Data{idx}.DATA.Displacement = zeros(size(DATA(:,2:end)));
        OUTPUT.Data{idx}.DATA.Time = DATA(:,1);
        OUTPUT.Data{idx}.Stats = signal_stats(table2array(Dtable), OUTPUT.Sensor_configuration.Names);
        OUTPUT.Data{idx}.ScaleSTR = SCALE_str;
        OUTPUT.Data{idx}.FilterSTR = FILTERS_str(filter_selected);
        OUTPUT.Data{idx}.Scale = SCALE;
        OUTPUT.Data{idx}.Filter = FILTERS(filter_selected);
        OUTPUT.Data{idx}.ConfigTable = struct2table(struct(...
            'FileName', datfile, 'DAQVersion', DAQVersion, ...
            'Fs', Fs, 'SignalDuration',duration, 'NSamples',length(DATA)));
        
        createNewTab(idx);
    end
end

function createNewTab(idx)
global OUTPUT tab_group
    tab = uitab('Parent', tab_group, 'Title', OUTPUT.Data{idx}.FileName);
    
    signal_length = OUTPUT.Data{idx}.SignalNSamples;
    num_sensors = size(data,2)/3;
    %create parameters
    window_size = 4096;
    smoothN = 31;
    
    %create UI controls
    time_tb = uicontrol('Parent', tab, 'Style', 'edit', ...
        'Units', 'normalized', 'Position', [0.72 0.98 0.05 0.02], ...
        'KeyReleaseFcn', time_tb_callback, ...
        'ToolTipString', 'Window Center Time');
    
    time_slider = uicontrol('Parent', tab, 'Style', 'slider', ...
        'Value', 0, 'Min', 0, 'Max', signal_length-window_size, ...
        'Units', 'normalized', 'Position', [0 0.98 0.72 0.02], ...
        'SliderStep', [0.001 0.001], 'Callback', slider_moved_callback, ...
        'ToolTipString', 'Time Slider', 'UserData', time_tb);
    
    window_size_tb = uicontrol('Parent', tab, 'Style', 'edit', ...
        'Units', 'normalized', 'Position', [0.9 0.98 0.05 0.02], ...
        'KeyReleaseFcn', window_size_tb_callback, 'String', num2str(window_size), ...
        'ToolTipString', 'Window Size'); %#ok<NASGU>
    
    hamming_cb = uicontrol('Parent', tab, 'Style', 'checkbox', ...
        'Units', 'normalized', 'Position', [0.77 0.98 0.08 0.02], ...
        'Callback', hamming_cb_callback, 'Value', 1, ...
        'ToolTipString', 'Apply Hamming to Window', ...
        'String', 'Apply Hamming Window'); %#ok<NASGU>
    
    smoothN_tb = uicontrol('Parent', tab, 'Style', 'edit', ...
        'Units', 'normalized', 'Position', [0.85 0.98 0.05 0.02], ...
        'KeyReleaseFcn', smoothN_tb_callback, 'String', num2str(smoothN), ...
        'ToolTipString', 'Spectrum Smooth Box Size'); %#ok<NASGU>
    
    save_button = uicontrol('Parent', tab, 'Style', 'pushbutton', ...
        'Units', 'normalized', 'Position', [0.95 0.98 0.05 0.02], ...
        'Callback', savebutton_callback, 'String', 'Save Data', ...
        'ToolTipString', 'Save'); %#ok<NASGU>
    
    %create axis
    full_plot_axis = subplot('Parent', tab, 'Position', [0 0.87 1 0.09]);
    plot_vert_size = 0.91/num_sensors*.9;
    ch_axis = cell(num_sensors, 1);
    for idx = 0:1:num_sensors - 1
        ch_axis{idx}.SignalAxis = subplot('Position', ...
            [0.015, plot_vert_size*idx+0.05, 0.71, plot_vert_size], ...
            'Xgrid', 'off', 'Ygrid', 'off', 'Color', 'w');
        ch_axis{idx}.SpectrumAxis = subplot('Position', ...
            [0.75, plot_vert_size*idx+0.05, 0.245, plot_vert_size], ...
            'Xgrid', 'off', 'Ygrid', 'off', 'Color', 'w'); 
    end
    
    %set user data objects
    time_slider.UserData = struct('Plot', full_plot_axis, ...
        'TimeTB', time_tb);
    tab.UserData = struct('window_size', window_size, ...
        'smoothN', smoothN, 'CurrentWindow', [0 window_size], ...
        'applyHamming', 1, 'DataIDX', idx, 'AccVelDisp', 1, ...
        'FullPlot', full_plot_axis, 'ChannelAxis', ch_axis, ...
        'VertBars', [], 'TimeSlider', time_slider);
    
    %plot data
    plot_tab_data(tab);
end

function plot_tab_data(tab)
global OUTPUT
    idx = tab.UserData.DataIDX;
    switch tab.UserData.AccVelDisp
        case 0
            data = OUTPUT.Data{idx}.DATA.Acceleration;
        case 2
            data = OUTPUT.Data{idx}.DATA.Displacement;
        otherwise
            data = OUTPUT.Data{idx}.DATA.Velocity;
    end
    ax = tab.UserData.full_plot_axis;
    
    plot(data, 'ButtonDownFcn', full_plot_callback, 'Parent', ax);
    grid on; hold on; axis tight
    set(gca, 'Color', 'w', 'GridColor', 'k', 'XAxisLocation', 'top');
    
    plot_vert_bars(tab);
    
    for idx = 0:1:num_sensors - 1
        plot_channel_data(tab)
    end
end

function plot_channel_data(tab)
global OUTPUT
    idx = tab.UserData.DataIDX;
    window_data_id = tab.UserData.CurrentWindow(1):1:tab.UserData.CurrentWindow(2);
    t=window_data_id/OUTPUT.Data{idx}.Fs;
    chanNames = OUTPUT.Sensor_configuration.Names;
    switch tab.UserData.AccVelDisp
        case 0
            data = OUTPUT.Data{idx}.DATA.Acceleration(window_data_id,:);
        case 2
            data = OUTPUT.Data{idx}.DATA.Displacement(window_data_id,:);
        otherwise
            data = OUTPUT.Data{idx}.DATA.Velocity(window_data_id,:);
    end
    data_range = [-1 1].*max(max(abs(data)));
    text_locations = [0.75 0 -0.75]*data_range(2)*.75;
    peak_data = find_Vpp_window(data);
    VppTable = zeros(1, 24);

    for idx = 0:1:num_sensors - 1
        data_id = ((num_sensors -1 - idx)*3 + 1):((num_sensors - idx)*3);
        ax = tab.UserData.ChannelAxis{idx}.SignalAxis;
        plot(t,data(:,data_id), 'LineWidth', 1, 'Parent', ax);
        grid on; hold on
        set(ax, 'Color', 'w', 'GridColor', 'k', 'XLim', [t(1) t(end)], ...
            'XAxisLocation', 'bottom');
        
        if(idx==0)
            ax.XAxis.Visible = 'on';
            lbl=xlabel('Time[s]');
            set(lbl, 'Units', 'normalized','Position',[0.5 0.2 0]);
        else
            ax.XAxis.Visible = 'off';
        end
        
        colors = [217 83 25; 0 114 189; 237 177 32]./255;
        for comp_id = 1:1:3
            idc = (num_sensors - 1 - idx)*3+comp_id;
            mVpp_idx = peak_data(idc,:);
            maxVpp = sum(abs(data(mVpp_idx,idc)));
            VppTable(idc) = maxVpp;
            plot(t(mVpp_idx), window_data(mVpp_idx, idc), 'LineStyle', 'none', ...
                'Marker','d','MarkerFaceColor', colors(comp_id,:))
            text(t(10), text_locations(comp_id), ...
            ['Vpp[', chanNames{idc},'][mm/s]=', num2str(maxVpp,'%5.3f')], ...
                'Color', 'k', 'BackgroundColor',[0.9 0.9 0.9]);
        end
        hold off
        ylim(data_range)
        
        applyHamming = tab.UserData.applyHamming;
        specSmoothN = tab.UserData.smoothN;
        if(applyHamming)
            window_function = repmat(hamming(N), 1, size(data,2));
        else
            window_function = ones(N,size(data,2));
        end
        fftdata = abs(fft(data.*window_function, N, 1)/(N-1));
        fftdata = abs(fftdata(ceil(1:N/2),:));
        fftdata(2:end-1,:) = 2*fftdata(2:end-1,:);
        if(specSmoothN == 1)
            fftdata_filt = fftdata;
        else
            fftdata_filt = filtfilt(ones(1,specSmoothN),1,fftdata);
        end
        f = Fs*(1:N/2)'/N;
        fft_range = [min(min(abs(fftdata_filt))) max(max(abs(fftdata_filt)))];
        
        ax = tab.UserData.ChannelAxis{idx}.SpectrumAxis;
        loglog(f,abs(fftdata_filt(:,data_id)), 'LineWidth', 1, ...
            'Parent', ax);
        grid on; 
        set(gca, 'Color', 'w', 'GridColor', 'k', ...
            'XAxisLocation', 'bottom');
        if(idx==0)
            ax.XAxis.Visible = 'on';
            lbl = xlabel('Frequency[Hz]');
            set(lbl, 'Units', 'normalized','Position',[0.5 0.2 0]);
        else
            ax.XAxis.Visible = 'off';
        end
        ylim(fft_range)
        xlim([f(1), f(end)]);
        set(gca, 'YTick', [0.001 1], 'XTick',[0.1 1 10 100]);
    end
    l = legend('X','Y','Z');
    l.TextColor = 'k';
    l.Location = 'south';
end

function plot_vert_bars(tab)
global OUTPUT
    idx = tab.UserData.DataIDX;
    window_data_id = tab.UserData.CurrentWindow(1):1:tab.UserData.CurrentWindow(2);
    t=window_data_id/Fs;
    switch tab.UserData.AccVelDisp
        case 0
            data = OUTPUT.Data{idx}.DATA.Acceleration(window_data_id,:);
        case 2
            data = OUTPUT.Data{idx}.DATA.Displacement(window_data_id,:);
        otherwise
            data = OUTPUT.Data{idx}.DATA.Velocity(window_data_id,:);
    end
    %establish and draw window
    vert_bars_t = [t(1) t(end)];
    vert_bars_t = [vert_bars_t; vert_bars_t];
    vert_bars_h = [min(min(data)); max(max(data))]; 
    vert_bars_h = [vert_bars_h vert_bars_h];
    
    delete(tab.UserData.VertBars)
    tab.UserData.VertBars = plot(vert_bars_t, vert_bars_h, ...
        'Parent', tab.FullPlot, 'Color', 'r', 'LineWidth', 2, ...
        'LineStyle','--');
end

%CALLBACKS
function full_plot_callback(hObject, eventData)
global OUTPUT
    tab = hObject.Parent;
    time_slider = tab.UserData.TimeSlider;
    Fs = OUTPUT.Data{tab.UserData.DataIDX}.Fs;
    val = Fs*eventData.IntersectionPoint(1) - tab.UserData.window_size/2;
    val = max(0, val);
    val = min(time_slider.Max, val);
    time_slider.Value = val;
    slider_moved_callback(time_slider, 0);
end

function hamming_cb_callback(hObject, ~)
    tab = hObject.Parent;
    time_slider = tab.UserData.TimeSlider;
    tab.UserData.applyHamming = hObject.Value;
    slider_moved_callback(time_slider, 0);
end

function time_tb_callback(hObject, eventData)
    tab = hObject.Parent;
    time_slider = tab.UserData.TimeSlider;
    if(~strcmp(eventData.Key, 'return'))
        return;
    end
    val = str2double(hObject.String);
    if(isnan(val))
        return
    end
    val = max(0, val);
    val = min(time_slider.Max, val);
    time_slider.Value = val;
    slider_moved_callback(time_slider, 0);
end

function smoothN_tb_callback(hObject, eventData)
    tab = hObject.Parent;
    time_slider = tab.UserData.TimeSlider;
    if(~strcmp(eventData.Key, 'return'))
        return;
    end
    val = str2double(hObject.String);
    if(isnan(val))
        return
    end
    tab.UserData.smoothN = val;
    slider_moved_callback(time_slider, 0);
end

function window_size_tb_callback(hObject, eventData)
    tab = hObject.Parent;
    time_slider = tab.UserData.TimeSlider;
    if(~strcmp(eventData.Key, 'return'))
        return;
    end
    val = str2double(hObject.String);
    if(isnan(val))
        return
    end
    tab.UserData.window_size = val;
    time_slider.Max = signal_length - val;
    time_slider.Value = min(time_slider.Value, time_slider.Max);
    slider_moved_callback(time_slider, 0);
end

function slider_moved_callback(hObject, ~)
    tab = hObject.Parent;
    time_slider = hObject;
    time_slider.Value = floor(time_slider.Value);

    hObject.UserData.String = num2str(time_slider.Value);
    %get data subset
    N = tab.UserData.window_size;
    window_data_id = (1:1:N)+floor(time_slider.Value);
    tab.UserData.CurrentWindow = [window_data_id(1) window_data_id(end)];
    
    plot_vert_bars()
    plot_channel_data();
end

function open_file_callback(~, ~)
global PathName OUTPUT
    [FileName, PathName, ~] = uigetfile([PathName, '*.tdms'], ...
        'Pick File','MultiSelect','on');
    if(~iscell(FileName))
        FileName = {FileName}; end
    if(FileName{1} == 0)
        return; 
    end
    OUTPUT.Source_FileName = FileName;
    read_sensor_config();
    read_Data();
end

function savebutton_callback(hObject, ~, data)
    throw(MException('Incomplete','Incomplete'))
    fig = hObject.Parent;
    time_tb = hObject.UserData;
    default_name = fig.Name;
    default_name(isspace(default_name))=[];
    dash_idx = find(default_name=='-') - 1;
    default_name = [default_name(1:dash_idx), '_', time_tb.String, ...
        '_', default_name(dash_idx+2:end)];
    
    [FileName,PathName_save] = uiputfile('*.png', 'Save Results', ...
        [PathName, default_name]);
    if(FileName == 0) ;return; end
    
    export_fig(strcat(PathName_save, FileName(1:end-4)), ...
        '-c[20 0 0 0]', fig);
    writetable(STATS, [PathName_save, FileName(1:end-4),'.xlsx'], ...
        'WriteRowNames', 1);
    
    savefig(fig,strcat(PathName_save, fig.Name),'compact');
    csvwrite([PathName_save, fig.Name,'.csv'], ...
        [(0:1:length(data)-1)'/Fs data]);
    disp('Save Complete')
end

function tab_changed_callback(hObject, eventdata)
end


%         disp('===============================================================');
%         disp(datfile)
%         
%         disp(['Filter Selected: ', num2str(FILTERS(filt_selected)), ...
%             'Hz || Scale Selected: ', SCALE]);
%         disp(['Sample Rate: ', num2str(Fs), 'Hz ', ...
%             '|| Signal Duration: ', num2str(t(end)-t(1)+1/Fs),'s']);
% 
%         %remove offset
%         data = (data-ones(length(data),1)*mean(data));
%         %secondary filter based on recording filter cutoff
%         filter_cutoff = FILTERS(filt_selected);
%         [fnum, fden] = butter(8, filter_cutoff*2/Fs, 'low');
%         data = filtfilt(fnum, fden, data);
%         
%         datfile = datfile(1:find(datfile=='.', 1, 'last')-1);
%                 disp(STATS);
%         %decimate to 100Hz
% %     if(Fs ~= 100)
% %         downsample_factor = ceil(Fs/100);
% %         DD = myDecimate([t data], downsample_factor, 45);
% %         t = DD(:,1);
% %         data = DD(:,2:end);
% %         Fs = 1/(t(2)-t(1));
% %     end