path = 'D:\Documents\PhD\Ecuador\';
fs = 1000;
[FileName,PathName,FilterIndex] = uigetfile(strcat(path, '*.txt'),'Pick File') %#ok<NOPTS>
fid = fopen(strcat(PathName, FileName));
channels = fgetl(fid);
% channels = strsplit(channels,'"');
% channels = channels(4:2:end);
channels = strsplit(channels,'\t');
channels = channels(2:1:end);
fclose(fid);
data = dlmread(strcat(PathName, FileName), '\t', 1, 0);
Nch = length(channels);
t=0:1/fs:(length(data)-1)/fs;
data=data(:,2:end);
ns=2^nextpow2(length(data)*5);
[b, a] = butter(4, 30*pi/fs, 'low');
data = filtfilt(b,a,data);
% for i=1:1:Nch
%     data_interp(:,i) = interp(data(:,i),5);
% end
fft_data2 = fft(data, ns, 1)/ns;
fft_data = abs(fft_data2(1:ns/2,:));
ff = linspace(0, fs/2, ns/2);
adata = diff(data)*fs/1000;%[m/s]
idata = cumsum(data)/fs;%[mm]

fspec = figure('MenuBar', 'none', 'Toolbar', 'figure', 'Name', 'Spectrum');
facc = figure('MenuBar', 'none', 'Toolbar', 'figure', 'Name', 'Acceleration');
fvel = figure('MenuBar', 'none', 'Toolbar', 'figure', 'Name', 'Velocity');
fdisp = figure('MenuBar', 'none', 'Toolbar', 'figure', 'Name', 'Displacement');
for i=1:1:Nch 
    figure(fspec)
    hf=subplot('Position', [0.05 (0.05+(1/Nch-(i~=1)*0.004)*(i-1)) 0.9 0.80/Nch]);
    semilogx(ff, fft_data(:,i),'k');
    h=title(channels{i});
    set(h,'units','normalized', 'Position', [1.0 0.75]);
    if(i~=1)
        hf.XAxis.Visible = 'off';
    else
        xlabel('Frequency[Hz]');
        hf.XAxis.TickValues = [3 6 9 12 15 18 21 24];
    end
    hf.Box='off';
    hf.XLim = [3 30]; %hf.YLim = [10^-6 0.5];
    grid minor
    
    figure(facc)
    hf=subplot('Position', [0.05 (0.05+(1/Nch-(i~=1)*0.004)*(i-1)) 0.9 0.80/Nch]);
    plot(t(1:end-1), adata(:,i),'k');
    h=title(channels{i});
    set(h,'units','normalized', 'Position', [1.0 0.75]);
    if(i~=1)
        hf.XAxis.Visible = 'off';
    else
        xlabel('Time[s]');
    end
    hf.Box='off';
    hf.XLim = [0 20];
    grid minor
    
    figure(fvel)
    hf=subplot('Position', [0.05 (0.05+(1/Nch-(i~=1)*0.004)*(i-1)) 0.9 0.80/Nch]);
    plot(t, data(:,i),'k');
    h=title(channels{i});
    set(h,'units','normalized', 'Position', [1.0 0.75]);
    if(i~=1)
        hf.XAxis.Visible = 'off';
    else
        xlabel('Time[s]');
    end
    hf.Box='off';
	hf.XLim = [0 20];
    grid minor
    
    figure(fdisp)
    hf=subplot('Position', [0.05 (0.05+(1/Nch-(i~=1)*0.004)*(i-1)) 0.9 0.80/Nch]);
    plot(t, idata(:,i),'k');
    h=title(channels{i});
    set(h,'units','normalized', 'Position', [1.0 0.75]);
    if(i~=1)
        hf.XAxis.Visible = 'off';
    else
        xlabel('Time[s]');
    end
    hf.Box='off';
    hf.XLim = [0 20];
    grid minor
end

[range(adata);range(data);range(idata)]