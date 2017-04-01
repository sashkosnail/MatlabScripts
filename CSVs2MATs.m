close all

if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<OR2>
        PathName = ''; end
[FileName, PathName, ~] = uigetfile([PathName, '*.csv'],'Pick File','MultiSelect','on');
if(~iscell(FileName))
    FileName = {FileName}; end
if(FileName{1} == 0)
    return; end
for idx = 1:1:length(FileName)
    D = csvread([PathName FileName{idx}]);
    mat_file = [PathName FileName{idx}(1:end-4) '.mat'];
    save(mat_file, 'D');
    Nch = size(D,2)-1;
    
    t=D(:,1);
    Ts = t(2)-t(1);
    Fs = 1.0/Ts;
    data = D(:,2:end);
    
    fig = figure('Name', FileName{idx}); clf
    subplot(2,1,1);
    ax = plot(t,data);
    
    N = 2^nextpow2(length(data)-1);
    fft_data2 = abs(fft(data.*repmat(hamming(N), 1, Nch), N, 1)/N);
    fft_data = abs(fft_data2(ceil(1:N/2),:));
    fft_data(2:end-1,:) = 2*fft_data(2:end-1,:);
    f = Fs*(1:N/2)'/N;
    subplot(2,1,2);
    loglog(f,abs(fft_data)); hold on
    loglog(f, mean(mean(fft_data))./f, 'Color', 'k','LineWidth',2); hold off
    axis([Fs/N Fs/2 10^-6 0.5])
end