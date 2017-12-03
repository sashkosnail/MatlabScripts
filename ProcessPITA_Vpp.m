%process PITA data
function ProcessPITA_Vpp
    global window_size Fs PathName filt_selected STATS sensor_distance cutoffs
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
    Ndecimation = 4;
    sensor_distance = 5.5;
%     sensor_distance = [11+(0:3)*sensor_distance 32+(0:3)*sensor_distance];
%     sensor_distance = 11+(0:1:7)*sensor_distance;
%     sensor_distance = [0 22+(0:1:6)*sensor_distance];
%     sensor_distance = [0 22 37.5 42+(0:1:4)*sensor_distance]; 
    sensor_distance = [(0:5)*sensor_distance 32+(0:1)*sensor_distance];
    cutoffs = [5 10 20 50 100];
    %process file
    disp('==============================================================');
    disp(FileName)
    %load data
    DATA = load([PathName FileName{1}]);
    t=DATA.D(:,1);
    Ts = t(2)-t(1); Fs = 1.0/Ts;
    data = DATA.D(:,2:end);
    tmp = data(:,[4,5,6]);
%     data(:,[4,5,6]) = data(:,[7,8,9]);
%     data(:,[7,8,9]) = tmp;
    %BANDPASS FILTERS
    filter_bank = generate_filters();
%     cutoffs=1;filter_bank = filter_bank(1);
    %Extract confguration information
    FILTERS = [32,64,128];
    SCALES_STR = {'0.1mm/s', 'Calibration', '100mm/s', '10mm/s', '1mm/s'};
    SCALE_MULT = [0.01, 10, 10, 1, 0.1];
    scale_selected = round(mean(data(:,end-1)))+1;
    filt_selected = FILTERS(round(mean(data(:,end)))-1);
%     filt_selected = 1;
    disp(['Filter Selected: ', num2str(filt_selected), ...
        'Hz || Scale Selected: ', SCALES_STR{scale_selected}])
    %remove amp and decimate channels from data matrix
    data = data(:,1:end-2);
    dec_filter = triang(5); dec_filter = dec_filter/sum(dec_filter);
    data = filtfilt(dec_filter,1,data);
    Fs=Fs/Ndecimation;
    data = data(1:Ndecimation:end,:);
    %phase shift
    Vs = 390;
    allchop = ceil((sensor_distance(end)-sensor_distance(1))/Vs*Fs);
    DD(:,[1 2 3]) = data(1:(end-allchop),[1, 2, 3]);
    for i = 2:1:8
        dd = sensor_distance(i)-sensor_distance(1);
        chop = ceil(dd/Vs*Fs);
        data_id = ((i-1)*3+1):(i*3);
        DD(:,data_id) = data(chop:(end-allchop+chop-1),data_id);
    end
    data=DD;
    %remove offsets and scale data to mm/s
    offsets = mean(data);
    data = (data-ones(length(data),1)*offsets).*SCALE_MULT(scale_selected);
    %filter data
    filter_cutoff = filt_selected;
    [fnum, fden] = butter(8, filter_cutoff*2/Fs, 'low');
%     data = filtfilt(fnum, fden, data);
    %begin stats table
    STATS = array2table([mean(data); std(data); range(data); ...
        zeros(length(filter_bank), size(data,2))]);
    filt_names = cell(1,length(filter_bank));
    for fn = 1:1:length(filter_bank)
        filt_names{fn} = ['Vpp_', filter_bank(fn).Value];
    end
    STATS.Properties.RowNames = {'offset', 'RMS', 'Range', filt_names{1:end}};
    STATS.Properties.VariableNames = DATA.D.Properties.VariableNames(2:end-2);
    STATS.Properties.Description = FileName{1};

    for filt = filter_bank
        %apply filter from bank
        if(filt.Num~=1)
            fdata = filtfilt(filt.Num, filt.Den, data);
            fdata = fdata(ceil(Fs*1):1:end,:);
        else
            fdata=data(Fs:1:end,:);
        end
        t=((1:1:length(fdata))-1)/Fs;
        %Create figure and plot window data
        fig = figure('Name', [filt.Value, ' - ', FileName{1}(1:end-4)] ...
            , 'Menubar', 'none', 'UserData', filt.Value); clf
        set(fig, 'Position', get(0,'Screensize')); % Maximize figure
        full_plot = subplot('Position', [0 0.87 1 0.09]);
        time_slider = uicontrol('Parent', fig, 'Style', 'slider', ...
            'Value', 0, 'Min', 0, 'Max', length(t)-window_size, ...
            'Units', 'normalized', 'Position', [0 0.98 0.9 0.02], ...
            'SliderStep', [0.001 0.001], ...
            'Callback', {@slider_moved_callback, fdata});
        time_tb = uicontrol('Parent', fig, 'Style', 'edit', ...
            'Units', 'normalized', 'Position', [0.9 0.98 0.05 0.02], ...
            'KeyReleaseFcn', {@time_tb_callback, fdata}, ...
            'UserData', time_slider);
        save_button = uicontrol('Parent', fig, 'Style', 'pushbutton', ...
            'Units', 'normalized', 'Position', [0.95 0.98 0.05 0.02], ...
            'Callback', {@savebutton_callback, data}, ...
            'UserData', time_tb, 'String', 'Save Data');
        set(time_slider, 'UserData', ...
            struct('Plot', full_plot, 'VertBars', [], 'TimeTB', time_tb));
        plot(t, fdata, 'ButtonDownFcn', {@full_plot_callback, fdata}, ...
            'UserData', time_slider);
        grid on; hold on; axis tight
        set(gca, 'Color', 'w', 'GridColor', 'k', ...
            'XAxisLocation', 'top');
        %trigger drawing callback
        slider_moved_callback(time_slider, 0, fdata);
    end
