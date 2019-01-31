function output = smoothFFT(fftdata, n, f, wait_window)
    output = zeros(size(fftdata));
    for fci = 2:1:length(f)
		if(~(wait_window == 0) && isvalid(wait_window))
			step = 0.3/length(f);
			waitbar(0.6+(fci-1)*step, wait_window);
		end
        fc = f(fci);
        tmp = (f./fc).^2;
        Wbpf = (tmp./((1-tmp).^2 + tmp)).^n;
		Wt = (f./fc.*(f<fc)+(1-(f-fc)./f).*(f>fc)).^n;
		Wt(isnan(Wt)) = 0;
		W = repmat(Wbpf/sum(Wbpf),1, size(fftdata,2));
        output(fci,:) = sum(W.*fftdata);
    end
end