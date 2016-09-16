function calc_spectrum(idc)
    global fig_spectrum;
    global fig_tseries;
    global Ns;
    global Fs;
    global Filters;
    global Nch;
    global h_old;
    global smooth_old;
    global figs2
    global fig_chan
    global fft_data;
    global ranges;
    
    fig = fig_spectrum(idc);
    limit = int32(fig_tseries(idc).XLim*Fs);
    tmp = range(limit);
    data = zeros([tmp, Nch]);
    for k=1:1:Nch
        child = fig_tseries(idc).Children(k);
        tmp = child.YData(limit(1)+1:limit(2));
        data(:,k) = tmp;
    end
    windata = data.*repmat(ones(Ns,1),1,Nch);
    if(Ns>10000)
        win_size = Fs*1;
        window = bartlett(win_size);
    %     [smooth_data, b] = envelope(data, win_size, 'peak');
        smooth_data = apply_window(window(1:end-1),abs(-data))*sqrt(win_size)/2;
        smooth_data = smooth_data - ones(length(smooth_data),1)*mean(smooth_data);
    %     smooth_data = smooth_data.*repmat(rms(data)./rms(smooth_data), length(data),1);
    end
    fftdata = fft(windata, Ns, 1)/Ns;
    fft_data_theta = angle(fftdata);
    fft_data_ampli = abs(fftdata);
    fftdata = fftdata(1:Ns/2,:)+fftdata(end:-1:1+Ns/2,:);
    fft_data = abs(fftdata);

    t = repmat(1/Fs*(double(limit(1)+1.0:1.0:limit(2))), Nch, 1)';
    [ff, w] = freqz(Filters.BH, Ns/2);
    f=w./(2*pi/Fs);
    fresp = abs(ff);
    fresp(1:15) = fresp(16);

    mod_data = data;
    mod_fft = fft_data;
    for k=1:1:Nch
        if(isempty(regexp(fig_tseries(idc).Children(k).DisplayName,'[A-Z]','ONCE')))
%             [a, b] = pol2cart(fft_data_theta(:,k), mod_fft(:,k));
            mod_fft(:,k) = fft_data(:,k)./fresp;
            a = 1;%sum(fft_data(:,k-1))/sum(mod_fft(:,k));
            mod_fft(:,k) = mod_fft(:,k)*a;
            [tmp1, tmp2] = pol2cart(fft_data_theta(:,k), fft_data_ampli(:,k).*[fresp; flip(fresp)]*a);
            mod_data(:,k) = real(ifft([tmp1, tmp2]*[1;1i], 'nonsymmetric')*Ns);
            b = 1;%std(data(:,k-1))/std(mod_data(:,k));
            mod_data(:,k)=mod_data(:,k)*b;
            if(~isnan(a*b))
                disp(a*b)
            end
        end
    end

    h = plot(fig, repmat(f, 1, Nch), fft_data);
    [~, peak_idx] = max(fft_data);
    for l=1:Nch
        ranges(4,(l-1)*3+idc) = f(peak_idx(Nch-l+1));
    end
    for k=1:1:Nch
        if(Ns>10000)
            if(isempty(smooth_old))
                smooth_old = repmat(smooth_h,Nch,3);
            end
            delete(smooth_old(k,idc));
            smooth_h = plot(fig_chan(idc,Nch-k+1), t(:,k), smooth_data(:,k),'r');
            smooth_old(k,idc) = smooth_h;
        else
            if(~isempty(smooth_old))
                delete(smooth_old(k,idc));
            end
        end
    end
%     figure(figs2(1));clf;
%     loglog(f, fft_data, '-');hold on;
%     loglog(f, mod_fft,'--');
%     loglog(f, fresp, 'k:');
%     figure(figs2(2));clf;
%     t=0:1/Fs:(length(data)-1)/Fs;
%     plot(t, data, '-');hold on;
%     mod_data(isnan(mod_data))=0;
%     plot(t, mod_data,'--','DisplayName','ModData');
    
    if(isempty(h_old))
        h_old = repmat(h,1,3);
    end
    delete(h_old(:,idc));
    h_old(:,idc) = h;
    
    for k=1:1:Nch
        child = fig_tseries(idc).Children(k);
        h(k).Color = child.Color;
        h(k).DisplayName = child.DisplayName;
        if(strcmpi(child.Visible, 'on'))
            h(k).Visible = 'on'; 
        else
            h(k).Visible = 'off'; 
        end
    end
end