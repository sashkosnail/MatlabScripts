function [corrected, freqs, correction] = FixResponse2(data, sensorNum, ...
                                            targetF, Fs, ignore_channels, steepnes)
    if(~exist('ignore_channels', 'var'))
        ignore_channels = [];
    end
    if(~exist('steepnes', 'var'))
        ignore_channels = 6;
    end
    
    num_chans = size(data,2);
    %%%
    sensorNum = -1*ones(num_chans,1);
    %%%
    N = size(data,1);
    sensor_freqs = GetCornerFreqs(sensorNum);
    %switch this to calc only one column of F1 and then replicate
    f = repmat((0:N-1)'*Fs/N, 1, num_chans);
    fs = repmat(sensor_freqs(1:1:num_chans), N, 1);
    ft = repmat(targetF, N, num_chans);
    tmp = zeros(size(fs)); tmp(1,:) = 10^-30;
    FT = f./ft + tmp;
    FS = (f./fs).^2;
    
    iSresp = (FS + tmp)./sqrt((1-FS).^2 + 2*FS);
%     ISresp(1) = 10^
    linedrop = ones(size(iSresp));
    linedrop(FT<1) = FT(FT<1).^(steepnes);
    correction = linedrop./iSresp;
%     correction(1,:) = 0;
    correction = correction + correction(end:-1:1,:) - ...
        repmat(correction(end,:),length(correction),1);
    fftdata = fft(data);
    corrected = ifft(fftdata.*correction, 'symmetric');
    
    %resotre ignored channels
    corrected(:,ignore_channels) = data(:,ignore_channels);
    freqs = f(:,1);
end

function freqs = GetCornerFreqs(sensorNum)
    if(sensorNum == -1)
        freqs = 4.5*ones(1, length(sensorNum));
    else
        freqs = 4.5*ones(1, 3*length(sensorNum));
    end
end

