function peak = fit_test(data, name, Ts)
    accepted = false;
    n = (1:1:length(data))';
    
    % ft = fittype(strcat(...
    %     'A*exp(-D*w0*n*Ts)*(D*w0*cos(w0*n*Ts*sqrt(1-D^2)-asin(D)+phi) + ', ...
    %     'sin(w0*n*Ts*sqrt(1-D^2)-asin(D)+phi)*w0*sqrt(1-D^2))'), ...
    %     'independent', 'n', 'problem', 'Ts');
    
    ft = fittype('A*w0/sqrt(1-D^2)*exp(-D*w0*(n-n0)*Ts)*sin(w0*(n-n0)*Ts*sqrt(1-D^2)-phi)+o', ...
        'independent', 'n', 'problem', 'Ts');
    fo = fitoptions(ft);
    %'A'    'D'    'n0'    'o'    'phi'    'w0'
    fo.Lower = [0.01, 0.2, 0, 0, 0, 0.5*2*pi];
    fo.Upper = [100, 0.707, 30, 0, 0, 1.5*2*pi];
    fo.StartPoint = [0.01, 0.707, 0, 0, 0, 1*2*pi];
    wcoff = 150;
%     fo.Weights = zeros(length(n),1);
%     fo.Weights(wcoff:end) = (0:1:length(n)-wcoff)/(length(n)-wcoff);
    [fdt, gof] = fit(n, data, ft, fo,'problem',Ts);
    figure(111);clf;plot(data);hold on;plot(fdt);
    title(name);
    out_text = sprintf('A: %4.3f Fn: %4.3f D: %4.3f\nn_0: %4.3f phi: %4.3f\nOffset: %4.3f\n RMSE: %4.3f\n', ...
        fdt.A, fdt.w0/(2*pi), fdt.D, fdt.n0, fdt.phi, fdt.o, gof.rmse);
    text(600, 3*std(data), out_text, 'FontSize', 15);
    grid minor
    
    button = 1;
    [~,~,button] = ginput(1);
    if(button ~= 3)
        accepted=true;
    end
    
    peak.Name = name;
    peak.Accepted = accepted;
    peak.A = fdt.A;
    peak.GOF = gof;
    peak.Fn = fdt.w0/(2*pi);
    peak.D  = fdt.D;
    peak.Data = peak;
    peak.Fit = fdt;
    peak.Offset = fdt.o;
end