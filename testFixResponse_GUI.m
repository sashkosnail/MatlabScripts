function testFixResponse_GUI()
global HT sensor_filter
	fig1 = figure(777);clf
	fig2 = figure(888);clf
	start_position = [10 10];
    next_size = [100 35];
	new_freq = uicontrol('Style','edit', 'Parent', fig1, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(1));
	start_position(1) = start_position(1) + next_size(1) + 50;
	new_response_damping = uicontrol('Style','edit', 'Parent', fig1, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(0.707));
	start_position(1) = start_position(1) + next_size(1) + 50;
	hp_freq = uicontrol('Style','edit', 'Parent', fig1, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(0.7));
	start_position(1) = start_position(1) + next_size(1) + 50;
	highpass_damping = uicontrol('Style','edit', 'Parent', fig1, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(0.35));
	
	ax1 = axes('Parent', fig1);
	
	s=tf('s');
	Fs = 1000;
	Tend = 200;
	t = 0:1/Fs:Tend-1/Fs;
	N = length(t);
	f = Fs*(0:(N/2))/N;
	%Sample Data
	ftest = logspace(-1.5, 2, 29);
	[T, FT] = meshgrid(t, ftest);
	data = sum(sin(2*pi.*T.*FT))+randn(1,N);
	fft_in = fft(data);
	fft_in = abs(fft_in)/N;
	fft_in = fft_in(1:N/2+1);
	fft_in(2:end-1) = 2*fft_in(2:end-1);
	
	figure(fig2);
	t11 = subplot(3,2,1, 'Parent', fig2); cla
	plot(t, data, 'k'); grid on
	title('Test Signal')
	xlim([0 10]);
	t21 = subplot(3,2,2, 'Parent', fig2); cla
	loglog(f, fft_in, 'k'); grid on
	axis([0.01 100 0.0001 1])
	title('Amplitude Spectrum');
	
	%sensor data
	tmp=readtable('sensor_calibration_MAEEN.csv');
	sensor_data = tmp;
	sensor_data(1:3:end,:) = tmp(3:3:end,:);
	sensor_data(3:3:end,:) = tmp(1:3:end,:);
	Fc = 4.2563;
	Ds = .707;
	%sensor response
	w1 = 2*pi*Fc;
	Sensor_Response = s^2.0/(s^2+2.0*Ds*s*w1+w1^2.0);
% 	Sensor_Response = s/(w1+s);
	sensor_filter = c2d(Sensor_Response,1/Fs,'matched');
	sensor_filter = dfilt.df2(sensor_filter.num{:},sensor_filter.den{:});
	
	data = filter(sensor_filter, data);
	fft_in = fft(data);
	fft_in = abs(fft_in)/N;
	fft_in = fft_in(1:N/2+1);
	fft_in(2:end-1) = 2*fft_in(2:end-1);
	
	%process
	H_inv = 1/Sensor_Response;
	value_change()
	function value_change(~, ~)
		w_new = 2*pi*str2double(new_freq.String);
		zeta1 = str2double(new_response_damping.String);
		H_newfreq = (s/w_new)^2/((s/w_new)^2+2*zeta1*s/w_new+1);
% 		H_newfreq = s/(w_new+s);
		
		w_hp = 2*pi*str2double(hp_freq.String);
		zeta2 = str2double(highpass_damping.String);
		H_highpass = (s/w_hp)^2/((s/w_hp)^2+2*zeta2*s/w_hp+1);
% 		H_highpass = s/(w_hp+s);
		
		H_total = H_inv*H_newfreq*H_highpass;
		H_SR = H_total*Sensor_Response;
		
		ht = c2d(H_total,1/Fs);
		ht = dfilt.df2(ht.num{:},ht.den{:});
		HT = ht;
		
		out_data = filter(ht, data);
		fft_out = fft(out_data);
		fft_out = abs(fft_out)/N;
		fft_out = fft_out(1:N/2+1);
		fft_out(2:end-1) = 2*fft_out(2:end-1);
		%figure1
		figure(fig1)
		p=bodeoptions;
		p.FreqUnits = 'Hz';
		p.XLabel.FontSize = 14;
		p.YLabel.FontSize = 14;
		p.Title.FontSize = 14;
		p.Grid = 'on';
		cla(ax1)
		tmpax = {};
		h6 = bodeplot(ax1, Sensor_Response, p); hold on
		h1 = bodeplot(ax1, H_inv, p)
		h2 = bodeplot(ax1, H_newfreq, p)
		h3 = bodeplot(ax1, H_highpass, p)
		h4 = bodeplot(ax1, H_total, p)
		h5 = bodeplot(ax1, H_SR, p)
		legend('Sensor Response', 'H inv', 'H newfreq', ...
			'H highpass', 'H total', 'Result Response')
		axs = findall(fig1.Children,'Type','Axes');
		for kkk = 1:2
			axs(kkk).FontSize = 14;
		end
		
		%figure2
		
		figure(fig2);
		t12 = subplot(3,2,3, 'Parent', fig2); cla;
		plot(t, data, 'k');  grid on
		title('Generic 4.5Hz Response to Test Signal')
		t13 = subplot(3,2,5, 'Parent', fig2); cla; 
		plot(t, out_data, 'k');
		xlim([0 10]);grid on
		xlabel('Time [s]');
		title('Processed 1Hz Response to Test Signal')
		t22 = subplot(3,2,4, 'Parent', fig2); cla; grid on
		loglog(f, fft_in, 'k');grid on
		t23 = subplot(3,2,6, 'Parent', fig2); cla; grid on
		loglog(f, fft_out, 'k');grid on
		xlabel('Frequency [Hz]');
		axis([0.01 100 0.0001 1])
		linkaxes([t11, t12, t13]);
		linkaxes([t21, t22, t23]);
	end
end