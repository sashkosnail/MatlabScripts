function testFreqs
    Fs = 500;
    t=0:1/Fs:50;
    Nc = 6;
%     f = logspace(-1, 1, Nc*3)*5;
    f = [1 10 20 2 11 21 3 12 23]; 
    [F, T] = meshgrid(f,t);
    
    dV = sin(2*pi*F.*T);
    dA = [zeros(1, size(dV,2)); diff(dV)*Fs];
    dD = cumtrapz(t, dV);
    [ddA, ddV, ddD] = processData(t,dV,Fs);
    
    figure(88);clf
%     subaxis(3,2,1,1)
%     plot(t,dA);
%     xlim([0 1]);
%     subaxis(3,2,1,2)
%     plot(t,dV);
%     xlim([0 1]);
%     subaxis(3,2,1,3)
%     plot(t,dD);
%     xlim([0 1]);
%     subaxis(3,2,2,1)
%     plot(t,ddA);
%     xlim([0 1]);
%     subaxis(3,2,2,2)
%     plot(t,ddV);
%     xlim([0 1]);
%     subaxis(3,2,2,3)
%     plot(t,ddD);
%     xlim([0 1]);
    
    for id = 1:1:Nc
        idx = ((id-1)*3+1):1:(id*3);
        subplot(Nc,2,(id-1)*2+1)
        plot(t,dV(:,idx))
        subplot(Nc,2,id*2)
        plot(t,ddV(:,idx))
    end
    figure(89)
    loglog(rms(dV),'r'); hold on
    loglog(rms(ddV), 'b');
end

function [outA, outV, outD] = processData(t, data, Fs)
    Ts = 1/Fs;
    taper_tau = 1.0;
    
    offset = repmat(mean(data),length(data),1);
    data = data - offset;
    %Apply taper
    taper = build_taper(t, taper_tau);
    taper = repmat(taper, 1, size(data,2));
    data = (data - repmat(mean(data),length(data),1)).*taper;
    data = (data - repmat(mean(data),length(data),1)).*taper;

    targetFc = 0.5;
    data = FixResponse(data, -1, targetFc, Fs);
    
    %Calculate Acceleration and Displacement
    %set data to output
    outV = data; %[mm/s]
    outA = [zeros(1, size(data,2)); diff(data/1000)/Ts]; %[m/s^2]
    outD = cumtrapz(t, data); %[mm]
end
