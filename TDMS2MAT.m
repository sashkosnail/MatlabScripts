close all

if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<OR2>
        PathName = ''; end
[FileName, PathName, ~] = uigetfile([PathName, '*.tdms'],'Pick File','MultiSelect','on');
if(~iscell(FileName))
    FileName = {FileName}; end
if(FileName{1} == 0)
    return; end
% stats = cell(length(FileName), 5); %mean std Vpp Vpp10Hz Vpp1Hz
clear Results
Results(length(FileName)) = struct();

for idx = 1:1:length(FileName)
    D = TDMS_getStruct([PathName FileName{idx}],5);
    mat_file = [PathName FileName{idx}(1:end-4) 'mat'];
    save(mat_file, 'D');
    Nch = size(D,2)-1;
    
    t=D.Time;
    Ts = t(2)-t(1);
    Fs = 1.0/Ts;
    data = D{:,2:end};
    
    Results(idx).Name = FileName{idx};
    Results(idx).Data = D;
    Results(idx).Stats = array2table([mean(data); std(data); range(data)]);
    Results(idx).Stats.Properties.RowNames = {'offset', 'RMS', 'Vpp'};
    Results(idx).Stats.Properties.VariableNames = D.Properties.VariableNames(2:end);
    
    fig = figure('Name', FileName{idx}); clf
    subplot(2,1,1);
    ax = plot(t,data);
    
    N = 2^(nextpow2(length(data))-1);
    data = data(1:1:N,:);
    fft_data2 = abs(fft(data.*repmat(hamming(N), 1, Nch), N, 1)/N);
    fft_data = abs(fft_data2(ceil(1:N/2),:));
    fft_data(2:end-1,:) = 2*fft_data(2:end-1,:);
    f = Fs*(1:N/2)'/N;
    subplot(2,1,2);
    loglog(f,abs(fft_data)); hold on
    loglog(f, mean(mean(fft_data))./f, 'Color', 'k','LineWidth',2); hold off
    axis([Fs/N Fs/2 10^-6 0.5])
end