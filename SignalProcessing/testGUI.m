
function testGUI
%%
close all
global OUTPUT
fig = figure(1);
set(fig, 'NumberTitle', 'off', ...
    'Name', ['DYNAMate Process ' version], 'MenuBar', 'none'); 
clf
figszfun = @(h,~) set(h, 'position', max([0 0 1280 768], h.Position));
fig.SizeChangedFcn = figszfun;
pause(0.00001);
%     set(fig, 'ToolBar', 'figure', 'Units', 'Normalized', ...
%         'OuterPosition', [0 0 1 1]);
WindowAPI(fig, 'Maximize');

tab_group = uitabgroup('Parent', fig, 'Units', 'normalized', ...
    'Position', [0 0, 1, 1], 'SelectionChangedFcn', @tab_changed_callback);
tab = uitab('Parent', tab_group, 'Title', OUTPUT.Data{1}.FileName, ...
    'Units', 'pixels');

num_sensors = OUTPUT.Data{1}.Nsensors;
%create parameters
smoothN = 256;

%create UI controls
%%
start_position = [20 2];

next_size = [130 35];
data_type_pd = uicontrol('Parent', tab, 'Style', 'popupmenu',...
    'Units', 'pixels', 'Position', [start_position next_size], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'Value', 2, 'String', {'Acceleration', 'Velocity', 'Displacement'}, ...
    'Callback', @data_type_pd_callback); %#ok<NASGU>
start_position(1) = start_position(1) + next_size(1) + 20;

%%
next_size = [80 40];
save_button = uicontrol('Parent', tab, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [start_position next_size], ...
    'Callback', @save_button_callback, 'String', 'Save Data', ...
    'FontSize', 12, 'FontWeight', 'bold'); %#ok<NASGU>
start_position(1) = start_position(1) + next_size(1) + 5;
%%
next_size = [80 40];
zoomin_button = uicontrol('Parent', tab, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [start_position next_size], ...
    'Callback', @zoomin_button_callback, 'String', 'Zoom IN', ...
    'FontSize', 12, 'FontWeight', 'bold'); %#ok<NASGU>
start_position(1) = start_position(1) + next_size(1) + 5;
%%
next_size = [80 40];
zoomout_button = uicontrol('Parent', tab, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [start_position next_size], ...
    'Callback', @zoomout_button_callback, 'String', 'Zoom OUT', ...
    'FontSize', 12, 'FontWeight', 'bold'); %#ok<NASGU>
start_position(1) = start_position(1) + next_size(1) + 5;
%%
next_size = [80 40];
pan_button = uicontrol('Parent', tab, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [start_position next_size], ...
    'Callback', @pan_button_callback, 'String', 'Pan', ...
    'FontSize', 12, 'FontWeight', 'bold'); %#ok<NASGU>
start_position(1) = start_position(1) + next_size(1) + 5;
%%
next_size = [80 40];
datatip_button = uicontrol('Parent', tab, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [start_position next_size], ...
    'Callback', @datatip_button_callback, 'String', 'Data Tip', ...
    'FontSize', 12, 'FontWeight', 'bold'); %#ok<NASGU>
start_position(1) = start_position(1) + next_size(1) + 5;

%%
next_size = [100 35];
smoothN_text = uicontrol('Parent', tab, 'Style', 'text', ...
    'Units', 'pixels', 'Position', [start_position next_size], ...
    'String', 'FFT Smoohting Degree:', 'FontSize', 8, 'FontWeight', ...
    'bold', 'HorizontalAlignment', 'right'); %#ok<NASGU>
start_position(1) = start_position(1) + next_size(1) + 5;

next_size = [60 40];
smoothN_tb = uicontrol('Parent', tab, 'Style', 'edit', ...
    'Units', 'pixels', 'Position', [start_position next_size], ...
    'KeyReleaseFcn', @smoothN_tb_callback, 'String', num2str(smoothN), ...
    'FontSize', 12, 'FontWeight', 'bold'); %#ok<NASGU>
start_position(1) = start_position(1) + next_size(1) + 20;

%% table
next_size = [462 40];
overview_text = uitable('Parent', tab);
overview_text.Data = table2cell(OUTPUT.Data{1}.ConfigTable(:,2:end));
overview_text.ColumnName = OUTPUT.Data{1}.ConfigTable.Properties.VariableNames(2:end);
overview_text.ColumnWidth = {70, 60, 30, 60, 50, 50, 40, 40, 60};
overview_text.Units = 'pixels';
overview_text.Position = [start_position next_size];
overview_text.RowName = [];

%% Plot Panel
parent_size = tab.Position;
panel_elev = 42;
axis_panel = uipanel('Parent', tab, 'Units', 'pixels', ...
    'Backgroundcolor', [0 1 0], 'BorderWidth', 0, 'BorderType', 'none', ...
    'Position', [0 panel_elev parent_size(3) parent_size(4) - panel_elev]);
tab.UserData.Panel = axis_panel;
tabszfun = @(h,~) set(h.UserData.Panel, ...
    'position', [0 panel_elev h.Position(3) h.Position(4)-panel_elev]);
tab.SizeChangedFcn = tabszfun;
drawnow()
%% create axis
parent_size = axis_panel.Position;
ch_axis.Spacing = [50 40];

plotL = ch_axis.Spacing(1);
plotHsig = floor(0.7*parent_size(3));
plotHfft = parent_size(3) - 2*plotL - plotHsig -5;

plotV = parent_size(4) - ch_axis.Spacing(2) - 5;
plotB = 40 + rem(plotV, num_sensors);
plotV = floor(plotV/num_sensors);

for id = 0:1:num_sensors - 1
    ch_axis.SignalAxis(id+1) = subplot('Position', [0 0 0 0], ...
        'Units', 'pixels', 'Parent', axis_panel, 'Xgrid', 'on', ...
        'Ygrid', 'on', 'Color', 'w');
    ch_axis.SignalAxis(id+1).Position = ...
                    [plotL, plotV*id+plotB, plotHsig, plotV];
    xlabel('Label'); ylabel('Label');
    ch_axis.SpectrumAxis(id+1) = subplot('Position', [0 0 0 0], ...
        'Units', 'pixels', 'Parent', axis_panel, 'Xgrid', 'on', ...
        'Ygrid', 'on', 'Color', 'w');
    ch_axis.SpectrumAxis(id+1).Position = ...
                    [2*plotL+plotHsig, plotV*id+plotB, plotHfft, plotV];
    xlabel('Label'); ylabel('Label');
end
linkaxes(ch_axis.SignalAxis);
linkaxes(ch_axis.SpectrumAxis);
axis_panel.SizeChangedFcn = @panel_szChange;

axis_panel.UserData = ch_axis;
drawnow()
panel_szChange(axis_panel);
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