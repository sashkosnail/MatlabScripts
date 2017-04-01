clear data out_files dat_file ch_file Ts Fs
if(~exist('PathName','var'))
    PathName = '';
end
[FileName, PathName, ~] = uigetfile([PathName, '*.dat'],'Pick File');
if(FileName == 0)
    return;
end
datfile = FileName;%strcat(PathName, FileName);
cd(PathName);
seg2ascii = 'D:\Projects\seg2asci.exe';
filter_cutoff = 64;
co = 18; %channel offset
cc = 6; %channel count

system([seg2ascii, ' "', datfile, '" 16K '], '-echo');

data = [];
out_files = dir([PathName,'*.0*']);
for ch_file = out_files'
    if(~exist('Ts','var'))
        Ts = dlmread(ch_file.name, '' , 'B30..B30');
        Fs = 1/Ts;
    end
    ch_data = dlmread(ch_file.name, '', 38, 0);
    data = [data, ch_data]; %#ok<AGROW>
    delete(ch_file.name);
end
data = data(:,co+1:co+cc);
Nch = size(data,2);
N = 2^nextpow2(length(data));
data = padarray(data, N-length(data),0,'post');
[fnum, fden] = butter(10, filter_cutoff*2/Fs, 'low');
fdata = filtfilt(fnum, fden, data);
% fdata = data;
t = 0:Ts:(length(data)-1)*Ts;
figure(); clf
subplot(3,1,1);
plot(t,fdata);
title(FileName(1:end-4))
fft_data2 = abs(fft(data.*repmat(hamming(N), 1, Nch), N, 1)/N);
fft_data = fft_data2(1:N/2,:);
fft_data(2:end-1,:) = 2*fft_data(2:end-1,:);
% fft_data = fftshift(fft(data, N, 1));
% fft_data = fft_data(N/2+1:end,:);
f = Fs*(1:N/2)'/N;
subplot(3,1,2);
semilogx(f,abs(fft_data))
axis([0.1 100 -0.001 0.5])
subplot(3,1,3);
HVSR = sqrt(abs(fft_data(:,2:3:end)).^2 + abs(fft_data(:,3:3:end)).^2) ./ abs(fft_data(:,1:3:end));
D = [t' data];
mat_file = [PathName FileName(1:end-4) '.mat'];
csv_file = [PathName FileName(1:end-4) '.csv'];
save(mat_file, 'D');
dlmwrite(csv_file, D);
plot(f,HVSR);


