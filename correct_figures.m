fig = gcf;

tab_group = fig.Children(end);
model_tab = tab_group.Children(end-1);
model_tab.Children(1).Location = 'northwest';

if(PathName == 0); PathName = pwd; end 
[saveFile,PN_save] = uiputfile('*.mat', ...
	'Save HVSR Results and Model', PathName);
if(saveFile == 0) ;return; end

tmpFN = strcat(PN_save, saveFile(1:end-4));

tab_group.SelectedTab = model_tab;
fig.Units = 'inches';
fig.Position = [1 1 9 9.25];
export_fig(strcat(tmpFN, '_model'), '-c[25 10 50 10]', fig);