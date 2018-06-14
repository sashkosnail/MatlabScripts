clear

v=sin(0:pi/100:2*pi)+1.01;

% v=V-4.42*10^-8;

h=triang(5);h=h/sum(h);

figure(3);clf; 
plot(v);hold on; plot(filtfilt(h,1,v)); 
grid on

figure(4);clf;
plot(filtfilt(h,1,v)./v);
grid on