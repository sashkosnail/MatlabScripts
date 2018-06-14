clear
Fs = 1000;freq = 0.01:0.01:Fs/2;

figure(111); clf;
f0s = logspace(-1, 2, 10);
for i = 1:1:length(f0s)
    f0 = f0s(i);
    func = spec_smooth(freq,f0,1,0.707);
    loglog(freq,func,'LineWidth',2);hold on
end
ax=gcs;
ax.XScale = 'log';
ax.YScale = 'log';
grid on
