function testFixResponse_GUI()%#ok<*NASGU>
global HT sensor_filter
	cfig = figure(678);clf
	fig1 = figure(777);clf
	fig2 = figure(888);clf
	fig3 = figure(666);clf
	fig4 = figure(867);clf
	start_position = [10 10];
	next_size = [100 35];
	target_text = uicontrol('Style', 'text', 'Parent', cfig, ...
		'units', 'pixels', 'Position', [start_position+[0 30] 250 20], ...
		'String', 'F         Target         D'); 
	new_freq = uicontrol('Style','edit', 'Parent', cfig, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(1));
	start_position(1) = start_position(1) + next_size(1) + 50;
	new_response_damping = uicontrol('Style','edit', 'Parent', cfig, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(0.707));
	
	start_position(1) = start_position(1) + next_size(1) + 50;
	hp_check = uicontrol('Style', 'checkbox', 'Parent', cfig, ...
		'units', 'pixels', 'Position', [start_position+[0 35] 50 20], ...
		'Callback', @value_change, 'String', 'use', 'Value', 1);
	hp_text = uicontrol('Style', 'text', 'Parent', cfig, ...
		'units', 'pixels', 'Position', [start_position+[40 30] 170 20], ...
		'String', 'F         HighPass         D');
	hp_freq = uicontrol('Style','edit', 'Parent', cfig, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(0.7));
	start_position(1) = start_position(1) + next_size(1) + 50;
	highpass_damping = uicontrol('Style','edit', 'Parent', cfig, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(0.35));
	
	start_position(1) = start_position(1) + next_size(1) + 50;
	save_button = uicontrol('Style', 'pushbutton', 'Parent', cfig, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @save_figures, 'UserData', 1, ...
		'String', 'Save Figures');
	
	cfig.Position = cfig.Position.*[1 1 0 0] + [0 0 750 75];
	
	fig1.Color = 'w';
	ax1 = axes('Parent', fig1);
	fig3.Color = 'w';
	ax2 = axes('Parent', fig3);
	fig2.Color = 'w';
	
	s=tf('s');
	Fs = 1000;
	Tend = 2^16/Fs;
	t = (0:1/Fs:Tend-1/Fs)';
	N = length(t);
	f = (Fs*(0:(N/2))/N)';
	
	%Sample Data
	ftest = [0.5 1 2 5 10];
% 	ftest = logspace(-0.5, 1.7, 10);
% 	ftest = [4 8 16 32 64 128 256 512 1028]'./Tend;
% 	ftest = [1];
	[FT, T] = meshgrid(ftest, t);
	data_in = sum(sin(2*pi.*T.*FT),2)+0.05*randn(N,1);
	data_in = detrend(data_in);
% 	data_in = data_in-mean(data_in);
% 	data_in = 10*data_in/(3*std(data_in));
% 
% 	ld=load('sampleDataResponseFix2');
% 	data_in = ld(1).tmp.D;
% 	t = ld(1).tmp.t;
% 	Fs = 1/(t(2)-t(1));	
% 	N = length(t);
% 	f = (Fs*(0:(N/2))/N)';
% 	
% 	ld = 1;
% 	data_in = 0.1*sin(2*pi*10*t)+((t>2&t<100)|(t>120&t<185)).*sin(2*pi*7*t);

	
	[num, den] = butter(8, 0.707, 'low');
	data_in = filter(num,den,data_in);
	fft_start = fft(data_in);
