Fs = 1000;
N = 100000;%2^nextpow2(Fs*100);

k = (0:N-1)';
t = k/Fs;
f = Fs*k/N/2;
tmpf = logspace(-1,2,4);
tmpf = [0.5 2.5 10 50];
fig = figure(7777);clf
for fi = 1:1:length(tmpf)
    fc = tmpf(fi); 
    % konno ohmachi
    b = 20;
    n = 4;
    tmp = log10((f./fc).^b);
    Wb = (sin(tmp)./tmp).^n;
	%Parzen Window
	L = 0.38*0.5/(Fs/N/2);
	L = L - mod(L,2) - 1;
	Wpz = parzenwin(L);
	[~,fidx] = min(abs(f-fc));
	if(fidx<(L-1)/2)
		Wpz = Wpz((L-1)/2-fidx:end);
	else
		Wpz = [zeros(fidx-(L-1)/2,1); Wpz]; %#ok<AGROW>
	end
	if(length(Wpz) > N)
		Wpz = Wpz(1:N);
	else
		Wpz = [Wpz;zeros(N-length(Wpz),1)]; %#ok<AGROW>
	end
    % Dolph-Chebyshev
    a = 5; %-a*20dB sidelobes
    b = cosh(1/N*acosh(10^a));
    % k=(-N/2:1:N/2-1)'; 
    Wguz = (cos(N*acos(b*cos(pi*(f-fc)/Fs)))./10.^a).^2;
    % Triang
    n = 6;
    Wt = (f./fc.*(f<fc)+(1-(f-fc)./f).*(f>fc)).^n;
    %BPF
    n = 64;
    tmp = (f./fc).^2;
    Wbpf = (tmp./((1-tmp).^2 + tmp)).^n;

    windows = 20*log10(abs([Wguz Wbpf Wb Wt Wpz]));
    iwindows = abs(ifft(windows));

%     subplot(2,1,1)
    fig.Name = 'Smoothing Functions';
	semilogx(f([2 end]), [1 1]'*-3, 'LineStyle', '-', ...
		'LineWidth', 2, 'LineStyle', ':', 'Color', 'm', 'DisplayName', '-3dB');
	hold on
    h=semilogx(f, windows);
	set(h,{'Color'}, {[0.6 0.4 0.8]-0.2; [0 0 0]; [0 0 1]; [0 1 0]; [1 0 0]});
	set(h,'LineWidth',1.2);
	set(h, {'DisplayName'}, {'Dolph-Chebyshev a=5', 'BPF n=64', 'Konno-Ohmachi b=20', 'Triangle n=6', 'Parzen BW=0.5Hz'}')
	l=legend('show');
	l.Location='northwest';
    axis([0.05 Fs/2 -80 1]);
	h(1).Parent.XTick = [0.1 tmpf 100];
	xlabel('Frequency[Hz]');
	ylabel('Amplitue[dB]');
	grid on
	
	fig.Position = [1 1 1000 500];
% 	
%     subplot(2,1,2)
%     plot(t, iwindows);
%     l=legend('sin(f)/f', 'Dolph-Chebyshev', 'Triangle', 'BPF', 'Parzen');
% 	l.Location='northwest';
% 	title(['Fc = ' num2str(fc)]);
%     drawnow()
end
