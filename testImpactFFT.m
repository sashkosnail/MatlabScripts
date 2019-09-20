function testImpactFFT
	Fs = 10000;
	N = 2^14;
	Ftest = 9;

	t=1.0/Fs*(0:1:N-1)';

	fig = figure(124551);
	DC_slider = uicontrol('Parent', fig, 'Style', 'slider', ...
		'Callback', @dc_changed, 'Value', 10, ...
		'Max', 100, 'Min', 0, 'SliderStep', [.01 .1], ...
		'Position', [10 10 200 20]);
	DC_display = uicontrol('Parent', fig, 'Style', 'text', 'String', 10, ...
		'Position', [215 10 50 20]);

	dc_changed(DC_slider)

	function dc_changed(h, ~)
		DC_display.String = num2str(h.Value);
% 		sig = square(2*pi*Ftest*t, h.Value);
% 
% 		sig = sawtooth(2*pi*Ftest*t, h.Value/100.0);
% 
% 		sig = diric(t, 1+h.Value);
% 
% 		sig = sin(2*pi*Ftest*t);
% 		sig = zeros(N,1);
% 		sig(1:ceil(Fs/Ftest):end) = 1;
% 
% 		sig = gmonopuls(-.5:1/Fs:.5, Ftest)';
% 		sig = gauspuls(0:1/Fs:.5, Ftest, h.Value/100.0)';
		duration = 0.0276;
		Fmain = 725;
		Nd = floor(duration*Fs);
		win_a = hamming(ceil(Nd/7.0));
		win_b = hamming(ceil(6.0*Nd/4.0));
		win = 100*[win_a(1:end/2)' win_b(end/2:end)']';
		tt = 1.0/Fs*(0:1:length(win)-1)';
		sig = sin(2*pi*Fmain*tt).*win;
		sig = [zeros(300,1); sig; zeros(ceil(Fs/Ftest)-300-length(win),1)];
 		sig = repmat(sig, ceil(N/length(sig)), 1);
		sig = sig(1:N);
		sig = sig + 2*(sin(2*pi*72*t));
% 		sig = sig + randn(N,1);
% 		sig = cumtrapz(sig);
		sig=detrend(sig);
		
		f = (Fs*(0:(N/2))/N)';
		fd = fft(sig);
		fd = fd(1:N/2+1)/N;
		fd(2:end-1) = 2*fd(2:end-1);

		fd = fd./f;
		
		figure(fig)
		subplot(3,1,1)
		plot(t, sig);
		grid on
% 		xlim([1 1.4])
		subplot(3,1,2)
		plot(f, abs(fd));
% 		axis([0 950 0 0.0001]);
		xlim([0 950])
		grid on
		subplot(3,1,3)
		plot(f, rad2deg(unwrap(angle(fd))));
		grid on
	end
end