% 	fft_in = abs(fft_in)/N;
	fft_start = fft_start(1:N/2+1)/N;
	fft_start(2:end-1) = 2*fft_start(2:end-1);
	
	figure(fig2);
	t11 = subaxis(5,3,1, 'SV', 0.05, 'PL', 0.01, 'PT', 0.01, 'Parent', fig2); cla
	plot(t, data_in, 'k'); grid on
	title('Test Signal')
	t21 = subaxis(5,3,2, 'SV', 0.05, 'PL', 0.01, 'PT', 0.01, 'Parent', fig2); cla
	loglog(f, abs(fft_start), 'k'); grid on
	t31 = subaxis(5,3,3, 'SV', 0.05, 'PL', 0.01, 'PT', 0.01, 'Parent', fig2); cla
	semilogx(f, unwrap(rad2deg(angle(fft_start))), 'k'); grid on
	
	if(exist('ld','var'))
		data = data_in;
		Fc = 4.62;
		Ds = 0.707;
		w1 = 2*pi*Fc;
		Sensor_Response = -s^2.0/(s^2+2.0*Ds*s*w1+w1^2.0);
		tmpp='';
	else
		%sensor data
		Fc = 4.2563;
		Ds = 0.707;
		w1 = 2*pi*Fc;
		Sensor_Response = -s^2.0/(s^2+2.0*Ds*s*w1+w1^2.0);
		sensor_filter = c2d(Sensor_Response, 1.0/Fs, 'tustin');
		sensor_filter = dfilt.df2(sensor_filter.num{:}, sensor_filter.den{:});
		data = filter(sensor_filter, data_in);
		%sensor response
		tmpp = ' of Test Signal';
	end
	
% 	Sensor_Response = s/(w1+s);
% 	data(data>0.15) = 0.15;
% 	data(data<-0.15) = -0.15;
% 	data = detrend(data);
% 	
% 	data = 2*square(t);
	fft_in_tmp = fft(data);%.*build_taper(t, 1)');
% 	fft_in = abs(fft_in_tmp)/N;
	fft_in = fft(data);
	fft_in = fft_in(1:N/2+1)/N;
	fft_in(2:end-1) = 2*fft_in(2:end-1);
	
	%process
	H_inv = 1/Sensor_Response;
	value_change()
	
	function value_change(~, ~)
		w_new = 2*pi*str2double(new_freq.String);
		zeta1 = str2double(new_response_damping.String);
		H_newfreq = -s^2/(s^2+2*zeta1*s*w_new+w_new^2);
% 		H_newfreq = s/(w_new+s);
		
		w_hp = 2*pi*str2double(hp_freq.String);
		zeta2 = str2double(highpass_damping.String);
		H_highpass = -s^2/(s^2+2*zeta2*s*w_hp+w_hp^2);
% 		H_highpass = s/(w_hp+s);
		
		H_total = H_inv*H_newfreq;
		if(hp_check.Value)
			H_total = H_total*H_highpass;
		end
		H_SR = H_total*Sensor_Response;
		
		ht = c2d(H_total,1/Fs,'foh');
% 		ap = zpk(1.1109+1j*0.022216*[-1 1],0.89982+1j*0.017995*[-1 1],1.2345,1/Fs);
% 		ht = ht/tf(ap);
		ht = dfilt.df2(ht.num{:},ht.den{:});
		HT = ht;

		out_data = filter(HT, data);%[data(6*Fs:-1:2) data]);
% 		out_data = detrend(out_data,'constant');
% 		out_data = out_data((N/2+1):end);
		fft_out = fft(out_data);
% 		fft_out = abs(fft_out)/N;
		fft_out = fft_out(1:length(out_data)/2+1)/length(out_data);
		fft_out(2:end-1) = 2*fft_out(2:end-1);

		ht_f = freqz(HT, f, Fs, 'whole');
		fft_out2 = fft_in_tmp.*[ht_f(1:end-1); ht_f(end:-1:2)];
		out_data2 = ifft(fft_out2, 'symmetric');
% 		out_data2 = out_data2((N/2+1):end);
		fft_out2 = fft(out_data2);
% 		fft_out2 = abs(fft_out2)/N;
		fft_out2 = fft_out2(1:length(out_data2)/2+1)/length(out_data2);
		fft_out2(2:end-1) = 2*fft_out2(2:end-1);
		
		%figure1
		figure(fig1)
		p=bodeoptions;
		p.FreqUnits = 'Hz';
		p.XLabel.FontSize = 14;
		p.YLabel.FontSize = 14;
		p.Title.FontSize = 14;
		p.Grid = 'on';
