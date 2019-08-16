fig=figure(45);clf
s=tf('s');
tau = 1/0.5;
HP = s/(s+1/tau);
w_new = 2*pi*0.5;
zeta1 = 0.67;
H_newfreq = -s^2/(s^2+2*zeta1*s*w_new+w_new^2);
p=bodeoptions;
p.FreqUnits = 'Hz';
p.XLabel.FontSize = 14;
p.YLabel.FontSize = 14;
p.Title.FontSize = 14;
p.Grid = 'on';
p.MagUnits = 'abs';
p.MagScale = 'log';
bodeplot(HP, p);grid on; hold on
bodeplot(H_newfreq, p)
bodeplot(HP*H_newfreq, p)
legend('1stOrder','New','*');