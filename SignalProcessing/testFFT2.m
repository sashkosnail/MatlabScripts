clear

d = dlmread('FFT_TestDATA.csv');
t = d(:,1);
data = d(:,2);

fftdata = fftshift(fft(data,4096));
zzz = [real(fftdata) imag(fftdata)];
dlmwrite('FFT_TestDATA_out.csv', zzz);

xxx = dlmread('FFT_TestDATAFFT.csv');
f = xxx(:,1);
yyy = xxx(:,2:end);

figure(875); clf
subplot(2,1,1)
plot(zzz, 'LineWidth', 2); hold on;
plot(yyy, 'LineWidth', 0.5)
subplot(2,1,2)
plot(abs(fftdata), 'LineWidth', 2, 'Color', 'k'); hold on
plot(abs(yyy(:,1)+1i*yyy(:,2)), 'LineWidth', 0.5, 'Color', 'r');