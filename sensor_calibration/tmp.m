%% CDR
clear summaryT cdrT
global summaryT
global cdrT
global fitT
% global frange
frange = [4.1 4.7];
summaryT = table;
cdrT = table;
fitT = table;
fig = figure(30);clf
set(fig, 'PaperPositionMode', 'auto')
% set(fig,'units','normalized','outerposition',[0 0 1 1])
ax11 = subaxis(2, 3, 1, 1,'ml',0.05);
ax21 = subaxis(2, 3, 1, 2,'ml',0.05);
cdr(xls_file, ndata, 'n', [ax11 ax21]);
ax11.XAxis.Visible = 'off';
ax12 = subaxis(2, 3, 2, 1,'ml',0.05);
ax22 = subaxis(2, 3, 2, 2,'ml',0.05);
cdr(xls_file, pdata, 'p', [ax12 ax22]);
ax12.XAxis.Visible = 'off';
ax12.YAxis.Visible = 'off';
ax22.YAxis.Visible = 'off';
ax13 = subaxis(2, 3, 3, 1,'ml',0.05);
ax23 = subaxis(2, 3, 3, 2,'ml',0.05);
cdr(xls_file, [ndata pdata], 'b', [ax13 ax23])
ax13.XAxis.Visible = 'off';
ax13.YAxis.Visible = 'off';
ax23.YAxis.Visible = 'off';

titlex = mean(get(ax12,'XLim'));
titley = get(ax12, 'YLim');
titley = titley(2)-0.1*range(titley);
text(titlex, titley, FileName(1:end-5), 'Parent', ax12, 'FontSize', 20)

ax21.YLim = frange;
ax22.YLim = frange;
ax23.YLim = frange;

set(gcf, 'Name', FileName(1:end-5));
print(fig, strcat(PathName, FileName(1:end-5), '.png'), '-dpng', '-r0');
