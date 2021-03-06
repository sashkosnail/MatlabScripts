global OUTPUT
fig = figure(2222);clf
fig.Color = 'w';
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
        title(sprintf('%s RMS:%3.3gm/s^2 L_a_w:%3.3gdB', ...
            OUTPUT.Sensor_configuration.SensorNames{m}, ...
            rmsTotal(n,m), 20*log10(rmsTotal(n,m)/10^-6)), 'FontSize', 8);
        if(n==1&&m==M)
            ylabel('Total Vector Amplitude[m/s^2]', ...
                'FontWeight', 'bold', 'FontSize', 12);
            xlabel('Time[s]', ...
                'FontWeight', 'bold', 'FontSize', 12);
        end
    end    
end
for n = 1:1:N
    for m = 1:1:M
        ax{m,n}.YLim = [0 max_data];
    end
end
rmsMean = mean(rmsTotal);
table_data = [rmsMean; 20*log10(rmsMean/10^-6)];
rmsTable = array2table(table_data);
rmsTable.Properties.RowNames = {'RMS[m/s^2]', 'L_a_w[dB]'};
rmsTable.Properties.VariableNames = OUTPUT.Sensor_configuration.SensorNames;
disp(rmsTable)
file = 'D:\Documents\PhD\FieldStudies\Holocim_Latacunga\2018\new_measurement\Result\RMS_Test11MillOn.xlsx';
writetable(rmsTable, file,'WriteRowNames',true)