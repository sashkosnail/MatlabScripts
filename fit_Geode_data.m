function data_fit = fit_sine_data(D, f, fig_name)
	fo = fitoptions('Method', 'NonLinearLeastSquares', ...
			'Lower', [0.001, 0.99*f, -1, 0], ...
			'Upper', [1000, 1.01*f, 1, 2*pi], ...
			'StartPoint', [1 f 0 pi]);
		
	ft = fittype('A*sin(2*pi*f*t+phi)+offset', ...
		'independent', 't', 'options', fo);

	num_sensors = floor((size(D,2)-1)/2);
	
	fig = figure();
    set(fig, 'Name', fig_name); clf
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
	
	for didx = 2:size(D,2)
		[fdt, gof] = fit(D(:,1), D(:,didx), ft);
		subplot(3,num_sensors,didx-1)
		plot(D(:,1), D(:,didx), 'k'); hold on
		plot(D(:,1), fdt.A*sin(2*pi*f*D(:,1)+fdt.phi)+fdt.offset, 'r--');
		
		out_text = sprintf('A: %4.3g F: %4.3g\nphi: %4.3g Offset: %4.3g\n RMSE: %4.3E', ...
        fdt.A, fdt.f, fdt.phi, fdt.offset, gof.rmse);
		text(1.0/f, 0, out_text, 'FontSize', 15);
		
		xlim([0 2.0/f])
% 		drawnow();
		
		data_fit(didx-1).A = fdt.A;
		data_fit(didx-1).f = fdt.f;
		data_fit(didx-1).phi = fdt.phi;
		data_fit(didx-1).offset = fdt.offset;
	end
end