end

function plot_curves()
    global STATS sensor_distance
    persistent fig
    RMS = table2array(STATS('RMS',:));
    RMS = RMS/RMS(1);
    Range = table2array(STATS('Vpp_20Hz',:));
    if(isempty(fig)||~isvalid(fig))
        fig = figure('Name', ['RMS|RANGE', STATS.Properties.Description]);
    end
    figure(fig); clf
%     figure(150); clf
%     subplot(2,1,1)
%     semilogy(sensor_distance, RMS(1:3:end), 'b'); hold on
%     semilogy(sensor_distance, RMS(2:3:end), 'r');
%     semilogy(sensor_distance, RMS(3:3:end), 'Color', [.929 .694 .125]);
%     title('RMS')
%     subplot(2,1,2)
    plot(sensor_distance, Range(1:3:end), 'b'); hold on
    plot(sensor_distance, Range(2:3:end), 'r');
    plot(sensor_distance, Range(3:3:end), 'Color', [.929 .694 .125]);
    xlabel('Distance From Source[m]');
    ylabel('Max Vpp[mm/s]');
    legend('X','Y','Z');
end

function plot_Vpp_surface()
    global sensor_distance STATS cutoffs
    VPPx = table2array(STATS(5:end,1:3:end))';
    VPPy = table2array(STATS(5:end,2:3:end))';
    VPPz = table2array(STATS(5:end,3:3:end))';
    if(isempty(VPPx))
     return;
    end
    for n=1:1:length(cutoffs)
     VPPx(:,n) = (VPPx(:,n)/VPPx(1,n));
     VPPy(:,n) = (VPPy(:,n)/VPPy(1,n));
     VPPz(:,n) = (VPPz(:,n)/VPPz(1,n));
    end
    figure(100); clf
    set(gcf, 'Name', ['VPP', STATS.Properties.Description]);
    subplot(1,3,1)
    surface(cutoffs, sensor_distance, VPPx)
    title('X'); view([120 30]); grid on
    ylabel('Distance[m]');
    xlabel('Frequency[Hz]');
    subplot(1,3,2)
    surface(cutoffs, sensor_distance, VPPy)
    title('Y'); view([120 30]); grid on
    ylabel('Distance[m]');
    xlabel('Frequency[Hz]');
    subplot(1,3,3)
    surface(cutoffs, sensor_distance, VPPz)
    title('Z'); view([120 30]); grid on
    ylabel('Distance[m]');
    xlabel('Frequency[Hz]');
end

function filter_bank = generate_filters()
    global Fs cutoffs
    filter_bank(1) = struct('Value', 'FullBW', 'Num', 1, 'Den',[]);
    [fnum, fden] = butter(4, cutoffs(1)*2/Fs, 'low');
    filter_bank(2) = struct('Value', [num2str(cutoffs(1)), 'Hz'], ...
        'Num', fnum, 'Den', fden);
    for c = 1:1:length(cutoffs)-2
        [fnum, fden] = butter(4, [cutoffs(c) cutoffs(c+1)]*2/Fs);
        filter_bank(end+1) = struct('Value', ...
            [num2str(cutoffs(c+1)), 'Hz'], 'Num', fnum, 'Den', fden);
    end    
    [fnum, fden] = butter(4, cutoffs(end-1)*2/Fs,'high');
    filter_bank(end+1) = struct('Value','128Hz', 'Num', fnum, 'Den', fden);
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
    time_slider.Value = val;
    slider_moved_callback(time_slider, 0, data);
end
function slider_moved_callback(hObject, ~, data)
    global window_size filt_selected Fs STATS sensor_distances
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
    peak_data = find_Vpp_window(window_data, sensor_distances, Fs);
    VppTable = zeros(1, 24);
    for idx = 0:1:7
        data_id = ((7-idx)*3+1):((8-idx)*3);
        subplot('Position',[0.015, 0.1055*idx+0.025, 0.81, 0.1055], ...
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
        axis([t(1) t(end) data_range])
        for comp_id = 1:1:3
            idc = (7-idx)*3+comp_id;
            mVpp_idx = peak_data(idc,:);
            maxVpp = sum(abs(window_data(mVpp_idx,idc)));
            VppTable(idc) = maxVpp;
%             plot(t(mVpp_idx), window_data(mVpp_idx, idc), 'kd')
            text(t(10), text_locations(comp_id), ...
                ['Vpp[', texts{comp_id},'][mm/s]=', num2str(maxVpp,'%5.3f')], ...
                'Color', 'k', 'BackgroundColor',[0.9 0.9 0.9]);
        end
        hold off
        
        subplot('Position',[0.85, 0.1055*idx+0.025, 0.145, 0.1055], ...
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
        axis([f(1) filt_selected(end) 10^-3 fft_range])
        set(gca, 'YTick', [0.001 1], 'XTick',[0.1 1 10 100]);
    end
    l = legend('X','Y','Z');
    l.TextColor = 'k';
    l.Location = 'south';
    %update Stats Table
    row_name = ['Vpp_', time_slider.Parent.UserData];
    VppTable = array2table(VppTable);
    eval(['STATS(''', row_name, ''', :)=VppTable;']);
    disp(STATS.Properties.Description)
    disp(STATS)
    plot_Vpp_surface();
    plot_curves();
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