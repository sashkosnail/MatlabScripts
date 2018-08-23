Fs = 1/(t(2)-t(1));
N = length(data1);
fftdata = real(fft(data1));
f = (1:N)*Fs/N;

figure(3);clf
plot(f,fftdata);