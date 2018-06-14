function peak = fit_test2(data, name, Ts, fit_params)
    accepted = false;
    n = (1:1:length(data))';
    
    % ft = fittype(strcat(...
    %     'A*exp(-D*w0*n*Ts)*(D*w0*cos(w0*n*Ts*sqrt(1-D^2)-asin(D)+phi) + ', ...
    %     'sin(w0*n*Ts*sqrt(1-D^2)-asin(D)+phi)*w0*sqrt(1-D^2))'), ...
    %     'independent', 'n', 'problem', 'Ts');
    
    %'A'    'D'    'n0'    'offset'    'phi'    'w0'
    fo = fitoptions('Method', 'NonLinearLeastSquares', ...
        'Algorithm', 'Trust-Region', ...
        'Robust', 'Bisquare', 'Display', 'Off', ...
        'Lower', [fit_params.A(1), fit_params.D(1), fit_params.n0(1), fit_params.Offset(1), fit_params.phi(1), fit_params.w(1)], ...
        'Upper', [fit_params.A(2), fit_params.D(2), fit_params.n0(2), fit_params.Offset(2), fit_params.phi(2), fit_params.w(2)], ...
        'StartPoint', mean(cell2mat(struct2cell(fit_params)),2)');
    
    ft = fittype('A*w0/sqrt(1-D^2)*exp(-D*w0*(n-n0)*Ts)*sin(w0*(n-n0)*Ts*sqrt(1-D^2)-phi)+offset', ...
        'independent', 'n', 'problem', 'Ts', 'options', fo);
%     fo.Weights = zeros(length(n),1);
%     fo.Weights(wcoff:end) = (0:1:length(n)-wcoff)/(length(n)-wcoff);
    [fdt, gof] = fit(n, data, ft, 'problem', Ts);
    figure(111);clf;plot(data);hold on;plot(fdt);
    title(name);
    out_text = sprintf('A: %4.3f Fn: %4.3f D: %4.3f\nn_0: %4.3f phi: %4.3f\nOffset: %4.3f\n RMSE: %4.3f\n', ...
        fdt.A, fdt.w0/(2*pi), fdt.D, fdt.n0, fdt.phi, fdt.offset, gof.rmse);
    text(.25*length(data), 2*std(data), out_text, 'FontSize', 15);
    grid minor
    
    button = 1;
%     [~,~,button] = ginput(1);
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
    peak.Offset = fdt.offset;
end