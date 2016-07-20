function calc_spectrum(idc)
    global fig_spectrum;
    global fig_tseries;
    global Ns;
    global Fs;
    global Filters;
    global Nch;
    persistent h_old;
    global figs2; 
    global fft_data;
    fig = fig_spectrum(idc);
    
    limit = int32(fig_tseries(idc).XLim*Fs);
    tmp = range(limit);
    data = zeros([tmp, 5]);
    for k=1:1:Nch
        child = fig_tseries(idc).Children(Nch-k+1);
        tmp = child.YData(limit(1)+1:limit(2));
        data(:,k) = tmp;
    end
    fft_data2 = fft(data.*repmat(ones(Ns,1),1,5), Ns, 1)/Ns;
    fft_data_theta = angle(fft_data2);
    fft_data_ampli = abs(fft_data2);
    fft_data = fft_data_ampli(1:Ns/2,:);
    fft_data(2:end-1,:) = 2*fft_data(2:end-1,:);

    [ff, w] = freqz(Filters.BH, Ns/2);
    f=w./(2*pi/Fs);
    fresp = abs(ff);
    fresp(1:15) = fresp(16);

    mod_data = data;
    mod_fft = fft_data;
    for k=1:1:Nch
        if(isempty(regexp(fig_tseries(idc).Children(Nch-k+1).DisplayName,'[A-Z]','ONCE')))
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

    h = plot(fig, repmat(f, 1, 5), fft_data);
    figure(figs2(1));clf;
    loglog(f, fft_data, '-');hold on;
    loglog(f, mod_fft,'--');
    loglog(f, fresp, 'k:');
    figure(figs2(2));clf;
    t=0:1/Fs:(length(data)-1)/Fs;
    plot(t, data, '-');hold on;
    mod_data(isnan(mod_data))=0;
    plot(t, mod_data,'--','DisplayName','ModData');
    
    if(isempty(h_old))
        h_old = repmat(h,1,3);
    end
    delete(h_old(:,idc));
    h_old(:,idc) = h;
    for k=1:1:Nch
        child = fig_tseries(idc).Children(Nch-k+1);
        h(k).Color = child.Color;
        h(k).DisplayName = child.DisplayName;
        if(strcmpi(child.Visible, 'on'))
            h(k).Visible = 'on'; 
        else
            h(k).Visible = 'off'; 
        end
    end
end