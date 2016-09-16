clear; close all;
global Fs;
global Ns;
global fig_tseries;
global fig_FullTS;
global fig_chan;
global fig_chan_disp;
global fig_chan_accel;
global fig_spectrum;
global figs2
global channel_enabled;
global Ns_field;
global Nch;
global Filters;
global channels;
global win_lines;
global h_chan_select;
global PathName;
global FileName;
global export_data;
global ranges;

Ns = 16384;
scaling_constant = 1/24.6;
f_cutoff = 450;
PathName = 'D:\Documents\PhD\Field Studies\';
[FileName,PathName,FilterIndex] = uigetfile(strcat(PathName, '*.wsdt'),'Pick File') %#ok<NOPTS>
if(FileName == 0)
    return;
end
desc_id = fopen(strcat(PathName, 'Description.txt'));

channels = strsplit(fgetl(desc_id));
Nch = length(channels)/3;
ranges = zeros(4, Nch*3);
% Nch = 1;
channel_enabled = ones(Nch, 1);
fclose(desc_id);
data = dlmread(strcat(PathName, FileName), ',', 1, 0);
time = data(:,1);

Ts = time(2)-time(1);
Fs = 1/Ts;

[b, a] = butter(6, f_cutoff*2/Fs, 'low');
Filters.Bl = tf2sos(b, a);
[b, a] = butter(6, f_cutoff*2/Fs, 'low');
Filters.BL = tf2sos(b, a);
[b, a] = butter(4, 4.2*2/Fs, 'high');
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
% chan_data = chan_data.*repmat([0.85 0.95 0.95 1 1 1],length(chan_data),1);
% pre and post spectre tranform to time-domain and get accelerations

SetupFigures(length(chan_data), strcat(PathName, FileName));

% label channels

proc_data = proc_filter(chan_data);
%  filter();

y_limits_1 = 0;
y_limits_2 = 0;

for i=1:1:Nch
    for j=1:1:3
        plot(fig_tseries(j), time, proc_data(:,j+3*(i-1)), 'DisplayName', channels{j+3*(i-1)});
        plot(fig_FullTS(j), time(1:10:end), proc_data(1:10:end,j+3*(i-1)));
        tmp = fig_tseries(j).YLim;
        y_limits_1 = max(abs([y_limits_1 tmp]));
        tmp = fig_FullTS(j).YLim;
        y_limits_2 = max(abs([y_limits_2 tmp]));
    end
end
for j=1:1:3
    fig_FullTS(j).YLim = [-1 1]*y_limits_2;
    fig_tseries(j).YLim = [-1 1]*y_limits_1;
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
% max_valV = 0;
% max_valA = 0;
% max_valD = 0;
for i=1:1:Nch
    for j=1:1:3
        vel = proc_data(:,j+3*(i-1));
        plot(fig_chan(j, i), time, vel, 'DisplayName', channels{j+3*(i-1)});
%         max_valV = max([abs(vel); max_valV]);
        legend(fig_chan(j,i), 'show');
        legend(fig_chan(j,i), 'boxoff');
        fig_chan(j,i).YLim = max(abs(vel)).*[-1 1];
        
        displ = cumtrapz(vel)/Fs;
        plot(fig_chan_disp(j, i), time, displ, 'DisplayName', channels{j+3*(i-1)});
%         max_valD = max([abs(displ); max_valD]);
        legend(fig_chan_disp(j,i), 'show');
        legend(fig_chan_disp(j,i), 'boxoff');
        fig_chan_disp(j,i).YLim = max(abs(displ)).*[-1 1];
        
        accel = diff(vel)*Fs;
        plot(fig_chan_accel(j, i), time(1:end-1), accel, 'DisplayName', channels{j+3*(i-1)});
%         max_valA = max([abs(accel); max_valA]);
        legend(fig_chan_accel(j,i), 'show');
        legend(fig_chan_accel(j,i), 'boxoff');
        fig_chan_accel(j,i).YLim = max(abs(accel)).*[-1 1];
        
        ranges(1,(i-1)*3+j) = range(accel);
        ranges(2,(i-1)*3+j) = range(vel);
        ranges(3,(i-1)*3+j) = range(displ);
    end
end

y_limits = [0 0];
for j=1:1:3
        calc_spectrum(j);
        tmp = fig_spectrum(j).YLim;
        y_limits = [min([y_limits tmp]) max([y_limits tmp])];
%      for i=1:1:Nch           
%         fig_chan(j,i).YLim = max_valV.*[-1 1];
%         fig_chan_disp(j,i).YLim = max_valD.*[-1 1];
%         fig_chan_accel(j,i).YLim = max_valA.*[-1 1];
%      end
end
for j=1:1:3
    fig_spectrum(j).YLim = y_limits;
end
if(exist('h_chan_select','var') && ~isempty(h_chan_select) && ishandle(h_chan_select))
    close(h_chan_select);
end
h_chan_select = channel_selector();
Ns_field.String = num2str(Ns);
export_data = [time proc_data];
legend(fig_tseries(2),'show')
