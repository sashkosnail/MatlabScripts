clear data out_files dat_file ch_file Ts Fs
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

for fid = 1:1:length(FileName)
    datfile = FileName{fid};
    test_num =(regexp(datfile, '([0-9]+)_','tokens','once'));
    test_num = str2double(test_num{1});
%     if(test_num ==10)
%         sign = 1;
%     else
%         sign = 1;
%     end
    switch test_num
       case {1,2,4,7,8,9,10} 
          number_of_sensors = 4;
       case {3,5,6,11,20}
          number_of_sensors = 2;
      otherwise
          number_of_sensors = 1;
    end
    
    cd(PathName);
    seg2ascii = 'D:\Projects\seg2asci.exe';
    filter_cutoff = 32;
    co = 0; %channel offset
    cc = number_of_sensors*3; %channel count

    system([seg2ascii, ' "', datfile, '" 16K '], '-echo');

    data = [];
    out_files = dir([PathName,'*.0*']);
    for ch_file = out_files'
        if(~exist('Ts','var'))
            Ts = dlmread(ch_file.name, '' , 'B30..B30');
            Fs = 1/Ts;
        end
        ch_data = dlmread(ch_file.name, '', 38, 0);
        data = [data, ch_data]; %#ok<AGROW>
        delete(ch_file.name);
    end
    datfile = datfile(1:strfind(datfile,'.')-1);
    
    t = 0:Ts:(length(data)-1)*Ts;
    data = data(:,co+1:co+cc);
    data = data-ones(length(data), 1)*mean(data);
    
    %flip L4s
    if(test_num == 11 || test_num == 20)
        tmp = 2;
    else
        tmp = ceil(number_of_sensors/2);
    end
    for ch_idx = 1:1:tmp
        if(test_num == 11 || test_num == 20)
            j=(ch_idx-1)*3; %#ok<FXSET>
        else
            j=(ch_idx-1)*6;
        end
        data(:,j+[1 2 3]) = 20/211*[sign*data(:,j+3), sign*data(:,j+2), data(:,j+1)];
    end
    %remove offset
    data = data-ones(length(data),1)*mean(data);
    
	D = [t' data];
    [fig, STATS] = plot_sensor_data(D, datfile);
    
    save_data = 'Y'; %#ok<NASGU>
%     save_data = input('Save Data Y/N [N]:','s');
    if isempty(save_data)
        save_data = 'Y'  %#ok<NOPTS>
    end
    if(~strcmp(save_data,'N'))
        mat_file = [PathName datfile '.mat'];
        csv_file = [PathName datfile '.csv'];
        png_file = [PathName datfile '.png'];
        
        save(mat_file, 'D', 'STATS');
        dlmwrite(csv_file, D);
        export_fig(png_file, '-c[0 0 0 0]', fig);
    end
end

