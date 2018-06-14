function D = myDecimate(data, factor, AAcutoff)
    t=data(:,1);
    Fs = 1/(t(2)-t(1));
    d=data(:,2:end);
    [fnum, fden] = butter(8, AAcutoff*2/Fs, 'low');

    fdata=filtfilt(fnum,fden, d);
    D=[t(1:factor:end) fdata(1:factor:end, :)];
end