function corrected = ShiftFilter(data, filterF, targetF, Fs)	
	num_chans = size(data,2);
    %%%
    N = size(data,1);
    sensor_freqs = filterF*ones(1, num_chans);
    %switch this to calc only one column of F1 and then replicate
    f = repmat((0:N-1)'*Fs/N, 1, num_chans);
    fs = repmat(sensor_freqs(1:1:num_chans), N, 1);
    ft = repmat(targetF, N, num_chans);
%     F1 = (f./fs).^2;
%     F2 = (f./ft).^2;
	FiltResp = (1./sqrt(1 + (f./fs).^(2*4)));
	newFiltResp = (1./sqrt(1 + (f./ft).^(2*4 )));
    correction = newFiltResp./FiltResp;
	
	c = correction(1:floor(length(correction)/2));
	correction(end:-1:end-length(c)+1) = c;
	
    figure(11); clf
	semilogy(f(:,1), [FiltResp(:,1) newFiltResp(:,1) correction(:,1)]);
	hold on
	semilogy([10 100] , 1/sqrt(2)*[1 1], 'k--');
    legend('FiltResp','newFiltResp','Combo');
% 	xlim([10 100]) 
    grid on
    fftdata = fft(data);
    corrected = ifft(fftdata.*correction, 'symmetric');
end