%UI setup
function DYNAMate_Process_Data_GUI_simplified(varargin)
clearvars -global OUTPUT
global OUTPUT PathName tab_group wait_window fig
    wait_window = waitbar(0,'Please wait...');
    wait_window.Children.Title.Interpreter = 'none';
    WindowAPI(wait_window, 'TopMost');
    WindowAPI(wait_window, 'clip', [1 1 360 78]);
    
    version = 'v1.6.0';
    if(isempty(PathName) || sum(PathName == 0) || ~exist(PathName, 'dir'))
        PathName = [pwd '\']; 
    end

    fig = figure(9999);
    figszfun = @(h,~) set(h, 'position', max([0 0 1280 768], h.Position));
    set(fig, 'DeleteFcn', @figure_close_cb, 'NumberTitle', 'off', ...
        'Name', ['DYNAMate Process ' version], 'MenuBar', 'none', ...
        'Position', [0 0 1280 768], 'SizeChangedFcn', figszfun);
    pause(0.00001);
%     set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
    WindowAPI(fig, 'Maximize');
    
    tab_group = uitabgroup('Parent', fig, 'Units', 'normalized', ...
        'Position', [0 0, 1, 1]);
    
    figure(wait_window)
    waitbar(0.05, wait_window, 'Select Input Files');
    [FileName, PathName2, ~] = uigetfile([PathName, '*.tdms'], ...
        'Pick File','MultiSelect','on');
    
    if(~iscell(FileName))
        FileName = {FileName}; end
    if(FileName{1} == 0)
        delete(wait_window)
        delete(fig)
        return; 
    end
    PathName = PathName2;
    OUTPUT.Source_FileName = FileName;
    OUTPUT.DoAll = 0;
    read_Data();
end

function createNewTab(idx)
global OUTPUT tab_group wait_window file_progress total_progress
    tab = uitab('Parent', tab_group, 'Title', OUTPUT.Data{idx}.FileName, ...
        'Units', 'pixels');

    num_sensors = OUTPUT.Data{idx}.Nsensors;
    %create parameters

    %create UI controls
    start_position = [20 2];

    next_size = [130 35];
    data_type_pd = uicontrol('Parent', tab, 'Style', 'popupmenu',...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'Value', 2, 'String', {'Acceleration', 'Velocity', 'Displacement'}, ...
        'Callback', @data_type_pd_callback); %#ok<NASGU>
    start_position(1) = start_position(1) + next_size(1) + 20;

    next_size = [100 40];
    save_button = uicontrol('Parent', tab, 'Style', 'pushbutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @save_button_callback, 'String', 'Save Data', ...
        'FontSize', 12, 'FontWeight', 'bold'); %#ok<NASGU>
    start_position(1) = start_position(1) + next_size(1) + 5;
    
    next_size = [100 40];
    zoom_button = uicontrol('Parent', tab, 'Style', 'togglebutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @zoom_button_callback, 'String', 'Zoom', ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'ToolTip', 'Hold SHIFT for Zooming out'); 
    start_position(1) = start_position(1) + next_size(1) + 5;
    
    next_size = [100 40];
    pan_button = uicontrol('Parent', tab, 'Style', 'togglebutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @pan_button_callback, 'String', 'Pan', ...
        'FontSize', 12, 'FontWeight', 'bold'); 
    start_position(1) = start_position(1) + next_size(1) + 5;
    
    next_size = [100 40];
    datatip_button = uicontrol('Parent', tab, 'Style', 'togglebutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @datatip_button_callback, 'String', 'Data Tip', ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'ToolTip', 'Hold SHIFT to add more then one'); 
    start_position(1) = start_position(1) + next_size(1) + 20;

    next_size = [100 40];
    exit_button = uicontrol('Parent', tab, 'Style', 'pushbutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @exit_button_callback, 'String', 'Exit', ...
        'FontSize', 12, 'FontWeight', 'bold'); %#ok<NASGU>
    start_position(1) = start_position(1) + next_size(1) + 20;
    
    zoom_button.UserData = [pan_button datatip_button];
    pan_button.UserData = [zoom_button datatip_button];
    datatip_button.UserData = [pan_button zoom_button];

    overview_text = uitable('Parent', tab);
    overview_text.Data = table2cell(OUTPUT.Data{idx}.ConfigTable(:,2:end));
    overview_text.ColumnName = ...
        OUTPUT.Data{idx}.ConfigTable.Properties.VariableNames(2:end);
    overview_text.ColumnWidth = {70, 60, 30, 60, 50, 50, 40, 50, 60, 60, 60, 60, 60};
    next_size = [sum(cell2mat(overview_text.ColumnWidth))+2 40];
    overview_text.Units = 'pixels';
    overview_text.Position = [start_position next_size];
    overview_text.RowName = [];
    
    %Plot Panel
    parent_size = tab.Position;
    panelH = 42;
    axis_panel = uipanel('Parent', tab, 'Units', 'pixels', ...
        'BorderWidth', 0, 'BorderType', 'none', ...
        'Position', [0 panelH parent_size(3) parent_size(4) - panelH]);
    tab.UserData.Panel = axis_panel;
    tabszfun = @(h,~) set(h.UserData.Panel, ...
        'position', [0 panelH h.Position(3) h.Position(4)-panelH]);
    tab.SizeChangedFcn = tabszfun;
    drawnow();
    %create axis
    ch_axis.Spacing = [40 25];
    for id = 0:1:num_sensors - 1
        ch_axis.SignalAxis(id+1) = subplot('Position', [0 0 0 0], ...
            'Units', 'pixels', 'Parent', axis_panel, 'Xgrid', 'on', ...
            'Ygrid', 'on', 'Color', 'w', 'XTick', [], 'YTick', []);
        ch_axis.SpectrumAxis(id+1) = subplot('Position', [0 0 0 0], ...
            'Units', 'pixels', 'Parent', axis_panel, 'Xgrid', 'on', ...
            'Ygrid', 'on', 'Color', 'w', 'XTick', [], 'YTick', []);
    end
    linkaxes(ch_axis.SignalAxis);
    linkaxes(ch_axis.SpectrumAxis);
    
    axis_panel.UserData = ch_axis;
    axis_panel.SizeChangedFcn = @panel_szChange;
    
    %set user data object
    tab.UserData = struct('Units', '[mm/s]', 'DataIDX', idx, ...
        'AccVelDisp', 2, 'ChannelAxis', ch_axis, 'Panel', axis_panel);
    drawnow()
    panel_szChange(axis_panel);
    
    if(isvalid(wait_window))
        waitbar(total_progress + file_progress*0.9, wait_window, ...
            [wait_window.UserData 'Plotting Data']);
    end
    
    %plot data
    plot_channel_data(tab);
    %force resize
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
            answer = 'No';
            if(strcmpi('Yes', answer))
                TDMSStruct.Properties.DAQVersion = '1.0';
            else
                TDMSStruct.Properties.DAQVersion = 'N/A';
            end
        end
        DAQVersion = TDMSStruct.Properties.DAQVersion;
        if(~isTableCol(TDMSStruct.Properties, 'SoftwareVersion'))
            SWVersion = 'N/A';
        else
            SWVersion = TDMSStruct.Properties.SoftwareVersion;
        end
        oldDAQ = strcmp(DAQVersion, '1.0');
        
        %Redundant read, future proof for config in TDMS
        read_sensor_config();
        
        %extract data from data file
        Dtable = TDMSStruct.DATA;
        Fs = 1/(Dtable{2,1}-Dtable{1,1});
        duration = round(Dtable{end,1}-Dtable{1,1}+1/Fs);
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
        
        %load config file
        cfg = readtable('DYNAMate.cfg', 'FileType', 'text', ...
            'ReadVariableNames', false, 'ReadRowNames', true, 'Delimiter', '\t');
        OUTPUT.cfg = array2table(table2array(cfg)', ...
            'VariableNames', cfg.Properties.RowNames);
        
        PossibleSaturationCH = find(sum(abs(DATA(:,2:end)) > OUTPUT.cfg.SatThreshold*SCALE));
        OUTPUT.Data{idx}.Sensor_Config = OUTPUT.Sensor_configuration.Table;
        OUTPUT.Data{idx}.FileName = datfile;
        OUTPUT.Data{idx}.SW_version = SWVersion;
        OUTPUT.Data{idx}.DAQ_version = DAQVersion;
        OUTPUT.Data{idx}.Fs = Fs;
        OUTPUT.Data{idx}.SignalDuration = duration;
        OUTPUT.Data{idx}.SignalNSamples = length(DATA);
        OUTPUT.Data{idx}.PossibleSaturationCH = PossibleSaturationCH;
        OUTPUT.Data{idx}.DATA.RAW = DATA(:,2:end);
        OUTPUT.Data{idx}.DATA.Velocity= [];
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
            'SensorFc', '4.5', 'SaturationThreshold', OUTPUT.cfg.SatThreshold));
        if(isvalid(wait_window))
            waitbar(total_progress + file_progress*0.3, wait_window, ...
                [wait_window.UserData 'Processing ' datfile ' data']);
        end
        processData(idx);
        if(isvalid(wait_window))
            waitbar(total_progress + file_progress*0.8, ...
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
    isTableCol=@(t, thisCol) ismember(thisCol, t.Properties.VariableNames);
    if(exist([PathName 'sensor_configuration.txt'], 'file'))
        ds = datastore([PathName 'sensor_configuration.txt'], ...
            'Delimiter','\t','MultipleDelimitersAsOne',true);
        sensor_config = read(ds);
        %trim table if too large
        sensor_config = sensor_config(1:min(height(sensor_config),8),:);
    else
        %default config
        sensor_config = table((1:8)', cellstr(strcat('s',num2str((1:8)'))), ...
            cellstr(repmat('xyz',8,1)), ...
            'VariableNames',{'Channel','Name','Components'});
    end

    active_ids = find(~strcmp(sensor_config.Name,'NA'))';
    sensor_names = sensor_config.Name(active_ids);
    components = sensor_config.Components(active_ids);
    number_of_sensors = length(active_ids);
    
    if(isTableCol(sensor_config, 'SensorID'))
        sensor_config = sensor_config(active_ids,:);
        sensorFreq = readtable('sensor_data.csv', 'ReadRowNames',true);
        sensorFreq = sensorFreq(cellstr(sensor_config.SensorID),:);
        sensorFreq.Properties.RowNames = {};
    else
        sensor_config = [sensor_config(active_ids,:) ...
            table(repmat('NA', number_of_sensors,1), 'VariableNames', {'SensorID'})];
        sensorFreq = array2table(4.5*ones(number_of_sensors,3), ...
            'VariableNames', {'xFc', 'yFc', 'zFc'});
    end

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
    sensor_config = [sensor_config ...
        table(reshape(data_channels,3,[])', 'VariableNames', {'ChannelsUsed'})];
    names = cellfun(@(c) strcat(c, {'_X';'_Y';'_Z'}), ...
        sensor_names, 'uni', 0);
    names = vertcat(names{:})';
    
    sensor_config = [sensor_config sensorFreq];
    freq_vector = reshape(table2array(sensorFreq)',1, numel(sensorFreq));
    OUTPUT.Sensor_configuration.Table = sensor_config;
    OUTPUT.Sensor_configuration.ChannelNames = names;
    OUTPUT.Sensor_configuration.SensorNames = sensor_names;
    OUTPUT.Sensor_configuration.SensorID = sensor_config.SensorID;
    OUTPUT.Sensor_configuration.DataChannels = data_channels;
    OUTPUT.Sensor_configuration.SensorFreqs = freq_vector;
end

%Process Data
function processData(idx)
global OUTPUT wait_window total_progress file_progress
    Fs = OUTPUT.Data{idx}.Fs;
    Ts = 1/Fs;
    N = OUTPUT.Data{idx}.SignalNSamples;
    
    cfg = OUTPUT.cfg;
    taper_tau = cfg.taper_tau*OUTPUT.Data{idx}.SignalDuration;
    specSmoothN = cfg.specSmoothN;
    targetFc = cfg.targetFc;
    corrSteepnes = cfg.corrSteepnes;
    
    data = OUTPUT.Data{idx}.DATA.RAW;
    t = OUTPUT.Data{idx}.DATA.Time;
    
    numCH = size(data,2);
    
    if(isvalid(wait_window))
        waitbar(total_progress + file_progress*0.4, wait_window, ...
            [wait_window.UserData 'Removing Trend and Offset']);
    end
    
    %Apply taper
    taper = build_taper(t, taper_tau);
    taper = repmat(taper, 1, numCH);
    data = (data - repmat(mean(data),N,1)).*taper;
    offset = repmat(mean(data),N,1);
    data = data - offset;
    
    switch OUTPUT.DoAll
        case 0
            answer = choosefixDialog(targetFc);
            if(strcmp('Yes to All', answer))
                OUTPUT.DoAll = 1;
                answer = 'Yes';
            elseif(strcmp('No to All', answer))
                OUTPUT.DoAll = 2;
                answer = 'No';
            else
                OUTPUT.DoAll = 0;
            end
        case 1
            answer = 'Yes';
        otherwise
            answer = 'No';
    end
    
    if(strcmp('Yes', answer))
        if(OUTPUT.Data{idx}.PossibleSaturationCH)
            msg = strjoin([{'For File:'} {OUTPUT.Data{idx}.FileName} ...
                {'Possible Saturation Detected on these Channels:'} ...
                OUTPUT.Sensor_configuration.ChannelNames(...
                OUTPUT.Data{idx}.PossibleSaturationCH) ...
                {'Sensor freqeuncy correction is DISABLED for these channels'}],'\n');
            sat_win = warndlg(msg, 'Possible Saturation');
            WindowAPI(sat_win,'TopMost');
        end
        if(isvalid(wait_window))
            waitbar(total_progress + file_progress*0.5, wait_window, ...
            [wait_window.UserData 'Correcting Sensor Response']);
        end
        [data, ~, ~] = FixResponse2(data, ...
            OUTPUT.Sensor_configuration.SensorFreqs, targetFc, Fs, ...
            OUTPUT.Data{idx}.PossibleSaturationCH, corrSteepnes);
       
        chan_frqs = targetFc*ones(size(OUTPUT.Sensor_configuration.SensorFreqs));
        chan_frqs(OUTPUT.Data{idx}.PossibleSaturationCH) = ...
            OUTPUT.Sensor_configuration.SensorFreqs(OUTPUT.Data{idx}.PossibleSaturationCH);
        OUTPUT.Data{idx}.Sensor_Config = [OUTPUT.Data{idx}.Sensor_Config ...
            array2table(reshape(chan_frqs, 3, length(OUTPUT.Sensor_configuration.SensorID))', ...
            'VariableNames', {'xFc_corrected', 'yFc_corrected', 'zFc_corrected'})];
        OUTPUT.Data{idx}.ConfigTable.SensorFc = targetFc;
    end
    
    if(isvalid(wait_window))
        waitbar(total_progress + file_progress*0.6, wait_window, ...
            [wait_window.UserData 'Calculating Acceleration and Displacement']);
    end
    %Calculate Acceleration and Displacement
    Displacement = cumtrapz(t, data);
    Acceleration = [zeros(1, numCH); diff(data/1000)/Ts];
    
    if(isvalid(wait_window))
        waitbar(total_progress + file_progress*0.7, wait_window, ...
            [wait_window.UserData 'Calculating Spectra']);
    end
    
    %calculate Spectra
    fftdata = abs(fft([Acceleration data Displacement])./N);
    fftdata = abs(fftdata(ceil(1:N/2+1),:));
    fftdata(2:end-1,:) = 2*fftdata(2:end-1,:);
    f = Fs*(0:N/2)'/N;
    fftdata = smoothFFT(fftdata, specSmoothN, f);
    %set data to output
    
    OUTPUT.Data{idx}.DATA.Velocity = data; %[mm/s]
    OUTPUT.Data{idx}.DATA.Acceleration = Acceleration; %[m/s^2]
    OUTPUT.Data{idx}.DATA.Displacement = Displacement; %[mm]
    
    OUTPUT.Data{idx}.FFT.Velocity = fftdata(:,1:numCH); %[mm/s]
    OUTPUT.Data{idx}.FFT.Acceleration = fftdata(:, numCH+(1:numCH)); %[m/s^2]
    OUTPUT.Data{idx}.FFT.Displacement = fftdata(:, 2*numCH+(1:numCH)); %[mm]
    OUTPUT.Data{idx}.FFT.Frequency = f;
    
    OUTPUT.Data{idx}.ConfigTable.TaperTau = taper_tau;
    OUTPUT.Data{idx}.ConfigTable.SpectrumSmoothPower = specSmoothN;
    OUTPUT.Data{idx}.ConfigTable.CorrectionSteepness = corrSteepnes;
end

function plot_channel_data(tab)
global OUTPUT fig
    idx = tab.UserData.DataIDX;
    t = OUTPUT.Data{idx}.DATA.Time;
    f = OUTPUT.Data{idx}.FFT.Frequency;
    num_sensors = OUTPUT.Data{idx}.Nsensors;
    switch tab.UserData.AccVelDisp
        case 1
            data = OUTPUT.Data{idx}.DATA.Acceleration;
            fftdata = OUTPUT.Data{idx}.FFT.Acceleration;
        case 3
            data = OUTPUT.Data{idx}.DATA.Displacement;
            fftdata = OUTPUT.Data{idx}.FFT.Displacement;
        otherwise
            data = OUTPUT.Data{idx}.DATA.Velocity;
            fftdata = OUTPUT.Data{idx}.FFT.Velocity;
    end
    
    figure(fig)
    
    %Plot Data
    data_range = max(max(abs(data)));
    fft_range = [max(10^-6, min(min(abs(fftdata(2:end,:))))) ...
        max(max(abs(fftdata(2:end,:))))];
    for idx = 0:1:num_sensors - 1
        data_id = ((num_sensors -1 - idx)*3 + 1):((num_sensors - idx)*3);
        %Spectrum Plot  
        ax = tab.UserData.ChannelAxis.SpectrumAxis(idx+1);
        cla(ax);
        loglog(f,fftdata(:,data_id), 'LineWidth', 1, 'Parent', ax);
        set(ax, 'Color', 'w', 'GridColor', 'k', ...
            'XAxisLocation', 'bottom', 'NextPlot', 'add', ...
            'XGrid', 'on', 'YGrid', 'on', 'GridLineStyle', '-', ...
            'GridColor', 'k', 'YLim', fft_range, 'YTick', 10.^(-7:1:5), ...
            'XLim', [max(0.1, f(2)), f(end)], 'XTick', 10.^(-2:1:2), ...
            'XScale', 'log', 'YScale', 'log');
        if(idx==0)
            ax.XAxis.Visible = 'on';
            text('Units', 'normalized', 'Parent', ax, ...
                'HorizontalAlignment' , 'right',...
                'VerticalAlignment' , 'top', 'Position', [1  0], ...
                'String', 'f[Hz]', 'FontWeight' ,'bold', 'FontSize', 12);
        else
            ax.XAxis.TickLabels = [];
        end  
        %Signal Plot
        ax = tab.UserData.ChannelAxis.SignalAxis(idx+1);
        cla(ax);
        plot(t,data(:,data_id), 'LineWidth', 1, 'Parent', ax);
        set(ax, 'Color', 'w', 'GridColor', 'k', 'XLim', [t(1) t(end)], ...
            'XAxisLocation', 'bottom', 'NextPlot', 'add', ...
        'XGrid', 'on', 'YGrid', 'on', 'GridColor', 'k', ...
        'GridLineStyle', '-', 'YLim', [-1 1].*data_range);
        if(idx==0)
            ax.XAxis.Visible = 'on';
            text('Units', 'normalized', 'Parent', ax, ...
                'HorizontalAlignment' , 'right',...
                'VerticalAlignment' , 'top', 'Position', [1  0], ...
                'String', 't[s]', 'FontWeight' ,'bold', 'FontSize', 12);
        else
            ax.XAxis.TickLabels = [];
        end
        text(t(2), max(ax.YLim), sprintf(' %s %s', tab.UserData.Units, ...
            OUTPUT.Sensor_configuration.SensorNames{num_sensors - idx}), ...
            'Color', 'k', 'BackgroundColor', 'none', 'Parent', ax, ...
            'VerticalAlignment', 'top', 'Margin', 0.0001, ...
            'FontSize', 18, 'FontWeight', 'bold');
    end
    %setup Legend
    axes(ax);
    l = legend('X','Y','Z');
    l.TextColor = 'k';
    l.Units = 'pixels';
    pos = ax.Position;
    cp = l.Position;
    l.Position = ceil([pos(1)+pos(3)-cp(3) pos(2)+pos(4)-cp(4) cp(3:4)]); 
    l.FontWeight = 'bold';
    ax.UserData = l;
    
end

%UI CALLBACKS
function save_button_callback(hObject, ~)
global OUTPUT PathName fig
    idx = hObject.Parent.UserData.DataIDX;
    source_file = OUTPUT.Data{idx}.FileName(1:end-5);
    file = [PathName source_file];
    
    [FileName, PathName2, ~] = uiputfile('*.xlsx', 'Save Data', [file '.xlsx']);
    if(~iscell(FileName))
        FileName = {FileName}; end
    if(FileName{1} == 0)
        return; 
    end
    PathName = PathName2;
    if(iscell(FileName))
        FileName = FileName{1}; end
    dot_index = strfind(FileName,'.');
    if(isempty(dot_index))
        dot_index = length(FileName);
    else
        dot_index = dot_index(end)-1;
    end
    
    base_file = [PathName FileName(1:dot_index)];
    
    WindowAPI(fig, 'maximize');
    export_fig([base_file '.png'], '-c[25 0 45 0]', fig);
    wait_save = waitbar(0.0, 'Saving Configuration, please wait...');
    WindowAPI(wait_save, 'TopMost');
    WindowAPI(wait_save, 'clip', [1 1 360 70]);
    
    %save CONFIG
    writetable(OUTPUT.Data{idx}.ConfigTable, [base_file '.xlsx']);
    writetable(OUTPUT.Data{idx}.Sensor_Config, [base_file '.xlsx'], ...
        'Sheet', 'Sheet1', 'Range', 'A5');
    writetable(OUTPUT.Data{idx}.Stats, [base_file '.xlsx'], ...
        'Sheet', 'Sheet1', 'Range', 'A15', 'WriteRowNames', true);
    
    waitbar(0.1429, wait_save, 'Saving Acceleration Data, please wait...');
    
    %save DATA 
    tbl = [OUTPUT.Data{idx}.DATA.Time OUTPUT.Data{idx}.DATA.Acceleration];
    tbl = array2table(tbl);
    writetable(tbl, [base_file '.xlsx'], 'Sheet', 'Acceleration');
    xlswrite([base_file '.xlsx'], ['Time[s]', ...
        cellfun(@(c) strcat(c, '[m/s^2]'), ...
        OUTPUT.Sensor_configuration.ChannelNames, 'uni', 0)], ...
        'Acceleration', 'A1');
    
    waitbar(0.2857, wait_save, 'Saving Velocity Data, please wait...');
    
    tbl = [OUTPUT.Data{idx}.DATA.Time OUTPUT.Data{idx}.DATA.Velocity];
    tbl = array2table(tbl);
    writetable(tbl, [base_file '.xlsx'], 'Sheet', 'Velocity');
    xlswrite([base_file '.xlsx'], ['Time[s]', ...
        cellfun(@(c) strcat(c, '[mm/s]'), ...
        OUTPUT.Sensor_configuration.ChannelNames, 'uni', 0)], ...
        'Velocity', 'A1');
    
    waitbar(0.4286, wait_save, 'Saving Displacement Data, please wait...');
    
    tbl = [OUTPUT.Data{idx}.DATA.Time OUTPUT.Data{idx}.DATA.Displacement];
    tbl = array2table(tbl);
    writetable(tbl, [base_file '.xlsx'], 'Sheet', 'Displacement');
    xlswrite([base_file '.xlsx'], ['Time[s]', ...
        cellfun(@(c) strcat(c, '[mm]'), ...
        OUTPUT.Sensor_configuration.ChannelNames, 'uni', 0)], ...
        'Displacement', 'A1');
    
    %save FFT
    waitbar(0.5714, wait_save, 'Saving Acceleration FFT, please wait...');
    
    tbl = [OUTPUT.Data{idx}.FFT.Frequency OUTPUT.Data{idx}.FFT.Acceleration];
    tbl = array2table(tbl);
    writetable(tbl, [base_file '.xlsx'], 'Sheet', 'FFT_Acceleration');
    xlswrite([base_file '.xlsx'], ['Frequency[Hz]', ...
        cellfun(@(c) strcat(c, '[m/s^2]'), ...
        OUTPUT.Sensor_configuration.ChannelNames, 'uni', 0)], ...
        'FFT_Acceleration', 'A1');
    
    waitbar(0.7143, wait_save, 'Saving Velocity FFT, please wait...');
    
    tbl = [OUTPUT.Data{idx}.FFT.Frequency OUTPUT.Data{idx}.FFT.Velocity];
    tbl = array2table(tbl);
    writetable(tbl, [base_file '.xlsx'], 'Sheet', 'FFT_Velocity');
    xlswrite([base_file '.xlsx'], ['Frequency[Hz]', ...
        cellfun(@(c) strcat(c, '[mm/s]'), ...
        OUTPUT.Sensor_configuration.ChannelNames, 'uni', 0)], ...
        'FFT_Velocity', 'A1');
    
    waitbar(0.8571, wait_save, 'Saving Displacement FFT, please wait...');
    
    tbl = [OUTPUT.Data{idx}.FFT.Frequency OUTPUT.Data{idx}.FFT.Displacement];
    tbl = array2table(tbl);
    writetable(tbl, [base_file '.xlsx'], 'Sheet', 'FFT_Displacement');
    xlswrite([base_file '.xlsx'], ['Frequency[Hz]', ...
        cellfun(@(c) strcat(c, '[mm]'), ...
        OUTPUT.Sensor_configuration.ChannelNames, 'uni', 0)], ...
        'FFT_Displacement', 'A1');  

    waitbar(1, wait_save, 'Saving Complete');
    pause(1.0);
    delete(wait_save);
end

function exit_button_callback(~, ~)
global fig
    answer = questdlg('Do you want to Exit?', ...
                'Quit', 'Yes', 'No', 'Yes');
    if(strcmp(answer,'Yes'))
        delete(fig)
        clear global
        close all force
    end
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
    plot_channel_data(tab);
end

function figure_close_cb(~, ~)
global wait_window
    if(isvalid(wait_window))
        delete(wait_window)
    end
end

function panel_szChange(hObject, ~)
global OUTPUT
    if(isempty(OUTPUT))
        return;
    end
    num_sensors = OUTPUT.Data{1}.Nsensors;
    parent_size = hObject.Position;
    ch_axis = hObject.UserData;

    plotL = ch_axis.Spacing(1);
    plotHsig = floor(0.7*parent_size(3));
    plotHfft = parent_size(3) - 2*plotL - plotHsig -1 ;

    plotV = parent_size(4) - ch_axis.Spacing(2);
    plotB = ch_axis.Spacing(2) + rem(plotV, num_sensors);
    plotV = floor(plotV/num_sensors);
    
    for id = 0:1:num_sensors - 1
    ch_axis.SignalAxis(id+1).Position = ...
                    [plotL, plotV*id+plotB, plotHsig, plotV];
    ch_axis.SpectrumAxis(id+1).Position = ...
                    [2*plotL+plotHsig, plotV*id+plotB, plotHfft, plotV];
    end
    
    l = ch_axis.SignalAxis(id+1).UserData;
    if(~isempty(l))
        pos = ch_axis.SignalAxis(id+1).Position;
        cp = l.Position;
        l.Position = ceil([pos(1)+pos(3)-cp(3) pos(2)+pos(4)-cp(4) cp(3:4)]); 
    end
end

function zoom_button_callback(hObject, ~)
    if(hObject.Value == 1)
        zoom on;
        hObject.UserData(1).Value = 0;
        hObject.UserData(2).Value = 0;
    else
        zoom off;
    end
end

function pan_button_callback(hObject, ~)
    if(hObject.Value == 1)
        pan on;
        hObject.UserData(1).Value = 0;
        hObject.UserData(2).Value = 0;
    else
        pan off;
    end
end

function datatip_button_callback(hObject, ~)
global fig
    dcm = datacursormode(fig);
    dcm.UpdateFcn = @datatip_format;
    if(hObject.Value == 1)
        dcm.Enable = 'on';
        hObject.UserData(1).Value = 0;
        hObject.UserData(2).Value = 0;
    else
        dcm.Enable = 'off';
    end
end

function output_txt = datatip_format(~, event_obj)
    units = event_obj.Target.Parent.Parent.Parent.UserData.Units;
    pos = get(event_obj,'Position');
    output_txt = sprintf('%5.3f%s\n%3.2f[s]', pos(2), units, pos(1));
end

function choice = choosefixDialog(targetFc)
    d = dialog('Units', 'normalized', 'Position', [0.4 0.7 0.1 0.1], ...
        'Name', 'Sensor Correction');
    d.Units = 'pixels';
    d.Position(3:4) = [375 100];
    
    uicontrol('Parent', d, 'Style', 'text', 'Position', [20 50 335 40], ...
        'String', ['Correct sensor reponse to ' num2str(targetFc) 'Hz?'], ...
        'FontSize', 14);
    
    start_position = [20 20];
    next_size = [80 30];
    uicontrol('Parent', d, 'Position', [start_position next_size], ...
        'Callback', @makechoice, 'String', 'Yes');
    start_position(1) = start_position(1) + next_size(1) + 5;
    next_size = [80 30];
    uicontrol('Parent', d, 'Position', [start_position next_size], ...
        'Callback', @makechoice, 'String', 'Yes to All');
    start_position(1) = start_position(1) + next_size(1) + 5;
    next_size = [80 30];
    uicontrol('Parent', d, 'Position', [start_position next_size], ...
        'Callback', @makechoice, 'String', 'No to All');
    start_position(1) = start_position(1) + next_size(1) + 5;
    next_size = [80 30];
    uicontrol('Parent', d, 'Position', [start_position next_size], ...
        'Callback', @makechoice, 'Tag', 'No', 'String', 'No');
    uiwait(d);
    function makechoice(button, ~)
        choice = button.String;
        delete(button.Parent);
    end
end
