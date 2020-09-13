%UI setup
function DYNAMate_Process_Data_GUI_simplified_notabs(varargin)
clearvars -global OUTPUT
global OUTPUT PathName
	OUTPUT.DMPversion = 'v1.99';  
    %load config files
    cfg_file = [GetExecutableFolder() '\DYNAMate.cfg'];
	fileattrib(cfg_file, '+w');
    cfg = readtable(cfg_file, 'FileType', 'text', ...
        'ReadVariableNames', false, 'ReadRowNames', true, ...
		'Delimiter', '\t');
	tmp = array2table(table2array(cfg)', ...
          'VariableNames', cfg.Properties.RowNames);
    OUTPUT.RuntimeCFG = array2table(table2array(cfg)', ...
        'VariableNames', cfg.Properties.RowNames);
    tmp2 = str2double(table2array(tmp(:,:)));
    OUTPUT.RuntimeCFG = [array2table(tmp2(~isnan(tmp2)), ...
        'VariableNames', tmp.Properties.VariableNames(~isnan(tmp2))) ...
        tmp(:,isnan(tmp2))];
    %trick to hide extention parameter
    if(~isTableCol(OUTPUT.RuntimeCFG, 'EnableFc'))
        OUTPUT.RuntimeCFG.targetFc = 0.5;
    end
    PathName = char(OUTPUT.RuntimeCFG.PathName);   
	if(length(PathName) <= 1 || ~exist(PathName, 'dir'))
		PathName = [GetExecutableFolder() '\']; 
	end
	createUI();
end
function createUI()
global fig OUTPUT
    %create main figure
    fig = figure();
    minsize = [1200 700];
	fig_basename = ['DYNAMate Process ' OUTPUT.DMPversion];
    set(fig, 'DeleteFcn', @figure_close_cb, 'NumberTitle', 'off', ...
        'Name', fig_basename, 'MenuBar', 'none', ...
        'Position', [0 0 minsize], 'SizeChangedFcn', @fig_szChange);
    pause(0.00001);
    dcm = datacursormode(fig);
    cm = get(dcm,'UIContextMenu');
	try
        dcm.removeAllDataCursors()
        set(findobj(cm.Children, 'Tag', 'DataCursorExport'), ...
            'Callback', @export_data_tips, 'Label', 'Export to File');
        set(findobj(cm.Children, 'Tag', 'DataCursorNewDatatip'), ...
            'Separator', 'off');
        set(findobj(cm.Children, 'Tag', 'DataCursorDisplayStyle'), ...
            'Visible', 'off');
        set(findobj(cm.Children, 'Tag', 'DataCursorSelectionStyle'), ...
            'Visible', 'off');  
        set(findobj(cm.Children, 'Tag', 'DataCursorSelectText'), ...
            'Visible', 'off');
        set(findobj(cm.Children, 'Tag', 'DataCursorEditText'), ...
            'Visible', 'off', 'Separator', 'off');
    catch
	end 
    WindowAPI(fig, 'Maximize');
    %create UI controls
    start_position = [70 2];
    next_size = [100 35];
    data_type_pd = uicontrol('Parent', fig, 'Style', 'popupmenu',...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'FontSize', 8, 'FontWeight', 'bold', 'Value', 2, ...
		'String', {'Acceleration', 'Velocity', 'Displacement'}, ...
        'Callback', @data_type_pd_callback, 'Enable', 'off');
    start_position(1) = start_position(1) + next_size(1) + 50;	
	next_size = [100 40];
    open_button = uicontrol('Parent', fig, 'Style', 'pushbutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @open_data_button_callback, 'String', 'Open...', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Tag', 'open');
    start_position(1) = start_position(1) + next_size(1) + 10;
    next_size = [100 40];
    save_button = uicontrol('Parent', fig, 'Style', 'pushbutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @save_data_button_callback, ...
		'String', 'Save Data...', 'FontSize', 10, 'FontWeight', 'bold', ...
		'Tag', 'data', 'Enable', 'off'); 
    start_position(1) = start_position(1) + next_size(1) + 10;
    next_size = [100 40];
    save_button_img = uicontrol('Parent', fig, 'Style', 'pushbutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @save_image_button_callback, ...
		'String', 'Save Image', 'FontSize', 10, 'FontWeight', 'bold', ...
		'Tag', 'image', 'Enable', 'off'); 
    start_position(1) = start_position(1) + next_size(1) + 50;
    next_size = [100 40];
    zoom_button = uicontrol('Parent', fig, 'Style', 'togglebutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @zoom_button_callback, 'String', 'Zoom', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Enable', 'off', ...
        'ToolTip', 'Hold SHIFT for Zooming out'); 
    start_position(1) = start_position(1) + next_size(1) + 10;
    next_size = [100 40];
    pan_button = uicontrol('Parent', fig, 'Style', 'togglebutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @pan_button_callback, 'String', 'Pan', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Enable', 'off'); 
    start_position(1) = start_position(1) + next_size(1) + 10;
    next_size = [100 40];
    datatip_button = uicontrol('Parent', fig, 'Style', 'togglebutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @datatip_button_callback, 'String', 'Data Cursor', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Enable', 'off', ...
        'ToolTip', 'Hold SHIFT to add more then one'); 
    start_position(1) = start_position(1) + next_size(1) + 50;
    next_size = [150 40];
    info_button = uicontrol('Parent', fig, 'Style', 'pushbutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @info_button_callback, ...
		'String', 'Information Table', 'FontSize', 10, ...
		'FontWeight', 'bold', 'Enable', 'off');	
    zoom_button.UserData = [pan_button datatip_button];
    pan_button.UserData = [zoom_button datatip_button];
    datatip_button.UserData = [pan_button zoom_button];  
    %set user data object
    fig.UserData = struct('Units', '[mm/s]', 'BaseName', fig_basename, ...
        'AccVelDisp', 2, 'minsize', minsize, 'UIComponents', ...
		[data_type_pd open_button save_button save_button_img ...
		zoom_button pan_button datatip_button info_button]);	
    fig_szChange(fig);
    drawnow()
end
function createAxis()
global OUTPUT fig
%Plot Panel
	num_sensors = OUTPUT.SensorConfig.Nsensors;
    parent_size = fig.Position;
    panelH = 42;	
	if(~isfield(fig.UserData, 'Panel'))
		fig.UserData.Panel = uipanel('Parent', fig, 'Units', 'pixels', ...
			'BorderWidth', 0, 'BorderType', 'none', ...
			'Position', [0 panelH parent_size(3) parent_size(4) - panelH]);
	else
		for idx = 1:1:length(fig.UserData.Panel.UserData.SignalAxis)
			delete(fig.UserData.Panel.UserData.SignalAxis(idx));
			delete(fig.UserData.Panel.UserData.SpectrumAxis(idx));
		end;
	end
    %create axis	
    for id = 0:1:num_sensors - 1
        ch_axis.SignalAxis(id+1) = subplot('Position', [0 0 0 0], ...
            'Units', 'pixels', 'Parent', fig.UserData.Panel, ...
			'Xgrid', 'on', 'Ygrid', 'on', 'Color', 'w', ...
			'XTick', [], 'YTick', [], 'Clipping', 'off');
        ch_axis.SpectrumAxis(id+1) = subplot('Position', [0 0 0 0], ...
            'Units', 'pixels', 'Parent', fig.UserData.Panel, ...
			'Xgrid', 'on', 'Ygrid', 'on', 'Color', 'w', ...
			'XTick', [], 'YTick', [], 'Clipping', 'off');
    end
    linkaxes(ch_axis.SignalAxis);
    linkaxes(ch_axis.SpectrumAxis);
    fig.UserData.Panel.UserData = ch_axis;
end
function plot_channel_data()
global OUTPUT fig
    t = OUTPUT.Data.TimeDomain.Time;
    f = OUTPUT.Data.FreqDomain.Frequency;
    num_sensors = OUTPUT.SensorConfig.Nsensors;
	switch fig.UserData.AccVelDisp
		case 1
			data = OUTPUT.Data.TimeDomain.Acceleration;
			fftdata = OUTPUT.Data.FreqDomain.Acceleration;
		case 3
			data = OUTPUT.Data.TimeDomain.Displacement;
			fftdata = OUTPUT.Data.FreqDomain.Displacement;
		otherwise
			data = OUTPUT.Data.TimeDomain.Velocity;
			fftdata = OUTPUT.Data.FreqDomain.Velocity;
	end
    figure(fig)
    %Plot Data
    data_range = max(max(abs(data)));
    fft_range = ceil(log10(max(max(abs(fftdata(2:end,:))))));
	fft_range = 10.^(fft_range + [-5 0]);
    for idx = 0:1:num_sensors - 1
        data_id = ((num_sensors - 1 - idx)*3 + 1):((num_sensors - idx)*3);
		%saturation differenitation
		lineStyle = {'-'; '-'; '-'};
		for sn = 1:1:length(data_id)
			if(any(OUTPUT.SensorConfig.SaturatedChannels == data_id(sn)))
				lineStyle{sn} = '--';
			end
		end
		backColor = [1 1 1];
		if(any(OUTPUT.SensorConfig.SaturatedSensors == (num_sensors-idx)))
			backColor = backColor*0.9;
		end
		%name generation
        sensor_name = ...
			OUTPUT.SensorConfig.SensorNames(num_sensors - idx);
        sensor_names = cellfun(@(c) strcat(c, {'_X';'_Y';'_Z'}), ...
        sensor_name, 'uni', 0);
        sensor_names = sensor_names{:};
        sensor_names_FFT = cellfun(@(c) strcat(c, ...
			{'_X_FFT';'_Y_FFT';'_Z_FFT'}), sensor_name, 'uni', 0);
        sensor_names_FFT = sensor_names_FFT{:};
        %Spectrum Plot  
        ax = fig.UserData.Panel.UserData.SpectrumAxis(idx+1);
        cla(ax);
        h = loglog(f,fftdata(:,data_id), 'LineWidth', 1, 'Parent', ax);
        set(h, {'color'}, {'r','b','k'}', {'LineStyle'}, lineStyle, ...
			{'Tag'}, sensor_names_FFT);
        set(ax, 'Color', backColor, 'GridColor', 'k', ...
            'XAxisLocation', 'bottom', 'NextPlot', 'add', ...
            'XGrid', 'on', 'YGrid', 'on', 'GridLineStyle', '-', ...
            'GridColor', 'k', 'XScale', 'log', 'YScale', 'log', ...
			'YLim', fft_range, 'XLim', [max(0.1, f(2)), f(end)], ...
			'YTick', 10.^(floor(log10(min(fft_range)))+1:1:5), ...
			'XTick', 10.^(-2:1:2));
		if(idx==0)
			ax.XAxis.Visible = 'on';
			text('Units', 'normalized', 'Parent', ax, ...
				'HorizontalAlignment' , 'right',...
				'VerticalAlignment' , 'top', 'Position', [1  0], ...
				'String', 'f[Hz]', 'FontWeight' ,'bold', 'FontSize', 12);
		else
			ax.XAxis.TickLabels = [];
		end  
		zoom reset
        %Signal Plot
        ax = fig.UserData.Panel.UserData.SignalAxis(idx+1);
        cla(ax);	
        h = plot(t,data(:,data_id), 'LineWidth', 1, 'Parent', ax);
        set(h, {'color'}, {'r','b','k'}', {'LineStyle'}, lineStyle, ...
			{'Tag'}, sensor_names);
        set(ax, 'Color', backColor, 'GridColor', 'k', ...
			'XLim', [t(1) t(end)], 'YLim', [-1 1].*data_range, ...
            'XAxisLocation', 'bottom', 'NextPlot', 'add', ...
        'XGrid', 'on', 'YGrid', 'on', 'GridColor', 'k', ...
        'GridLineStyle', '-');
		ax.YAxis.TickLabelFormat='%5.3g';
% 		ax.YTickLabel = ax.YTick;
		ax.YTickLabelMode = 'auto';
		if(idx==0)
			ax.XAxis.Visible = 'on';
			text('Units', 'normalized', 'Parent', ax, ...
				'HorizontalAlignment' , 'right',...
				'VerticalAlignment' , 'top', 'Position', [1  0], ...
				'String', 't[s]', 'FontWeight' ,'bold', 'FontSize', 12);
		else
			ax.XAxis.TickLabels = [];
		end
		if(max(abs(data_range))<0.01)
			tmp_units = ['[u' fig.UserData.Units(3:end)];
		else
			tmp_units = fig.UserData.Units;
		end
		ylabel(ax, sprintf('%s %s', sensor_name{:}, ...
			tmp_units), 'Color', 'k', 'FontWeight', 'bold', ...
			'BackgroundColor', 'none', 'FontSize', 10, 'Margin', 1);
		zoom reset
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
    panel_szChange(fig.UserData.Panel);    
end
%deal with Data
function read_Data()
global PathName OUTPUT wait_window
	datfile = OUTPUT.SourceFileName; 
	if(isvalid(wait_window))
		waitbar(0.2, wait_window, ['Loading ' datfile]);
		wait_window.UserData = sprintf('Loading %s\n', datfile);
	end
	TDMSStruct = TDMS_READ_FILE([PathName datfile]);
	if(~isfield(TDMSStruct.Properties, 'VersionDAQ'))
		answer = 'No';
		if(strcmpi('Yes', answer))
			TDMSStruct.Properties.VersionDAQ = '1.0';
		else
			TDMSStruct.Properties.VersionDAQ = 'N/A';
		end
	end
	VersionDAQ = TDMSStruct.Properties.VersionDAQ;
	if(~isfield(TDMSStruct.Properties, 'VersionDynaMate'))
		VersionDynaMate = 'N/A';
	else
		VersionDynaMate = TDMSStruct.Properties.VersionDynaMate;
	end
	oldDAQ = strcmp(VersionDAQ, '1.0')||strcmp(VersionDAQ, 'N/A');
	%extract data from data file
	Dtable = TDMSStruct.DATA;%(1000:34001,:);
	Fs = str2double(TDMSStruct.Properties.SampleRate);%1/(Dtable{2,1}-Dtable{1,1});
	if(Fs<=0)
		Fs = 250;
	end
	duration = round(Dtable{end,1}-Dtable{1,1}+1/Fs);
	DATA = Dtable{:,[1 OUTPUT.SensorConfig.DataChannels + 1]};
	CONFIG = Dtable{:,26:end};
	%Extract confguration information
	FILTERS = [32,64,128];
	FILTERS_str = {'32Hz','64Hz','128Hz'};
	SCALES_1 = [0.1, 0, 100, 10, 1];
	SCALES_str1 = {'0.1mm/s', 'Calibration', '100mm/s', '10mm/s', '1mm/s'};
	SCALES_2 = [0, 100, 10, 1, 0.1, 0.01];
	SCALES_str2 = {'Calibration', '100mm/s', '10mm/s', ...
		'1mm/s', '0.1mm/s', '0.01mm/s'};
	scale_selected = round(mean(CONFIG(:,end)));
% 	scale_selected = 0;
	filter_selected = round(mean(CONFIG(:,end-1)))-1;
	if(oldDAQ)
		scale_selected = scale_selected + 1;
		SCALE_str = SCALES_str1{scale_selected};
		SCALE = SCALES_1(scale_selected);
	else
		SCALE_str = SCALES_str2{scale_selected};
		SCALE = SCALES_2(scale_selected);
	end
	if(SCALE)
		SaturatedChannels = find(sum(abs(DATA(:,2:end)) > ...
			OUTPUT.RuntimeCFG.SatThreshold*SCALE));
		tmp_sat_chans = zeros(length(SaturatedChannels),3);
		tmp = zeros(OUTPUT.SensorConfig.Nsensors, 3);
		tmp = reshape(1:1:(size(DATA,2) - 1), size(tmp'))';
		tmp_sat_sensors = zeros(length(SaturatedChannels),1);
		for sn = 1:1:length(SaturatedChannels)
			[tmp_sat_sensors(sn), ~] = find(tmp == SaturatedChannels(sn));
			tmp_sat_chans(sn,:) = tmp(tmp_sat_sensors(sn),:);
		end
		tmp = unique(tmp_sat_chans, 'rows');
		SaturatedSensors = unique(tmp_sat_sensors);
		SaturatedChannelsFull = reshape(tmp', 1, numel(tmp));
	else
		SaturatedChannels = [];
		SaturatedChannelsFull = [];
		SaturatedSensors = [];
	end	
	OUTPUT.TDMSProperties = TDMSStruct.Properties;
	OUTPUT.SensorConfig.SaturatedChannels = SaturatedChannels;
	OUTPUT.SensorConfig.SaturatedChannelsFull = SaturatedChannelsFull;
	OUTPUT.SensorConfig.SaturatedSensors = SaturatedSensors;	
	OUTPUT.SW_version = VersionDynaMate;
	OUTPUT.DAQ_version = VersionDAQ;	
	OUTPUT.Data.Fs = Fs;
	OUTPUT.Data.SignalDuration = duration;
	OUTPUT.Data.SignalNSamples = length(DATA);	
	OUTPUT.Data.Scale = SCALE;
	OUTPUT.Data.ScaleSTR = SCALE_str;
	OUTPUT.Data.Filter = FILTERS(filter_selected);
	OUTPUT.Data.FilterSTR = FILTERS_str(filter_selected);	
	OUTPUT.Data.Time = DATA(:,1);
	OUTPUT.Data.RAW = DATA(:,2:end);	
	OUTPUT.Data.TimeDomain.Time = [];
	OUTPUT.Data.TimeDomain.Velocity= [];
	OUTPUT.Data.TimeDomain.Acceleration = [];
	OUTPUT.Data.TimeDomain.Displacement = [];	
	OUTPUT.Data.FreqDomain.Frequency = [];
	OUTPUT.Data.FreqDomain.Velocity= [];
	OUTPUT.Data.FreqDomain.Acceleration = [];
	OUTPUT.Data.FreqDomain.Displacement = [];	
	OUTPUT.Tables.TestConfig = struct2table(struct(...
		'FileName', datfile, 'DMPversion', OUTPUT.DMPversion, ...
		'VersionDAQ', VersionDAQ, 'SWVersion', VersionDynaMate, 'Fs', Fs, ...
		'NSamples', length(DATA), 'SignalDuration', duration, ...
		'NumberOfSensors', OUTPUT.SensorConfig.Nsensors, ...
		'AcquisitionFilter', FILTERS_str(filter_selected), ...
		'AcquisitionScale', SCALE_str, 'SensorFc', '4.5', ...
		'SaturationThreshold', OUTPUT.RuntimeCFG.SatThreshold, ...
		'TaperTau', OUTPUT.RuntimeCFG.taper_tau, ...
		'SpectrumSmoothPower', OUTPUT.RuntimeCFG.specSmoothN, ...
		'CorrectionSteepness', OUTPUT.RuntimeCFG.corrSteepnes));
end
function output = TDMS_READ_FILE(filename)
global OUTPUT wait_window
	isTableRow=@(t, thisRow) ismember(thisRow, t.Properties.RowNames);
	index = [filename '_index']; %#ok<NASGU>
	[TDMSData,~] = TDMS_readTDMSFile(filename);
	
	propN = strrep(TDMSData.propNames{1,1}, ' ', '');
	output.Properties = cell2struct(TDMSData.propValues{1,1}(:), propN);
	
	S.groupIDx = TDMSData.groupIndices';
	S.chanIDx = TDMSData.chanIndices';
	S.chanNames = TDMSData.chanNames';
	groups = struct2table(S, 'RowNames', TDMSData.groupNames);
	
	if(isTableRow(groups, 'Untitled'))
		try
			if(isvalid(wait_window))
				waitbar(0.1, wait_window, 'Loading Sensor Configuration');
			end
			read_sensor_config();
		catch ME
			if(strcmp(ME.identifier, 'DYNAMate:NOConfigStop'));
				throw(ME)
			end
		end
		chanNames = TDMSData.chanNames{1}(2:end);
		data = cell2mat(TDMSData.data(groups{'Untitled', 'chanIDx'}{:}(2:end))')';
		t = cell2mat(TDMSData.data(groups{'Untitled', 'chanIDx'}{:}(1))')';
	else
		ai = read_sensor_config_new(TDMSData);
		
		try
			Fs = str2double(output.Properties.SampleRate);
		catch
			Fs = output.Properties.SampleRate;
		end
% 		t0 = TDMSData.data{groups{'Misc', 'chanIDx'}{1}(1)}(1);
		chanNames_active = groups{'Active','chanNames'}{1};
		data_active = cell2mat(TDMSData.data(groups{'Active', 'chanIDx'}{:})')';
		chanNames_inactive = groups{'Inactive','chanNames'}{1};
		data_inactive = cell2mat(TDMSData.data(groups{'Inactive', 'chanIDx'}{:})')';
		chanNames_misc = groups{'Misc','chanNames'}{1};
		data_misc = cell2mat(TDMSData.data(groups{'Misc', 'chanIDx'}{:})')';
		if(ai)
			data = [data_active data_inactive data_misc(:,2:end)];
			chanNames = [chanNames_active chanNames_inactive chanNames_misc(2:end)];
		else
			data = [data_inactive data_active data_misc(:,2:end)];
			chanNames = [chanNames_inactive chanNames_active chanNames_misc(2:end)];
		end
		t = TDMSData.data{groups{'Misc', 'chanIDx'}{1}(1)}';
	end
	output.DATA = array2table([t data], 'VariableNames', ['Time', chanNames]);
end
function ai = read_sensor_config_new(TDMS)
global OUTPUT
	S.groupIDx = TDMS.groupIndices';
	S.chanIDx = TDMS.chanIndices';
	S.chanNames = TDMS.chanNames';
	groups = struct2table(S, 'RowNames', TDMS.groupNames);
	if(strcmp('Active', questdlg('Do you want ot process Active or Inactive channels', ...
                'Channels', 'Active', 'Inactive', 'Active')))
		active_sensor_id = groups{'Active','chanIDx'}{1};
		ai = 1;
	else
		active_sensor_id = groups{'Inactive','chanIDx'}{1};
		ai = 0;
	end
	number_of_sensors = length(active_sensor_id)/3;
	sensor_config=table();
	for n=0:number_of_sensors-1
		s_id = active_sensor_id(n*3+1);
		sd = cell2struct(TDMS.propValues{s_id}',strrep(TDMS.propNames{s_id}, ' ', ''));
		sensor_row = table(n+1, {sd.NI_ChannelName}, {'XYZ'}, {sd.Sensor_Element(1:end-2)});
		sensor_config = [sensor_config; sensor_row]; %#ok<AGROW>
	end
	
	sensor_config.Properties.VariableNames = {'Channel', 'Name', 'Components', 'SensorID'};
	sens_file = [GetExecutableFolder() '\sensor_data.csv'];
	sensorFreqTable = readtable(sens_file, 'ReadRowNames',true);
	sensorFreqTable.Properties.RowNames = strrep(sensorFreqTable.Properties.RowNames,' ','_');
	sensorFreq = array2table(4.425 * ...
		ones(length(sensor_config.SensorID),3));
	sensorFreq.Properties.VariableNames = ...
		sensorFreqTable.Properties.VariableNames;	
	for sid = 1:1:length(sensor_config.SensorID)
		if(strcmp(sensor_config.SensorID(sid), 'NA') || ...
				strcmp(sensor_config.SensorID(sid), 'S02 0'))
			continue;
		else
			try
				sensorFreq(sid,:) = sensorFreqTable(...
					cellstr(strrep(sensor_config.SensorID(sid),' ','_')),:);
			catch
				sensorFreq(sid,:) = sensorFreqTable(strcat('S01_', ...
					sensor_config.SensorID(sid)),:);
			end
		end
	end
    sensor_names = sensor_config.Name;
    names = cellfun(@(c) strcat(c, {'_X';'_Y';'_Z'}), ...
        sensor_names, 'uni', 0);
    names = vertcat(names{:})';
    sensor_config = [sensor_config sensorFreq];
    freq_vector = reshape(table2array(sensorFreq)',1, numel(sensorFreq));
	OUTPUT.Tables.SensorConfig = sensor_config;
	OUTPUT.SensorConfig.Nsensors = number_of_sensors;
    OUTPUT.SensorConfig.ChannelNames = names;
    OUTPUT.SensorConfig.SensorNames = sensor_names;
    OUTPUT.SensorConfig.SensorID = sensor_config.SensorID;
    OUTPUT.SensorConfig.DataChannels = 1:3*number_of_sensors;
    OUTPUT.SensorConfig.SensorFreqs = freq_vector;
end
function read_sensor_config()
global PathName OUTPUT
    isTableCol=@(t, thisCol) ismember(thisCol, t.Properties.VariableNames);
	try
	if(exist([PathName 'sensor_configuration.txt'], 'file'))
		try
			sensor_config = readtable(...
				[PathName 'sensor_configuration.txt'], ...
				'Delimiter', '\t', 'ReadRowNames', false, ...
				'MultipleDelimsAsOne',true,'Format', '%s%s%s%s', ...
				'TreatAsEmpty', 'NA', 'ReadVariableNames', true, ...
				'HeaderLines', 0);
		catch
			sensor_config = readtable(...
				[PathName 'sensor_configuration.txt'], ...
				'Delimiter', '\t', 'ReadRowNames', false, ...
				'MultipleDelimsAsOne',true,'Format', '%s%s%s', ...
				'TreatAsEmpty', 'NA', 'ReadVariableNames', true, ...
				'HeaderLines', 0);
		end
		%trim table if too large
		sensor_config = sensor_config(1:min(height(sensor_config),8),:);
		sensor_config.SensorID = strrep(sensor_config.SensorID, ' ', '_');
		active_ids = find(~strcmp(sensor_config.Name,'NA'))';
		sensor_config = sensor_config(active_ids,:);
		number_of_sensors = length(active_ids);
		if(isTableCol(sensor_config, 'SensorID'))
			sens_file = [GetExecutableFolder() '\sensor_data.csv'];
			sensorFreqTable = readtable(sens_file, 'ReadRowNames',true);
			sensorFreqTable.Properties.RowNames = strrep(sensorFreqTable.Properties.RowNames,' ','_');
			sensorFreq = array2table(4.5 * ...
				ones(length(sensor_config.SensorID),3));
			sensorFreq.Properties.VariableNames = ...
				sensorFreqTable.Properties.VariableNames;	
			for sid = 1:1:length(sensor_config.SensorID)
				if(strcmp(sensor_config.SensorID(sid), 'NA'))
					continue;
				else
					sensorFreq(sid,:) = sensorFreqTable(...
						cellstr(sensor_config.SensorID(sid)),:);
				end
			end
		else
			sensor_config = [sensor_config ...
				table(repmat({'NA'}, number_of_sensors,1), ...
				'VariableNames', {'SensorID'})];
			sensorFreq = array2table(4.5*ones(number_of_sensors,3), ...
				'VariableNames', {'xFc', 'yFc', 'zFc'});
		end
	else
		throw(MException('DYNAMate:NOConfig', ...
			'No Sensor Config File Found'));
	end
    catch ME
        if(~strcmp('Continue', questdlg(...
				{'Error Loading Sensor Configuration', ME.message, ...
	'Do you want ot continue with defualt config or Stop processing'}, ...
                'Error Loading', 'Stop', 'Continue', 'Continue')))
            throw(MException('DYNAMate:NOConfigStop', 'Stop'));
        end
        sensor_config = table((1:8)', ...
			cellstr(strcat('s',num2str((1:8)'))), ...
            cellstr(repmat('xyz',8,1)), repmat({'NA'}, 8,1), ...
            'VariableNames',{'Channel', 'Name', 'Components', 'SensorID'});
        sensorFreq = array2table(4.5*ones(8,3), ...
                'VariableNames', {'xFc', 'yFc', 'zFc'});
        number_of_sensors = 8;
        active_ids = 1:1:8;
	end
    sensor_names = sensor_config.Name;
    components = sensor_config.Components;
    %figure out the order of channels and components
    data_channels = zeros(1, 3*number_of_sensors);
    for sensor = 1:1:number_of_sensors
        chan = active_ids(sensor);
        if(strcmp(components(sensor),'NA'))
            comps = 'xyz';
        else
            comps = cell2mat(components(sensor));
        end
        %column numbers for the given channel
        cn = (chan*3-2):(chan*3);
        %reorder based on comps
        comp_set = [cn(comps == 'x') cn(comps == 'y') cn(comps == 'z')];
        %add one to skip over time column and append to final vector
        data_channels((sensor*3-2):(sensor*3)) = comp_set;
    end
    sensor_config = [sensor_config array2table(reshape(...
		data_channels, 3, [])', ...
		'VariableNames', strcat('ChannelUsed', {'_X';'_Y';'_Z'}))];
    names = cellfun(@(c) strcat(c, {'_X';'_Y';'_Z'}), ...
        sensor_names, 'uni', 0);
    names = vertcat(names{:})';
    sensor_config = [sensor_config sensorFreq];
    freq_vector = reshape(table2array(sensorFreq)',1, numel(sensorFreq));
	OUTPUT.Tables.SensorConfig = sensor_config;
	OUTPUT.SensorConfig.Nsensors = height(sensor_config);
    OUTPUT.SensorConfig.ChannelNames = names;
    OUTPUT.SensorConfig.SensorNames = sensor_names;
    OUTPUT.SensorConfig.SensorID = sensor_config.SensorID;
    OUTPUT.SensorConfig.DataChannels = data_channels;
    OUTPUT.SensorConfig.SensorFreqs = freq_vector;
end
function processData()
global OUTPUT wait_window
    Fs = OUTPUT.Data.Fs;
    Ts = 1/Fs;
    N = OUTPUT.Data.SignalNSamples;
    taper_tau = OUTPUT.RuntimeCFG.taper_tau*OUTPUT.Data.SignalDuration;
    specSmoothN = OUTPUT.RuntimeCFG.specSmoothN;
    targetFc = OUTPUT.RuntimeCFG.targetFc;
    corrSteepnes = OUTPUT.RuntimeCFG.corrSteepnes;
    data = OUTPUT.Data.RAW;
    t = (OUTPUT.Data.Time(1):Ts: OUTPUT.Data.Time(end))';
	numCH = size(data,2);
	if(~mod(OUTPUT.Data.SignalNSamples, 2))
		t = [t; t(end)+Ts];
		data = [data; zeros(1, numCH)];
		N = N+1;
	end
	if(isvalid(wait_window))
        waitbar(0.35, wait_window, ...
            [wait_window.UserData 'Removing Trend and Offset']);
	end
    %Apply taper
    taper = build_taper(t, taper_tau);
    taper = repmat(taper, 1, numCH);
	data = detrend(data);
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!%
    data = (data - repmat(mean(data),N,1));%.*taper;
%     offset = repmat(mean(data),N,1);
%     data = data - offset;
	sat_channels = OUTPUT.SensorConfig.SaturatedChannels;
	sat_channelsFull = OUTPUT.SensorConfig.SaturatedChannelsFull;
% 	data = ShiftFilter(data, 32, 75, 1000);
	if(isfield(OUTPUT.TDMSProperties,'ResponseExtension'))
		tmp_bool = strcmp(OUTPUT.TDMSProperties.ResponseExtension,'NO');
		if(~tmp_bool)
			OUTPUT.Tables.TestConfig.SensorFc = 1;
		end
	else
		tmp_bool = true;
	end
	if(tmp_bool && strcmp('Yes', choosefixDialog(targetFc)))
		if(sat_channels)
			msg = strjoin([{'For File:'} {OUTPUT.SourceFileName} ...
				{'Possible Saturation Detected on these Channels:'} ...
				OUTPUT.SensorConfig.ChannelNames(sat_channels) ...
		{'Sensor freqeuncy correction is DISABLED for these channels'}],'\n');
			sat_win = warndlg(msg, 'Possible Saturation');
			WindowAPI(sat_win,'TopMost');
		end
		if(isvalid(wait_window))
			waitbar(0.4, wait_window, ...
			[wait_window.UserData 'Correcting Sensor Response']);
		end
		[data, ~, ~] = FixResponse2(data, ...
			OUTPUT.SensorConfig.SensorFreqs, targetFc, Fs, ...
			sat_channelsFull, corrSteepnes);
		chan_frqs = targetFc*ones(1, numCH);
		chan_frqs(sat_channelsFull) = ...
			OUTPUT.SensorConfig.SensorFreqs(sat_channelsFull);
		OUTPUT.Tables.SensorConfig = ...
			[OUTPUT.Tables.SensorConfig ...
			array2table(reshape(chan_frqs, 3, ...
			OUTPUT.SensorConfig.Nsensors)', 'VariableNames', ...
			{'xFc_corrected', 'yFc_corrected', 'zFc_corrected'})];
		OUTPUT.Tables.TestConfig.SensorFc = targetFc;
	end
    if(isvalid(wait_window))
        waitbar(0.5, wait_window, [wait_window.UserData ...
			'Calculating Acceleration and Displacement']);
    end
    %Calculate Acceleration and Displacement
    Displacement = cumtrapz(t, data);
    Displacement = detrend(Displacement);
	Displacement = Displacement - repmat(mean(Displacement),N,1);
	Velocity = [zeros(1, numCH); diff(Displacement)/Ts];
	Acceleration = [zeros(1, numCH); diff(Velocity/1000)/Ts];
	if(~mod(OUTPUT.Data.SignalNSamples, 2))
		Displacement = Displacement(1:end-1, :);
		Acceleration = Acceleration(2:end, :);
		Velocity = Velocity(2:end, :);
		t = t(1:end-1);
	end
	if(isvalid(wait_window))
		waitbar(0.6, wait_window, ...
			[wait_window.UserData 'Calculating Spectra']);
	end
    %calculate Spectra
    fftdata = abs(fft(data)./N);
    fftdata = abs(fftdata(ceil(1:N/2+1),:));
    fftdata(2:end-1,:) = 2*fftdata(2:end-1,:);
    f = Fs*(0:N/2)'/N;
	if(specSmoothN)
		fftdata = smoothFFT(fftdata, specSmoothN, f, wait_window);
	end
    %set data to output
    %time
	OUTPUT.Data.TimeDomain.Time = t;
    OUTPUT.Data.TimeDomain.Velocity = Velocity; %[mm/s]
    OUTPUT.Data.TimeDomain.Acceleration = Acceleration; %[m/s^2]
    OUTPUT.Data.TimeDomain.Displacement = Displacement; %[mm]
    %spectrum
	f(1) = 0;
	OUTPUT.Data.FreqDomain.Frequency = f;
    OUTPUT.Data.FreqDomain.Velocity = fftdata; %[mm/s]
    OUTPUT.Data.FreqDomain.Acceleration = ...
		fftdata.*(2*pi*repmat(f,1,numCH))/1000; %[m/s^2]
    f(1) = 10^-10;
    OUTPUT.Data.FreqDomain.Displacement = ...
		fftdata./(2*pi*repmat(f,1,numCH)); %[mm]
    %stats
    OUTPUT.Tables.VStatsTable = signal_stats([t Velocity], ...
        OUTPUT.SensorConfig.ChannelNames);
    OUTPUT.Tables.AStatsTable = signal_stats([t Acceleration], ...
        OUTPUT.SensorConfig.ChannelNames);
    OUTPUT.Tables.DStatsTable = signal_stats([t Displacement], ...
        OUTPUT.SensorConfig.ChannelNames);
end
%UI CALLBACKS
function open_data_button_callback(~, ~)
global OUTPUT PathName fig wait_window
	if(ishandle(wait_window))
		delete(wait_window)
	end
    wait_window = waitbar(0,'Please wait...');
    wait_window.Children.Title.Interpreter = 'none';
    WindowAPI(wait_window, 'TopMost');
    WindowAPI(wait_window, 'clip', [2 2 360 78]);
    figure(wait_window)
    waitbar(0, wait_window, 'Select Input File');
	%get input files
    [FileName, tmpPath, ~] = uigetfile([PathName, '*.tdms'], ...
        'Pick File','MultiSelect','off');
	if(FileName == 0)
		delete(wait_window)
		return; 
	end
	tmpPathOld = PathName;
	PathName = tmpPath;
	OUTPUT.RuntimeCFG.PathName = PathName;
    OUTPUT.SourceFileName = FileName;
	%try to read data exit if bad
	try
		read_Data()
		if(isvalid(wait_window))
			waitbar(0.3, wait_window,[wait_window.UserData 'Processing data']);
		end
		processData();
	catch ME
		if(~strcmp(ME.identifier, 'DYNAMate:NOConfigStop'))
			warndlg({'Error Loading Data File'; ME.message; ...
				['@ ' ME.stack(1).name ':' num2str(ME.stack(1).line)]}, ...
				'Error Loading');
		end
		delete(wait_window);
		PathName = tmpPathOld;
		return
	end
	set(fig, 'Name', [fig.UserData.BaseName ' - ' FileName]);
	%plot data
	if(isvalid(wait_window))
		waitbar(0.9, wait_window, ...
			[wait_window.UserData 'Plotting Data']);
	end
	createAxis();
    plot_channel_data();
	%re-enable UI controls
	UIComponents = fig.UserData.UIComponents;
	for uin = 1:1:length(UIComponents)
		UIComponents(uin).Enable = 'on';
	end
	%save path file
	cfg_file = [GetExecutableFolder() '\DYNAMate.cfg'];
	tmp = OUTPUT.RuntimeCFG;
	if(~isTableCol(OUTPUT.RuntimeCFG, 'EnableFc'))
		tmp.targetFc = [];
	end
    writetable(cell2table(table2cell(tmp)', ...
        'RowNames', tmp.Properties.VariableNames), ...
		cfg_file, 'FileType', 'text', 'Delimiter', '\t', ...
        'WriteVariableNames', false, 'WriteRowNames', true);
	if(isvalid(wait_window))
		waitbar(1.0, wait_window, 'Done');
		pause(0.5);
		delete(wait_window);
	end
end
function save_data_button_callback(~, ~)
global OUTPUT PathName
    source_file = OUTPUT.SourceFileName(1:end-5);
    file = [PathName source_file];
    [FileName, PathName2, ~] = ...
		uiputfile('*.xlsx', 'Save Data', [file '.xlsx']);
	if(FileName == 0)
		return; 
	end
    PathName = PathName2;
    dot_index = strfind(FileName,'.');
	if(isempty(dot_index))
		dot_index = length(FileName);
	else
		dot_index = dot_index(end)-1;
	end
    file = [PathName FileName(1:dot_index) '.xlsx'];
    wait_save = waitbar(0.0, 'Saving Acceleration Data, please wait...');
    WindowAPI(wait_save, 'TopMost');
    WindowAPI(wait_save, 'clip', [1 1 360 70]);
    %save DATA 
    xlswrite(file, ['Time[s]', cellfun(@(c) strcat(c, '[m/s^2]'), ...
        OUTPUT.SensorConfig.ChannelNames, 'uni', 0); ...
		num2cell([OUTPUT.Data.TimeDomain.Time ...
		OUTPUT.Data.TimeDomain.Acceleration])], 'Acceleration', 'A1');
    waitbar(0.1429, wait_save, 'Saving Velocity Data, please wait...');
    xlswrite(file, ['Time[s]', cellfun(@(c) strcat(c, '[mm/s]'), ...
        OUTPUT.SensorConfig.ChannelNames, 'uni', 0); ...
		num2cell([OUTPUT.Data.TimeDomain.Time ...
		OUTPUT.Data.TimeDomain.Velocity])], 'Velocity', 'A1');
    waitbar(0.2857, wait_save, 'Saving Displacement Data, please wait...');
    xlswrite(file, ['Time[s]', cellfun(@(c) strcat(c, '[mm]'), ...
        OUTPUT.SensorConfig.ChannelNames, 'uni', 0); ...
		num2cell([OUTPUT.Data.TimeDomain.Time ...
		OUTPUT.Data.TimeDomain.Displacement])], 'Displacement', 'A1');
    %save FFT
    waitbar(0.4286, wait_save, 'Saving Acceleration FFT, please wait...');
    xlswrite(file, ['Frequency[Hz]', cellfun(@(c) strcat(c, ...
		'[m/s^2]'), OUTPUT.SensorConfig.ChannelNames, 'uni', 0); ...
		num2cell([OUTPUT.Data.FreqDomain.Frequency ...
		OUTPUT.Data.FreqDomain.Acceleration])], 'FFT_Acceleration', 'A1');
    waitbar(0.5714, wait_save, 'Saving Velocity FFT, please wait...');
    xlswrite(file, ['Frequency[Hz]', cellfun(@(c) strcat(c, ...
		'[mm/s]'), OUTPUT.SensorConfig.ChannelNames, 'uni', 0); ...
		num2cell([OUTPUT.Data.FreqDomain.Frequency ...
		OUTPUT.Data.FreqDomain.Velocity])], 'FFT_Velocity', 'A1');
    waitbar(0.7143, wait_save, 'Saving Displacement FFT, please wait...');
    xlswrite(file, ['Frequency[Hz]', cellfun(@(c) strcat(c, ...
		'[mm]'), OUTPUT.SensorConfig.ChannelNames, 'uni', 0); ...
		num2cell([OUTPUT.Data.FreqDomain.Frequency ...
		OUTPUT.Data.FreqDomain.Displacement])], 'FFT_Displacement', 'A1'); 
    %save CONFIG
    waitbar(0.81, wait_save, 'Saving Configuration, please wait...');
    xlswrite(file, [OUTPUT.Tables.TestConfig.Properties.VariableNames;...
		table2cell(OUTPUT.Tables.TestConfig)], 'Configuration', 'A1');
    xlswrite(file, [OUTPUT.Tables.SensorConfig.Properties.VariableNames;...
		table2cell(OUTPUT.Tables.SensorConfig)], 'Configuration', 'A4');
    %save STATS
    waitbar(0.9, wait_save, 'Saving Signal Statistics, please wait...');
    tbl = OUTPUT.Tables.DStatsTable; r = tbl.Properties.RowNames;
    tbl = [table(r, 'VariableNames', {'Displacement'}), tbl];
    tbl.Properties.RowNames = {}; N = width(tbl);
	tblOUT = [tbl.Properties.VariableNames; table2cell(tbl)];
	tbl = OUTPUT.Tables.VStatsTable; r = tbl.Properties.RowNames;
    tbl = [table(r, 'VariableNames', {'Velocity'}), tbl];
    tbl.Properties.RowNames = {};
	tblOUT = [tbl.Properties.VariableNames; ...
		table2cell(tbl); cell(1, N); tblOUT];
	tbl = OUTPUT.Tables.AStatsTable; r = tbl.Properties.RowNames;
    tbl = [table(r, 'VariableNames', {'Acceleration'}), tbl];
    tbl.Properties.RowNames = {}; N = width(tbl);
	tblOUT = [tbl.Properties.VariableNames; ...
		table2cell(tbl); cell(1, N); tblOUT];
	xlswrite(file, tblOUT, 'Configuration', ...
		['A' num2str(6+OUTPUT.SensorConfig.Nsensors)]);
	waitbar(1, wait_save, 'Saving Complete');
    pause(0.5);
    delete(wait_save);
end
function save_image_button_callback(hObject, ~)
global OUTPUT PathName fig
    source_file = OUTPUT.SourceFileName(1:end-5);
    file = [PathName source_file];
	switch hObject.Parent.UserData.AccVelDisp
		case 1
			TYPE = '_Acceleration';
		case 3
			TYPE = '_Displacement';
		otherwise
			TYPE = '_Velocity';
	end
    [FileName, PathName2, ~] = uiputfile('*.png', 'Save Image', ...
		[file TYPE '.png']);
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
    export_fig([base_file '.png'], '-c[0 0 40 0]', fig);
end
function info_button_callback(~, ~)
global OUTPUT info_dialog
	if(ishandle(info_dialog))
		delete(info_dialog);
	end
    widths.Min = [50,50,50,30,60,40,30,40,60,40,40,40,40,40];
    widths.Max = [80,80,75,30,70,100,110,100,110,65,125,65,140,125];
    info_dialog = dialog('Resize', 'on', 'Units', 'normalized', ...
		'WindowStyle', 'normal', 'Position', [0.4 0.7 0.1 0.1], ...
        'Name', 'Processing and Aquisition Information',  ... 
        'SizeChangedFcn', @size_changed);
    info_dialog.Units = 'pixels';
    info_dialog.Position(3:4) = [sum(widths.Min) 40];
    WindowAPI(info_dialog, 'TopMost');
    WindowAPI(info_dialog, 'maximize');
    WindowAPI(info_dialog, 'maximize', false);
    config_table = uitable('Parent', info_dialog, 'UserData', widths);
    config_table.Data = table2cell(OUTPUT.Tables.TestConfig(:,2:end));
    config_table.ColumnName = ...
        OUTPUT.Tables.TestConfig.Properties.VariableNames(2:end);
    column_widths = config_table.UserData.Min;
    config_table.ColumnWidth = num2cell(column_widths);
    config_table.Units = 'normalized';
    config_table.Position = [0 0 1 1];
    config_table.RowName = [];
    size_changed(info_dialog);
    function size_changed(hObject, ~)
        if(isempty(hObject.Children))
            return
        end
        tbl = hObject.Children(1);
        tblsize = tbl.Position;
        tabsize = hObject.Position;
        new_size = tbl.UserData.Min;
        minsize = [sum(tbl.UserData.Min) 40];
        maxsize = [sum(tbl.UserData.Max) 40];
        hObject.Position(3:4) = min(maxsize, hObject.Position(3:4));
        hObject.Position(3:4) = max(minsize, hObject.Position(3:4));
        while(1)
            free_space = tabsize(3) - sum(new_size) - tblsize(1);
            toadd = tbl.UserData.Max-new_size;
            possible_add = toadd>0;
            if(~sum(possible_add))
                break;
            end
            min_add = sum(toadd>0);
            times_add = min(toadd(toadd~=0));
            times_add = min(times_add, floor(free_space/min_add));
            if(times_add<=0)
                break;
            end
            new_size = new_size + times_add.*possible_add;
        end
        tbl.ColumnWidth = num2cell(new_size);
        tbl.Position(3) = sum(new_size)+2;
    end
end
function data_type_pd_callback(hObject, ~)
global fig
    fig.UserData.AccVelDisp = hObject.Value;
    switch hObject.Value
        case 1
            fig.UserData.Units = '[m/s^2]';
        case 3
            fig.UserData.Units = '[mm]';
        otherwise
            fig.UserData.Units = '[mm/s]';
    end
    plot_channel_data();
end
function figure_close_cb(~, ~)
global wait_window info_dialog
    try
		if(ishandle(wait_window) || isvalid(wait_window))
			delete(wait_window)
		end
		if(ishandle(info_dialog) || isvalid(info_dialog))
			delete(info_dialog)
		end
    catch
    end
end
function fig_szChange(hObject,~)
	set(hObject, 'position', ...
		max([0 0 hObject.UserData.minsize], hObject.Position))
    if(isfield(hObject.UserData, 'Panel'))
        panelM = 42;
        figsize = hObject.Position;
        set(hObject.UserData.Panel, ...
            'position', [0 panelM figsize(3) figsize(4)-panelM]);
        panel_szChange(hObject.UserData.Panel);
    end
end
function panel_szChange(hObject, ~)
global OUTPUT
	if(~isfield(OUTPUT, 'Data'))
		return;
	end
	if(isempty(OUTPUT.Data))
		return;
	end
    num_sensors = OUTPUT.SensorConfig.Nsensors;
    parent_size = hObject.Position;
    ch_axis = hObject.UserData;
    ch_axis.Spacing = [70 27 40];
	plotM = ch_axis.Spacing(3);
    plotL = ch_axis.Spacing(1);
    plotHsig = floor(0.7*parent_size(3));
    plotHfft = parent_size(3) - plotL - plotM - plotHsig;
    plotV = parent_size(4) - ch_axis.Spacing(2);
    plotB = ch_axis.Spacing(2) + rem(plotV, num_sensors);
    plotV = floor(plotV/num_sensors);
    for id = 0:1:num_sensors - 1
    ch_axis.SignalAxis(id+1).Position = ...
                    [plotL, plotV*id+plotB, plotHsig, plotV];
    ch_axis.SpectrumAxis(id+1).Position = ...
                    [plotL+plotHsig+plotM, plotV*id+plotB, plotHfft, plotV];
    end
    l = ch_axis.SignalAxis(id+1).UserData;
    if(~isempty(l))
        cp = ch_axis.SignalAxis(id+1).Position;
        lp = l.Position;
        l.Position = ceil([cp(1)+cp(3)-lp(3) cp(2)+cp(4)-lp(4) lp(3:4)]); 
    end
end
function zoom_button_callback(hObject, ~)
    h=zoom();
    h.ActionPreCallback = @prezoomCB;
    h.ActionPostCallback = @postzoomCB;
    if(hObject.Value == 1)
        h.Enable = 'on';
        hObject.UserData(1).Value = 0;
        hObject.UserData(2).Value = 0;
    else
        h.Enable = 'off';
    end
    function prezoomCB(~, eventData) %#ok<INUSD>
%         disp('PRE');
%         disp(eventData.Axes.YLim)
    end
    function postzoomCB(~, eventData) %#ok<INUSD>
%         disp('POST');
%         disp(eventData.Axes.YLim)
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
    pos = get(event_obj,'Position');
    uY = event_obj.Target.Parent.Parent.Parent.UserData.Units;
    name = event_obj.Target.Tag;
    if(strcmp(event_obj.Target.Parent.XScale, 'log'))
        output_txt = sprintf('%s\n%5.3e %s\n%3.3f Hz', ...
            name, pos(2), uY(2:end-1), pos(1));
    else
        output_txt = sprintf('%s\n%5.3f %s\n%3.3f s', ...
            name, pos(2), uY(2:end-1), pos(1));
    end
end
function export_data_tips(~, ~)
global PathName
    file = [PathName 'data_cursors.csv'];
    [FileName, PathName2, ~] = uiputfile('*.csv', 'Save Cursors', file);
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
    file = [PathName FileName(1:dot_index) '.csv']; 
    dcm_obj=datacursormode(gcf);
    cursors = dcm_obj.getCursorInfo;
    tmp = zeros(2, length(cursors));
    names = cell(length(cursors),1);
    for n = 1:1:length(cursors)
        cursor = cursors(n);
        tmp(:,n) = cursor.Position;
        names(n) = cellstr(cursor.Target.Tag);
    end
    units = cursor.Target.Parent.Parent.Parent.UserData.Units;
    [unq_names, ia, ic] = unique(names, 'sorted');
    max_count = max(hist(ic, unique(ic)));
    data = struct();
    cols = cell(1,length(ia));
    colnames = cell(size(cols));
	for n = 1:1:length(ic)
		col_id = ic(n);
		cols{col_id} = [cols{col_id}; tmp(:, n)'];
	end
	for n = 1:1:length(ia)
		data.(unq_names{n}) =  [num2cell(sortrows(cols{n}, 1)); ...
			cell(max_count-size(cols{n}, 1), 2)];
		if(strfind(unq_names{n}, '_FFT'))
			colnames(n) = {strcat(unq_names(n), {'_f[Hz]' ['_' units]})};
		else
			colnames(n) = {strcat(unq_names(n), {'_t[s]' ['_' units]})};
		end
	end
   	output_data = struct2table(data);
    output_data(2:end+1,:) = output_data; 
    output_data(1,:) = colnames;
    writetable(output_data, file, 'FileType', 'text', 'Delimiter', ',', ....
        'WriteRowNames', 0, 'WriteVariableNames', 0);
end
% Helpers
function choice = choosefixDialog(targetFc)
    choice = 'No';
    d = dialog('Units', 'normalized', 'Position', [0.4 0.7 0.1 0.1], ...
        'Name', 'Sensor Correction');
    d.Units = 'pixels';
	d.Position(3:4) = [200 120];
	text_width = 180;
	text_bottom = 60;
    WindowAPI(d, 'Button', 'off');
	uicontrol('Parent', d, 'Style', 'text', ...
		'Position', [20 text_bottom text_width d.Position(4)-text_bottom-10], 'String', ...
		['Correct sensor response to ' num2str(targetFc) 'Hz'], ...
        'FontSize', 14, 'KeyPressFcn', @keypressCB);
    start_position = [20 20];
    next_size = [80 30];
    yb = uicontrol('Parent', d, 'Position', [start_position next_size], ...
        'Callback', @makechoice, 'KeyPressFcn', @keypressCB, 'String', 'Yes');
    start_position(1) = start_position(1) + next_size(1) + 5;
    next_size = [80 30];
    uicontrol('Parent', d, 'Position', [start_position next_size], ...
        'Callback', @makechoice, 'KeyPressFcn', @keypressCB, 'Tag', 'No', 'String', 'No');
	uicontrol(yb);
    WindowAPI(d, 'TopMost');
    uiwait(d);
	function keypressCB(hObject, eventData)
		if(~(strcmp(eventData.Key, 'return')||strcmp(eventData.Key, ' ')))
			return;
		end
		makechoice(hObject);
	end
    function makechoice(button, ~)
        choice = button.String;
        delete(button.Parent);
    end
end
function [executableFolder] = GetExecutableFolder() 
	try
		if isdeployed 
			% User is running an executable in standalone mode. 
			[~, result] = system('set PATH');
			executableFolder = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
		else
			% User is running an m-file from the MATLAB integrated development environment (regular MATLAB).
			executableFolder = mfilename('fullpath');
            tmp = strfind(executableFolder, '\');
            executableFolder = executableFolder(1:tmp(end)-1);
		end 
	catch ME
		errorMessage = sprintf('Error in function %s() at line %d.\n\nError Message:\n%s', ...
			ME.stack(1).name, ME.stack(1).line, ME.message);
		uiwait(warndlg(errorMessage));
	end
	return;
end
function ret = isTableCol(table, column_name)
	ret = ismember(column_name, table.Properties.VariableNames);
end
%end