global HVSR
data = ones(10,3);
params = HVSR.ExternalModel;
f = HVSR.Fs*(0:(length(data)-1)/2)'/length(data);
freq = [f; f(end-mod(length(data),2):-1:1)];
[bpf, ~] = CalculateBPFResponse(params, 'freq-sum', 0, freq);
size(data)
size(f)
size(bpf)