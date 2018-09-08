function taper = build_taper(t, tau)
    t = reshape(t,length(t),1);
    Fs = 1/(t(2)-t(1));
    tau_t = floor(min([tau t(end)/2]));
    
    rise = sin(pi*t(1:1:round(tau_t*Fs))/(2*tau)).^2;
    fall = rise(end:-1:1);
    taper = [rise; max(rise)*ones(length(t)-length(rise)-length(fall),1); fall];
    taper = taper/max(taper);
end