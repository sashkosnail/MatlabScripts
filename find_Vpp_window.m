% function [peak_data, maxVpp]= find_Vpp_window(data)
% %     dp = data; dp(data < 0) = 0;
% %     dn = data; dn(data > 0) = 0;
% %     peak_data = zeros(size(data,2),2);
% %     maxVpp = zeros(length(data),1);
%     disp()
% end

function [peak_data, maxVpp]= find_Vpp_window(data, ~)
    dp = data; dp(data < 0) = 0;
    dn = data; dn(data > 0) = 0;
    peak_data = zeros(size(data,2),2);
    maxVpp = zeros(length(data),1);
    for idx=1:1:size(data,2)
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
        maxVPP = 0; mVppi = [1 1];
        while 1
    %         [f, fi] = findpeaks(first(n:end),'Npeaks',1);
    %         [s, si] = findpeaks(second(n:end),'Npeaks',1);

            fend = n + find(f(n:end)==0, 1,'first');
            send = fend + find(s(fend:end)==0, 1, 'first');
            if(isempty(send) || send>length(f))
                break;
            end
            tend = send+find(f(send:end)==0, 1, 'first');
            if(tend>length(f))
                break;
            end
            [fmax, fmi] = max(f(n:fend));
            fmi = n+fmi-1;
            [smax, smi] = max(s(fend:send));
            smi = fend + smi - 1;
            [tmax, tmi] = max(f(send:tend));
            if(isempty(tmi))
                break;
            end
            tmi = send + tmi-1;
            Vpp_id = [fmi smi; smi tmi; mVppi];
            [maxVPP, ii] = max([fmax+smax, smax+tmax, maxVPP]);
            mVppi = Vpp_id(ii,:);
            n = send;
        end
        peak_data(idx,:) = mVppi;
        maxVpp(idx) = maxVPP;
    end
end