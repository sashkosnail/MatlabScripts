if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<OR2>
    PathName = ''; 
end
folder_name = uigetdir(PathName,'Pick File');
if(folder_name == 0)
    return
else
    PathName = folder_name;
end

dirs = dir(PathName);
dirs = {dirs([dirs.isdir]).name};
if(length(dirs)<3)
	return;
end
dirs = dirs(3:end);
if(~exist([PathName, '\Results'], 'dir'))
	mkdir(PathName, 'Results')
end
result_dir = [PathName '\Results\'];
result_xls = [result_dir 'RESULTS.xlsx'];
results_tab = {};
for did = 1:1:length(dirs)
	sensor = dirs{did};	
	tmp_filename = [PathName '\' sensor '\' sensor];
	if(~exist([tmp_filename '.mat'], 'file'))
		disp(['Skipping ' sensor]);
		continue;
	end
	disp(sensor);
	copyfile([tmp_filename '.png'], result_dir);
	xd = xlsread([tmp_filename '.xlsx'], 'Details', 'B2:E11');
	results_tab(end+1,:) = [{sensor, xd(1,2), xd(1,3), xd(1,1)}, ...
		num2cell(xd(end,:))]; %#ok<SAGROW>
end
writetable(array2table(results_tab, 'VariableNames', ...
	{'Sensor' 'Rin' 'Rimp' 'Vbatt' 'Fn' 'D' 'CDR' 'Rsh'}), ...
	result_xls, 'Sheet', 'Results', 'Range', 'A1');