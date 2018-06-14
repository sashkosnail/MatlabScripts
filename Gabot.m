a=0.5;
b=0.1;
y=1;
f=6;
t=0:0.05:10;
A=sqrt(a*exp(-b*t)*t^y)*sin(w*pi*f*t);
plot(t,A)