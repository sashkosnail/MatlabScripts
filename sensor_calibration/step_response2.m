function [output_data] = step_response2(xlsfile, fit_params, polarity)

tables_n=readtable(xlsfile, 'Sheet', polarity);
output_data = [];
figure(1);clf;
for ctab = {tables_n}
    tab = ctab{1};
    t = table2array(tab(:,1));
    Ts = t(2)-t(1);
    Fs = 1/Ts;
    Wn = 512;
    num_tests = (width(tab)-1)/2;
    
    data = table2array(tab(:,2:2:2*num_tests+1));
	pulses = table2array(tab(:,3:2:2*num_tests+1));
    data(isnan(data))=0;
	pulses(isnan(pulses))=0;
    Nch = min(size(data)) %#ok<NOPRT>

    fprintf(strcat('_________________________________________________________________', ...
        '____________________________________________________________________\n'));
    fprintf(strcat('|Channel\t\t#P\t|\t\tA\t\t|\t\tmA\t\t', ...
        '|\t\tD\t\t|\t\tmD\t\t|\t\tFn\t\t|\t\tmFn\t\t|\t\tFd\t\t|\n'));
    fprintf(strcat('|\t\t\t\t\t|mean\tstd\t\t|mean\tstd\t\t|', ...
        'mean\tstd\t\t|mean\tstd\t\t|mean\tstd\t\t|mean\tstd\t\t|', ...
        'mean\tstd\t\t|\n'))

    [num, den] = butter(8, 32*2/Fs, 'low');
    for i=1:1:Nch
        p=data(:,i);
		pls=pulses(:,i);
        if (polarity == 'P')
            p=-p;
        end
        figure(1);
        a = filtfilt(num, den, p);
        %SELECT PEAK
        peak_id = 1;
        figure(100);clf;old_start = 0;hold on; start_id = 0;
        plot(a); set(gcf, 'Toolbar','none'); plot(pls);
        while true
            if(isempty(a))
                break;
            end
            [~,k] = findpeaks(abs(a), 'Npeaks', 1, 'minpeakheight', 0.75*max(a));  
            if isempty(k)
                break;
            end
            if(start_id ~= 0)
                old_start = old_start + start_id + window_size - 200;
            end
            window_size = min(length(a),Wn);
            start_id = max(1, k-40);
            
            %CHOP OFF PEAK
            if(length(a) < start_id + window_size)
                peak = a(start_id:end);
                a = [];
                p = [];
            else
                peak = a(start_id:start_id+window_size);
                a = a((start_id+window_size-200):end);
                p = p((start_id+window_size-200):end);
            end
%             offset = mean(peak(end:-1:end-128));
            %zero peak offset
%             peak = peak - offset;
            
            %pick peak direction
            
            figure(100);hold on;
            
            if (peak(11)-peak(10))<0
                plot([old_start+start_id old_start+start_id] ,[-.5 .5],'r--');
                continue;
            else
                plot([old_start+start_id old_start+start_id] ,[-.5 .5],'g--');
            end

            ws = floor(Fs/250);
            [pks, locs] = findpeaks(peak,'Npeaks',2,'MinPeakDistance',25,'MinPeakProminence', 0.065);
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
            elseif(isempty(extr))
                break;
            else
                A = extr(1)/extr(2);
            end
            D = (1+(pi/log(A))^2)^-0.5;
            Fd = mean(mFd);
            Fn = Fd/sqrt(1-D^2);

            %nLMS optimize generic response curve
            peakd = fit_test2(peak, tab.Properties.VariableNames{2*i}, Ts, fit_params);
            peakd.Ch = i;
            peakd.ID = peak_id;
            peakd.Fd = Fd;
            peakd.mFn = Fn;
            peakd.mD  = D;
            peakd.mA = A;
            pdata(i,peak_id) = peakd; %#ok<AGROW>
            peak_id = peak_id+1;    

            %PLOT DATA
            figure(1);hold on;
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
        fprintf('|%s\t%d', tab.Properties.VariableNames{2*i}, peak_id-1);
        fprintf('\t|%6.3f\t%6.3f', mean(Aavg), std(Aavg));
        fprintf('\t|%6.3f\t%6.3f', mean(mAavg), std(mAavg));
        fprintf('\t|%6.3f\t%6.3f', mean(Davg), std(Davg));
        fprintf('\t|%6.3f\t%6.3f', mean(mDavg), std(mDavg));
        fprintf('\t|%6.3f\t%6.3f', mean(Fnavg), std(Fnavg));
        fprintf('\t|%6.3f\t%6.3f', mean(mFnavg), std(mFnavg));
        fprintf('\t|%6.3f\t%6.3f\t|\n', mean(Fdavg), std(Fdavg)); 
    end
    fprintf('-------------------------------------------------------------------------------------------------------------------------------------\n'); 
    output_data = pdata;
end
end