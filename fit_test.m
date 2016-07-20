function peak = fit_test(data, name, Ts)
    accepted = false;
    n = (1:1:length(data))';
    
    % ft = fittype(strcat(...
    %     'A*exp(-D*w0*n*Ts)*(D*w0*cos(w0*n*Ts*sqrt(1-D^2)-asin(D)+phi) + ', ...
    %     'sin(w0*n*Ts*sqrt(1-D^2)-asin(D)+phi)*w0*sqrt(1-D^2))'), ...
    %     'independent', 'n', 'problem', 'Ts');
    
    ft = fittype('A*w0/sqrt(1-D^2)*exp(-D*w0*(n+n0)*Ts)*sin(w0*(n+n0)*Ts*sqrt(1-D^2)-phi)', ...
        'independent', 'n', 'problem', 'Ts');
    fo = fitoptions(ft);
    fo.Lower = [0.001, 0.25, -10, 0, 2*2*pi];
    fo.Upper = [1, 0.9, 10, 0, 6*2*pi];
    fo.StartPoint = [0.01, 0.7, 0, -1, 4.5*2*pi];
    [fdt, gof] = fit(n, data, ft, fo,'problem',Ts);
    figure(111);clf;plot(data);hold on;plot(fdt);
    title(name);
    out_text = sprintf('Fn: %4.3f D: %4.3f\nn_0: %4.3f RMSE: %4.3f\n', ...
        fdt.w0/(2*pi), fdt.D, fdt.n0, gof.rmse);
    text(600, 0.1, out_text, 'FontSize', 15);
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
end