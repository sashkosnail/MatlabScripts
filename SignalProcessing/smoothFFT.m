function output = smoothFFT(fftdata, n, f)
    output = zeros(size(fftdata));
    for fci = 2:1:length(f)
        fc = f(fci);
        tmp = (f./fc).^2;
        Wbpf = (tmp./((1-tmp).^2 + tmp)).^n;
        Wbpf = repmat(Wbpf/sum(Wbpf),1, size(fftdata,2));
        output(fci,:) = sum(Wbpf.*fftdata);
    end
end