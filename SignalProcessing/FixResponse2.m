function [corrected, freqs, correction] = FixResponse2(data, sFreqs, ...
                                    targetF, Fs, ignore_channels, steepnes)
    if(~exist('ignore_channels', 'var'))
        ignore_channels = [];
    end
    if(~exist('steepnes', 'var'))
        ignore_channels = 6;
    end
    
    num_chans = size(data,2);
    N = size(data,1);
    fs = repmat(sFreqs, N, 1);
    f = repmat((0:N-1)'*Fs/N, 1, num_chans);
    ft = repmat(targetF, N, num_chans);
    tmp = zeros(size(fs)); tmp(1,:) = 10^-30;
    FT = f./ft + tmp;
    FS = (f./fs).^2;
    iSresp = (FS + tmp)./sqrt((1-FS).^2 + 2*FS);
    linedrop = ones(size(iSresp));
    linedrop(FT<1) = FT(FT<1).^(steepnes);
    correction = linedrop./iSresp;
    correction = correction + correction(end:-1:1,:) - ...
        repmat(correction(end,:),length(correction),1);
    fftdata = fft(data);
    corrected = ifft(fftdata.*correction, 'symmetric');
    
    %resotre ignored channels
    corrected(:,ignore_channels) = data(:,ignore_channels);
    freqs = f(:,1);
end