% 		p.PhaseMatching = 'on';
% 		p.PhaseMatchingFreq = 2*pi*f(2);
% 		p.PhaseMatchingValue = 10;
		cla(ax1)
		bodeplot(ax1, Sensor_Response, p); hold on
		bodeplot(ax1, H_total, p);
		bodeplot(ax1, H_SR, p);
		ll = legend(ax1, 'Sensor Response', 'IRC', 'Resulting Response');
		set(ll, 'FontSize', 12, 'TextColor', 'black');
		axs = findall(fig1.Children,'Type','Axes');
		axs(2).YLim = [-50 50];
		for kkk = 1:1:length(axs)
			axs(kkk).FontSize = 14;
		end
		
		figure(fig3)
		p=bodeoptions;
		p.FreqUnits = 'Hz';
		p.XLabel.FontSize = 14;
		p.YLabel.FontSize = 14;
		p.Title.FontSize = 14;
		p.PhaseVisible = 'off';
		p.Grid = 'on';
% 		p.PhaseMatching = 'on';
% 		p.PhaseMatchingFreq = 2*pi*f(2);
% 		p.PhaseMatchingValue = 10;
		cla(ax2)
		bodeplot(ax2, H_inv, p); hold on
		bodeplot(ax2, H_newfreq, p);
		bodeplot(ax2, H_highpass, p);
		bodeplot(ax2, H_total, p);
		ll = legend(ax2, 'Inverted Sensor Response', 'Target Response', ...
			'High Pass Filter', 'IRC');
		set(ll, 'FontSize', 12, 'TextColor', 'black');
		axs = findall(fig3.Children, 'Type', 'Axes');
		axs(2).YLim = [-50 50];
		for kkk = 1:1:length(axs)
			axs(kkk).FontSize = 14;
		end
		
		
		%figure2
		figure(fig2);
		t2 = t((N/2+1):end);
		if(length(data)==length(out_data))
			t2=t;
		end
		t12 = subaxis(5,3,4, 'SV', 0.05, 'PL', 0.01,'Parent', fig2); cla;
			plot(t, data, 'k');  grid on
			title([num2str(Fc) 'Hz Shaping' tmpp])
		t13 = subaxis(5,3,7, 'SV', 0.05, 'PL', 0.01, 'Parent', fig2); cla; 
			plot(t2, out_data, 'k');grid on
			title('1Hz Response using IIR Filtering')
			ylabel('Amplitude');
		t14 = subaxis(5,3,10, 'SV', 0.05, 'PL', 0.01, 'Parent', fig2); cla;
			plot(t2, out_data2, 'k');  grid on
			title('1Hz Response using Spectral Multiplicaiton ')
		t15 = subaxis(5,3,13, 'SV', 0.05, 'PL', 0.01, 'PB', 0.04, 'Parent', fig2); cla;
			plot(t2, out_data-out_data2, 'k');  grid on
			title('Processing Difference')
		xlabel('Time [s]');
		
