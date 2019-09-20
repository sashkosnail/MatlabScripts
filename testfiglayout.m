fig4 = figure(11111);clf
fig4.Color = 'w';
set(fig4, 'Position', [100 40 1200 950]);
for n = 1:4
	axs(n,1) = axes('Position', [0.05 (n-1)/3+0.06 0.6 1/3-0.08]);
	axs(n,2) = axes('Position', [0.7 (n-1)/3+0.06 0.28 1/3-0.08]);
	xlabel(axs(n,1), 'Time[s]')
	ylabel(axs(n,1), 'Amlplitude')
	xlabel(axs(n,2), 'Frequency[Hz]')
	ylabel(axs(n,2), 'Amlplitude')
	grid(axs(n,1), 'on');
	grid(axs(n,2), 'on');
end
set(axs, 'FontSize', 12);