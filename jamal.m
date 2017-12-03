    if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<OR2>
            PathName = ''; end
    [FileName, PathName, ~] = uigetfile([PathName, '*.at2'], 'Pick File');
    if(~iscell(FileName))
        FileName = {FileName}; end
    if(FileName{1} == 0)
        return; end
    
    [data, Ts, npts] = readPEER(PathName, FileName{1});
    t=(0:1:length(data)-1)*Ts;
    
    Fs = 1/Ts;
    [num, den] = butter(4, 100*2/Fs, 'low');
    fdata = filtfilt(num, den, data);
    
    figure(99); clf
    subplot(2,1,1)
    plot(t,data,'b'); hold on
    plot(t,fdata,'r');
    
    %obtain spectrum
    N=2^nextpow2(length(data)/2);
    window = hamming(N);window = window/sum(window);
    fftdata = abs(fft(data(1:N).*window,N, 1));
    fftdata = abs(fftdata(ceil(1:N/2),:));
    fftdata(2:end-1,:) = 2*fftdata(2:end-1,:);
    fftdata_filt = filtfilt(ones(10,1)/10,1,fftdata);
    f = Fs*(1:N/2)'/N;
    fft_range = max(max(abs(fftdata)));
    
    subplot(2,1,2)
    plot(f, fftdata,'b'); hold on
    plot(f, fftdata_filt, 'r')
    axis([0 15 10e-6 fft_range]);
    