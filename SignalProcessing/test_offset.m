[t, data, off] = build_test_data;

%%
figure(55);clf
plot(t, [off data]);
hold on

%%
N = 101;
off = filtfilt(triang(N)/sum(triang(N)), 1, data);
plot(t, off, 'DisplayName', 'filtfilt');

%%
N = 301;
mvmean = movmean(data,triang(N));
plot(t, mvmean, 'DisplayName', 'movmean');

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