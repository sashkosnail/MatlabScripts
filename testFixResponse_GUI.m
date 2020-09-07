function testFixResponse_GUI()%#ok<*NASGU>
	global HT sensor_filter
	
	cfig = figure(678);clf
	fig1 = figure(777);clf
	fig2 = figure(888);clf
	fig3 = figure(666);clf
	fig4 = figure(867);clf
	fig5 = figure(768);clf
	
	cfig.Position = cfig.Position.*[1 1 0 0] + [0 0 750 75];
	
	fig1.Color = 'w';
	ax1 = axes('Parent', fig1);
	fig2.Color = 'w';
	fig3.Color = 'w';
	fig4.Color = 'w';
	fig5.Color = 'w';
	
	start_position = [10 10];
	next_size = [100 35];
	target_text = uicontrol('Style', 'text', 'Parent', cfig, ...
		'units', 'pixels', 'Position', [start_position+[0 30] 250 20], ...
		'String', 'F         Target         D'); 
	new_freq = uicontrol('Style','edit', 'Parent', cfig, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(0.25));
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
		'String', num2str(0.175));
	start_position(1) = start_position(1) + next_size(1) + 50;
	highpass_damping = uicontrol('Style','edit', 'Parent', cfig, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(0.4));
	
	start_position(1) = start_position(1) + next_size(1) + 50;
	save_button = uicontrol('Style', 'pushbutton', 'Parent', cfig, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @save_figures, 'UserData', 1, ...
		'String', 'Save Figures');
	
	s=tf('s');
	Fs = 100;
	Tend = 2^16/Fs;
	t = (0:1/Fs:Tend-1/Fs)';
	N = length(t);
	f = (Fs*(0:(N/2))/N)';
	
	%Sample Data
% 	ftest = [0.5 1 2 5 10];
	ftest = logspace(-0.5, 1.7, 10);
% 	ftest = [4 8 16 32 64 128 256 512 1028]'./Tend;
% 	ftest = [1];
% 	[FT, T] = meshgrid(ftest, t);
% 	data_in = sum(sin(2*pi.*T.*FT),2)+0.5*randn(N,1);
% 	data_in = detrend(data_in);
% 	data_in = data_in-mean(data_in);
% 	data_in = 10*data_in/(3*std(data_in));
% 
	ld=load('sampleDataResponseFix3');
	data_in = ld(1).tmp.D;
	t = ld(1).tmp.t;
	Fs = 1/(t(2)-t(1));
	N = length(t);
	f = (Fs*(0:(N/2))/N)';
% 	
% 	ld = 1;
% 	data_in = 0.1*sin(2*pi*10*t)+((t>2&t<100)|(t>120&t<185)).*sin(2*pi*7*t);

