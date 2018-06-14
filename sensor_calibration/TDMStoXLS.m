if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<OR2>
    PathName = ''; 
end
folder_name = uigetdir(PathName,'Pick File');
if(folder_name == 0)
    return
else
    PathName = folder_name;
end

xls_file = dir([PathName '\*.xlsx']);
tdms_files = dir([PathName '\*.tdms']);

for idx = 1:numel(tdms_files)
    tdms = tdms_files(idx);
    disp(tdms.name);
    polarity = upper(tdms.name(1));
    index = [(64+str2double(tdms.name(2))*2) '2'];
    tdmsStruct = TDMS_getStruct([PathName '\' tdms.name],1);
    data_sensor = tdmsStruct.Untitled.cDAQ1Mod1_ai0.data;
    data_pulse = tdmsStruct.Untitled.cDAQ1Mod1_ai1.data;
    data = [data_sensor' data_pulse'];
    xlswrite([PathName '\' xls_file.name], data, polarity, index);
end
