function corrected = FixResponse(data, sensorNum, targetF, Fs)
    num_chans = size(data,2);
    %%%
    sensorNum = zeros(num_chans,1);
    %%%
    N = size(data,1);
    sensor_freqs = GetCornerFreqs(sensorNum);
    f = repmat((1:N)'*Fs/N, 1, num_chans);
    fs = repmat(sensor_freqs(1:1:num_chans), N, 1);
    ft = repmat(targetF, N, num_chans);
    F1 = (f./ft).^2;
    F2 = (f./fs).^2;
    tmp1 = (f./(ft.^2)).^2./((1-F1).^2+2*F1);
    tmp2 = (1./fs).^2./sqrt((1-F2).^2+2*F2);
    correction = tmp1./tmp2;
    correction = correction + correction(end:-1:1,:) - ...
        repmat(correction(end,:),length(correction),1);
%     semilogy(f(:,1), [tmp1(:,1) tmp2(:,1) correction(:,1)]);
%     legend('tmp1','tmp2','Combo');
%     xlim([0.01 50]);
%     ylim([0.001 1000]);
%     grid on
    fftdata = fft(data);
    fftdata_real = real(fftdata);
    fftdata_imag = imag(fftdata);
    
    fftcorrected = (fftdata_real + 1i*fftdata_imag).*correction;
    corrected = ifft(fftcorrected, 'symmetric');
end

function freqs = GetCornerFreqs(sensorNum)
    freqs = 4.5*ones(1, length(sensorNum));
end