% 		f2 = f(6*Fs:end);	
		f2 = Fs*(0:(length(out_data)/2))/length(out_data);
		t22 = subaxis(5,3,5, 'SV', 0.05, 'PL', 0.01, 'Parent', fig2); cla
			loglog(f, abs(fft_in), 'k'); grid on
		t23 = subaxis(5,3,8, 'SV', 0.05, 'PL', 0.01, 'Parent', fig2); cla
			loglog(f2, abs(fft_out), 'k'); grid on
			ylabel('Amplitude');
		t24 = subaxis(5,3,11, 'SV', 0.05, 'PL', 0.01, 'Parent', fig2); cla
			loglog(f2, abs(fft_out2), 'k'); grid on
		t25 = subaxis(5,3,14, 'SV', 0.05, 'PL', 0.01, 'PB', 0.04, 'Parent', fig2); cla
			loglog(f2, abs(fft_out./fft_out2), 'k'); grid on
		xlabel('Frequency [Hz]');
		
		t32 = subaxis(5,3,6, 'SV', 0.05, 'PL', 0.01, 'Parent', fig2); cla
			semilogx(f, unwrap(rad2deg(angle(fft_in))), 'k'); grid on
		t33 = subaxis(5,3,9, 'SV', 0.05, 'PL', 0.01, 'Parent', fig2); cla
			semilogx(f2, unwrap(rad2deg(angle(fft_out))), 'k'); grid on
			ylabel('Phase[deg]');
		t34 = subaxis(5,3,12, 'SV', 0.05, 'PL', 0.01, 'Parent', fig2); cla
			semilogx(f2, unwrap(rad2deg(angle(fft_out2))), 'k'); grid on
		t35 = subaxis(5,3,15, 'SV', 0.05, 'PL', 0.01, 'PB', 0.04, 'Parent', fig2); cla
			semilogx(f2, rad2deg(...
				unwrap(angle(fft_out./fft_out2))), 'k'); 
			grid on
		xlabel('Frequency [Hz]');
		
		linkaxes([t11, t12, t13, t14, t15]);
		axis(t11, [0 10 -5 5]);
		linkaxes([t21, t22, t23, t24]);
		axis(t21, [0.1 100 0.00001 10])
		for a = [t21, t22, t23, t24, t25]
			a.YAxis.TickValues = 10.^(-5:1:5);
% 			a.YAxis.TickLabels = cellstr(num2str(a.YAxis.TickValues'));
		end
		linkaxes([t31, t32, t33, t34]);
		axis(t31, [0.1 100 -1000 400])
		xlim(t35, [0.1 100])
		xlim(t25, [0.1 100])
		alldata = [data_in data out_data out_data2];
		disp(mean(alldata))
		disp(std(alldata))
		figure(cfig)
		plot_paper_figure()
		
		function plot_paper_figure		
			figure(fig4);clf
			fig4.Color = 'w';
			set(fig4, 'Position', [100 40 1200 950]);
			for n = 1:4
				axs(n,1) = axes('Position', [0.05 (n-1)/4+0.06 0.6 1/4-0.08]);
				axs(n,2) = axes('Position', [0.71 (n-1)/4+0.06 0.28 1/4-0.08]);
			end
			
			plot(axs(4,1), t, data_in, 'k');
			plot(axs(3,1), t, data, 'k');  grid on
			plot(axs(2,1), t, out_data, 'k');grid on
			plot(axs(1,1), t, out_data2, 'k'); grid on
			
			loglog(axs(4,2), f, abs(fft_start), 'k');
			loglog(axs(3,2), f, abs(fft_in), 'k'); grid on
			loglog(axs(2,2), f, abs(fft_out), 'k'); grid on
			loglog(axs(1,2), f, abs(fft_out2), 'k'); grid on

			linkaxes(axs(:,1));
			axis(axs(1,1), [0 5 -12 12]);
			linkaxes(axs(:,2));
			axis(axs(1,2), [0.1 50 0.00001 10])
			for aa = axs(:,2)'
				aa.YAxis.TickValues = 10.^(-5:1:5);
	% 			a.YAxis.TickLabels = cellstr(num2str(a.YAxis.TickValues'));
			end
			for n = 1:4
				xlabel(axs(n,1), 'Time[s]')
				ylabel(axs(n,1), 'Amlplitude')
				x=xlabel(axs(n,2), 'Frequency[Hz]');
				y=ylabel(axs(n,2), 'Amplitude/$\sqrt{Hz}$','Interpreter','latex');
				y.FontName = x.FontName;
				y.FontSize = 12;
				y.FontWeight = 'bold';
				grid(axs(n,1), 'on');
				grid(axs(n,2), 'on');
				axs(n,1).GridAlpha = 0.5;
				axs(n,2).GridAlpha = 0.5;
				axs(n,2).MinorGridAlpha = 0.2;
				axs(n,2).MinorGridLineStyle = '-';
			end
			set(axs, 'FontSize', 12);
		end
	end

	function save_figures(h, o)
		
	end
end