filename = 'ecuador_data_1_7.xlsx';
global Fs;
global Ns;
global channel_enabled;
global Nch;
global channels;

Fs = 1000;
Ns = 8192;

[b, a] = butter(4, 32*pi/Fs, 'low');
path = 'D:\Documents\PhD\Ecuador\';

[FileName,PathName,FilterIndex] = uigetfile(strcat(path, '*.wsdt'),'Pick File') %#ok<NOPTS>
desc_id = fopen(strcat(PathName, 'Description.txt'));
test = strsplit(PathName, '\');
test = test(end-1);

channels = strsplit(fgetl(desc_id));
Nch = length(channels)/3;
channel_enabled = ones(Nch, 1);
fclose(desc_id);
data = dlmread(strcat(PathName, FileName), ',', 1, 0);
time = data(:,1);
% -offset and ch1
chan_data = data(:,3:end)-repmat(mean(data(:,3:end)), length(data), 1); 
proc_data = proc_filter(chan_data);
%store in XLS
xlswrite(strcat(path, filename), {'Time', channels{1:end}}, test{1}, 'A1');
xlswrite(strcat(path, filename), [time(1:(50*Fs)), chan_data((1):(50*Fs),:)], test{1}, 'A2');