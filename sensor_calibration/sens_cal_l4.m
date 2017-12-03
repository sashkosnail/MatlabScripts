%% Read Data
clear;
path = 'D:\Projects\PhD\vibSystem\sensor_data\'; 
[FileName, PathName, ~] = uigetfile(strcat(path, '*.xlsx'),'Pick File');
xlsfile = strcat(PathName, FileName);
[pdata_n, pdata_p] = step_response(xlsfile);
% save(strcat(PathName, FileName(1:end-5), '.mat'));
% writetable(cdrT, strcat(xlsfile(1:lis),'cdr.csv'));
% writetable(fitT, strcat(xlsfile(1:lis),'out.csv'));
%% run
save(strcat(PathName, FileName(1:end-5), '.mat'));