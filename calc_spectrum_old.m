function calc_spectrum(idc)
    global fig_spectrum;
    global fig_tseries;
    global Ns;
    global Fs;
    global Nch;
    
    persistent h_old;
    
    fig = fig_spectrum(idc);
    
    limit = int32(fig_tseries(idc).XLim*Fs);
    tmp = range(limit);
    data = zeros([tmp, Nch]);
    for i=1:1:Nch
        child = fig_tseries(idc).Children(6-i);
        tmp = child.YData(limit(1)+1:limit(2));
        data(:,i) = tmp;
    end
    fft_data2 = abs(fft(data.*repmat(hamming(Ns), 1, Nch), Ns, 1)/Ns);
    fft_data = fft_data2(1:Ns/2,:);
    fft_data(2:end-1,:) = 2*fft_data(2:end-1,:);
    f = Fs*(1:Ns/2)'/Ns;
    h = plot(fig, repmat(f, 1, Nch), fft_data);
    if(isempty(h_old))
        h_old = repmat(h,1,3);
    end
    delete(h_old(:,idc));
    h_old(:,idc) = h;
    for i=1:1:Nch
        child = fig_tseries(idc).Children(6-i);
        h(i).Color = child.Color;
        h(i).DisplayName = child.DisplayName;
        if(strcmpi(child.Visible, 'on'))
            h(i).Visible = 'on'; 
        else
            h(i).Visible = 'off'; 
        end
    end
end