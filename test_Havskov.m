f = 0:0.1:100;
w = 2*pi*f';
d=0.707;
Tv1 = w.^2./(w.^2-w0.^2-1i*2*w*w0*d);
Tv2 = w.^2./(w0.^2-w.^2+1i*2*w*w0*d);
figure(123)
subplot(2,1,1)
loglog(w, abs([Tv1 Tv2]));
legend('S','Havskov');
subplot(2,1,2)
semilogx(w, rad2deg(angle([Tv1 Tv2])));