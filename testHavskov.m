w=0:pi/1000.0:pi;
w0=2*pi*4.5;
d=0.707;
Tv = w.^2/(w0.^2-w.^2+1i*2*w*w0*d);
figure(123)
subplot(2,1,1)
loglog(w, abs(Tv));
subplot(2,1,2)
semilogx(w, rad2deg(angle(Tv)));