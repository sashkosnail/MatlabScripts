if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<OR2>
    PathName = ''; 
end
folder_name = uigetdir(PathName,'Pick File');
if(folder_name == 0)
    return
else
    PathName = folder_name;
end
RV_Values = readtable(([PathName '\RV.xlsx']));
RV_Values = RV_Values(~any(ismissing(RV_Values),2),:);

for ln=1:1:height(RV_Values)
	sensor = upper(RV_Values.sensor{ln});
	fname = [PathName '\' sensor '\' sensor '.xlsx'];
	if(exist(fname,'file'))
		disp(['Skipping ' sensor])
		continue;
	end
	disp(sensor)
	copyfile([PathName '\template.xlsx'], fname);
	xlswrite(fname, table2cell(RV_Values(ln,:)), 'Details', 'A2');
end
	