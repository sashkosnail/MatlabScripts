%UI setup
function DYNAMate_Process_Data_GUI(varargin)
global OUTPUT PathName tab_group wait_window 
    if(~exist('PathName', 'file'))
        PathName = [pwd '\']; 
    end
    wait_window = waitbar(0,'Please wait...');
    wait_window.Children.Title.Interpreter = 'none';
    fig = figure('DeleteFcn', @figure_close_cb); clf
    pause(0.00001);
    set(fig, 'ToolBar', 'none', 'Units', 'Normalized', ...
        'OuterPosition', [0 0 1 1]);
    
    tab_group = uitabgroup('Parent', fig, 'Units', 'normalized', ...
        'Position', [0 0, 1, 1], 'SelectionChangedFcn', @tab_changed_callback);
    
    figure(wait_window)
    [FileName, PathName, ~] = uigetfile([PathName, '*.tdms'], ...
        'Pick File','MultiSelect','on');
    
    if(~iscell(FileName))
        FileName = {FileName}; end
    if(FileName{1} == 0)
        delete(wait_window)
        return; 
    end
    OUTPUT.Source_FileName = FileName;
    read_Data();
end

function createNewTab(idx)
global OUTPUT tab_group wait_window file_progress total_progress
    tab = uitab('Parent', tab_group, 'Title', OUTPUT.Data{idx}.FileName);
    
    Fs = OUTPUT.Data{idx}.Fs;
    signal_length = OUTPUT.Data{idx}.SignalNSamples;
    num_sensors = OUTPUT.Data{idx}.Nsensors;
    %create parameters
    window_size = min(4096, 2^(nextpow2(signal_length)-1));
    smoothN = 31;
    
    %create UI controls
    overview_text = uitable('Parent', tab);
    overview_text.Data = table2cell(OUTPUT.Data{idx}.ConfigTable(:,2:end));
    overview_text.ColumnName = OUTPUT.Data{idx}.ConfigTable.Properties.VariableNames(2:end);
    overview_text.ColumnWidth = {70, 70, 40, 60, 60, 50, 40, 40, 40};
    overview_text.Units = 'normalized';
    overview_text.Position = [0.75 0.92 0.25 0.05];
    overview_text.RowName = [];
    overview_text.Units = 'pixels';
    overview_text.Position(3:4) = [475 75];
    overview_text.Units = 'normalized';
    
    data_type_pd = uicontrol('Parent', tab, 'Style', 'popupmenu',...
        'Units', 'normalized', 'Position', [0 0.98 0.1 0.02], ...
        'Value', 2, 'String', {'Acceleration', 'Velocity', 'Displacement'}, ...
        'ToolTipString', 'Window Center Time', 'Callback', @data_type_pd_callback); %#ok<NASGU>
    
    save_button = uicontrol('Parent', tab, 'Style', 'pushbutton', ...
        'Units', 'normalized', 'Position', [0.1 0.98 0.05 0.02], ...
        'Callback', @savebutton_callback, 'String', 'Save Data', ...
        'ToolTipString', 'Save'); %#ok<NASGU>
    
    time_text = uicontrol('Parent', tab, 'Style', 'text', ...
        'Units', 'normalized', 'Position', [0.15 0.98 0.075 0.02], ...
        'String', 'Window Center Time:', 'HorizontalAlignment', 'right'); %#ok<NASGU>
    time_tb = uicontrol('Parent', tab, 'Style', 'edit', ...
        'Units', 'normalized', 'Position', [0.225 0.98 0.05 0.02], ...
        'KeyReleaseFcn', @time_tb_callback, 'String', num2str(window_size/(2*Fs)), ...
        'ToolTipString', 'Window Center Time');
    
    window_size_text = uicontrol('Parent', tab, 'Style', 'text', ...
        'Units', 'normalized', 'Position', [0.3 0.98 0.075 0.02], ...
        'String', 'Frame Size:', 'HorizontalAlignment', 'right'); %#ok<NASGU>
    window_size_tb = uicontrol('Parent', tab, 'Style', 'edit', ...
        'Units', 'normalized', 'Position', [0.375 0.98 0.05 0.02], ...
        'KeyReleaseFcn', @window_size_tb_callback, 'String', num2str(window_size), ...
        'ToolTipString', 'Frame Size'); %#ok<NASGU>
    
    window_type_text = uicontrol('Parent', tab, 'Style', 'text', ...
        'Units', 'normalized', 'Position', [0.45 0.98 0.07 0.02], ...
        'String', 'Frame Window Type:', 'HorizontalAlignment', 'right'); %#ok<NASGU>
    window_type_cb = uicontrol('Parent', tab, 'Style', 'checkbox', ...
        'Units', 'normalized', 'Position', [0.52 0.98 0.08 0.02], ...
        'Callback', @hamming_cb_callback, 'Value', 1, ...
        'ToolTipString', 'Apply Hamming to Window', ...
        'String', 'Apply Hamming Window'); %#ok<NASGU>
    
    smoothN_text = uicontrol('Parent', tab, 'Style', 'text', ...
        'Units', 'normalized', 'Position', [0.6 0.98 0.075 0.02], ...
        'String', 'FFT Smooting Window Size:', 'HorizontalAlignment', 'right'); %#ok<NASGU>
    smoothN_tb = uicontrol('Parent', tab, 'Style', 'edit', ...
        'Units', 'normalized', 'Position', [0.675 0.98 0.05 0.02], ...
        'KeyReleaseFcn', @smoothN_tb_callback, 'String', num2str(smoothN), ...
        'ToolTipString', 'Spectrum Smooth Box Size'); %#ok<NASGU>
    
    %create axis
    full_plot_axis = subplot('Position', [0.02 0.89 0.71 0.07], 'Parent', tab);
    plot_vert_size = 0.875/(num_sensors*1.05);
    ch_axis = cell(num_sensors, 1);
    for id = 0:1:num_sensors - 1
        ch_axis{id+1}.SignalAxis = subplot('Position', ...
            [0.02, plot_vert_size*id+0.05, 0.71, plot_vert_size], ...
            'Xgrid', 'on', 'Ygrid', 'on', 'Color', 'w');
        ch_axis{id+1}.SpectrumAxis = subplot('Position', ...
            [0.75, plot_vert_size*id+0.05, 0.245, plot_vert_size], ...
            'Xgrid', 'on', 'Ygrid', 'on', 'Color', 'w');
    end
    
    %set user data object
    tab.UserData = struct('window_size', window_size, 'Units', '[mm/s]', ...
        'smoothN', smoothN, 'CurrentWindow', [1 window_size], ...
        'applyHamming', 1, 'DataIDX', idx, 'AccVelDisp', 2, ...
        'FullPlot', full_plot_axis, 'ChannelAxis', {ch_axis}, ...
        'VertBars', [], 'VertBarsH', [], 'TimeTB', time_tb);
    if(isvalid(wait_window))
        waitbar(total_progress + file_progress*0.8, wait_window, ...
            [wait_window.UserData 'Plotting Data']);
    end
    %plot data
    plot_tab_data(tab);
end

%Read Data
function read_Data()
global PathName OUTPUT wait_window file_progress total_progress
    isTableCol=@(t, thisCol) ismember(thisCol, t.Properties.VariableNames);
    OUTPUT.Data = cell(length(OUTPUT.Source_FileName),1);
    file_progress = 1/length(OUTPUT.Source_FileName);
    total_progress = 0;
    for idx = 1:1:length(OUTPUT.Source_FileName)
        datfile = OUTPUT.Source_FileName{idx}; 
        if(isvalid(wait_window))
            waitbar(total_progress + file_progress*0.1, ...
                wait_window, ['Loading ' datfile]);
            wait_window.UserData = sprintf('Loading %s\n', datfile);
        end
        TDMSStruct = TDMS_getStruct([PathName datfile],6);
        
        if(~isTableCol(TDMSStruct.Properties, 'DAQVersion'))
            answer = questdlg('Is data from DYNAMate V1.0?', ...
                'Cannot Determine HW version', 'Yes', 'No', 'No');
            if(strcmpi('Yes', answer))
                DAQVersion = '1.0';
            else
                DAQVersion = 'N/A';
            end
        else
            DAQVersion = TDMSStruct.Properties.DAQVersion;
        end
        if(~isTableCol(TDMSStruct.Properties, 'SoftwareVersion'))
            SWVersion = 'N/A';
        else
            SWVersion = TDMSStruct.Properties.SoftwareVersion;
        end
        oldDAQ = strcmp(TDMSStruct.Properties.DAQVersion, '1.0');
        
        %Redundant read, future proof for config in TDMS
        read_sensor_config();
        
        %extract data from data file
        Dtable = TDMSStruct.DATA;
        Fs = 1/(Dtable{2,1}-Dtable{1,1});
        duration = Dtable{end,1}-Dtable{1,1}+1/Fs;
        DATA = Dtable{:,[1 OUTPUT.Sensor_configuration.DataChannels]};
        CONFIG = Dtable{:,26:end};
        
        %Extract confguration information
        FILTERS = [32,64,128];
        FILTERS_str = {'32Hz','64Hz','128Hz'};
        SCALES_1 = [0.1, 0, 100, 10, 1];
        SCALES_str1 = {'0.1mm/s', 'Calibration', '100mm/s', '10mm/s', '1mm/s'};
        SCALES_2 = [0, 100, 10, 1, 0.1, 0.01];
        SCALES_str2 = {'Calibration', '100mm/s', '10mm/s', '1mm/s', '0.1mm/s', '0.01mm/s'};

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
        
        OUTPUT.Data{idx}.FileName = datfile;
        OUTPUT.Data{idx}.SW_version = SWVersion;
        OUTPUT.Data{idx}.DAQ_version = DAQVersion;
        OUTPUT.Data{idx}.Fs = Fs;
        OUTPUT.Data{idx}.SignalDuration = duration;
        OUTPUT.Data{idx}.SignalNSamples = length(DATA);
        OUTPUT.Data{idx}.DATA.Velocity = DATA(:,2:end);
        OUTPUT.Data{idx}.DATA.Acceleration = [];
        OUTPUT.Data{idx}.DATA.Displacement = [];
        OUTPUT.Data{idx}.DATA.Time = DATA(:,1);
        OUTPUT.Data{idx}.Stats = signal_stats(DATA, OUTPUT.Sensor_configuration.ChannelNames);
        OUTPUT.Data{idx}.ScaleSTR = SCALE_str;
        OUTPUT.Data{idx}.FilterSTR = FILTERS_str(filter_selected);
        OUTPUT.Data{idx}.Scale = SCALE;
        OUTPUT.Data{idx}.Filter = FILTERS(filter_selected);
        OUTPUT.Data{idx}.Nsensors = height(OUTPUT.Sensor_configuration.Table);
        OUTPUT.Data{idx}.ConfigTable = struct2table(struct(...
            'FileName', datfile, 'DAQVersion', DAQVersion, ...
            'SWVersion', SWVersion, 'Fs', Fs, 'NSamples', length(DATA), ...
            'Duration', duration, ...
            'Sensors', OUTPUT.Data{idx}.Nsensors, ...
            'Filter', FILTERS_str(filter_selected), 'Scale', SCALE_str, ...
            'SensorFc', '4.5'));
        if(isvalid(wait_window))
            waitbar(total_progress + file_progress*0.3, wait_window, ...
                [wait_window.UserData 'Processing ' datfile ' data']);
        end
        processData(idx);
        if(isvalid(wait_window))
            waitbar(total_progress + file_progress*0.7, ...
                wait_window, [wait_window.UserData 'Generating UI']);
        end
        createNewTab(idx);
        figure(wait_window);
        total_progress = total_progress+file_progress;
    end
    delete(wait_window);
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
    sensor_ids = [];
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
    names = cellfun(@(c,i) strcat(c, {'_X_';'_Y_';'_Z_'}, num2str(i)), ...
        sensor_names, num2cell(active_ids)', 'uni', 0);
    names = vertcat(names{:})';
    
    OUTPUT.Sensor_configuration.Table = sensor_config;
    OUTPUT.Sensor_configuration.ChannelNames = names;
    OUTPUT.Sensor_configuration.SensorNames = sensor_names;
    OUTPUT.Sensor_configuration.SensorID = sensor_ids;
    OUTPUT.Sensor_configuration.DataChannels = data_channels;
    
    disp('Using Sensor Configuration:');
    disp(sensor_config);
end

function processData(idx)
global OUTPUT wait_window total_progress file_progress
    Fs = OUTPUT.Data{idx}.Fs;
    Ts = 1/Fs;
    
    Nw = 0.015;
    Nf = 3*Fs;
    taper_tau = 1.0;
    
    data = OUTPUT.Data{idx}.DATA.Velocity;
    t = OUTPUT.Data{idx}.DATA.Time;
    if(isvalid(wait_window))
        waitbar(total_progress + file_progress*0.4, wait_window, ...
            [wait_window.UserData 'Removing Trend and Offset']);
    end
    %remove trend and offset
    window = hanning(floor(Nw*length(data)));
    window = repmat(window'/sum(window),1,3);
    mvmean = movmean(data,window);
    offset = movmean(mvmean,ones(Nf,1)/Nf); 
    data = data - offset;
    %Apply taper
    taper = build_taper(t, taper_tau);
    taper = repmat(taper, 1, size(data,2));
    data = (data - repmat(mean(data),length(data),1)).*taper;
    data = (data - repmat(mean(data),length(data),1)).*taper;
    
    if(strcmp('Yes', questdlg(...
            'Do you want to correct sensor reponse to 0.5Hz', ...
            'Sensor Correction', 'Yes', 'No', 'No')))
        if(isvalid(wait_window))
            waitbar(total_progress + file_progress*0.5, wait_window, ...
            [wait_window.UserData 'Correcting Sensor Response']);
        end
        targetFc = 0.5;
        data = FixResponse(data, -1, targetFc, Fs);
        OUTPUT.Data{idx}.ConfigTable.SensorFc = targetFc;
    end
    
    
    if(isvalid(wait_window))
        waitbar(total_progress + file_progress*0.6, wait_window, ...
            [wait_window.UserData 'Calculating Acceleration and Displacement']);
    end
    %Calculate Acceleration and Displacement
    dsp = cumtrapz(t, data); 
    dfm = cumtrapz(t, dsp)*0.5./repmat((t+Ts),1 ,size(data,2));
    
    OUTPUT.Data{idx}.DATA.Velocity = data; %[mm/s]
    OUTPUT.Data{idx}.DATA.Acceleration = [zeros(1, size(data,2)); ...
        diff(data/1000)/Ts]; %[m/s^2]
    OUTPUT.Data{idx}.DATA.Displacement = dsp-dfm; %[mm]
end

function fftdata = getFFT(data, tab)
    N = tab.UserData.window_size;
    applyHamming = tab.UserData.applyHamming;
    specSmoothN = tab.UserData.smoothN;
    if(applyHamming)
        window_function = repmat(hamming(N), ...
            1, size(data,2));
    else
        window_function = ones(N,size(data,2));
    end
    fftdata = abs(fft(data.*window_function, N, 1));
    fftdata = abs(fftdata(ceil(1:N/2),:));
    fftdata(2:end-1,:) = 2*fftdata(2:end-1,:);
    if(specSmoothN ~= 1)
        fftdata = filtfilt(ones(1,specSmoothN),1,fftdata);
    end
end

%Plot Data
function plot_tab_data(tab)
global OUTPUT
    idx = tab.UserData.DataIDX;
    t = OUTPUT.Data{idx}.DATA.Time;
    switch tab.UserData.AccVelDisp
        case 1
            data = OUTPUT.Data{idx}.DATA.Acceleration;
        case 3
            data = OUTPUT.Data{idx}.DATA.Displacement;
        otherwise
            data = OUTPUT.Data{idx}.DATA.Velocity;
    end
    
    ax = tab.UserData.FullPlot;cla(ax);
    y_limits = [min(min(data)); max(max(data))]; 
    tab.UserData.VertBarsH = [y_limits y_limits];
    plot(t, data, 'ButtonDownFcn', @full_plot_callback, 'Parent', ax);
    set(ax, 'Color', 'w', 'XAxisLocation', 'top', 'NextPlot', 'add', ...
        'XGrid', 'on', 'YGrid', 'on', 'GridColor', 'k', 'TickDir', 'in', ...
        'GridLineStyle', ':', 'XLim', [t(1) t(end)], 'Ylim', y_limits); 
    ax.YTickLabel = cellstr(num2str(ax.YTick', '%5.3f'));
    
    plot_vert_bars(tab);
    plot_channel_data(tab)
end

function plot_channel_data(tab)
global OUTPUT
    idx = tab.UserData.DataIDX;
    Fs = OUTPUT.Data{idx}.Fs;
    window_data_id = tab.UserData.CurrentWindow(1):1:tab.UserData.CurrentWindow(2);
    t=(window_data_id-1)/OUTPUT.Data{idx}.Fs;
    switch tab.UserData.AccVelDisp
        case 1
            data = OUTPUT.Data{idx}.DATA.Acceleration(window_data_id,:);
        case 3
            data = OUTPUT.Data{idx}.DATA.Displacement(window_data_id,:);
        otherwise
            data = OUTPUT.Data{idx}.DATA.Velocity(window_data_id,:);
    end
    
    %Signal Plot
    colors = [217 83 25; 0 114 189; 237 177 32]./255;
    components = 'XYZ';
    num_sensors = OUTPUT.Data{idx}.Nsensors;
    data_range = max(max(abs(data)));
    for idx = 0:1:num_sensors - 1
        data_id = ((num_sensors -1 - idx)*3 + 1):((num_sensors - idx)*3);
        ax = tab.UserData.ChannelAxis{idx+1}.SignalAxis;
        cla(ax);
        plot(t,data(:,data_id), 'LineWidth', 1, 'Parent', ax);
        set(ax, 'Color', 'w', 'GridColor', 'k', 'XLim', [t(1) t(end)], ...
            'XAxisLocation', 'bottom', 'NextPlot', 'add', ...
        'XGrid', 'on', 'YGrid', 'on', 'GridColor', 'k', ...
        'GridLineStyle', '-', 'YLim', [-1 1].*data_range);
        ax.YTickLabel = cellstr(num2str(ax.YTick', '%5.3f'));
        if(idx==0)
            ax.XAxis.Visible = 'on';
            ax.XLabel = text('Units', 'normalized', 'Parent', ax, ...
                'Position', [0.5 0.1 0], 'String', 'Time[s]');
        else
            ax.XAxis.TickLabels = [];
        end
        %Peaks      
        peak_data = find_Vpp_window(data);
        VppTable = zeros(1, 24);
        Vpp_string = '';
        for comp_id = 1:1:3
            idc = (num_sensors - 1 - idx)*3+comp_id;
            mVpp_idx = peak_data(idc,:);
            maxVpp = sum(abs(data(mVpp_idx,idc)));
            VppTable(idc) = maxVpp;
            plot(t(mVpp_idx), data(mVpp_idx, idc), 'LineStyle', 'none', ...
                'Marker','d','MarkerFaceColor', colors(comp_id,:), ...
                'Parent', ax)
            Vpp_string = sprintf('%sV_p_p%c=%5.3f \n', ...
                Vpp_string, components(comp_id), maxVpp);
        end 
        text(t(end-2), min(ax.YLim), Vpp_string(1:end-1), 'Color', 'k', ...
            'BackgroundColor', 'none', 'Parent', ax, ...
            'VerticalAlignment', 'bottom', 'Margin', 0.0001, ...
            'HorizontalAlignment', 'right', 'FontWeight', 'bold');
        text(t(2), max(ax.YLim), sprintf(' %s %s', tab.UserData.Units, ...
            OUTPUT.Sensor_configuration.SensorNames{idx+1}), ...
            'Color', 'k', 'BackgroundColor', 'none', 'Parent', ax, ...
            'VerticalAlignment', 'top', 'Margin', 0.0001, ...
            'FontSize', 18, 'FontWeight', 'bold');
    end
    %setup Legend
    axes(ax);
    l = legend('X','Y','Z');
    l.TextColor = 'k';
    l.Location = 'NorthEast';
    l.FontWeight = 'bold';
    %Spectrum Plot
    fftdata = getFFT(data, tab);
    f = Fs*(1:tab.UserData.window_size/2)'/tab.UserData.window_size;
    fft_range = [min(min(abs(fftdata))) max(max(abs(fftdata)))];
    for idx = 0:1:num_sensors - 1
        data_id = ((num_sensors -1 - idx)*3 + 1):((num_sensors - idx)*3);
        ax = tab.UserData.ChannelAxis{idx+1}.SpectrumAxis;
        cla(ax);
        loglog(f,abs(fftdata(:,data_id)), 'LineWidth', 1, 'Parent', ax);
        set(ax, 'Color', 'w', 'GridColor', 'k', ...
            'XAxisLocation', 'bottom', 'NextPlot', 'add', ...
            'XGrid', 'on', 'YGrid', 'on', 'GridLineStyle', '-', ...
            'GridColor', 'k', 'YLim', fft_range, 'YTick', 10.^(-4:1:4), ...
            'XLim', [f(1), f(end)], 'XTick', [0.1 1 10 100]);

        if(idx==0)
            ax.XAxis.Visible = 'on';
            ax.XLabel = text('Units', 'normalized', 'Parent', ax, ...
                'Position', [0.5 0.1 0], 'String', 'Frequency[Hz]');
        else
            ax.XAxis.TickLabels = [];
        end        
    end
end

function plot_vert_bars(tab)
global OUTPUT
    Fs = OUTPUT.Data{tab.UserData.DataIDX}.Fs;
    %establish and draw window
    vert_bars_t = (tab.UserData.CurrentWindow-1)/Fs;
    vert_bars_t = [vert_bars_t; vert_bars_t];
    vert_bars_h = tab.UserData.VertBarsH;
    
    delete(tab.UserData.VertBars)
    tab.UserData.VertBars = plot(vert_bars_t, vert_bars_h, ...
        'Parent', tab.UserData.FullPlot, 'Color', 'r', 'LineWidth', 2, ...
        'LineStyle','--');
end

function adjust_window(tab, center)
global OUTPUT
    N = tab.UserData.window_size;
    idx = tab.UserData.DataIDX;
    Fs = OUTPUT.Data{idx}.Fs;
    L = OUTPUT.Data{idx}.SignalNSamples;
    
    if(center<0)
        center = floor(mean(tab.UserData.CurrentWindow));
    else
        center = floor(center);
    end

    CurrentWindow = center + [-N/2+1 N/2];
    if(CurrentWindow(1) < 1)
        CurrentWindow = CurrentWindow + 1 - CurrentWindow(1);
    elseif(CurrentWindow(2) > L)
        CurrentWindow = CurrentWindow - CurrentWindow(2)+L;
    end
    tab.UserData.CurrentWindow = CurrentWindow;
    tab.UserData.TimeTB.String = num2str(floor(mean(CurrentWindow))/Fs);
    plot_vert_bars(tab)
    plot_channel_data(tab);

end

%UI CALLBACKS
function full_plot_callback(hObject, eventData)
global OUTPUT
    tab = hObject.Parent.Parent;
    idx = tab.UserData.DataIDX;
    L = OUTPUT.Data{idx}.SignalNSamples;
    Wn = tab.UserData.window_size;
    Fs = OUTPUT.Data{idx}.Fs;
    
    val = Fs*eventData.IntersectionPoint(1);
    val = max(Wn/2, val);
    val = min(L-Wn/2, val);
    
    adjust_window(tab, val);
end

function time_tb_callback(hObject, eventData)
global OUTPUT
    tab = hObject.Parent;
    if(~strcmp(eventData.Key, 'return'))
        return;
    end
    
    idx = tab.UserData.DataIDX;
    L = OUTPUT.Data{idx}.SignalNSamples;
    Wn = tab.UserData.window_size;
    Fs = OUTPUT.Data{idx}.Fs;
    
    val = str2double(hObject.String)*Fs;
    if(isnan(val))
        return
    end
    
    val = max(Wn/2, val);
    val = min(L-Wn/2, val);
    
    adjust_window(tab, val);
end

function hamming_cb_callback(hObject, ~)
    tab = hObject.Parent;
    tab.UserData.applyHamming = hObject.Value;
    plot_channel_data(tab);
end

function smoothN_tb_callback(hObject, eventData)
    tab = hObject.Parent;
    if(~strcmp(eventData.Key, 'return'))
        return;
    end
    val = str2double(hObject.String);
    if(isnan(val))
        return
    end
    tab.UserData.smoothN = val;
    plot_channel_data(tab);
end

function window_size_tb_callback(hObject, eventData)
global OUTPUT
    tab = hObject.Parent;
    if(~strcmp(eventData.Key, 'return'))
        return;
    end
    idx = tab.UserData.DataIDX;
    signal_length = OUTPUT.Data{idx}.SignalNSamples;
    val = str2double(hObject.String);
    if(isnan(val))
        return
    end
    
    val = min(val, signal_length);
    tab.UserData.window_size = val;
    hObject.String = num2str(val);
    adjust_window(tab, -1);
end

function savebutton_callback(~, ~)
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

function data_type_pd_callback(hObject, ~)
    tab = hObject.Parent;
    tab.UserData.AccVelDisp = hObject.Value;
    switch hObject.Value
        case 1
            tab.UserData.Units = '[m/s^2]';
        case 3
            tab.UserData.Units = '[mm]';
        otherwise
            tab.UserData.Units = '[mm/s]';
    end
    plot_tab_data(tab);
end

function figure_close_cb(~, ~)
global wait_window
    if(isvalid(wait_window))
        delete(wait_window)
    end
end

function tab_changed_callback(~, ~)
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