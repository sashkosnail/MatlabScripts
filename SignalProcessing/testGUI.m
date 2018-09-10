
function testGUI
%%
    close all
    global OUTPUT
    fig = figure(1);
    maxsize = [1200 700];
    figszfun = @(h,~) set(h, 'position', max([0 0 maxsize], h.Position));
    set(fig, 'NumberTitle', 'off', ...
        'Name', ['DYNAMate Process ' version], 'MenuBar', 'none', ...
        'Position', [0 0 maxsize], 'SizeChangedFcn', figszfun);
    pause(0.00001);
    WindowAPI(fig, 'Maximize');

    tab_group = uitabgroup('Parent', fig, 'Units', 'normalized', ...
        'Position', [0 0, 1, 1], 'SelectionChangedFcn', @tab_changed_callback);
    tab = uitab('Parent', tab_group, 'Title', 'TEST', ...
        'Units', 'pixels');

    num_sensors = OUTPUT.Data{1}.Nsensors;

    %create UI controls
    start_position = [20 2];

    next_size = [100 35];
    data_type_pd = uicontrol('Parent', tab, 'Style', 'popupmenu',...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'FontSize', 8, 'FontWeight', 'bold', ...
        'Value', 2, 'String', {'Acceleration', 'Velocity', 'Displacement'}, ...
        'Callback', @data_type_pd_callback); %#ok<NASGU>
    start_position(1) = start_position(1) + next_size(1) + 10;

    next_size = [80 40];
    save_button = uicontrol('Parent', tab, 'Style', 'pushbutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @save_data_button_callback, 'String', 'Save Data', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Tag', 'data'); %#ok<NASGU>
    start_position(1) = start_position(1) + next_size(1) + 5;

    next_size = [80 40];
    save_button = uicontrol('Parent', tab, 'Style', 'pushbutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @save_image_button_callback, 'String', 'Save Image', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Tag', 'image'); %#ok<NASGU>
    start_position(1) = start_position(1) + next_size(1) + 5;

    next_size = [80 40];
    zoom_button = uicontrol('Parent', tab, 'Style', 'togglebutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @zoom_button_callback, 'String', 'Zoom', ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'ToolTip', 'Hold SHIFT for Zooming out'); 
    start_position(1) = start_position(1) + next_size(1) + 5;

    next_size = [80 40];
    pan_button = uicontrol('Parent', tab, 'Style', 'togglebutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @pan_button_callback, 'String', 'Pan', ...
        'FontSize', 10, 'FontWeight', 'bold'); 
    start_position(1) = start_position(1) + next_size(1) + 5;

    next_size = [80 40];
    datatip_button = uicontrol('Parent', tab, 'Style', 'togglebutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @datatip_button_callback, 'String', 'Data Tip', ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'ToolTip', 'Hold SHIFT to add more then one'); 
    start_position(1) = start_position(1) + next_size(1) + 10;

    next_size = [80 40];
    exit_button = uicontrol('Parent', tab, 'Style', 'pushbutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @exit_button_callback, 'String', 'Exit', ...
        'FontSize', 10, 'FontWeight', 'bold'); %#ok<NASGU>
    start_position(1) = start_position(1) + next_size(1) + 10;

    zoom_button.UserData = [pan_button datatip_button];
    pan_button.UserData = [zoom_button datatip_button];
    datatip_button.UserData = [pan_button zoom_button];

    overview_text = uitable('Parent', tab);
    overview_text.Data = table2cell(OUTPUT.Data{1}.ConfigTable(:,2:end));
    overview_text.ColumnName = ...
        OUTPUT.Data{1}.ConfigTable.Properties.VariableNames(2:end);
    column_widths = [50, 50, 30, 60, 40, 20, 40, 40, 40, 40, 40, 40, 40];
    overview_text.ColumnWidth = num2cell(column_widths);
    next_size = [sum(column_widths)+2 40];
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
    tab.SizeChangedFcn = @tabszfun;
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
    tab.UserData = struct('Units', '[mm/s]', 'DataIDX', 1, ...
        'AccVelDisp', 2, 'ChannelAxis', ch_axis, 'Panel', axis_panel);
    drawnow()
    panel_szChange(axis_panel);
end

function tabszfun(hObject,~) 
    panelH = 42;
    set(hObject.UserData.Panel, ...
        'position', [0 panelH hObject.Position(3) hObject.Position(4)-panelH]);
end

function panel_szChange(hObject, ~)
global OUTPUT
    num_sensors = OUTPUT.Data{1}.Nsensors;
    parent_size = hObject.Position;
    ch_axis = hObject.UserData;

    plotL = ch_axis.Spacing(1);
    plotHsig = floor(0.7*parent_size(3));
    plotHfft = parent_size(3) - 2*plotL - plotHsig -5;

    plotV = parent_size(4) - ch_axis.Spacing(2) - 5;
    plotB = 40 + rem(plotV, num_sensors);
    plotV = floor(plotV/num_sensors);
    
    for id = 0:1:num_sensors - 1
    ch_axis.SignalAxis(id+1).Position = ...
                    [plotL, plotV*id+plotB, plotHsig, plotV];
    ch_axis.SpectrumAxis(id+1).Position = ...
                    [2*plotL+plotHsig, plotV*id+plotB, plotHfft, plotV];
    end
end