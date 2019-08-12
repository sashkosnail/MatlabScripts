%Test continuity
if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<OR2>
        PathName = [pwd '\']; 
end
[FileName, PathName, ~] = uigetfile([PathName, '*.tdms'],'Pick File','MultiSelect','on');
if(~iscell(FileName))
    FileName = sort({FileName}); 
else
    FileName = sort(FileName);
end
if(FileName{1} == 0)
    return; 
end
if(exist([PathName 'sensor_configuration.txt'], 'file'))
    sensor_config = readtable([PathName 'sensor_configuration.txt'], ...
        'Format','%d%s%s', 'Delimiter', '\t', 'MultipleDelimsAsOne', 1);
    %trim table if too large
    sensor_config = sensor_config(1:min(height(sensor_config),8),:);
else
    %default config
    sensor_config = table((1:8)', cellstr(strcat('s',num2str((1:8)'))), ...
        cellstr(repmat('xyz',8,1)), ...
        'VariableNames',{'Ch','Name','Components'});
end

active_ids = find(~strcmp(sensor_config.Name,'0'))';
sensor_names = sensor_config.Name(active_ids);
components = sensor_config.Components(active_ids);
number_of_sensors = length(active_ids);

%figure out the order of channels and components
data_channels = zeros(1, 3*number_of_sensors);
for sensor = 1:1:number_of_sensors
    chan = active_ids(sensor);
    comps = cell2mat(components(sensor));
    %column numbers for the given channel
    cn = (chan*3-2):(chan*3);
    %reorder based on comps
    comp_set = [cn(comps == 'x') cn(comps == 'y') cn(comps == 'z')];
    %add one to skip over time column and append to final vector
    data_channels((sensor*3-2):(sensor*3)) = comp_set + 1;
end

sensor_config = [sensor_config(active_ids,:) ...
    table(reshape(data_channels,3,[])', 'VariableNames', {'ColumnsUsed'})];
names = cellfun(@(c)strcat({'X_';'Y_';'Z_'},c), sensor_names, 'uni', 0);
names = vertcat(names{:})';

data = [];
T = [];
breaks = [];
%% 
for idx = 1:1:length(FileName)
    datfile = FileName{idx};
    Dtable = TDMS_getStruct([PathName datfile],6);
        
    %extract data from data file
    t = Dtable.DATA{:,1}; 
    Fs = 1/(t(2)-t(1));
    data = [data; Dtable.DATA{:,data_channels}]; %#ok<AGROW>
    if(idx == 1)
        T=t;
    else
        T = [T; T(end)+1/Fs+t]; %#ok<AGROW>
    end
    breaks = [breaks; T(end)]; %#ok<AGROW>
end
%% 
figure(); clf
nbreaks = length(breaks);
for n=1:1:nbreaks
    subplot(1,nbreaks, n)
    plot(T, data);hold on
    plot([1 1]*breaks(n), [min(min(data)) max(max(data))],'k--');
    xlim([-0.25 0.25]+breaks(n));
end