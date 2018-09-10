function taper = build_taper(t, tau)
    t = reshape(t,length(t),1);
    Fs = 1/(t(2)-t(1));
    tau_t = min([tau t(end)/2]);
    if(tau_t == 0)
        taper = ones(size(t));
        return
    end
    rise = sin(pi*t(1:1:round(tau_t*Fs))/(2*tau)).^2;
    fall = rise(end:-1:1);
    taper = [rise; max(rise)*ones(length(t)-length(rise)-length(fall),1); fall];
    taper = taper/max(taper);
end