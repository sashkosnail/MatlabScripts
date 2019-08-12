s=tf('s');
Fs = 1000;

w1 = 2*pi*4.5;
Sensor_Response = s^2/(s^2+2*0.7*s*w1+w1^2);
H_inv = 1/Sensor_Response;
w_new = 2*pi*0.863;
zeta1 = 0.707;
H_newfreq = (s/w_new)^2/((s/w_new)^2+2*zeta1*s/w_new+1);
w_hp = 2*pi*0.5;
zeta2 = 0.4;
H_highpass = (s/w_hp)^2/((s/w_hp)^2+2*zeta2*s/w_hp+1);
H_total = H_inv*H_newfreq*H_highpass;

% z=tf('z')
ht = c2d(H_total,1/Fs);
% H_allpass = tf(ht.den{1}(1:end),ht.den{1}(end:-1:1), 1/Fs);
% ht = ht*H_allpass;
HT = dfilt.df2(ht.num{:},ht.den{:});
% Hallpass = dfilt.df2(H_allpass.num{:},H_allpass.den{:});


[h,w] = freqz(HT);
f = w/(2*pi)*Fs;
h_nophase = pol2cart(zeros(size(w)), abs(h));
wt=zeros(size(f));
wt(f<128) = 1;
[b,a] = invfreqz(h_nophase, w, 100, 100, wt);
HT_nophase = dfilt.df2(b,a);

[h_out,~] = freqz(HT_nophase);


figure(999);clf
subplot(2,1,1)
loglog(f, abs(h),'k'); hold on
loglog(f, abs(h_out),'r'); grid on
% loglog(f, abs(h_nophase),'g');
subplot(2,1,2)
semilogx(f, angle(h),'k');hold on
semilogx(f, angle(h_out),'r'); grid on
% semilogx(f, angle(h_nophase),'g');
