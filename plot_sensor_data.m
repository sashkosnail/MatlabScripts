function [fig, Stats] = plot_sensor_data(D, data_string)
    Nsensors = (size(D,2)-1)/3;
    names = cell(Nsensors*3,1);
    for sen_id = 1:1:Nsensors
        names{(sen_id-1)*3+1} = ['X' num2str(sen_id)];
        names{(sen_id-1)*3+2} = ['Y' num2str(sen_id)];
        names{(sen_id-1)*3+3} = ['Z' num2str(sen_id)];
    end
    
    t=D(:,1);Fs = 1/(t(2)-t(1));
    data = D(:,2:end);
%     data_range = [-1 1].*max(max(abs(D))); 
    
    filter_cutoff = 10;
    [fnum, fden] = butter(4, filter_cutoff*2/Fs, 'low');
    fdata_10Hz = filtfilt(fnum, fden, data);
    filter_cutoff = 1;
    [fnum, fden] = butter(4, filter_cutoff*2/Fs, 'low');
    fdata_1Hz = filtfilt(fnum, fden, data);
    
    Stats = array2table(1000*[mean(data); std(data); range(data); range(fdata_10Hz(end/2:end,:)); range(fdata_1Hz(end/2:end,:))]);
    Stats.Properties.RowNames = {'offset', 'RMS', 'Vpp', 'Vpp_10Hz', 'Vpp_1Hz'};
    Stats.Properties.VariableNames = names;
    
    N = 2^(nextpow2(length(data))-1);
    fftdata = data(1:1:N,:);
    fftdata = abs(fft(fftdata.*repmat(hamming(N), 1, Nsensors*3), N, 1)/N);
    fftdata = abs(fftdata(ceil(1:N/2),:));
    fftdata(2:end-1,:) = 2*fftdata(2:end-1,:);
    fftdata_filt = filtfilt(triang(11)',1,fftdata);
%     fft_range = max(max(abs(fftdata_filt)));
    
    f = Fs*(1:N/2)'/N;
    
    fig = figure(1);
    set(fig, 'Name', data_string); clf
    pause(0.00001);
    frame_h = get(handle(fig),'JavaFrame');
    set(frame_h,'Maximized',1);

    for ch_idx = 1:1:Nsensors
        data_id = ((ch_idx-1)*3+1):(ch_idx*3);
        H = sqrt(fftdata_filt(:,data_id(1)).^2 + fftdata_filt(:,data_id(2)).^2);
        V = fftdata_filt(:,data_id(3));
        
        subaxis(Nsensors,3,ch_idx*3-2,'ML',0.02);
        plot(t(1:15*Fs),data(1:15*Fs,data_id));    
        xlim([10 10.5])
        grid on; grid minor
        
        subaxis(Nsensors,3,ch_idx*3-1);
        plot(t,data(:,data_id));    
        legend(names{(ch_idx-1)*3+1:(ch_idx-1)*3+3})
        xlim([t(1) t(end)]);
        grid on;
        
        subaxis(Nsensors,3,ch_idx*3);
        loglog(f,abs(fftdata_filt(:,data_id)));
        hold on; grid on; grid minor
        HVSR  = filtfilt(triang(41)',1, H./V);
        HVSR = HVSR *mean(std(fftdata_filt(:,data_id))/std(HVSR));
        loglog(f, HVSR,'k');
        xlim([0.1 32])
    end
    
    drawnow()
end