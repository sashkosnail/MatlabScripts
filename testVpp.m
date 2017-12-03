global d
data = d;
dp =d;dp(d<0) = 0;
dn =d;dn(d>0) = 0;

for idx=2:1:size(data,2)
    %find first zero xing
    zp = find(dp(:,idx)==0,1);
    zn = find(dn(:,idx)==0,1);
    if(zp>zn)
        f = -dn(:,idx);
        s = dp(:,idx);
    else
        f = dp(:,idx);
        s = -dn(:,idx);
    end

    n = max(zp,zn);
    maxVpp = 0; mVpp = [0 0]; mVppi = [1 1];
    while 1
%         [f, fi] = findpeaks(first(n:end),'Npeaks',1);
%         [s, si] = findpeaks(second(n:end),'Npeaks',1);

        fend = n + find(f(n:end)==0, 1,'first');
        send = fend + find(s(fend:end)==0, 1, 'first');
        if(isempty(send) || send>length(f))
            break;
        end
        tend = send+find(f(send:end)==0, 1, 'first');
        [fmax, fmi] = max(f(n:fend));
        fmi = n+fmi-1;
        [smax, smi] = max(s(fend:send));
        smi = fend + smi-1;
        [tmax, tmi]= max(f(send:tend));
        if(isempty(tmi))
            break;
        end
        tmi = send + tmi-1;
        Vpp_id = [fmi smi; smi tmi; mVppi];
        [maxVpp, ii] = max([fmax+smax, smax+tmax, maxVpp]);
        mVppi = Vpp_id(ii,:);
        n = send;
    end
    figure(9+idx); clf
    plot(dp(:,idx), 'r'); hold on; plot(dn(:,idx),'b')
    plot(mVppi, data(mVppi, idx),'k');
    if(data(mVppi(1))>0)
        plot(mVppi(1), data(mVppi(1), idx), 'cv')
        plot(mVppi(2), data(mVppi(2), idx), 'c^')
        text(mVppi(2), 0, ['Vpp = ', num2str(maxVpp)], ...
            'Color', 'k', 'BackgroundColor','w');
    else
        plot(mVppi(1), data(mVppi(1), idx), 'cv')
        plot(mVppi(2), data(mVppi(2), idx), 'c^')
        text(mVppi(1), 0, ['Vpp = ', num2str(maxVpp)], ...
            'Color', 'k', 'BackgroundColor','w');
    end
    pause
end