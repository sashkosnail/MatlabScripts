function CalculatePatkaGUI()
	global FilterCoeffs FilterParams
	FilterCoeffs = [];
	FilterParams = [];
	fig1 = figure(777);clf
	fig2 = figure(888);clf
	start_position = [10 10];
    next_size = [100 35];
	new_freq = uicontrol('Style','edit', 'Parent', fig1, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(0.85));
	start_position(1) = start_position(1) + next_size(1) + 50;
	new_damping = uicontrol('Style','edit', 'Parent', fig1, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(0.707));
	start_position(1) = start_position(1) + next_size(1) + 50;
	HPeF = uicontrol('Style','edit', 'Parent', fig1, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(0.5));
	start_position(1) = start_position(1) + next_size(1) + 50;
	HPeD = uicontrol('Style','edit', 'Parent', fig1, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(0.4));
	next_size = [100 40];
	start_position(1) = start_position(1) + next_size(1) + 50;
	next_button = uicontrol('Parent', fig1, 'Style', 'pushbutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @gotonext, 'String', 'Next Sensor', ...
        'FontSize', 10, 'FontWeight', 'bold'); %#ok<NASGU>
	start_position(1) = start_position(1) + next_size(1) + 50;
	save_button = uicontrol('Parent', fig1, 'Style', 'pushbutton', ...
        'Units', 'pixels', 'Position', [start_position next_size], ...
        'Callback', @saveresults, 'String', 'Save Results', ...
        'FontSize', 10, 'FontWeight', 'bold'); %#ok<NASGU>
	
	
	start_position = [10 100];
    next_size = [35 400];
	HPslD = uicontrol('Style','slider', 'Parent', fig1, ...
		'Min', 0.25, 'Max', 0.75, 'SliderStep', [0.01 0.1], ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @slider_change, 'UserData', 1, ...
		'String', num2str(0.35));
	start_position(2) = start_position(2) + next_size(2) + 50;
	HPslF = uicontrol('Style','slider', 'Parent', fig1, ...
		'Min', 0.1, 'Max', 1.0, 'SliderStep', [0.01 0.1], ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @slider_change, 'UserData', 1, ...
		'String', num2str(0.7));
		
	ax1 = axes('Parent', fig1);
	
	s=tf('s');
	Fs = 1000;
	Tend = 200;
	t = 0:1/Fs:Tend-1/Fs;
	N = length(t);
	f = Fs*(0:(N/2))/N;
	
	%sensor data
	tmp=readtable('sensor_calibration_MAEEN.csv');
	sensor_data = tmp;
	sensor_data(1:3:end,:) = tmp(3:3:end,:);
	sensor_data(3:3:end,:) = tmp(1:3:end,:);
	sensor_id = 0;
	
	H_inv = []; HT = [];
	Sensor_Response = [];
	data=[];fft_in=[];
	t11=0;t21=0;
	next_sensor;

	function next_sensor
		sensor_id = sensor_id + 1;
		if(sensor_id>height(sensor_data))
			disp('Done')
			return
		end
		Fc = sensor_data{sensor_id,4};
		Ds = 0.707;
		%sensor response
		w1 = 2*pi*Fc;
		Sensor_Response = s^2.0/(s^2+2.0*Ds*s*w1+w1^2.0);
	% 	Sensor_Response = s/(w1+s);
		sensor_filter = c2d(Sensor_Response,1/Fs);
		sensor_filter = dfilt.df2(sensor_filter.num{:},sensor_filter.den{:});

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
		xlim([0 10]);
		t21 = subplot(3,2,2, 'Parent', fig2); cla
		loglog(f, fft_in, 'k'); grid on
		axis([0.01 100 0.0001 1])
		
		data = filter(sensor_filter, data);
		fft_in = fft(data);
		fft_in = abs(fft_in)/N;
		fft_in = fft_in(1:N/2+1);
		fft_in(2:end-1) = 2*fft_in(2:end-1);

		%process
		H_inv = 1/Sensor_Response;
		
		if(exist('FilterParams','var') && sensor_id<size(FilterParams,1))
			HPslF.Value = FilterParams(sensor_id, 3);
			HPslD.Value = FilterParams(sensor_id, 4);
			new_freq.String = num2str(FilterParams(sensor_id, 5));
			new_damping.String = num2str(FilterParams(sensor_id, 6));
		else
			HPslF.Value = str2double(HPeF.String);
			HPslD.Value = str2double(HPeD.String);
		end
		slider_change
	end
	function slider_change(~, ~)
		HPeF.String = num2str(HPslF.Value);
		HPeD.String = num2str(HPslD.Value);
		value_change;
	end
	function saveresults(~, ~)
		dlmwrite('patka_coeffs_all_filt.csv',FilterCoeffs,'precision','%10.20f')
		save('patka.mat', 'FilterCoeffs', 'FilterParams');
	end
	function gotonext(~, ~)
		FilterCoeffs = [FilterCoeffs; [HT.Numerator; HT.Denominator]];
		target_freq = str2double(new_freq.String);
		target_d = str2double(new_damping.String);
		new_FilterParams = [sensor_data{sensor_id,4}, 0.707, ...
			HPslF.Value, HPslD.Value, target_freq, target_d];
		FilterParams = [FilterParams; new_FilterParams];
		sensor_id = sensor_id + 1;
		if(sensor_id>height(sensor_data))
			disp('Done')
			return
		end
		next_sensor;
	end
	function value_change(~, ~)
		HPslF.Value = str2double(HPeF.String);
		HPslD.Value = str2double(HPeD.String);
		w_new = 2*pi*str2double(new_freq.String);
		zeta1 = str2double(new_damping.String);
		H_newfreq = (s/w_new)^2/((s/w_new)^2+2*zeta1*s/w_new+1);
