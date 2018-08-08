function fig = plot_sensor_data(D, fig_name, names)
    Nsensors = (size(D,2)-1)/3;    
    t=D(:,1);Fs = 1/(t(2)-t(1));
    data = D(:,2:end);
    N = 2^(nextpow2(length(data))-1);
    fftdata = data(1:1:N,:);
    fftdata = abs(fft(fftdata, N, 1)/N);
    fftdata = abs(fftdata(ceil(1:N/2),:));
    fftdata(2:end-1,:) = 2*fftdata(2:end-1,:);
    fftdata_filt = fftdata;
%     fftdata_filt = filtfilt(triang(11)',1,fftdata);
%     fft_range = max(max(abs(fftdata_filt)));
    
    f = Fs*(1:N/2)'/N;
    
    fig = figure(1);
    set(fig, 'Name', fig_name); clf
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);

    for ch_idx = 1:1:Nsensors
        data_id = ((ch_idx-1)*3+1):(ch_idx*3);
        H = sqrt(fftdata_filt(:,data_id(1)).^2 + fftdata_filt(:,data_id(2)).^2);
        V = fftdata_filt(:,data_id(3));
        
        subaxis(Nsensors,3,ch_idx*3-2,'ML',0.02);
        subsamplewindow = 1:min(15*Fs,length(data));
        plot(t(subsamplewindow),data(subsamplewindow,data_id));    
        xlim([10 10.5])
        grid on; grid minor
        
        subaxis(Nsensors,3,ch_idx*3-1);
        plot(t,data(:,data_id));    
        legend(names((ch_idx-1)*3+1:(ch_idx-1)*3+3), 'Interpreter', 'none')
        xlim([t(1) t(end)]);
        grid on;
        
        subaxis(Nsensors,3,ch_idx*3);
        loglog(f,abs(fftdata_filt(:,data_id)));
        hold on; grid on; grid minor
        HVSR  = filtfilt(triang(min(41,floor(length(H)/3)))',1, H./V);
        HVSR = HVSR *mean(std(fftdata_filt(:,data_id))/std(HVSR));
        loglog(f, HVSR,'k');
        xlim([min(f) max(f)])
    end
    drawnow()
end