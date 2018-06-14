if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<OR2>
    PathName = ''; 
end
[FileName, PathName, ~] = uigetfile([PathName, '*.xlsx'],'Pick File');
if(FileName == 0)
    return
end

xlsfile = strcat(PathName, FileName);

fit_params.A = [0.001 100];
fit_params.w = [2.5 7.5].*(2*pi);
fit_params.D = [0.3 0.9];
fit_params.n0 = [0 0];
fit_params.Offset = [-1 1];
fit_params.phi = [-1 1]*pi/8;

ndata = step_response2(xlsfile, fit_params, 'N');
pdata = step_response2(xlsfile, fit_params, 'P');
