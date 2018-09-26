function output = smoothFFT(fftdata, n, f, wait_window)
    output = zeros(size(fftdata));
    for fci = 2:1:length(f)
		if(isvalid(wait_window))
			step = 0.3/length(f);
			waitbar(0.6+(fci-1)*step, wait_window);
		end
        fc = f(fci);
        tmp = (f./fc).^2;
        Wbpf = (tmp./((1-tmp).^2 + tmp)).^n;
        Wbpf = repmat(Wbpf/sum(Wbpf),1, size(fftdata,2));
        output(fci,:) = sum(Wbpf.*fftdata);
    end
end