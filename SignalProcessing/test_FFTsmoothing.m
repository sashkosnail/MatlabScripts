Fs = 100;
N = 1000;

k = (0:N-1)';
t = k/Fs;
f = k*Fs/N;
% f = logspace(-1, 2, N)';
tmpf = f(1:10:end);
for fi = 1:1:length(tmpf)
    fc = tmpf(fi); 
    
    % konno ohmachi
    b = 32;
    n = 4;
    tmp = log10((f./fc).^b);
    Wb = (sin(tmp)./tmp).^n;
    % Dolph-Chebyshev
    a = 5; %-a*20dB sidelobes
    b = cosh(1/N*acosh(10^a));
    % k=(-N/2:1:N/2-1)'; 
    Wguz = (cos(N*acos(b*cos(pi*(f-fc)/Fs)))./10.^a).^2;
    % Triang
    n = 16;
    Wt = (f./fc.*(f<fc)+(1-(f-fc)./f).*(f>fc)).^n;
    %BPF
    n = 16;
    tmp = (f./fc).^2;
    Wbpf = (tmp./((1-tmp).^2 + tmp)).^n;

    windows = [Wb Wguz Wt Wbpf];
    iwindows = ifft(windows);

    fig = figure(7777);
    subplot(2,1,1)
    fig.Name = 'Smoothing Functions';
    loglog(f, windows);
    legend('sin(f)/f', 'Dolph-Chebyshev', 'Triangle', 'BPF');
    ylim([10^-7 1]);
    subplot(2,1,2)
    plot(t, iwindows);
    legend('sin(f)/f', 'Dolph-Chebyshev', 'Triangle', 'BPF');
    drawnow()
end
