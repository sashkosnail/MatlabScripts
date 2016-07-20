function fdata = proc_filter(odata)
    global Fs;
    global Nch;
    global Ns;
    global Filters;
    global channels;
    
    % freq down to 40db butterworth 4th
%     Ns = nextpow2(length(odata)-1);
    for i=1:1:length(channels)
        fdata(:,i) = filtfilt(Filters.Bank{i}, 1, odata(:,i));
    end

%     %inverse filter
%     [fresp, w] = freqz(Filters.BH, Ns/2);
%     fresp = abs(fresp);
%     f=w./(2*pi/Fs);
%     
%     fft_data2 = abs(fft(chan_data.*repmat(hamming(Ns), 1, Nch), Ns, 1)/Ns);
%     fft_data = fft_data2(1:Ns/2,:);
%     fft_data(2:end-1,:) = 2*fft_data(2:end-1,:);
%     for i=1:1:Nch
%         if(isempty(regexp(channels{i},'[A-Z]','ONCE')))
%             proc_data(:,i) = ifft(fft_data(:,i)./fresp;
%         end
%     end
%     end
end