N = length(data);
fftdata = abs(fft(data)./N);
fftdata = abs(fftdata(ceil(1:N/2+1),:));
fftdata(2:end-1,:) = 2*fftdata(2:end-1,:);
f = Fs*(0:N/2)'/N;