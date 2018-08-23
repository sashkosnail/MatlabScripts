%% Low-pass sections
% ttt = tf([1 0], [1 (1e6*2.2e-6)^-1]);
% fff = tf([1 0], [1 (100e3*20e-6)^-1]);
% qqq = tf([1 0], [1 (1000e3*10e-6)^-1]);
% aa=ttt*fff*qqq;
% a=fff*qqq;
% f= figure(888); clf; hold on
% h = bodeplot(aa,'k',ttt,'r',fff,'g',qqq,'b',a,'k--');
% childrenHnd = get(f, 'Children');
% setoptions(h,'FreqUnits','Hz');
% setoptions(h,'Ylim',{[-80 0],[-2.7000  272.7000]});
% axes(childrenHnd(3))
% hold on
% plot([0.001 1000],[-3 -3],'k');
% legend('all','input','postAMP','output','all but input');
% grid major; grid minor
% figure(777)
% step(aa)
% grid major; grid minor
%% High-pass sections
% ttt = tf([1 0], [1 (1e6*7e-6)^-1]);
% fff = tf([1 0], [1 (1000e3*10e-6)^-1]);
% qqq = tf([1 0], [1 (1000e3*10e-6)^-1]);
aa=ttt*fff*qqq;
a=fff*qqq;
f= figure(999); clf; hold on
h = bodeplot(aa,'k',ttt,'r',fff,'g',qqq,'b',a,'k--');
childrenHnd = get(f, 'Children');
setoptions(h,'FreqUnits','Hz');
setoptions(h,'Ylim',{[-80 0],[-2.7000  272.7000]});
axes(childrenHnd(3))
hold on
plot([0.001 1000],[-3 -3],'k');
legend('all','input','postAMP','output','all but input');
grid major; grid minor
figure(777)
step(aa)
grid major; grid minor