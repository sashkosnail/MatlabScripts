%process PITA data
function ProcessPITA
    global window_size Fs PathName filt_selected
    % close all
    %prompt for input files
    if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<NODEF,OR2>
            PathName = ''; end
    [FileName, PathName, ~] = uigetfile([PathName, '*.mat'], 'Pick File', ...
        'MultiSelect','on');
    if(~iscell(FileName))
        FileName = {FileName}; end
    if(FileName{1} == 0)
        return; end
    %PARAMETERS
    window_size = 4096;
    %process file list
    for idx = 1:1:length(FileName)
        disp('==============================================================');
        disp(FileName{idx})
        %load data
        DATA = load([PathName FileName{idx}]);
        t=DATA.D(:,1);
        Ts = t(2)-t(1); Fs = 1.0/Ts;
        data = DATA.D(:,2:end);
        %Extract confguration information
        FILTERS = [32,64,128];
        SCALES_STR = {'0.1mm/s', 'Calibration', '100mm/s', '10mm/s', '1mm/s'};
        SCALE_MULT = [0.01, 10, 10, 1, 0.1];
        scale_selected = ceil(mean(data(:,end-1))+0.5);
        filt_selected = FILTERS(ceil(mean(data(:,end))+0.5));
        disp(['Filter Selected: ', num2str(filt_selected), ...
            'Hz || Scale Selected: ', SCALES_STR{scale_selected}])
        %remove amp and filter channels from data matrix
%         data = data(:,1:end-2);
        %remove offsets and scale data to mm/s
        offsets = mean(data);
        data = (data-ones(length(data),1)*offsets).*SCALE_MULT(scale_selected);
        %filter data
        filter_cutoff = filt_selected;
        [fnum, fden] = butter(8, filter_cutoff*2/Fs, 'low');
        data = filtfilt(fnum, fden, data);
        %Create figure and plot window data
        fig = figure('Name', FileName{idx},'Menubar','none'); clf
        time_slider = uicontrol('Parent', fig, 'Style', 'slider', ...
            'Value', 0, 'Min', 0, 'Max', length(t)-window_size, ...
            'Units', 'normalized', 'Position', [0 0 1 0.02], ...
            'SliderStep', [0.001 0.001], ...
            'Callback', {@slider_moved, data});
        set(fig, 'Position', get(0,'Screensize')); % Maximize figure
        %trigger drawing callback
        slider_moved(time_slider, 0, data);
        if(length(FileName)>1)
            disp('Press any key to move to the next file...')
            pause
        end
    end
end

function slider_moved(hObject, ~, data)
    global window_size filt_selected Fs
    time_slider = hObject;
    %obtain spectrum
    N = window_size;
    window_data_id = (1:1:N)+floor(time_slider.Value);
    t=window_data_id/Fs;
    window_data = data(window_data_id,:);
    fftdata = abs(fft(window_data.*repmat(hamming(N), 1, size(data,2)), ...
        N, 1)/N);
    fftdata = abs(fftdata(ceil(1:N/2),:));
    fftdata(2:end-1,:) = 2*fftdata(2:end-1,:);
    fftdata_filt = filtfilt(ones(1,2),1,fftdata);
    f = Fs*(1:N/2)'/N;
    fft_range = max(max(abs(fftdata_filt)));
    data_range = [-1 1].*max(max(abs(window_data)));
    for idx = 0:1:1
        data_id = ((7-idx)*3+1):((8-idx)*3);
        subplot('Position',[0.01, 0.12*idx+0.05, 0.75, 0.115], ...
        'Xgrid', 'on', 'Ygrid', 'on', 'Color', 'k'); 
        plot(t,window_data(:,data_id));
        grid on; set(gca, 'Color', 'k', 'GridColor', 'w');
        axis([t(1) t(end) data_range])
        subplot('Position',[0.775, 0.12*idx+0.05, 0.225, 0.115], ...
        'Xgrid', 'on', 'Ygrid', 'on', 'Color', 'k'); 
        loglog(f,abs(fftdata_filt(:,data_id)));
        grid on; set(gca, 'Color', 'k', 'GridColor', 'w');
        axis([f(1) filt_selected 10^-5 fft_range])
    end
    l = legend('X','Y','Z');
    l.TextColor = 'w';
    l.Location = 'south';
end