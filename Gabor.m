function A=Gabor(a,b,y,f,t)
    A=sqrt(a*exp(-b*t).*t.^y).*sin(2*pi*f*t);