% 	data_in = zeros(N,1);
% 	data_in(2:end) = square(2*t(2:end));
	
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
% 	data = data.*build_taper(t, 5);

	fft_in_tmp = fft(data);%.*build_taper(t, 2));
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
		ht = dfilt.df2(ht.num{:},ht.den{:});
		HT = ht;

		out_data = filter(HT, data);%[data(6*Fs:-1:2) data]);
		fft_out = fft(out_data);
		fft_out = fft_out(1:length(out_data)/2+1)/length(out_data);
		fft_out(2:end-1) = 2*fft_out(2:end-1);

		ht_f = freqz(HT, f, Fs, 'whole');
		fft_out2 = fft_in_tmp.*[ht_f(1:end-1); ht_f(end:-1:2)];
		out_data2 = ifft(fft_out2, 'symmetric');
		fft_out2 = fft(out_data2);
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
		cla(ax1)
		bodeplot(ax1, Sensor_Response, p); hold on
		bodeplot(ax1, H_total, p);
		bodeplot(ax1, H_SR, p);
		bodeplot(ax1, H_inv, p); hold on
		bodeplot(ax1, H_newfreq, p);
		bodeplot(ax1, H_highpass, p);
		
		llm = legend(ax1, 'Sensor Response', 'IRC', 'Resulting Response', ...
			'Inverted Sensor Response', 'Target Response', 'High Pass Filter');
		set(llm, 'FontSize', 12, 'TextColor', 'black');
		axs = findall(fig1.Children,'Type','Axes');
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
		end
		linkaxes([t31, t32, t33, t34]);
		axis(t31, [0.1 100 -1000 400])
		xlim(t35, [0.1 100])
		xlim(t25, [0.1 100])
		alldata = [data_in data out_data out_data2];
		disp(mean(alldata))
		disp(std(alldata))
		
		figure(1754);clf
		od1 = cumsum(out_data)/Fs;
		od2 = cumsum(out_data2)/Fs;
		a11 = subplot(3,2,2); plot(t, out_data); hold on; plot([t(1) t(end)], [1 1]*mean(out_data))
		a12 = subplot(3,2,4); plot(t, out_data2); hold on; plot([t(1) t(end)], [1 1]*mean(out_data2))
		a13 = subplot(3,2,6); plot(t, out_data - out_data2);
		a21 = subplot(3,2,1); plot(t, od1); hold on; plot([t(1) t(end)], [1 1]*mean(od1))
		a22 = subplot(3,2,3); plot(t, od2); hold on; plot([t(1) t(end)], [1 1]*mean(od2))
		a23 = subplot(3,2,5); plot(t, od1 - od2);
		linkaxes([a11 a12 a13 a21 a22 a23])
		xlim(a12, [0 5]);
		
		figure(cfig)
		plot_paper_figure()
		
		function plot_paper_figure		
			figure(fig3);
			fig3.Color = 'w';
			set(fig3, 'Position', [100 40 1200 950]);
			
			SR = freqs(Sensor_Response.num{:},Sensor_Response.den{:}, 2*pi*f);
			iSR = freqs(H_inv.num{:},H_inv.den{:}, 2*pi*f);
			IRC = freqs(H_total.num{:},H_total.den{:}, 2*pi*f);
			HP = freqs(H_highpass.num{:},H_highpass.den{:}, 2*pi*f);
			TRGT = freqs(H_newfreq.num{:},H_newfreq.den{:}, 2*pi*f);
			RSLT = freqs(H_SR.num{:},H_SR.den{:}, 2*pi*f);
			
			axsP = axes('Parent', fig3, 'Position', [0.07 0.05 0.85 0.4], ...
				'FontSize', 12);
			axsM = axes('Parent', fig3, 'Position', [0.07 0.47 0.85 0.5], ...
				'FontSize', 12);
			hP=[];
			axes(axsP);
			[axsPP, hP(1), hP(2)] = plotyy(f, rad2deg(unwrap(angle(IRC))), ...
				f, grpdelay(HT, f, Fs), @semilogx);
			ylabel(axsPP(1), 'Phase[deg]', 'FontSize', 12, ...
				'FontWeight', 'bold');
			ylabel(axsPP(2), 'Group Delay[samples]', 'FontSize', 12, ...
				'FontWeight', 'bold');
			hM = semilogx(axsM, f, 20*log10(abs([SR iSR TRGT HP IRC RSLT])));
			ylabel(axsM, 'Magnitude[dB]', 'FontSize', 12, ...
				'FontWeight', 'bold');
			colors = 'kkkkkk';
			styles = {'--', ':', '-.', ':', '-', '-'};
			widths = [2 1 1 2 2 3];
			set(hP, {'Color'}, {'k'; 'k'}, ...
					{'LineWidth'}, {1; 1}, ...
					{'LineStyle'}, {'-'; '--'});
			set(hM, {'Color'}, num2cell(colors)', ...
					{'LineWidth'}, num2cell(widths)', ...
					{'LineStyle'}, styles');
			axsPP(1).YColor = [0 0 0];
			axsPP(2).YColor = [0 0 0];
			llm = legend(axsM, 'Sensor Response', 'Inverted Sensor Response', ...
				'Target Response', 'High Pass Filter', 'IRC', 'Resulting Response');
			llp = legend(axsP, 'IRC Phase', 'IRC Group Delay');
			set(llm, 'FontSize', 12, 'TextColor', 'black');
			
			xlim(axsP, [0.01 50]);
			xlim(axsM, [0.01 50]);
			
% 			ylim(axsP, [-360 180]);
			ylim(axsM, [-80 80]);
			
			x = xlabel(axsP, 'Frequency [Hz]', 'FontSize', 12, ...
				'FontWeight', 'bold');
			grid(axsP, 'on');
			grid(axsM, 'on');
			axsP.GridAlpha = 0.5;
			axsP.MinorGridAlpha = 0.2;
			axsP.MinorGridLineStyle = '-';
			
			axsM.XAxis.Visible = 'off';
			axsM.GridAlpha = 0.5;
			axsM.MinorGridAlpha = 0.2;
			axsM.MinorGridLineStyle = '-';
			
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
			axis(axs(1,1), [0 20 -20 20]);
			linkaxes(axs(:,2));
			axis(axs(1,2), [0.1 50 0.00001 10])
			for aa = axs(:,2)'
				aa.YAxis.TickValues = 10.^(-5:1:5);
			end
			for n = 1:4
				xlabel(axs(n,1), 'Time[s]')
				ylabel(axs(n,1), 'Velocity [mm/s]')
				x=xlabel(axs(n,2), 'Frequency[Hz]');
				y=ylabel(axs(n,2), 'Velocity [mm/(s*$\sqrt{Hz}$)]','Interpreter','latex');
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
			
			figure(fig5);clf
			fig5.Color = 'w';
			set(fig5, 'Position', [100 40 1200 950]);
			data_to_plot = cumtrapz([data_in data out_data out_data2])/Fs;
			fplot = fft(data_to_plot);
			fplot = fplot(1:N/2+1,:)/N;
			fplot(2:end-1,:) = 2*fplot(2:end-1,:);
			for n = 1:4
				axs2(n,1) = axes('Parent', fig5, 'Position', [0.05 (n-1)/4+0.06 0.6 1/4-0.08]); %#ok<AGROW>
				axs2(n,2) = axes('Parent', fig5, 'Position', [0.71 (n-1)/4+0.06 0.28 1/4-0.08]); %#ok<AGROW>
				plot(axs2(n,1), t, data_to_plot(:,5-n), 'k');
				loglog(axs2(n,2), f, abs(fplot(:,5-n)),'k');
				grid(axs2(n,1),'on');
				grid(axs2(n,2),'on');
				axs2(n,1).GridAlpha = 0.5;
				axs2(n,2).GridAlpha = 0.5;
				axs2(n,2).MinorGridAlpha = 0.2;
				axs2(n,2).MinorGridLineStyle = '-';
				xlabel(axs2(n,1), 'Time[s]')
				xlabel(axs2(n,2), 'Frequency[Hz]')
				ylabel(axs2(n,1), 'Displacement[mm]')
				ylabel(axs2(n,2), 'Displacement[mm/$\sqrt{Hz}$]','Interpreter','latex');
				xlim(axs2(n,1),[0 20]);
			end
			set(axs2, 'FontSize', 12);
			axis(axs2(1,1), [0 20 -20 20]);
			linkaxes(axs2(:,2));
			axis(axs2(1,2), [0.1 50 0.00001 10])

		end
	end

	function save_figures(~, ~)
		
	end
end