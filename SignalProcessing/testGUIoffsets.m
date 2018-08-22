function testGUIoffsets
    global Ws Wo Wf ax t data off

    Ws = 0.05;
    Wo = 0.5;
    Wf = 'triang';
    
    fig = figure(123);clf
    
    [t, data, off] = build_test_data;
    
    window_size_text = uicontrol('Style','text', 'Parent', fig, ...
        'Units', 'normalized', 'Position', [0.05 0.96 0.05 0.04], ...
        'String', 'Window Size:'); %#ok<NASGU>
    window_size = uicontrol('Style','edit', 'Parent', fig, ...
        'Units', 'normalized', 'Position', [0.15 0.96 0.1 0.04], ...
        'KeyReleaseFcn', @keydown_editbox, 'UserData', 1, ...
        'String', num2str(Ws)); %#ok<NASGU>

    window_overlap_text = uicontrol('Style','text', 'Parent', fig, ...
        'Units', 'normalized', 'Position', [0.35 0.96 0.05 0.04], ...
        'String', 'Window Overlap:'); %#ok<NASGU>
    window_overlap = uicontrol('Style','edit', 'Parent', fig, ...
        'Units', 'normalized', 'Position', [0.45 0.96 0.1 0.04], ...
        'KeyReleaseFcn', @keydown_editbox, 'UserData', 2, ...
        'String', num2str(Wo)); %#ok<NASGU>

    window_function_text = uicontrol('Style','text', 'Parent', fig, ...
        'Units', 'normalized', 'Position', [0.65 0.96 0.05 0.04], ...
        'String', 'Window Function:'); %#ok<NASGU>
    window_function = uicontrol('Style','edit', 'Parent', fig, ...
        'Units', 'normalized', 'Position', [0.75 0.96 0.1 0.04], ...
        'KeyReleaseFcn', @keydown_editbox, 'UserData', 3, ...
        'String', Wf); %#ok<NASGU>
    
    ax2 = subplot('Position', [0.05 0.05 0.9 0.40], 'Parent', fig);
    ax1 = subplot('Position', [0.05 0.5 0.9 0.45], 'Parent', fig);
    
    ax = [ax1 ax2];

    calc_offsets();
end

function keydown_editbox(hObject, eventData)
global Ws Wo Wf
    if(~strcmp(eventData.Key, 'return'))
        return;
    end
    val = hObject.String;
    switch hObject.UserData
        case 1
            Ws = str2double(val);
        case 2
            Wo = str2double(val);
        case 3
            Wf = val;
    end
    calc_offsets();
end

function calc_offsets()
    global Ws Wo Wf ax t data off
    Nw = Ws*length(data);
    window = eval([Wf '(' num2str(Nw) ')']);
    window = window/sum(window);
    
    ff = filtfilt(window, 1, data);
    mvmean = movmean(data,window);
    a=offset(data, Ws, Wo, 0);
    
    axes(ax(1));cla; hold on
    plot(t, data, 'DisplayName', 'DATA');
    plot(t, off, 'DisplayName', 'Included Offset', 'LineStyle','--');
    plot(t, ff, 'DisplayName', 'filtfilt');
    plot(t, mvmean, 'DisplayName', 'movmean');
    plot(t(a(:,1)),a(:,2:end), 'DisplayName', 'offset');
    axis([115 125 -5 25])
    legend(ax(1), 'show', 'Location', 'NorthWest');
    
    window_size = length(data);
    fftdata = abs(fft([ff mvmean])/window_size);
    fftdata = fftdata(1:window_size/2,:)+fftdata(end:-1:1+window_size/2,:);
    fff = fftdata(:,1);
    fmvmean = fftdata(:,2);
    Ts = t(2)-t(1); Fs = 1/Ts;
    freq = Fs*(1:window_size/2)'/window_size;
    
    axes(ax(2)); cla; hold on
    loglog(freq, fff, 'DisplayName', 'filtfilt');
    loglog(freq, fmvmean, 'DisplayName', 'movmean');
    ax(2).XScale = 'log';
    ax(2).YScale = 'log';
    axis([freq(1) freq(end) min(min(fftdata)) max(max(fftdata))])
    legend(ax(2), 'show', 'Location', 'NorthWest');
end