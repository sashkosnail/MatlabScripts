% close all

if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<OR2>
        PathName = [pwd '\']; 
end
[FileName, PathName, ~] = uigetfile([PathName, '*.tdms'],'Pick File','MultiSelect','on');
if(~iscell(FileName))
    FileName = {FileName}; end
if(FileName{1} == 0)
    return; 
end
%% 
for idx = 1:1:length(FileName)
    datfile = FileName{idx};
    test_num =(regexp(datfile, '([0-9]+)_','tokens','once'));
    test_num = str2double(test_num{1});
    sign=1;
%     if(test_num ==10)

%         sign = 1;
%     else
%         sign = 1;
%     end
%     switch test_num
%        case {1,2,4,7,8,9,10} 
%           number_of_sensors = 4;
%        case {3,5,6,11,20}
%           number_of_sensors = 2;
%       otherwise
%           number_of_sensors = 1;
%     end

    number_of_sensors = 2;
    sensor_offset = 6;
%     
    disp('===============================================================');
    disp(datfile)
    D = TDMS_getStruct([PathName datfile],5);
    datfile = datfile(1:strfind(datfile,'.')-1);
    t = D{:,1};
    data = D{:,(sensor_offset*3+1)+(1:number_of_sensors*3)};
% 	data = D{:, 1+[1:6, 22:24]};
    config = D{:,26:end};
    %Extract confguration information
    FILTERS = [32,64,128];
    SCALES_STR = {'0.1mm/s', 'Calibration', '100mm/s', '10mm/s', '1mm/s'};
    SCALE_MULT = [0.01, 10, 10, 1, 0.1];
%     scale_selected = ceil(mean(config(:,end))+0.5);
%     filt_selected = FILTERS(ceil(mean(config(:,end-1))-1));
%     disp(['Filter Selected: ', num2str(filt_selected), ...
%         'Hz || Scale Selected: ', SCALES_STR{scale_selected}])

    %L4 Reorder and scale
%     if(test_num == 11|| test_num == 20)
%         tmp = 2;
%     else
%         tmp = ceil(number_of_sensors/2);
%     end
%     for ch_idx = 1:1:tmp
%         if(test_num == 11|| test_num == 20)
%             j=(ch_idx-1)*3;
%         else
%             j=(ch_idx-1)*6;
%         end
%         data(:,j+[1 2 3]) = 20/211*[sign*data(:,j+3), sign*data(:,j+2), data(:,j+1)];
%     end

    %remove offset
    data = (data-ones(length(data),1)*mean(data))*SCALE_MULT(scale_selected);
	D = [t data];
   
    fig = plot_sensor_data(D, datfile, repmat({'x','y','z'},number_of_sensors,1), 123);
    
    save_data = 'Y'; %#ok<NASGU>
    save_data = input('Save Data Y/N [N]:','s');
    if isempty(save_data)
        save_data = 'Y'  %#ok<NOPTS>
    end
    if(~strcmp(save_data,'N'))
        mat_file = [PathName datfile '.mat'];
        csv_file = [PathName datfile '.csv'];
        png_file = [PathName datfile '.png'];
        
        save(mat_file, 'D');
        dlmwrite(csv_file, D);
        export_fig(png_file, '-c[0 0 0 0]', fig);
    end
end