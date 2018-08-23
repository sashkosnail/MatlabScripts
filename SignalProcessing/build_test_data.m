function [t, data, offset] = build_test_data(filename)
    if(~exist('filname', 'var'))
        filename = 'D:\Documents\PhD\TestData\x6_test.csv';
    end
    delimiter = ',';
    startRow = 1;

    data = dlmread(filename, delimiter, startRow, 0);
    t = data(:,1);
    data = data(:,2:end)-ones(size(data(:,2:end)))*mean(data(:,2:end));
    disp(mean(data))
    Ts = t(2)-t(1); Fs = 1/Ts;

    n=1:1:Fs*10;
    zz=zeros(length(data)-Fs*10, 1);  
    zz = [zz; n'*10/(Fs*10)];
    xx = 10*(exp(((1:1:length(data))/length(data)).^20)-1); 
    xx = xx';
    offset = zz;
    data = data + offset;
end