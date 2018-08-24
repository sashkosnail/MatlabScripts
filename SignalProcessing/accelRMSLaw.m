global OUTPUT
figure(2222);clf
N = length(OUTPUT.Data);
M = OUTPUT.Data{1}.Nsensors;
rmsTotal = zeros(N,M);
max_data = 0;
ax = cell(M,N);
for n = 1:1:N
    accel = OUTPUT.Data{n}.DATA.Acceleration;
    t = OUTPUT.Data{n}.DATA.Time;
    for m = 1:1:M
        ch_ids = (m-1)*3+1:1:m*3;
        
        rmsTotal(n, m) = sqrt(sum(rms(accel(:, ch_ids)).^2));
        ampTotal = sqrt(sum(accel(:, ch_ids).^2, 2));
        max_data = max(max(ampTotal), max_data);
        ax{m,n} = subaxis(M, N, n, m, ...
            'ML', 0.03, 'MT', 0.05, 'MR', 0.01, 'MB', 0.05, 'S', 0.05);
        plot(t, ampTotal, 'k'); hold on
        plot([t(1) t(end)], rmsTotal(n, m)*[1 1], 'r');
        axis tight
        title([OUTPUT.Sensor_configuration.SensorNames{m} ' RMS:' num2str(rmsTotal(n,m)) 'mm/s^2']);
        if(n==1&&m==M)
            ylabel('Total Vector Amplitude[mm/s^2]');
            xlabel('Time[s]');
        end
    end    
end
for n = 1:1:N
    for m = 1:1:M
        ax{m,n}.YLim = [0 max_data];
    end
end
rmsMean = geomean(rmsTotal);
table_data = [rmsMean; 20*log10(rmsMean/10^-6)];
rmsTable = array2table(table_data);
rmsTable.Properties.RowNames = {'RMS[m/s^2]', 'L_a_w[dB]'};
rmsTable.Properties.VariableNames = OUTPUT.Sensor_configuration.SensorNames;
disp(rmsTable)