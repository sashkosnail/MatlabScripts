function [pdata_n, pdata_p] = step_response(xlsfile)
tables_n=readtable(xlsfile, 'Sheet', 'n');
tables_p=readtable(xlsfile, 'Sheet', 'p');
dir = 'n';
for ctab = {tables_n, tables_p}
    tab = ctab{1};
    t = table2array(tab(:,1));
    Ts = t(2)-t(1);
    Fs = 1/Ts;
    Wn = 1024;
    num_tests = 4;
    data = table2array(tab(:,2:2:end));
    pulse = abs(table2array(tab(:,3:2:end)));
    pulse(isnan(pulse))=0;
    data=data(:,1:4);
    data(isnan(data))=0;
    pulse=pulse(:,1:4)>rms(rms(pulse));
    t=0:1/Ts:length(pulse)*Ts;
    Nch = min(size(data)) %#ok<NOPRT>

    fprintf(strcat('_____________________________________________________', ...
        '________________________________________________________________\n'));
    fprintf(strcat('|Channel\t\t#P\t|\t\tA\t\t|\t\tD\t\t', ...
        '|\t\tmD\t\t|\t\tFn\t\t|\t\tmFn\t\t|\t\tFd\t\t|\n'));
    fprintf(strcat('|\t\t\t\t\t|mean\tstd\t\t|mean\tstd\t\t', ...
        '|mean\tstd\t\t|mean\tstd\t\t|mean\tstd\t\t|mean\tstd\t\t|\n'))

    [num, den] = butter(4, 40*2*pi/Fs, 'low');

    for i=1:1:Nch
        p=diff(pulse(:,i));
        figure(mod(i-1,num_tests)+1);clf;
        a = filtfilt(num, den, data(:, i));
        %SELECT PEAK
        peak_id = 1;
        while true
            window_size = min(length(a),Wn);
            k = find(p<0, 1, 'first');  
            if isempty(k)
                break;
            end
            start_id = k+5;
            figure(100);clf;hold on;
            plot(a); set(gcf, 'Toolbar','none');
            plot([start_id start_id] ,[-.5 .5],'r--');
            %CHOP OFF PEAK
            if(length(a) < start_id + window_size)
                peak = a(start_id:end);
                a = a(start_id:end);
                p = p(start_id:end);
            else
                peak = a(start_id:start_id+window_size);
                a = a((start_id+window_size):end);
                p = p((start_id+window_size):end);
            end
            offset = mean(peak(end:-1:end-100));
            %zero peak offset
            peak = peak - offset;
            if (peak(5)-peak(4))<0
                peak = -peak;
            end
            %CALCULATE parameters
            [mx, mi] = max(peak);
            [~, ni] = min(peak(mi:end));
            if((ni+mi)<11||length(peak)<(ni+mi+10))
                continue;
            end
            nx = mean(peak(ni+mi-10:ni+mi+10));
            extr = sort(abs([mx nx]));
            A = abs(extr(2)/extr(1));
            D = (1+(pi/log(A))^2)^-0.5;
            Fd = 1/(2*Ts*ni);
            Fn = Fd/sqrt(1-D^2);

            %nLMS optimize generic response curve
            peakd = fit_test(peak, tab.Properties.VariableNames{2*i}, Ts);
            peakd.Ch = i;
            peakd.ID = peak_id;
            peakd.Fd = Fd;
            peakd.mFn = Fn;
            peakd.mD  = D;
            pdata(i,peak_id) = peakd; %#ok<AGROW>
            peak_id = peak_id+1;    

            %PLOT DATA
            figure(mod(i-1,num_tests)+1);hold on;
            plot(peak);
            plot([0 ni-1]+mi,[mx nx],'x');
            set(gca, 'xlim', [0 window_size-1]);
            set(gcf, 'name', peakd.Name);
        end
        Davg = zeros(peak_id-1,1);
        mDavg = zeros(peak_id-1,1);
        Aavg = zeros(peak_id-1,1);
        Fdavg = zeros(peak_id-1,1);
        Fnavg = zeros(peak_id-1,1);
        mFnavg = zeros(peak_id-1,1);
        for j=1:1:peak_id-1
            Davg(j) = pdata(i,j).D;
            mDavg(j) = pdata(i,j).mD;
            Aavg(j) = pdata(i,j).A;
            Fnavg(j) = pdata(i,j).Fn;
            mFnavg(j) = pdata(i,j).mFn;
            Fdavg(j) = pdata(i,j).Fd;
        end
        if(mod(i,num_tests)==1)
            fprintf(strcat('+-------------------+---------------', ...
                '+---------------+---------------+---------------', ...
                '+---------------+---------------+\n'));
        end
        fprintf('|%2d(%s)\t%d', i, tab.Properties.VariableNames{2*i}, peak_id-1);
        fprintf('\t|%6.3f\t%6.3f', mean(Aavg), std(Aavg));
        fprintf('\t|%6.3f\t%6.3f', mean(Davg), std(Davg));
        fprintf('\t|%6.3f\t%6.3f', mean(mDavg), std(mDavg));
        fprintf('\t|%6.3f\t%6.3f', mean(Fnavg), std(Fnavg));
        fprintf('\t|%6.3f\t%6.3f', mean(mFnavg), std(mFnavg));
        fprintf('\t|%6.3f\t%6.3f\t|\n', mean(Fdavg), std(Fdavg)); 
    end
    fprintf('----------------------------------------------------------------------------------------------------------------------\n'); 
    if(dir=='n')
        pdata_n = pdata;
    else
        pdata_p = pdata;
    end
    dir = 'p';
end
end