%% Read Data
clear;
path = 'D:\Projects\PhD\vibSystem\sensor_data\'; 
[FileName, PathName, ~] = uigetfile(strcat(path, '*.xlsx'),'Pick File');
xlsfile = strcat(PathName, FileName);
[pdata_n, pdata_p] = step_response(xlsfile);

% save(strcat(PathName, FileName(1:end-5), '.mat'));

%% CDR
clear summaryT cdrT
global summaryT
global cdrT
global fitT
global frange
frange = [4.55 4.65];
summaryT = table;
cdrT = table;
fitT = table;
fig = figure(30);clf
set(fig, 'PaperPositionMode', 'auto')
% set(fig,'units','normalized','outerposition',[0 0 1 1])
ax11 = subaxis(2, 3, 1, 1, 'Spacing', 0, 'Padding', 0, 'mb', 0, 'mt', 0, 'ml', 0.03, 'mr', 0 , 'HoldAxis', 1);
ax21 = subaxis(2, 3, 1, 2, 'Spacing', 0, 'Padding', 0, 'mb', 0.05, 'mt', 0, 'ml', 0.03, 'mr', 0);
cdr(xlsfile, pdata_n, 'n', [ax11 ax21]);
ax11.XAxis.Visible = 'off';
ax12 = subaxis(2, 3, 2, 1,'Spacing', 0, 'Padding', 0, 'mb', 0, 'mt', 0, 'ml', 0.01, 'mr', 0);
ax22 = subaxis(2, 3, 2, 2,'Spacing', 0, 'Padding', 0, 'mb', 0.05, 'mt', 0, 'ml', 0.01, 'mr', 0);
cdr(xlsfile, pdata_p, 'p', [ax12 ax22]);
ax12.XAxis.Visible = 'off';
ax12.YAxis.Visible = 'off';
ax22.YAxis.Visible = 'off';
ax13 = subaxis(2, 3, 3, 1,'Spacing', 0, 'Padding', 0, 'mb', 0, 'mt', 0, 'ml', 0.01, 'mr', 0);
ax23 = subaxis(2, 3, 3, 2,'Spacing', 0, 'Padding', 0, 'mb', 0.05, 'mt', 0, 'ml', 0.01, 'mr', 0);
cdr(xlsfile, [pdata_n pdata_p], 'b', [ax13 ax23])
ax13.XAxis.Visible = 'off';
ax13.YAxis.Visible = 'off';
ax23.YAxis.Visible = 'off';

titlex = mean(get(ax12,'XLim'));
titley = get(ax12, 'YLim');
titley = titley(2)-0.1*range(titley);
text(titlex, titley, FileName(1:end-5), 'Parent', ax12, 'FontSize', 20)

ax21.YLim = frange;
ax22.YLim = frange;

set(gcf, 'Name', FileName(1:end-5));
print(fig, strcat(PathName, FileName(1:end-5), '.png'), '-dpng', '-r0');

%% Save Data
lis = find(xlsfile=='\',1,'last');

writetable(summaryT, xlsfile, 'Sheet', 'Summary', 'Range', 'A2');
writetable(cdrT, xlsfile, 'Sheet', 'CDR', 'Range', 'A2');
writetable(fitT, xlsfile, 'Sheet', 'Details', 'Range', 'H1');

% writetable(summaryT, strcat(xlsfile(1:lis),'summary.csv'));
% writetable(cdrT, strcat(xlsfile(1:lis),'cdr.csv'));
% writetable(fitT, strcat(xlsfile(1:lis),'out.csv'));

save(strcat(PathName, FileName(1:end-5), '.mat'));