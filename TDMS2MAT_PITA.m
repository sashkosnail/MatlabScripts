% close all

if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<OR2>
        PathName = ''; end
[FileName, PathName, ~] = uigetfile([PathName, '*.tdms'],'Pick File','MultiSelect','on');
if(~iscell(FileName))
    FileName = {FileName}; end
if(FileName{1} == 0)
    return; 
end
clear Results

for idx = 1:1:length(FileName)
    disp('===============================================================');
    disp(FileName{idx})
    D = TDMS_getStruct([PathName FileName{idx}],5);
    %correct orientation 
    %foundation_test | Ch8 rotated 90deg | Ch7 rotated 180deg |
%     D{:,:} = [D{:,1:19} -D{:,'x7'} -D{:,'y7'} D{:,'z7'} ...
%             -D{:,'y8'} -D{:,'x8'} D{:,'z8'} D{:,26:end}];
    %attenuation_test1 | machine stopped noise only
%     none
    %attenuation_test2/3 | Ch3 rotated 90deg |
%     D{:,{'x3','y3'}} = [D{:,'y3'} -D{:,'x3'}];
    %attenuation_test4 | Ch1 rotated 90 deg
%     D{:,{'x1','y1'}} = [D{:,'y1'} -D{:,'x1'}];
    %attenuation_test5
%     none
    %attenuation_test6
%     none
    %attenuation_test7
%     none    
    t=D.Time;
    Ts = t(2)-t(1);
    Fs = 1.0/Ts;
    data = D{:,2:end};
    
    data_range = [-1 1].*max(max(abs(data)));
    
    %remove amp and filter chans
    Nch = size(D,2)-3;
    data = data(:,1:end-2);
    t=t(1:length(data));
    
    filter_cutoff = 10;
    [fnum, fden] = butter(4, filter_cutoff*2/Fs, 'low');
    fdata_10Hz = filtfilt(fnum, fden, data);
    filter_cutoff = 1;
    [fnum, fden] = butter(4, filter_cutoff*2/Fs, 'low');
    fdata_1Hz = filtfilt(fnum, fden, data);
    
    Results.Name = FileName{idx};
    Results.Stats = array2table(1000*[mean(data); std(data); range(data); range(fdata_10Hz(end/2:end,:)); range(fdata_1Hz(end/2:end,:))]);
    Results.Stats.Properties.RowNames = {'offset', 'RMS', 'Vpp', 'Vpp_10Hz', 'Vpp_1Hz'};
    Results.Stats.Properties.VariableNames = D.Properties.VariableNames(2:end-2);
    
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
    
    save_data = ''; %#ok<NASGU>
    save_data = input('Save Data Y/N [N]:','s');
    if isempty(save_data)
        save_data = 'N'  %#ok<NOPTS>
    end
    if(~strcmp(save_data,'N'))
        mat_file = [PathName FileName{idx}(1:end-5) '.mat'];
        save(mat_file, 'D', 'Results');
        tab_file = [PathName FileName{idx}(1:end-5) '.csv'];
        writetable(Results.Stats, tab_file, 'WriteRowNames',true);
        tab_file = [PathName FileName{idx}(1:end-5) '_data.csv'];
        writetable(D, tab_file);
    end
end