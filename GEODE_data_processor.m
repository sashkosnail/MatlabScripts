myclear
if(~exist('PathName','var'))
    PathName = '';
end
[FileName, PathName, ~] = uigetfile([PathName, '*.dat'], ...
    'Pick File','MultiSelect','on');
if(~iscell(FileName))
        FileName = {FileName}; end
if(FileName{1} == 0)
    return; 
end
% freqs = [0.05, 0.1, 0.2, 0.4, 0.6, 0.8, 1, 1.5, 2, 2.5, 3, 4, 6, 8, 10];
freqs = [0.01 0.05 0.07 0.1 0.2 0.4 0.6 0.8 1 1.1 1.5 2 2.5 3 4 5 7 10 15 20];
% freqs = [15 20 30 12 35 40 50 25];
% freqs = [0.1 0.5 1 2 3 4];
% a = [freqs; freqs];
% freqs = reshape(a, 1, numel(a));
freqs=0.4;
As=[];

for fid = 1:1:length(FileName)
    datfile = FileName{fid};
%     test_num =(regexp(datfile, '([0-9]+)_','tokens','once'));
% 	test_num =(regexp(datfile, '([0-9]+)','tokens','once'));
%     test_num = str2double(test_num{1});
% 	test_num = (test_num - 60);
	number_of_sensors = 2;
	
	test_num = fid;
% 	number_of_sensors = 1;
    
    cd(PathName);
    seg2ascii = 'D:\Projects\seg2asci.exe';
    filter_cutoff = 32;
    co = 0; %channel offset
    cc = number_of_sensors*3; %channel count

    system([seg2ascii, ' "', datfile, '" 16K ']);%, '-echo');

    data = [];
    out_files = dir([PathName,'*.0*']);
    for ch_file = out_files'
		Ts = dlmread(ch_file.name, '' , 'B30..B30');
		Fs = 1/Ts;
        ch_data = dlmread(ch_file.name, '', 38, 0);
        data = [data, ch_data]; %#ok<AGROW>
        delete(ch_file.name);
    end
    datfile = datfile(1:strfind(datfile,'.')-1);
    
    t = 0:Ts:(length(data)-1)*Ts;
% 	data = data(:,[1:3, 13:15]);
% 	data = data(:,1:3);
    data = data-ones(length(data),1)*mean(data);
    
	D = [t' data];
	fff = fit_sine_data(D, freqs(test_num), ...
		strcat(datfile, '_', num2str(freqs(test_num))));
	
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

out = [freqs' As];
out = sortrows(out,1);