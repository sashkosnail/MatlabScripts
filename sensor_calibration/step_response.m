function [pdata_n, pdata_p] = step_response(xlsfile)
tables_n=readtable(xlsfile, 'Sheet', 'N');
tables_p = table();
pdata_n = [];
pdata_p = [];
% tables_p=readtable(xlsfile, 'Sheet', 'P');
dir = 'n';
for ctab = {tables_n}
    tab = ctab{1};
    t = table2array(tab(:,1));
    Ts = t(2)-t(1);
    Fs = 1/Ts;
    Wn = 2048;
    num_tests = 3;
    data = table2array(tab(:,2:2:2*num_tests+1));
    pulse = table2array(tab(:,3:2:2*num_tests+1));
    pulse(isnan(pulse))=0;
    data=data(:,1:num_tests);
    data(isnan(data))=0;
    pulse=pulse(:,1:num_tests)<rms(rms(pulse))/2;
    Nch = min(size(data)) %#ok<NOPRT>

    fprintf(strcat('____________________________________________________________________', ...
        '________________________________________________________________\n'));
    fprintf(strcat('|Channel\t\t#P\t|\t\tA\t\t|\t\tmA\t\t', ...
        '|\t\tD\t\t|\t\tmD\t\t|\t\tFn\t\t|\t\tmFn\t\t|\t\tFd\t\t|\n'));
    fprintf(strcat('|\t\t\t\t\t|mean\tstd\t\t|mean\tstd\t\t|', ...
        'mean\tstd\t\t|mean\tstd\t\t|mean\tstd\t\t|mean\tstd\t\t|', ...
        'mean\tstd\t\t|\n'))

    [num, den] = butter(8, 5*2*pi/Fs, 'low');

    for i=1:1:Nch
%         p=diff(pulse(:,i));
        p=data(:,i);
        figure(mod(i-1,num_tests)+1);clf;
        a = filtfilt(num, den, data(:, i));
        %SELECT PEAK
        peak_id = 1;
        while true
            window_size = min(length(a),Wn);
            if(isempty(a))
                break;
            end
            [~,k] = findpeaks(abs(a), 'Npeaks', 1, 'minpeakheight', 0.9*min(max(a),75));  
            if isempty(k)
                break;
            end
            start_id = k-70;
            figure(100);clf;hold on;
            plot(a); set(gcf, 'Toolbar','none');
            plot([start_id start_id] ,[-.5 .5],'r--');
            %CHOP OFF PEAK
            if(length(a) < start_id + window_size)
                peak = a(start_id:end);
                a = [];
                p = [];
            else
                peak = a(start_id:start_id+window_size);
                a = a((start_id+window_size):end);
                p = p((start_id+window_size):end);
            end
            offset = mean(peak(end:-1:end-700));
            %zero peak offset
            peak = peak - offset;
            if (peak(51)-peak(50))<0
                continue;
            end
            %CALCULATE parameters
%             [~, mi] = max(peak);
%             [~, ni] = min(peak(mi:end));
%             [~, ti] = max(peak(mi+ni:end));
%             ws = 5;
%             if((ni+mi)<11||length(peak)<(ni+mi+ti+ws))
%                 continue;
%             end
%             mx = mean(peak(mi-ws:mi+ws));
%             nx = mean(peak(ni+mi-ws:ni+mi+ws));
%             tx = mean(peak(ti+ni+mi-ws:ti+ni+mi+ws));
%             extr = sort(abs([mx nx tx]));
            ws = floor(Fs/250);
            [pks, locs] = findpeaks(peak,'Npeaks',2,'MinPeakDistance',100,'MinPeakProminence', 0.065);
            extr = zeros(1,length(pks)*2);
            mFd = zeros(1,length(pks));
            min_id = zeros(length(pks),1);
            for jj=1:length(locs)
                extr(2*jj-1) = abs(mean(peak(locs(jj)-ws:locs(jj)+ws)));
                [~, min_id(jj)] = min(peak(locs(jj):end));
                mFd(jj) = 1/(2*Ts*min_id(jj));
                extr(2*jj) = abs(mean(peak(min_id(jj)+locs(jj)-ws:min_id(jj)+locs(jj)+ws)));                
            end
%             A = mean(extr(2:end)./extr(1:end-1));
            if(length(extr)>=3)
                A = (extr(1)+extr(2))/(extr(2)+extr(3));
            else
                A = extr(1)/extr(2);
            end
            D = (1+(pi/log(A))^2)^-0.5;
            Fd = mean(mFd);
            Fn = Fd/sqrt(1-D^2);

            %nLMS optimize generic response curve
            peakd = fit_test(peak, tab.Properties.VariableNames{2*i}, Ts);
            peakd.Ch = i;
            peakd.ID = peak_id;
            peakd.Fd = Fd;
            peakd.mFn = Fn;
            peakd.mD  = D;
            peakd.mA = A;
            pdata(i,peak_id) = peakd; %#ok<AGROW>
            peak_id = peak_id+1;    

            %PLOT DATA
            figure(mod(i-1,1)+1);hold on;
            plot(peak);
            plot(sort([locs; locs + min_id]) ,sort(extr, 'descend').*(-1).^(2:length(extr)+1),'x');
            set(gca, 'xlim', [0 window_size-1]);
            set(gcf, 'name', peakd.Name);
            
            if(length(a) < start_id + window_size)
                break;
            end
            drawnow();
        end
        Davg = zeros(peak_id-1,1);
        mDavg = zeros(peak_id-1,1);
        Aavg = zeros(peak_id-1,1);
        mAavg = zeros(peak_id-1,1);
        Fdavg = zeros(peak_id-1,1);
        Fnavg = zeros(peak_id-1,1);
        mFnavg = zeros(peak_id-1,1);
        for j=1:1:peak_id-1
            Davg(j) = pdata(i,j).D;
            mDavg(j) = pdata(i,j).mD;
            Aavg(j) = pdata(i,j).A;
            mAavg(j) = pdata(i,j).mA;
            Fnavg(j) = pdata(i,j).Fn;
            mFnavg(j) = pdata(i,j).mFn;
            Fdavg(j) = pdata(i,j).Fd;
        end
        if(mod(i,num_tests)==1)
            fprintf(strcat('+-------------------+---------------', ...
                '+---------------+---------------+---------------', ...
                '+---------------+---------------', ...
                '+---------------+\n'));
        end
        fprintf('|%2d(%s)\t%d\t', i, tab.Properties.VariableNames{2*i}, peak_id-1);
        fprintf('\t|%6.3f\t%6.3f', mean(Aavg), std(Aavg));
        fprintf('\t|%6.3f\t%6.3f', mean(mAavg), std(mAavg));
        fprintf('\t|%6.3f\t%6.3f', mean(Davg), std(Davg));
        fprintf('\t|%6.3f\t%6.3f', mean(mDavg), std(mDavg));
        fprintf('\t|%6.3f\t%6.3f', mean(Fnavg), std(Fnavg));
        fprintf('\t|%6.3f\t%6.3f', mean(mFnavg), std(mFnavg));
        fprintf('\t|%6.3f\t%6.3f\t|\n', mean(Fdavg), std(Fdavg)); 
    end
    fprintf('-------------------------------------------------------------------------------------------------------------------------------------\n'); 
    if(dir=='n')
        pdata_n = pdata;
    else
        pdata_p = pdata;
    end
    dir = 'p';
end
end