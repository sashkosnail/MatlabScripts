%process PITA data
function ProcessDynaMate_Vpp
    global window_size Fs PathName num_sensors signal_length
    close all
    %prompt for input files
    if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<OR2>
            PathName = ''; end
    [FileName, PathName, ~] = uigetfile([PathName, '*.mat'], 'Pick File');
    if(~iscell(FileName))
        FileName = {FileName}; end
    if(FileName{1} == 0)
        return; end
    %PARAMETERS
    if(~exist('window_size','var')||isempty(window_size));
        window_size = 1024;
    end
    %process file
    disp('==============================================================');
    disp(FileName)
    %load data
    DATA = load([PathName FileName{1}]);
    if(istable(DATA.D))
        data = table2array(DATA.D(:,2:end));
        t = table2array(DATA.D(:,1));
    else
        data = DATA.D(:,2:end);
        t=DATA.D(:,1);
    end
    Ts = t(2)-t(1); Fs = 1.0/Ts;
    num_sensors = size(data,2)/3;
    signal_length = length(t);
    %Create figure and plot window data
    fig = figure('Name', FileName{1}(1:end-4), 'Menubar', 'figure'); clf
    set(fig, 'Position', get(0,'Screensize')); % Maximize figure
    full_plot = subplot('Position', [0 0.87 1 0.09]);
    time_slider = uicontrol('Parent', fig, 'Style', 'slider', ...
        'Value', 0, 'Min', 0, 'Max', signal_length-window_size, ...
        'Units', 'normalized', 'Position', [0 0.98 0.85 0.02], ...
        'SliderStep', [0.001 0.001], 'UserData', signal_length, ...
        'Callback', {@slider_moved_callback, data});
    time_tb = uicontrol('Parent', fig, 'Style', 'edit', ...
        'Units', 'normalized', 'Position', [0.9 0.98 0.05 0.02], ...
        'KeyReleaseFcn', {@time_tb_callback, data}, ...
        'UserData', time_slider);
    window_size_tb = uicontrol('Parent', fig, 'Style', 'edit', ...
        'Units', 'normalized', 'Position', [0.85 0.98 0.05 0.02], ...
        'KeyReleaseFcn', {@window_size_tb_callback, data}, ...
        'UserData', time_slider, 'String', num2str(window_size)); %#ok<NASGU>
    save_button = uicontrol('Parent', fig, 'Style', 'pushbutton', ...
        'Units', 'normalized', 'Position', [0.95 0.98 0.05 0.02], ...
        'Callback', {@savebutton_callback, data}, ...
        'UserData', time_tb, 'String', 'Save Data'); %#ok<NASGU>
    set(time_slider, 'UserData', ...
        struct('Plot', full_plot, 'VertBars', [], 'TimeTB', time_tb));
    plot(t, data, 'ButtonDownFcn', {@full_plot_callback, data}, ...
        'UserData', time_slider);
    grid on; hold on; axis tight
    set(gca, 'Color', 'w', 'GridColor', 'k', ...
        'XAxisLocation', 'top');
    %trigger drawing callback
    slider_moved_callback(time_slider, 0, data);
end

function full_plot_callback(hObject, eventData, data)
    global Fs window_size
    time_slider = hObject.UserData;
    val = Fs*eventData.IntersectionPoint(1) - window_size/2;
    val = max(0, val);
    val = min(time_slider.Max, val);
    time_slider.Value = val;
    slider_moved_callback(time_slider, 0, data);
end

function time_tb_callback(hObject, eventData, data)
    time_slider = hObject.UserData;
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
    slider_moved_callback(time_slider, 0, data);
end

function window_size_tb_callback(hObject, eventData, data)
    global window_size signal_length
    
    time_slider = hObject.UserData;
    if(~strcmp(eventData.Key, 'return'))
        return;
    end
    val = str2double(hObject.String);
    if(isnan(val))
        return
    end
    window_size = val;
    time_slider.Max = signal_length - window_size;
    time_slider.Value = min(time_slider.Value, time_slider.Max);
    slider_moved_callback(time_slider, 0, data);
end

