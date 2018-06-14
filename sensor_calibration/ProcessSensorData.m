%%Load and Combine data from TDMS to XLSX

if((~exist('PathName', 'var'))|(PathName == 0)) %#ok<OR2>
    PathName = ''; 
end
folder_name = uigetdir(PathName,'Pick File');
if(folder_name == 0)
    return
else
    PathName = folder_name;
end

cc=strcat({'HGD'}, strtrim(num2str((10:20)')));
bb=strcat({'HGD'}, strtrim(num2str((1:9)')));
bbcc=[bb;cc];
PathName_start = PathName;

for fldr_id = 1:length(bbcc)
    PathName=[PathName_start '\' bbcc{fldr_id}]

    xls_file = dir([PathName '\*.xlsx']);
    xls_file = [PathName '\' xls_file.name];
    tdms_files = dir([PathName '\*.tdms']);

    max_length_p = 0;
    max_length_n = 0;
    Ts = -1;
    disp(PathName)

    for idx = 1:numel(tdms_files)
        tdms = tdms_files(idx);
        disp(tdms.name);
        polarity = upper(tdms.name(1));
        index = [(64+str2double(tdms.name(2))*2) '2'];

        tdms = [PathName '\' tdms_files(idx).name];
        tdmsStruct = TDMS_getStruct(tdms, 1);

        data_sensor = tdmsStruct.Untitled.cDAQ1Mod1_ai0.data;
        data_pulse = tdmsStruct.Untitled.cDAQ1Mod1_ai1.data;
        data = [data_sensor' data_pulse'];
        xlswrite(xls_file, data, polarity, index);

        if(polarity == 'N')
            max_length_n = max(max_length_n, length(data));
        else
            max_length_p = max(max_length_p, length(data));
        end
        Ts = tdmsStruct.Untitled.cDAQ1Mod1_ai0.props.value(3);
        Ts = Ts{1};
    end

    xlswrite(xls_file, (0:1:max_length_n-1)'*Ts, 'N', ...
        ['A2:A' num2str(max_length_n + 1)]);
    xlswrite(xls_file, (0:1:max_length_p-1)'*Ts, 'P', ...
        ['A2:A' num2str(max_length_p + 1)]);

    %% Run Step Response Analyzer
    fit_params.A = [0.001 100];
    fit_params.w = [2.5 7.5].*(2*pi);
    fit_params.D = [0.3 0.9];
    fit_params.n0 = [0 0];
    fit_params.Offset = [-1 1];
    fit_params.phi = [-1 1]*pi/8;

    ndata = step_response2(xls_file, fit_params, 'N');
    pdata = step_response2(xls_file, fit_params, 'P');

    %% CDR
    clear summaryT cdrT
    global summaryT
    global cdrT
    global fitT
    global frange
    frange = [4.1 4.7];
    summaryT = table;
    cdrT = table;
    fitT = table;
    fig = figure(30);clf
    set(fig, 'PaperPositionMode', 'auto')
    % set(fig,'units','normalized','outerposition',[0 0 1 1])
    ax11 = subaxis(2, 3, 1, 1,'ml',0.05);
    ax21 = subaxis(2, 3, 1, 2,'ml',0.05);
    cdr(xls_file, ndata, 'n', [ax11 ax21]);
    ax11.XAxis.Visible = 'off';
    ax12 = subaxis(2, 3, 2, 1,'ml',0.05);
    ax22 = subaxis(2, 3, 2, 2,'ml',0.05);
    cdr(xls_file, pdata, 'p', [ax12 ax22]);
    ax12.XAxis.Visible = 'off';
    ax12.YAxis.Visible = 'off';
    ax22.YAxis.Visible = 'off';
    ax13 = subaxis(2, 3, 3, 1,'ml',0.05);
    ax23 = subaxis(2, 3, 3, 2,'ml',0.05);
    cdr(xls_file, [ndata pdata], 'b', [ax13 ax23])
    ax13.XAxis.Visible = 'off';
    ax13.YAxis.Visible = 'off';
    ax23.YAxis.Visible = 'off';

    titlex = mean(get(ax12,'XLim'));
    titley = get(ax12, 'YLim');
    titley = titley(2)-0.1*range(titley);
    text(titlex, titley, xls_file(find(xls_file=='\',1,'last')+1:end-5), 'Parent', ax12, 'FontSize', 20)

    ax21.YLim = frange;
    ax22.YLim = frange;
    ax23.YLim = frange;

    set(gcf, 'Name', xls_file(find(xls_file=='\',1,'last')+1:end-5));
    %% Save Data
    print(fig, strcat(xls_file(1:end-5), '.png'), '-dpng', '-r0');
    writetable(summaryT, xls_file, 'Sheet', 'Averages', 'Range', 'A2');
    writetable(cdrT, xls_file, 'Sheet', 'CDR', 'Range', 'A2');
    writetable(fitT, xls_file, 'Sheet', 'Details', 'Range', 'B8');
    % writetable(summaryT, strcat(xlsfile(1:lis),'summary.csv'));
    % writetable(cdrT, strcat(xlsfile(1:lis),'cdr.csv'));
    % writetable(fitT, strcat(xlsfile(1:lis),'out.csv'));

    save(strcat(xls_file(1:end-5), '.mat'));
    disp('DONE');
end