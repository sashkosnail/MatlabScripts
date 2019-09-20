global HT
t1 = 0:0.01:200;
signal = 0.1*sin(2*pi*10*t1)+((t1>2&t1<100)|(t1>120&t1<185)).*sin(2*pi*7*t1);
figure(5786)
out = filter(HT, signal);
plot(t1, [signal; out]');
legend('in', 'out');