function slider_moved_callback(hObject, ~, data)
    global window_size Fs num_sensors
    texts = {'X','Y','Z'};
    time_slider = hObject;
    time_slider.Value = floor(time_slider.Value);
    vert_bars = hObject.UserData.VertBars;
    full_plot = hObject.UserData.Plot;
    hObject.UserData.TimeTB.String = num2str(time_slider.Value);
    %get data subset
    N = window_size;
    window_data_id = (1:1:N)+floor(time_slider.Value);
    t=window_data_id/Fs;
    window_data = data(window_data_id,:);
    %establish and draw window
    vert_bars_t = [t(1) t(end); t(1) t(end)];
    vert_bars_h = [min(min(data)) min(min(data)); 
        max(max(data)) max(max(data))];
    delete(vert_bars)
    vert_bars = plot(vert_bars_t, vert_bars_h, 'Parent', full_plot, ...
        'Color', 'r', 'LineWidth', 2, 'LineStyle','--');
    time_slider.UserData.VertBars = vert_bars;
    %obtain spectrum
    fftdata = abs(fft(window_data.*repmat(hamming(N), 1, size(data,2)), ...
        N, 1)/(N-1));
    fftdata = abs(fftdata(ceil(1:N/2),:));
    fftdata(2:end-1,:) = 2*fftdata(2:end-1,:);
    fftdata_filt = filtfilt(ones(1,5),1,fftdata);
    f = Fs*(1:N/2)'/N;
    fft_range = max(max(abs(fftdata_filt)));
    data_range = [-1 1].*max(max(abs(window_data)));
    text_locations = [0.75 0 -0.75]*data_range(2)*.75;
    peak_data = find_Vpp_window(window_data);
    VppTable = zeros(1, 24);
    plot_vert_size = 0.91/num_sensors*.9;
    for idx = 0:1:num_sensors - 1
        data_id = ((num_sensors -1 - idx)*3 + 1):((num_sensors - idx)*3);
        subplot('Position',[0.015, plot_vert_size*idx+0.05, 0.81, plot_vert_size], ...
        'Xgrid', 'off', 'Ygrid', 'off', 'Color', 'w');
        plot(t,window_data(:,data_id), 'LineWidth', 1);
        grid on; hold on
        set(gca, 'Color', 'w', 'GridColor', 'k', ...
            'XAxisLocation', 'bottom');
        ax = gca;
        if(idx==0)
            ax.XAxis.Visible = 'on';
            lbl=xlabel('Time[s]');
            set(lbl, 'Units', 'normalized','Position',[0.5 0.2 0]);
        else
            ax.XAxis.Visible = 'off';
        end
%         axis([t(1) t(end) data_range])
        xlim([t(1) t(end)]);
        colors = [217 83 25; 0 114 189; 237 177 32]./255;
        for comp_id = 1:1:3
            idc = (num_sensors - 1 - idx)*3+comp_id;
            mVpp_idx = peak_data(idc,:);
            maxVpp = sum(abs(window_data(mVpp_idx,idc)));
            VppTable(idc) = maxVpp;
            plot(t(mVpp_idx), window_data(mVpp_idx, idc), 'LineStyle', 'none', ...
                'Marker','d','MarkerFaceColor', colors(comp_id,:))
            text(t(10), text_locations(comp_id), ...
                ['Vpp[', texts{comp_id},'][mm/s]=', num2str(maxVpp,'%5.3f')], ...
                'Color', 'k', 'BackgroundColor',[0.9 0.9 0.9]);
        end
        hold off
        
        subplot('Position',[0.85, plot_vert_size*idx+0.05, 0.145, plot_vert_size], ...
        'Xgrid', 'off', 'Ygrid', 'off', 'Color', 'w'); 
        loglog(f,abs(fftdata_filt(:,data_id)), 'LineWidth', 1);
        grid on; set(gca, 'Color', 'w', 'GridColor', 'k', ...
            'XAxisLocation', 'bottom');
        ax = gca;
        if(idx==0)
            ax.XAxis.Visible = 'on';
            lbl = xlabel('Frequency[Hz]');
            set(lbl, 'Units', 'normalized','Position',[0.5 0.2 0]);
        else
            ax.XAxis.Visible = 'off';
        end
        ylim([10^-3 fft_range])
        set(gca, 'YTick', [0.001 1], 'XTick',[0.1 1 10 100]);
    end
    l = legend('X','Y','Z');
    l.TextColor = 'k';
    l.Location = 'south';
end

function savebutton_callback(hObject, ~, data)
    global PathName STATS Fs
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