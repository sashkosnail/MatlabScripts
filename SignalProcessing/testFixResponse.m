clear; close all

% [t, data1, offset] = build_test_data();

global tmp

data = tmp.D;
t = tmp.T;

Fs = 1/(t(2)-t(1));
targetFc = 0.1;

taper_tau = 1.0;
taper = build_taper(t, taper_tau);
taper = repmat(taper, 1, size(data,2));
% data = data1 - offset;
data = (data - repmat(mean(data),length(data),1)).*taper;

[fix_data, f, correction] = FixResponse2(data, repmat(4.5,1,size(data,2)), targetFc, Fs);

cf = figure(999);
cf.Name = 'Correction Curve';
loglog(f(1:floor(length(f)/2)), correction(1:floor(length(f)/2),1), 'k');
hold on; grid on
axs = gca;
loglog(targetFc*[1 1], axs.YLim, 'r');
loglog(4.5*[1 1], axs.YLim, 'g');

in_fft = abs(fft(data));
out_fft = abs(fft(fix_data));

cf = figure(888);
cf.Name = 'Spectra';
subplot(2,1,1)
loglog(f(1:floor(length(f)/2)), in_fft(1:floor(length(f)/2),:));
grid on; hold on;
loglog(4.5*[1 1], 10.^[-5 5], 'g--');
loglog(targetFc*[1 1], 10.^[-5 5], 'r--');
title('In Spectra')
subplot(2,1,2)
loglog(f(1:floor(length(f)/2)), out_fft(1:floor(length(f)/2),:));
grid on; hold on;
loglog(4.5*[1 1], 10.^[-5 5], 'g--');
loglog(targetFc*[1 1], 10.^[-5 5], 'r--');
title('Out Spectra')


% data = (data1 - repmat(mean(data1),length(data1),1)).*taper;
% 
% figure(1);
% set(gcf, 'Name', 'Forced offset and Taper');
% subplot(3,1,1)
% fix1 = FixResponse(data, 1, 0.5, Fs);
% plot(t, [data fix1])
% title('HighPass')
% subplot(3,1,2)
% fix2 = FixResponse2(data, -1, 0.5, Fs);
% plot(t, [data fix2])
% title('LineDrop')
% subplot(3,1,3)
% plot(t, fix1-fix2);

% data = data1 -offset;
% data = (data - repmat(mean(data),length(data),1)).*taper;
% 
% figure(2);
% set(gcf, 'Name', 'no offset and Taper');
% subplot(3,1,1)
% fix1 = FixResponse(data, 1, 0.5, Fs);
% plot(t, [data fix1])
% title('HighPass')
% subplot(3,1,2)
% fix2 = FixResponse2(data, -1, 0.5, Fs);
% plot(t, [data fix2])
% title('LineDrop')
% subplot(3,1,3)
% plot(t, fix1-fix2);

% data = data1 -offset;
% 
% figure(3);
% set(gcf, 'Name', 'no offset and no Taper');
% subplot(3,1,1)
% fix1 = FixResponse(data, 1, 0.5, Fs);
% plot(t, [data fix1])
% title('HighPass')
% subplot(3,1,2)
% fix2 = FixResponse2(data, -1, 0.5, Fs);
% plot(t, [data fix2])
% title('LineDrop')
% subplot(3,1,3)
% plot(t, fix1-fix2);