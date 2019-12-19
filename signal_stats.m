function Stats = signal_stats(D, names)
    data = D(:,2:end);
    t=D(:,1);Fs = 1/(t(2)-t(1));
	if(Fs<=0)
		Fs = 250;
	end
    
    filter_cutoff = 10;
    [fnum, fden] = butter(4, filter_cutoff*2/Fs, 'low');
    fdata_10Hz = filtfilt(fnum, fden, data);
    filter_cutoff = 1;
    [fnum, fden] = butter(4, filter_cutoff*2/Fs, 'low');
    fdata_1Hz = filtfilt(fnum, fden, data);
    
    Stats = array2table([mean(data); std(data); min(data); ...
        max(data); range(data); range(fdata_10Hz(end/2:end,:)); ...
        range(fdata_1Hz(end/2:end,:))], 'RowNames', ...
        {'offset', 'RMS', 'Min', 'Max', 'Vpp', 'Vpp_10Hz', 'Vpp_1Hz'}, ...
        'VariableNames', names);