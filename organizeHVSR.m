clear
%% Params
PathName = 'D:\Documents\PhD\FieldStudies\Summer\Hockley\2\HVSR_Results\' %#ok<NOPTS>
orderNS = [1,2,3,4,5,21,11,22,10,9,8,23,7,24,6,12,13,14,15,16,17,18,19,20];
data_files = dir([PathName,'*.mat']);
test_data_GEODE = {};
test_data_PITA = {};

%% Load Data
for test_file = data_files'
    test_num =(regexp(test_file.name, '([0-9]+)_','tokens','once'));
    test_num = str2double(test_num{1});
    NSid = find(orderNS==test_num,1,'first');
    if (isempty(NSid))
        continue
    end
    
    switch test_num
       case {1,2,4,7,8,9,10} 
          num_sensors = 4;
       case {3,5,6,11,20}
          num_sensors = 2;
      otherwise
          num_sensors = 1;
    end
    if(test_num==11||test_num==20)
        L4s = [1 2];
    else
        L4s = 1:2:num_sensors;
    end
    
    source =(regexp(test_file.name, '_([a-zA-Z].*)[.]','tokens','once'));
    
    Data = load(test_file.name);
    
    HVSR.HVSR = Data.HVSR;
    HVSR.FileName = test_file.name;
    HVSR.Source = source{1};
    HVSR.TestNumber = test_num;
    HVSR.L4s = L4s;
    
    switch source{1}
        case 'GEODE'
            test_data_GEODE{NSid} = HVSR; %#ok<SAGROW>
        case 'PITA'
            test_data_PITA{NSid} = HVSR; %#ok<SAGROW>
    end
end

%% Plot Data
close all
frame_size = 1024;
spot1 = {'N', 'S'};
spot2 = {'Barn', 'Farm'};
sensor_types = {'RTC', 'L4'};

D = test_data_GEODE;
Fs = 125;
plotHVSR(D, Fs, frame_size , spot1 , spot2 , sensor_types, 'GEODE', '-');

D = test_data_PITA;
Fs = 250;
figs = plotHVSR(D, Fs, frame_size , spot1 , spot2 , sensor_types, 'SYS', '--');

for fid = 1:1:length(figs)
    fig = figs(fid);
    fig.Units = 'inches';
    P = fig.Position;
    fig.Position = [1 0.5 7.5 10];
    export_fig(strcat(PathName, num2str(fid)), '-c[10 0 0 0]', fig);
    fig.Position = P;
end
