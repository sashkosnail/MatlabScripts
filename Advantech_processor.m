clear; close all;
global Fs;
global Ns;
global fig_tseries;
global fig_FullTS;
global fig_chan;
global fig_spectrum;
global channel_enabled;
global Ns_field;
global Nch;
global Filters;
global channels;
global win_lines;

Ns = 512;
scaling_constant = 1/24;
f_cutoff = 400;
PathName = 'D:\Documents\PhD\Field Studies\';
[FileName,PathName,FilterIndex] = uigetfile(strcat(PathName, '*.wsdt'),'Pick File') %#ok<NOPTS>
desc_id = fopen(strcat(PathName, 'Description.txt'));

channels = strsplit(fgetl(desc_id));
Nch = length(channels)/3;
% Nch = 1;
channel_enabled = ones(Nch, 1);
fclose(desc_id);
data = dlmread(strcat(PathName, FileName), ',', 1, 0);
time = data(:,1);

Ts = time(2)-time(1);
Fs = 1/Ts;

[b, a] = butter(4, f_cutoff*2/Fs, 'low');
Filters.Bl = tf2sos(b, a);
[b, a] = butter(4, f_cutoff*2/Fs, 'low');
Filters.BL = tf2sos(b, a);
[b, a] = butter(4, 4.5*2/Fs, 'high');
Filters.BH = tf2sos(b, a);

%assign filters
for i=1:1:length(channels)
    disp(channels{i})
    if(isempty(regexp(channels{i},'[A-Z]','ONCE')))
        Filters.Bank{i} = Filters.Bl;
    else
        Filters.Bank{i} = Filters.BL;
    end
end

%trim channels
data = data(:,3:Nch*3+2);

% -offset
chan_data = scaling_constant*(data-repmat(mean(data), length(data), 1)); 

% pre and post spectre tranform to time-domain and get accelerations

SetupFigures(length(chan_data), strcat(PathName, FileName));

% label channels

proc_data = proc_filter(chan_data);
%  filter();

y_limits = [0 0];
for i=1:1:Nch
    for j=1:1:3
        plot(fig_tseries(j), time, proc_data(:,j+3*(i-1)), 'DisplayName', channels{j+3*(i-1)});
        plot(fig_FullTS(j), time(1:10:end), proc_data(1:10:end,j+3*(i-1)));
        tmp = fig_tseries(j).YLim;
        y_limits = [min([y_limits tmp]) max([y_limits tmp])];
    end
end
for j=1:1:3
    fig_FullTS(j).YLim = y_limits;
    fig_tseries(j).YLim = y_limits;
    %draw window
    lines = [   plot(fig_FullTS(j), [0 0], fig_FullTS(j).YLim, 'k')
                plot(fig_FullTS(j), [1 1]*Ns/Fs, fig_FullTS(j).YLim, 'k')];
    if isempty(win_lines)
          win_lines=repmat(lines',length(fig_FullTS),1);
    end
    delete(win_lines(j,:));
    win_lines(j,:) = lines;
end

L = length(channels) - sum(strcmp(channels, 'xxx'));
for i=1:1:Nch
    for j=1:1:3
        plot(fig_chan(j, i), time, proc_data(:,j+3*(i-1)), 'DisplayName', channels{j+3*(i-1)});
        max_val = max(abs(proc_data(1:end,j+3*(i-1))));
        if max_val == 0
            max_val = 1;
        end
        fig_chan(j,i).YLim = max_val.*[-1 1];
        legend(fig_chan(j,i), 'show');
        legend(fig_chan(j,i), 'boxoff');
        disp([j,i])
    end
end

y_limits = [0 0];
for j=1:1:3
        calc_spectrum(j);
        tmp = fig_spectrum(j).YLim;
        y_limits = [min([y_limits tmp]) max([y_limits tmp])];
end
for j=1:1:3
    fig_spectrum(j).YLim = y_limits;
end

channel_selector();
Ns_field.String = num2str(Ns);
