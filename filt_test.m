ttt = tf([1 0], [1 2*pi*1e6*2.2e-6]);
fff = tf([1 0], [1 2*pi*510e3*10e-6]);
a=ttt*fff;
freqresp(a)