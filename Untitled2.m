A = Den;%[1 0 -2.7607 0 3.8106 0 -2.6535 0 0.9238];
n=32;

[H,F1] = freqz(1,A,[],1);
x = randn(1000,1);
y = filter(1,A,x);
[Pxx,F2] = pyulear(y,n,1024,1);
Px = real(mem(y, n));

figure(1); clf
hold on
plot(F1,20*log10(abs(H)),'k')
plot(F2,10*log10(Pxx))
plot(F1,Px(end:-1:length(Px)/2+1))

% for i=5:2:15
%     aa = real(mem(y,i));
%     plot(F1,aa(end:-1:length(aa)/2+1),'--')
% end

xlabel('Frequency (Hz)')
ylabel('PSD (dB/Hz)')
legend('True Power Spectral Density','pyulear PSD Estimate','MEM')
grid on