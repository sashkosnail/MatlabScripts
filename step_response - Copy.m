function pdata = step_response()
path = 'D:\Projects\PhD\vibSystem\sensor_data\';
[FileName,PathName,~] = uigetfile(strcat(path, '*.*'),'Pick File')  %#ok<NOPRT>
tab=readtable(strcat(PathName, FileName));
t = table2array(tab(:,1));
Ts = t(2)-t(1);
Fs = 1/Ts;
Wn = 512;
num_tests = 4;
data = table2array(tab(:,2:2:end));
pulse = table2array(tab(:,3:2:end));
data=data(:,1:4);data(isnan(data))=0;
pulse=abs(pulse(:,1:4));pulse(isnan(pulse))=0;
t=0:1/Ts:length(pulse)*Ts;
Nch = min(size(data)) %#ok<NOPRT>

fprintf(strcat('_____________________________________________________', ...
    '________________________________________________________________\n'));
fprintf(strcat('|Channel\t\t#P\t|\t\tA\t\t|\t\tD\t\t', ...
    '|\t\tmD\t\t|\t\tFn\t\t|\t\tmFn\t\t|\t\tFd\t\t|\n'));
fprintf(strcat('|\t\t\t\t\t|mean\tstd\t\t|mean\tstd\t\t', ...
    '|mean\tstd\t\t|mean\tstd\t\t|mean\tstd\t\t|mean\tstd\t\t|\n'))
fid = fopen(strcat(PathName, FileName(1:end-4), '_out.csv'),'w');
fprintf(fid, 'Channel,#P,A,,D,,Fn,,Fd\n');
fprintf(fid, ',,mean,std,mean,std,mean,std,mean,std\n');

[num, den] = butter(4, 40*2*pi/Fs, 'low');
ft = fittype(strcat(...
    'A*exp(-D*w0*((n+n0)*Ts))*(D*w0*cos(w0*((n+n0)*Ts)*sqrt(1-D^2)', ...
    '-asin(D))+sin(w0*((n+n0)*Ts)*sqrt(1-D^2)-asin(D))*w0*sqrt(1-D^2))'), ...
    'independent', 'n', 'problem', 'Ts');
fo = fitoptions(ft);
fo.Lower = [0.001, 0.3, 0, 18.85];
fo.Upper = [0.1, 0.9, 0, 31.42];
fo.StartPoint = [0.01, 0.7, 0, 4.5*2*pi];

for i=1:1:Nch
    figure(mod(i-1,num_tests)+1);clf;
    a = filtfilt(num, den, data(:, i));
    %SELECT PEAK
    peak_id = 1;
    while true
        window_size = min(length(a),Wn);
        inmean = mean(a(1:100));
        peak_threshold = 40*max(a(1:100)-inmean);
        k = find(abs(a - inmean) > peak_threshold, 1, 'first');  
        
        if isempty(k)
            break;
        end
%         kk = find(abs(a(k-20:k))>2*std(a(k-20:k-1)),1,'first')
        start_id = k;
        
        %interim plots
%         figure(101);clf;hold on;
%         plot(abs(a(max(1,k+1-window_size):k+window_size) - inmean), 'k');
%         plot(window_size*[0; 2], peak_threshold*[1; 1], 'r--');
%         plot(window_size*[1; 1], [0; 1],'--b');
%         plot(window_size, abs(a(k)),'bx');
%         plot(window_size, abs(a(start_id)),'gx');
%         plot(window_size+(-1:1), abs(a(k-1:k+1)), 'kx');
%         axis([window_size*[.9 1.1] 0 abs(a(k+10))]);
        
        figure(100);clf;hold on;
        plot(a);
        plot([start_id start_id] ,[-.5 .5],'r--');
%         set(gca, 'xlim', [start_id-100 start_id+100]);
%          tmp=ginput(1);
        
        %CHOP OFF PEAK
        if(length(a) < start_id + window_size)
            peak = a(start_id:end);
            a = a(1:start_id);
        else
            peak = a(start_id:start_id+window_size);
            a = a((start_id+window_size):end);
        end
        %keep only retrun to zero peaks
        offset = mean(peak(end:-1:end-100));
        if abs(offset)>0.075
            continue;
        end
        %zero peak offset
        peak = peak - offset;
        if (peak(5)-peak(4))<0
            peak = -peak;
        end
        %refine beggining
        zc = find(peak > 0, 1, 'first');
        peak = [0; peak(zc:end)];
        %CALCULATE parameters
        [mx, mi] = max(peak);
        [~, ni] = min(peak(mi:end));
        if((ni+mi)<11||length(peak)<(ni+mi+10))
            break;
        end
        nx = mean(peak(ni+mi-10:ni+mi+10));
        extr = sort(abs([mx nx]));
        A = abs(extr(2)/extr(1));
        D = (1+(pi/log(A))^2)^-0.5;
        Fd = 1/(2*Ts*ni);
        Fn = Fd/sqrt(1-D^2);
        
%         %correct step-in
%         lp = ceil(mi./2);
%         rate = mean(diff(peak(1:lp)));
%         for ii=lp:-1:1
%             peak(ii) = peak(ii+1)-rate;
%         end
        
        %nLMS optimize generic response curve
        n=(1:1:length(peak))';
        [fpeak, gof] = fit(n, peak, ft, fo, 'problem', Ts);
        
        %PLOT DATA
        figure(mod(i-1,num_tests)+1);hold on;
        plot(peak);
        plot([0 ni-1]+mi,[mx nx],'x');
        set(gca, 'xlim', [0 window_size-1]);
        set(gcf, 'name', tab.Properties.VariableNames{1+i});
        
        %STORE DATA
        peakd.Name = tab.Properties.VariableNames{1+i};
        peakd.Ch = i;
        peakd.ID = peak_id;
        peakd.A = fpeak.A;
        peakd.GOF = gof;
        peakd.Fd = Fd;
        peakd.Fn = fpeak.w0/(2*pi);
        peakd.D  = fpeak.D;
        peakd.mFn = Fn;
        peakd.mD  = D;
        peakd.Data = peak;
        peakd.Fit = fpeak;
        pdata(i,peak_id) = peakd; %#ok<AGROW>
        peak_id = peak_id+1;
        
        %PRINT DATA
%          disp(peakd.Fn);
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
    fprintf('|%2d(%s)\t%d', i, tab.Properties.VariableNames{1+i}, peak_id-1);
    fprintf('\t|%6.3f\t%6.3f', mean(Aavg), std(Aavg));
    fprintf('\t|%6.3f\t%6.3f', mean(Davg), std(Davg));
    fprintf('\t|%6.3f\t%6.3f', mean(mDavg), std(mDavg));
    fprintf('\t|%6.3f\t%6.3f', mean(Fnavg), std(Fnavg));
    fprintf('\t|%6.3f\t%6.3f', mean(mFnavg), std(mFnavg));
    fprintf('\t|%6.3f\t%6.3f\t|\n', mean(Fdavg), std(Fdavg)); 
    fprintf(fid, '%2d(%s),%d', i, tab.Properties.VariableNames{1+i}, peak_id-1);
    fprintf(fid, ',%6.3f,%6.3f', mean(Aavg), std(Aavg));
    fprintf(fid, ',%6.3f,%6.3f', mean(Davg), std(Davg));
    fprintf(fid, ',%6.3f,%6.3f', mean(Fnavg), std(Fnavg));
    fprintf(fid, ',%6.3f,%6.3f\n', mean(Fdavg), std(Fdavg)); 
end
fclose(fid);
fprintf('----------------------------------------------------------------------------------------------------------------------\n');
end