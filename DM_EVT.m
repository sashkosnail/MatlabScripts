myclear
if(~exist('PathName','var'))
    PathName = '';
end
[FileName, PathName, ~] = uigetfile([PathName, '*.tdms'], ...
    'Pick File','MultiSelect','on');
if(~iscell(FileName))
        FileName = {FileName}; end
if(FileName{1} == 0)
    return; 
end
% freqs = [0.05, 0.1, 0.2, 0.4, 0.6, 0.8, 1, 1.5, 2, 2.5, 3, 4, 6, 8, 10];
% freqs = [0.1 0.5 1 2 3 4];
% freqs = [0.01 0.05 0.07 0.1 0.2 0.4 0.6 0.8 1 1.1 1.5 2 2.5 3 4 5 7 10 15 20];
% a = [freqs; freqs];
% freqs = reshape(a, 1, numel(a));

As=[];

for fid = 1:1:length(FileName)
    datfile = FileName{fid};
%     test_num =(regexp(datfile, '([0-9]+)_','tokens','once'));
	f(fid) = str2double(regexp(datfile, '_([0-9.]+)Hz','tokens','once'));
	test_num = fid;
	number_of_sensors = 1;
    
    co = 0; %channel offset
    cc = number_of_sensors*3; %channel count
	
    [TDMSData,~] = TDMS_readTDMSFile([PathName datfile]);
	S.groupIDx = TDMSData.groupIndices';
	S.chanIDx = TDMSData.chanIndices';
	S.chanNames = TDMSData.chanNames';
	groups = struct2table(S, 'RowNames', TDMSData.groupNames);
	propN = strrep(TDMSData.propNames{1,1}, ' ', '');
	Properties = cell2struct(TDMSData.propValues{1,1}(:), propN);
	
	data = cell2mat(TDMSData.data(groups{'Active', 'chanIDx'}{:})')';
    
	Fs = str2double(Properties.SampleRate);
	Ts = 1.0/Fs;
    t = 0:Ts:(length(data)-1)*Ts;
% 	data = data(:,[1:3, 13:15]);
	data = data(:,1:3);
    data = data-ones(length(data),1)*mean(data);
    
	D = [t' data];
	fff = fit_sine_data(D, f(fid), ...
		strcat(datfile, '_', num2str(f(fid))));
	
	data_fit(:,fid) = fff;
	As = [As; [fff.A]];
    
    save_data = 'Y'; %#ok<NASGU>
%     save_data = input('Save Data Y/N [N]:','s');
    if isempty(save_data)
        save_data = 'Y'  %#ok<NOPTS>
    end
    if(~strcmp(save_data,'N'))
        mat_file = [PathName datfile '.mat'];
        csv_file = [PathName datfile '.csv'];
%         png_file = [PathName datfile '.png'];
        
%         save(mat_file, 'D', 'STATS');
        dlmwrite(csv_file, D);
%         export_fig(png_file, '-c[0 0 0 0]', fig);
	end
end

out = [f' As];
out = sortrows(out,1);
As = out(:,2:end);

