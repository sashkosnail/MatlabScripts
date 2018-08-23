%UI setup
function DYNAMate_Process_Data_GUI(varargin)
global OUTPUT PathName tab_group   
    if(~exist('PathName', 'file'))
        PathName = [pwd '\']; 
    end
    
    fig = figure(1111); clf
    pause(0.00001);
    set(fig, 'ToolBar', 'none', 'Units', 'Normalized', ...
        'OuterPosition', [0 0 1 1]);
    
    tab_group = uitabgroup('Parent', fig, 'Units', 'normalized', ...
        'Position', [0 0, 1, 1], 'SelectionChangedFcn', @tab_changed_callback);
    
    [FileName, PathName, ~] = uigetfile([PathName, '*.tdms'], ...
        'Pick File','MultiSelect','on');
    if(~iscell(FileName))
        FileName = {FileName}; end
    if(FileName{1} == 0)
        return; 
    end
    OUTPUT.Source_FileName = FileName;
    read_Data();
end

function createNewTab(idx)
global OUTPUT tab_group
    tab = uitab('Parent', tab_group, 'Title', OUTPUT.Data{idx}.FileName);
    
    signal_length = OUTPUT.Data{idx}.SignalNSamples;
    num_sensors = OUTPUT.Data{idx}.Nsensors;
    %create parameters
    window_size = min(4096, 2^(nextpow2(signal_length)-1));
    smoothN = 31;
    
    %create UI controls
    overview_text = uitable('Parent', tab);
    overview_text.Data = table2cell(OUTPUT.Data{idx}.ConfigTable(:,2:end));
    overview_text.ColumnName = OUTPUT.Data{idx}.ConfigTable.Properties.VariableNames(2:end);
    overview_text.ColumnWidth = {70, 70, 40, 60, 60, 50, 40, 40};
    overview_text.Units = 'normalized';
    overview_text.Position = [0.75 0.92 0.25 0.05];
    overview_text.RowName = [];
    overview_text.Units = 'pixels';
    overview_text.Position(3:4) = [431 75];
    overview_text.Units = 'normalized';
    
    time_text = uicontrol('Parent', tab, 'Style', 'text', ...
        'Units', 'normalized', 'Position', [0.075 0.98 0.075 0.02], ...
        'String', 'Window Center Time:', 'HorizontalAlignment', 'right'); %#ok<NASGU>
    time_tb = uicontrol('Parent', tab, 'Style', 'edit', ...
        'Units', 'normalized', 'Position', [0.15 0.98 0.05 0.02], ...
        'KeyReleaseFcn', @time_tb_callback, ...
        'ToolTipString', 'Window Center Time');
    
    window_size_text = uicontrol('Parent', tab, 'Style', 'text', ...
        'Units', 'normalized', 'Position', [0.2 0.98 0.075 0.02], ...
        'String', 'Frame Size:', 'HorizontalAlignment', 'right'); %#ok<NASGU>
    window_size_tb = uicontrol('Parent', tab, 'Style', 'edit', ...
        'Units', 'normalized', 'Position', [0.275 0.98 0.05 0.02], ...
        'KeyReleaseFcn', @window_size_tb_callback, 'String', num2str(window_size), ...
        'ToolTipString', 'Frame Size'); %#ok<NASGU>
    
    window_type_text = uicontrol('Parent', tab, 'Style', 'text', ...
        'Units', 'normalized', 'Position', [0.35 0.98 0.07 0.02], ...
        'String', 'Frame Window Type:', 'HorizontalAlignment', 'right'); %#ok<NASGU>
    window_type_cb = uicontrol('Parent', tab, 'Style', 'checkbox', ...
        'Units', 'normalized', 'Position', [0.42 0.98 0.08 0.02], ...
        'Callback', @hamming_cb_callback, 'Value', 1, ...
        'ToolTipString', 'Apply Hamming to Window', ...
        'String', 'Apply Hamming Window'); %#ok<NASGU>
    
    smoothN_text = uicontrol('Parent', tab, 'Style', 'text', ...
        'Units', 'normalized', 'Position', [0.5 0.98 0.075 0.02], ...
        'String', 'FFT Smooting Window Size:', 'HorizontalAlignment', 'right'); %#ok<NASGU>
    smoothN_tb = uicontrol('Parent', tab, 'Style', 'edit', ...
        'Units', 'normalized', 'Position', [0.575 0.98 0.05 0.02], ...
        'KeyReleaseFcn', @smoothN_tb_callback, 'String', num2str(smoothN), ...
        'ToolTipString', 'Spectrum Smooth Box Size'); %#ok<NASGU>
    
    save_button = uicontrol('Parent', tab, 'Style', 'pushbutton', ...
        'Units', 'normalized', 'Position', [0 0.98 0.05 0.02], ...
        'Callback', @savebutton_callback, 'String', 'Save Data', ...
        'ToolTipString', 'Save'); %#ok<NASGU>
    
    %create axis
    full_plot_axis = subplot('Position', [0.015 0.89 0.71 0.07], 'Parent', tab);
    plot_vert_size = 0.875/(num_sensors*1.05);
    ch_axis = cell(num_sensors, 1);
    for id = 0:1:num_sensors - 1
        ch_axis{id+1}.SignalAxis = subplot('Position', ...
            [0.015, plot_vert_size*id+0.05, 0.71, plot_vert_size], ...
            'Xgrid', 'on', 'Ygrid', 'on', 'Color', 'w');
        ch_axis{id+1}.SpectrumAxis = subplot('Position', ...
            [0.75, plot_vert_size*id+0.05, 0.245, plot_vert_size], ...
            'Xgrid', 'on', 'Ygrid', 'on', 'Color', 'w');
    end
    
    %set user data object
    tab.UserData = struct('window_size', window_size, ...
        'smoothN', smoothN, 'CurrentWindow', [1 window_size], ...
        'applyHamming', 1, 'DataIDX', idx, 'AccVelDisp', 1, ...
        'FullPlot', full_plot_axis, 'ChannelAxis', {ch_axis}, ...
        'VertBars', [], 'VertBarsH', [], 'TimeTB', time_tb);
    
    %plot data
    plot_tab_data(tab);
end

%Read Data
function read_Data()
global PathName OUTPUT
    isTableCol=@(t, thisCol) ismember(thisCol, t.Properties.VariableNames);
    OUTPUT.Data = cell(length(OUTPUT.Source_FileName),1);
    for idx = 1:1:length(OUTPUT.Source_FileName)
        datfile = OUTPUT.Source_FileName{idx};        
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
        OUTPUT.Data{idx}.DATA.Acceleration = zeros(size(DATA(:,2:end)));
        OUTPUT.Data{idx}.DATA.Displacement = zeros(size(DATA(:,2:end)));
        OUTPUT.Data{idx}.DATA.Time = DATA(:,1);
        OUTPUT.Data{idx}.Stats = signal_stats(DATA, OUTPUT.Sensor_configuration.Names);
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
            'Filter', FILTERS_str(filter_selected), 'Scale', SCALE_str));
        
        createNewTab(idx);
    end
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
    names = cellfun(@(c,i) strcat(c, {'_X_';'_Y_';'_Z_'}, num2str(i)), ...
        sensor_names, num2cell(active_ids)', 'uni', 0);
    names = vertcat(names{:})';
    
    OUTPUT.Sensor_configuration.Table = sensor_config;
    OUTPUT.Sensor_configuration.Names = names;
    OUTPUT.Sensor_configuration.DataChannels = data_channels;
    
    disp('Using Sensor Configuration:');
    disp(sensor_config);
end

%Plot Data
function plot_tab_data(tab)
global OUTPUT
    idx = tab.UserData.DataIDX;
    t = OUTPUT.Data{idx}.DATA.Time;
    switch tab.UserData.AccVelDisp
        case 0
            data = OUTPUT.Data{idx}.DATA.Acceleration;
        case 2
            data = OUTPUT.Data{idx}.DATA.Displacement;
        otherwise
            data = OUTPUT.Data{idx}.DATA.Velocity;
    end
    
    ax = tab.UserData.FullPlot;
    y_limits = [min(min(data)); max(max(data))]; 
    tab.UserData.VertBarsH = [y_limits y_limits];
    plot(t, data, 'ButtonDownFcn', @full_plot_callback, 'Parent', ax);
    set(ax, 'Color', 'w', 'XAxisLocation', 'top', 'NextPlot', 'add', ...
        'XGrid', 'on', 'YGrid', 'on', 'GridColor', 'k', 'TickDir', 'in', ...
        'GridLineStyle', ':', 'XLim', [t(1) t(end)], 'Ylim', y_limits); 
    
    plot_vert_bars(tab);
    plot_channel_data(tab)
end

function plot_channel_data(tab)
global OUTPUT
    idx = tab.UserData.DataIDX;
    N = tab.UserData.window_size;
    Fs = OUTPUT.Data{idx}.Fs;
    window_data_id = tab.UserData.CurrentWindow(1):1:tab.UserData.CurrentWindow(2);
    t=(window_data_id-1)/OUTPUT.Data{idx}.Fs;
    chanNames = OUTPUT.Sensor_configuration.Names;
    switch tab.UserData.AccVelDisp
        case 0
            data = OUTPUT.Data{idx}.DATA.Acceleration(window_data_id,:);
        case 2
            data = OUTPUT.Data{idx}.DATA.Displacement(window_data_id,:);
        otherwise
            data = OUTPUT.Data{idx}.DATA.Velocity(window_data_id,:);
    end
    
    num_sensors = OUTPUT.Data{idx}.Nsensors;
    ax=[]; %#ok<NASGU>
    for idx = 0:1:num_sensors - 1
        data_id = ((num_sensors -1 - idx)*3 + 1):((num_sensors - idx)*3);
        %signal
        ax = tab.UserData.ChannelAxis{idx+1}.SignalAxis;
        cla(ax);
        plot(t,data(:,data_id), 'LineWidth', 1, 'Parent', ax);
        set(ax, 'Color', 'w', 'GridColor', 'k', 'XLim', [t(1) t(end)], ...
            'XAxisLocation', 'bottom', 'NextPlot', 'add', ...
        'XGrid', 'on', 'YGrid', 'on', 'GridColor', 'k', ...
        'GridLineStyle', '-', 'YLim', [-1 1].*max(max(abs(data))));
        
        if(idx==0)
            ax.XAxis.Visible = 'on';
            ax.XLabel = text('Units', 'normalized', 'Parent', ax, ...
                'Position', [0.5 0.1 0], 'String', 'Time[s]');
        else
            ax.XAxis.TickLabels = [];
        end
        %Peaks      
        colors = [217 83 25; 0 114 189; 237 177 32]./255;
        
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
            Vpp_string = sprintf('%sVpp[%s][mm/s]=%5.3f\n', ...
                Vpp_string, chanNames{idc}, maxVpp);
        end 
        text(t(20), mean(ax.YLim), Vpp_string(1:end-1), 'Color', 'k', ...
            'BackgroundColor',[0.9 0.9 0.9], 'Parent', ax);
        %Spectrum
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
        if(specSmoothN == 1)
            fftdata_filt = fftdata;
        else
            fftdata_filt = filtfilt(ones(1,specSmoothN),1,fftdata);
        end
        f = Fs*(1:N/2)'/N;
        fft_range = [min(min(abs(fftdata_filt))) max(max(abs(fftdata_filt)))];
        
        ax = tab.UserData.ChannelAxis{idx+1}.SpectrumAxis;
        cla(ax);
        loglog(f,abs(fftdata_filt(:,data_id)), 'LineWidth', 1, ...
            'Parent', ax);
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
    axes(ax);
    l = legend('X','Y','Z');
    l.TextColor = 'k';
    l.Location = 'NorthWest';
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