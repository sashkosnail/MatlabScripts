global tmp

data = tmp.D;
t = tmp.T;

Ts = t(2)-t(1);
Fs = 1/Ts;
% 
% Nw = 0.05;
% Nf = 1*Fs;
taper_tau = 1;
% 
% Apply taper
taper = build_taper(t, taper_tau);
taper = repmat(taper, 1, size(data,2));
%         data = (data - repmat(mean(data),length(data),1)).*taper;
data = (data - repmat(mean(data),length(data),1)).*taper;
% remove trend and offset
% window = hanning(floor(Nw*length(data)));
% window = repmat(window'/sum(window),1,3);
% mvmean = movmean(data,window);
% offset = movmean(mvmean,ones(Nf,1)/Nf); 
%     offset = repmat(mean(data),length(data),1);
% data = data - offset;

%%
% figure(55);clf
% plot(t, [off data]);
% hold on

%%
N = 3*Fs;
off = filtfilt(triang(N)/sum(triang(N)), 1, data);
plot(t, off);

%%
N = 5*Fs;
off = movmean(data, rectwin(N));
plot(t, off);

%%
N = 5*Fs;
mvmean = movmean(off,rectwin(N));
plot(t, mvmean);

%%
window_size = 0.05;
window_overlap = 0.99;
threshold = 0;

Nw = length(data)*window_size;

a=offset(data, window_size, window_overlap, threshold);
plot(t(a(:,1)),a(:,2:end), 'DisplayName', 'offset');

%%
lines = ceil(1/(1-window_overlap)+1);
for n=1:1:length(a)
%     plot(t(a(n,1)+[-Nw*0.5 Nw*0.5-1]), 0.25*mod(n-1,lines)*[1 1], ...
%         'LineWidth', 2, 'LineStyle', '-', 'Color', 'black');
end