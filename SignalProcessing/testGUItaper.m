function testGUItaper
    global t tau ax

    t = 0:0.01:10;
    tau  = 1;
    
    fig = figure(234);clf
    
    t_text = uicontrol('Style','text', 'Parent', fig, ...
        'Units', 'normalized', 'Position', [0.05 0.96 0.05 0.04], ...
        'String', 't:'); %#ok<NASGU>
    t_tb = uicontrol('Style','edit', 'Parent', fig, ...
        'Units', 'normalized', 'Position', [0.15 0.96 0.1 0.04], ...
        'KeyReleaseFcn', @keydown_editbox, 'UserData', 1, ...
        'String', '0:0.01:10'); %#ok<NASGU>

    tau_text = uicontrol('Style','text', 'Parent', fig, ...
        'Units', 'normalized', 'Position', [0.35 0.96 0.05 0.04], ...
        'String', 'Window Overlap:'); %#ok<NASGU>
    tau_tb = uicontrol('Style','edit', 'Parent', fig, ...
        'Units', 'normalized', 'Position', [0.45 0.96 0.1 0.04], ...
        'KeyReleaseFcn', @keydown_editbox, 'UserData', 2, ...
        'String', num2str(tau)); %#ok<NASGU>
    
    ax2 = subplot('Position', [0.05 0.05 0.9 0.40], 'Parent', fig);
    ax1 = subplot('Position', [0.05 0.5 0.9 0.45], 'Parent', fig);
    
    ax = [ax1 ax2];

    calc_taper();
end

function keydown_editbox(hObject, eventData)
global t tau
    if(~strcmp(eventData.Key, 'return'))
        return;
    end
    val = hObject.String;
    switch hObject.UserData
        case 1
            t = eval(val);
        case 2
            tau = str2double(val);
    end
    calc_taper();
end

function calc_taper()
    global t tau ax
    
    taper = build_taper(t, tau);
    Ts = t(2)-t(1); Fs = 1/Ts;
    
    axes(ax(1));cla; hold on
    plot(t, taper, 'DisplayName', 'Taper');
    legend(ax(1), 'show', 'Location', 'NorthWest');
    axis tight; grid on
    
    window_size = length(taper);
    fftdata = abs(fft(taper)/window_size);
    fftdata = fftdata(1:ceil(window_size/2),:)+fftdata(end:-1:1+floor(window_size/2),:);
    taper_fft = fftdata(:,1);
    freq = Fs*(1:ceil(window_size/2))'/window_size;
    
    axes(ax(2)); cla; hold on
    loglog(freq, taper_fft, 'DisplayName', 'Taper DFT');
    ax(2).XScale = 'log';
    ax(2).YScale = 'log';
    axis([freq(1) freq(end) min(min(fftdata)) max(max(fftdata))])
    legend(ax(2), 'show', 'Location', 'NorthWest');
end