% 		H_newfreq = s/(w_new+s);
		
		w_hp = 2*pi*HPslF.Value;
		zeta2 = HPslD.Value;
		H_highpass = (s/w_hp)^2/((s/w_hp)^2+2*zeta2*s/w_hp+1);
% 		H_highpass = s/(w_hp+s);
		
		H_total = H_inv*H_newfreq*H_highpass;
		ht = c2d(H_total,1/Fs);
		ht = dfilt.df2(ht.num{:},ht.den{:});
		HT = ht;
		H_out = H_total*Sensor_Response;
		
		out_data = filter(ht, data);
		fft_out = fft(out_data);
		fft_out = abs(fft_out)/N;
		fft_out = fft_out(1:N/2+1);
		fft_out(2:end-1) = 2*fft_out(2:end-1);
		%figure1
		figure(fig1)
		p=bodeoptions;
		p.FreqUnits = 'Hz';
		p.Grid = 'on';
		cla(ax1)
		bodeplot(ax1, H_inv, p); hold on
		bodeplot(ax1, H_newfreq, p)
		bodeplot(ax1, H_highpass, p)
		bodeplot(ax1, H_total, p)
		bodeplot(ax1, H_out, p);
		ppp = findobj(ax1,'Type','line');
		title(strcat(sensor_data{sensor_id, 2}, '--', ...
			num2str(sensor_data{sensor_id, 4}), '--', ...
			num2str(max(ppp(2).YData))));
		axis(ax1,[0.1 50 -40 40]);
		legend('H inv','H newfreq','H highpass','H total','Out')
		%figure2
		figure(fig2);
		t12 = subplot(3,2,3, 'Parent', fig2); cla;
		plot(t, data, 'k');  grid on
		t13 = subplot(3,2,5, 'Parent', fig2); cla; 
		plot(t, out_data, 'k');
		xlim([0 10]);grid on
		t22 = subplot(3,2,4, 'Parent', fig2); cla; grid on
		loglog(f, fft_in, 'k');grid on
		t23 = subplot(3,2,6, 'Parent', fig2); cla; grid on
		loglog(f, fft_out, 'k');grid on
		axis([0.01 100 0.0001 1])
		linkaxes([t11, t12, t13]);
		linkaxes([t21, t22, t23]);
		axes(ax1)
	end
end