function fig = plot_GEODE_data(D, fig_name)
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
    
    fig = figure();
    set(fig, 'Name', fig_name); clf
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);

    for ch_idx = 1:1:Nsensors
        data_id = ((ch_idx-1)*3+1):(ch_idx*3);
        
        subaxis(Nsensors,3,ch_idx*3-2,'ML',0.02,'MB',0.05);
        subsamplewindow = 1:min(15*Fs,length(data));
        plot(t(subsamplewindow),data(subsamplewindow,data_id));    
        xlim([0 1])
        grid on; grid minor
        
        subaxis(Nsensors,3,ch_idx*3-1,'MB',0.05);
        plot(t,data(:,data_id));    
        legend(cellfun(@(c) strcat(num2str(ch_idx),'_',c), {'x','y','z'}, ...
			'UniformOutput', 0), 'Interpreter', 'none')
        xlim([t(1) t(end)]);
        grid on;
        
        subaxis(Nsensors,3,ch_idx*3,'MB',0.05);
        loglog(f,abs(fftdata_filt(:,data_id)));
        hold on; grid on; grid minor
        xlim([min(f) max(f)])
        ylim([10^-6 1]*max(max(abs(fftdata_filt(:,data_id)))))
    end
    drawnow()
end