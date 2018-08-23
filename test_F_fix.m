function test_F_fix
global OUTPUT
    t = OUTPUT.Data{1}.DATA.Time;
    data = OUTPUT.Data{1}.DATA.Velocity;
    off = zeros(length(t),1);
%     [t, data, off] = build_test_data();
%     data=data-off;
%     data = [data data(end:-1:1) 0.5*data];
    Ts = t(2)-t(1); Fs = 1/Ts;
    Nw = 0.015;
    Nf = 3*Fs;
    window = hanning(floor(Nw*length(data)));
    window = window/sum(window);
    mvmean = movmean(data,window);
    offset = movmean(mvmean,ones(Nf,1)/Nf);
    data1 = data - offset;
    result_offset = movmean(data1, window);

    figure(51); clf
    subplot(2,1,1)
    plot(t, data,'r');hold on
    plot(t,data1, 'k')
    legend('Original', 'Result')
    subplot(2,1,2)
    plot(t,[off mvmean offset result_offset])
    legend('Forced Offset','mvmean','Calc offset','Result Offset');

    %%
    taper = build_taper(t, 1.0);
    taper = repmat(taper, 1, size(data,2));
    data2 = (data1 - repmat(mean(data1),length(data1),1)).*taper;
    data3 = (data2 - repmat(mean(data2),length(data2),1)).*taper;

    disp(mean([data; data1; data2; data3]));

    figure(52);clf
    plot(t,[data1 data2 data3])

    %%
    dm = data3/1000;
    acc = diff(dm)/Ts/9.81;
    dsp = cumtrapz(t, dm)*1000;
    dsp_trend = movmean(dsp, ones(301,1));
    dfm = cumtrapz(t, dsp)*0.5./repmat((t+Ts),1 ,size(data,2));

    figure(53); clf

    subplot(4,1,1)
    plot(t(1:length(acc)),acc);
    ylabel('Acceleration[g]')
    grid on
    % xlim([0 10])

    subplot(4,1,2)
    plot(t,dm);
    ylabel('Velocity[m/s]')
    grid on
    % xlim([0 10])

    subplot(4,1,3)
    plot(t,dsp); hold on
    plot(t, dsp-dfm);
    ylabel('Displacement[mm]')
    grid on
    % xlim([0 100])

    subplot(4,1,4)
    plot(t,dfm);
    ylabel('Displacement[mm]')
    grid on
    % xlim([0 100])

    %%
    data4 = FixResponse(data3, 1, 0.5, Fs);
    fftdata3 = getFFT(data3);
    fftdata4 = getFFT(data4);
    f = Fs*(1:length(data)/2)'/length(data);
    figure(54); clf
    for i=1:1:3
        subaxis(3,3,i,1)
        plot(t, [data3(:,i), data4(:,i)]); hold on
        subaxis(3,3,i,2)
        loglog(f, fftdata3(:,i)); hold on
        subaxis(3,3,i,3)
        loglog(f, fftdata4(:,i)); hold on
    end
end

function fftdata = getFFT(data)
    N = length(data);
    specSmoothN = 31;
    window_function = repmat(hamming(N), 1, size(data,2));
    fftdata = abs(fft(data.*window_function, N, 1));
    fftdata = abs(fftdata(ceil(1:N/2),:));
    fftdata(2:end-1,:) = 2*fftdata(2:end-1,:);
    if(specSmoothN ~= 1)
        fftdata = filtfilt(ones(1,specSmoothN),1,fftdata);
    end
end