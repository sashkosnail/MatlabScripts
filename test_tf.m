s=tf('s');
Fs = 1000;
Tend = 100;
t = 0:1/Fs:Tend-1/Fs;
N = length(t);

%% Sample Data
ftest = logspace(-2, 2, 37);
[T, FT] = meshgrid(t, ftest);
data = sum(sin(2*pi.*T.*FT));
%sensor response
w1 = 2*pi*4.5;
Sensor_Response = s^2/(s^2+2*0.7*s*w1+w1^2);

%% Generate Inverse Filter
H_inv = 1/Sensor_Response;
w_new = 2*pi*1;
H_newfreq = (s/w_new)^2/((s/w_new)^2+2*0.7*s/w_new+1);
Ht = H_newfreq*H_inv;
w_hp = 2*pi*0.5;
H_highpass = (s/w_hp)^2/((s/w_hp)^2+2*0.4*s/w_hp+1);
H_total = H_inv*H_newfreq*H_highpass;
p=bodeoptions;
p.FreqUnits = 'Hz';
p.Grid = 'on';
figure(222); clf
bodeplot(H_inv,p); hold on
bodeplot(H_newfreq,p)
bodeplot(H_highpass,p)
bodeplot(H_total,p)
legend('H inv','H newfreq','H highpass','H total')

%%
% [sos,g] = tf2sos(H1.num{:},H1.den{:});
a=c2d(Ht,1/Fs);
h1 = dfilt.df2(a.num{:},a.den{:});
o1 = filter(h1, data);
% [sos,g] = tf2sos(H2.num{:},H2.den{:});
% h2 = dfilt.df2sos(sos,g);
% o2 = filter(h2, sines);
% [sos,g] = tf2sos(Ht.num{:},Ht.den{:});
% ht = dfilt.df2sos(sos,g);
% ot = filter(ht, sines);
figure(333); clf
subplot(2,2,1)
plot(t,data)
subplot(2,2,2)
fftdata = fft(data);
P2 = abs(fftdata)/N;
P1 = P2(1:N/2+1);
P1(2:end-1) = 2*P1(2:end-1);
loglog(Fs*(0:(N/2))/N, P1);
subplot(2,2,3)
plot(t,o1);
subplot(2,2,4)
fftdata = fft(o1);
P2 = abs(fftdata)/N;
P1 = P2(1:N/2+1);
loglog(Fs*(0:(N/2))/N, P1);