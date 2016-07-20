figure
Fs=250;Ts = 1/Fs;

th_win_duration = 7;
th_win_size = ceil(th_win_duration/Ts/2)*2;
th_win = bartlett(th_win_size+1);
ttt = sin(linspace(0,pi,th_win_size)).^2;

aaa=randn(2^13, 1);
an = 10*randn(th_win_size,1).*ttt';
zz = zeros(length(aaa)-th_win_size,1);
aaa = abs(aaa + [zz(1:length(zz)/2) ;an ;zz(length(zz)/2+1:end)]);
% a = [a(length(a)/2:-1:1); a; a(end:-1:end-length(a)/2+1)];
aa=randn(2^13, 1);
an = 10*randn(th_win_size,1).*ttt';
zz = zeros(length(aa)-th_win_size,1);
aa = abs(aa + [zz(1:length(zz)/2) ;an ;zz(length(zz)/2+1:end)]);
a=randn(2^13, 1);
an = 10*randn(th_win_size,1).*ttt';
zz = zeros(length(a)-th_win_size,1);
a = abs(a + [zz(1:length(zz)/2) ;an ;zz(length(zz)/2+1:end)]);

a = [aaa aa a];

b = filter(th_win, 1, a)/th_win_size*2;
c = filter(th_win, 1, b(end:-1:1,:)); c=c(end:-1:1,:)/th_win_size*2;
d = filtfilt(th_win, 1, a)/th_win_size^2*4;
e = apply_window(th_win, a);

subaxis(5,1,1);
plot(a);
subaxis(5,1,2);
plot(b);
h1=subaxis(5,1,3);
plot(c);
h2=subaxis(5,1,4);
plot(d);
set(h2, 'YLim', h1.YLim)
h3=subaxis(5,1,5);
plot(e);
% set(h3, 'YLim', h1.YLim)