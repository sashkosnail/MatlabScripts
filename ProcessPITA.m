%process PITA data
close all

if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<OR2>
        PathName = ''; end
[FileName, PathName, ~] = uigetfile([PathName, '*.mat'], 'Pick File', ...
    'MultiSelect','on');
if(~iscell(FileName))
    FileName = {FileName}; end
if(FileName{1} == 0)
    return; end

for idx = 1:1:length(FileName)
    disp('==============================================================');
    disp(FileName{idx})
    %load data
    DATA = load([PathName FileName{idx}]);
    t=DATA.D.Time;
    Ts = t(2)-t(1); Fs = 1.0/Ts;
    data = DATA.D{:,2:end};
    %Extract confguration information
    FILTERS = [32,64,128];
    SCALES_STR = {'0.1mm/s', 'Calibration', '100mm/s', '10mm/s', '1mm/s'};
    SCALE_MULT = [0.01, 10, 10, 1, 0.1];
    scale_selected = round(mean(data(:,end-1)))+1;
    filt_selected = round(mean(data(:,end)))-1;
    disp(['Filter Selected: ', num2str(FILTERS(filt_selected)), ...
        'Hz || Scale Selected: ', SCALES_STR{scale_selected}])
    %remove amp and filter chans and scale data to mm/s
    Nch = size(data,2)-2;
    data = data(:,1:end-2).*SCALE_MULT(scale_selected);
    
    %remove offsets and scale data
    offsets = mean(data);
    data = (data-ones(length(data),1)*offsets).*SCALE_MULT(scale_selected);
    data_range = [-1 1].*max(max(abs(data)));
    
    filter_cutoff = 10;
    [fnum, fden] = butter(4, filter_cutoff*2/Fs, 'low');
    fdata_10Hz = filtfilt(fnum, fden, data);
    filter_cutoff = 1;
    [fnum, fden] = butter(4, filter_cutoff*2/Fs, 'low');
    fdata_1Hz = filtfilt(fnum, fden, data);
    
    N = 2^(nextpow2(length(data))-1);
    fftdata = data(1:1:N,:);
    fftdata = abs(fft(fftdata.*repmat(hamming(N), 1, Nch), N, 1)/N);
    fftdata = abs(fftdata(ceil(1:N/2),:));
    fftdata(2:end-1,:) = 2*fftdata(2:end-1,:);
    fftdata_filt = filtfilt(ones(1,20),1,fftdata);
    f = Fs*(1:N/2)'/N;
    
    fig = figure('Name', FileName{idx}); clf
    fft_range = max(max(abs(fftdata_filt)));
    for ch_idx = 1:1:8
        data_id = ((ch_idx-1)*3+1):(ch_idx*3);
        subaxis(8,2,ch_idx*2-1);
        plot(t,data(:,data_id));
        axis([t(1) t(end) data_range])
        subaxis(8,2,ch_idx*2);
        loglog(f,abs(fftdata_filt(:,data_id)));
        axis([1 Fs/2 10^-6 fft_range])
    end
    legend('X','Y','Z')
end