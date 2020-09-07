function test_filterFS
	Fs_new = 500;
	Fs_old = 1000;

	fig = figure(1);clf

	start_position = [10 30];		
    next_size = [100 20];
    Fs_new_text = uicontrol('Style','text', 'Parent', fig, ...
            'Units', 'pixels', 'Position', [start_position next_size], ...
            'String', 'Fs_new'); %#ok<NASGU>
	next_size = [100 20];
	start_position(2) = start_position(2) - next_size(2);
    Fs_new_edit = uicontrol('Style','edit', 'Parent', fig, ...
            'Units', 'pixels', 'Position', [start_position next_size], ...
            'KeyReleaseFcn', @parameter_changed, ...
            'String', num2str(Fs_new));%#ok<NASGU>
		
	next_size = [100 20];
	start_position = start_position + next_size + [10 0];
    Fs_old_text = uicontrol('Style','text', 'Parent', fig, ...
            'Units', 'pixels', 'Position', [start_position next_size], ...
            'String', 'Fs_old'); %#ok<NASGU>
	next_size = [100 20];
	start_position(2) = start_position(2) - next_size(2);
    Fs_old_edit = uicontrol('Style','edit', 'Parent', fig, ...
            'Units', 'pixels', 'Position', [start_position next_size], ...
            'KeyReleaseFcn', @parameter_changed, ...
            'String', num2str(Fs_old));%#ok<NASGU>
	parameter_changed()
		
	function parameter_changed(hObject, ~, ~)
		global FilterCoeffs
		b = [1.00000000000000000000,-3.81366645151776540000,5.45715917182685570000,-3.47331891472243730000,0.82982619441334748000];
		a = [1.00000000000000000000,-3.95173288882587230000,5.85651684207927660000,-3.85781840384427800000,0.95303460273939289000];

% 		[b, a] = butter(5, 2*5/Fs_old);

% 		b = FilterCoeffs(1,:);
% 		a = FilterCoeffs(2,:);
		
		k = 1;
		z = roots(b);
		p = roots(a);
		
		Fs_old = str2double(Fs_old_edit.String);
		Fs_new = str2double(Fs_new_edit.String);
		
		Fs_ratio = Fs_old/(Fs_new);
		f = logspace(-2, log10(max([Fs_old, Fs_new])/2), 1024);

		z_new = (z.*[0.99999 0.99999 1 1]').^(Fs_ratio);
		p_new = p.^(Fs_ratio);

		filt_new = tf(zpk(z_new, p_new, k, Fs_new));
		filt_old = tf(zpk(z, p, k, Fs_old));

		[h_old, fo] = freqz(filt_old.num{:}, filt_old.den{:}, f, Fs_old);
		[h_new, fn] = freqz(filt_new.num{:}, filt_new.den{:}, f, Fs_new);

		cla
		loglog(fo, (abs(h_old)), 'k'); hold on
		loglog(fn, (abs(h_new)), 'r--');
		grid on;
		% ylim([-10 50]);
		ylim([0.1 100])
		xlim([f(1) f(end)]);
		legend(['Fs = ' num2str(Fs_old) 'Hz'], ['Fs = ' num2str(Fs_new) 'Hz']);
end
end