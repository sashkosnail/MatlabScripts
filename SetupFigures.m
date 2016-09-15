function SetupFigures(data_length, name, redraw)
    global Ns;
    global Nch;
    global Fs;
    global fig_tseries;
    global fig_FullTS;
    global fig_spectrum;
    global fig_chan;
    global figs2;
    global channels;
    
    if(exist('redraw','var'))
        ev.Axes = redraw;
        post_pan(0, ev);
        return;
    end
    
    figure('Name', name, 'Units','normalized', 'MenuBar', 'none', ...
        'ToolBar', 'figure', 'OuterPosition',[0.5, 0.5, 0.5, 0.5]);
    
    tsx = subplot('Position',[0.02 0.35 0.32 0.5]); 
    tsx.XLim = [0 Ns/Fs]; axis autoy ; grid on
    hold on; tsx.Tag = 'X';
    tsy = subplot('Position',[0.35 0.35 0.32 0.5]); 
    tsy.XLim = [0 Ns/Fs]; tsy.YAxis.Visible = 'off'; 
    hold on; tsy.Tag = 'Y'; axis autoy; grid on
    tsz = subplot('Position',[0.68 0.35 0.32 0.5]); 
    tsz.XLim = [0 Ns/Fs]; tsz.YAxis.Visible = 'off'; 
    hold on; tsz.Tag = 'Z'; axis autoy; grid on

    ftsx = subplot('Position',[0.02 0.87 0.32 0.10]); 
    axis([0 data_length/Fs -1 1]); axis autoy
    title(channels{1}(1));hold on; ftsx.Tag = 'Xf';
    ftsy = subplot('Position',[0.35 0.87 0.32 0.10]); 
    axis([0 data_length/Fs -1 1]);  axis autoy
    ftsy.YAxis.Visible = 'off'; 
    title(channels{2}(1));hold on; ftsy.Tag = 'Yf';
    ftsz = subplot('Position',[0.68 0.87 0.32 0.10]); 
    axis([0 data_length/Fs -1 1]); axis autoy
    ftsz.YAxis.Visible = 'off'; 
    title(channels{3}(1));hold on; ftsz.Tag = 'Zf';

    psdx = subplot('Position',[0.02 0.025 0.32 0.30]);
    hold on; psdx.YScale = 'log'; psdx.XScale = 'log'; 
    psdx.XLim = [4.5 Fs/2];psdx.YLim = [.1E-6 0.01]; grid on 
%     axis autoy
    psdy = subplot('Position',[0.35 0.025 0.32 0.30]); 
    hold on; psdy.YScale = 'log'; psdy.XScale = 'log';
    psdy.XLim = [4.5 Fs/2];psdy.YLim = [.1E-6 0.01]; grid on
%     axis autoy
    psdz = subplot('Position',[0.68 0.025 0.32 0.30]); 
    hold on; psdz.YScale = 'log'; psdz.XScale = 'log';
    psdz.XLim = [4.5 Fs/2];psdz.YLim = [.1E-6 0.01]; grid on
%     axis autoy
    
    ftsx.UserData = tsx; ftsy.UserData = tsy; ftsz.UserData = tsz;
    tsx.UserData = ftsx; tsy.UserData = ftsy; tsz.UserData = ftsz;    
    
    z = zoom; z.Motion = 'vertical';
    z.ButtonDownFilter = @zoom_button_down;
    h = pan; h.Motion = 'horizontal';
    h.ButtonDownFilter = @pan_button_down;
    h.ActionPostCallback = @post_pan;
    h.ActionPreCallback = @pre_pan;
    h.Enable = 'on';
    
    ftsx.ButtonDownFcn = @click_fts;
    ftsy.ButtonDownFcn = @click_fts;
    ftsz.ButtonDownFcn = @click_fts;
    
    L = length(channels) - sum(strcmp(channels, 'xxx'));
    clear fig_chans;
    disp('====================')
    for j=1:1:3
        figure('Units', 'normalized', 'MenuBar', 'none', 'OuterPosition', [0,0,0.5,1]); clf
        k=0;
        for i=1:1:Nch
            chan = channels{j+(i-1)*3};
            if(~(strcmp(chan, 'xxx')))
                disp(chan)
                figg = subplot('Position',[0.05, 0.05+0.95*k/(L/3), 0.9, 0.9/(L/3)]);  %#ok<*AGROW>
                figg.Tag = chan;
                figg.YLimMode = 'manual';
                figg.XLimMode = 'manual';
                figg.XLim = [0 Ns/Fs];hold on;
                figg.XAxis.Visible = 'off'; 
                k=k+1;
%                 disp(fig_chans);
                disp([j,k])
                if ~exist('fig_chans', 'var')
                    fig_chans = repmat(figg, L/3, 3)';
                end
                fig_chans(j, k) = figg;
            end
        end
        if exist('fig_chans', 'var')
            fig_chans(j, 1).XAxis.Visible = 'on';
        end
        disp('====================')
    end
    
    figs2 = figure('Name', 'Spectrum', 'Units','normalized', 'MenuBar', 'none', 'ToolBar', 'figure', 'OuterPosition',[0.5, 0, 0.25, 0.5]);
    figs2(2) = figure('Name', 'Corrected', 'Units','normalized', 'MenuBar', 'none', 'ToolBar', 'figure', 'OuterPosition',[0.75, 0, 0.25, 0.5]);
    
    fig_tseries = [tsx tsy tsz];
    fig_FullTS = [ftsx ftsy ftsz];
    fig_spectrum = [psdx psdy psdz];
    fig_chan = fig_chans;
end

function click_fts(obj, ~)
    global win_lines;
    global Ns;
    global Fs
    global fig_tseries;
    global fig_FullTS;
%     if obj.Parent.CurrentState.Blocking
%         return
%     end
    click_point = ginput(1);
    cp = click_point(1);
    for id=1:1:3
        fig_tseries(id).XLim = [(cp - 1/2 * Ns/Fs), (cp + 1/2 * Ns/Fs)];
        lines = [   plot(fig_FullTS(id), (cp - 1/2 * Ns/Fs)*[1 1], fig_FullTS(id).YLim, 'k')
                    plot(fig_FullTS(id), (cp + 1/2 * Ns/Fs)*[1 1], fig_FullTS(id).YLim, 'k')];
        if isempty(win_lines)
          win_lines=repmat(lines',3,1);
        end
        delete(win_lines(id,:));
        win_lines(id,:) = lines;
        h=pan(gcf);
        h.Enable = 'on';
    end
end
function pre_pan(~, ~)
    global fig_tseries;
    global Fs;
    global Ns;
    for i=1:1:3
        c = mean(fig_tseries(i).XLim);
        if((c-Ns/Fs/2)>0)
            fig_tseries(i).XLim = [c-Ns/Fs/2; c+Ns/Fs/2];
        else
            fig_tseries(i).XLim = [0; Ns/Fs];
        end
    end
end
function post_pan(~, evd)
    global win_lines;
    global fig_chan;
    global fig_tseries;
    global fig_FullTS;
    values = evd.Axes.XLim;
    try 
        for i=1:1:length(fig_FullTS)
            fig_tseries(i).XLim = values;
            lines = [   plot(fig_FullTS(i), [values(1), values(1)], fig_FullTS(i).YLim, 'k')
                        plot(fig_FullTS(i), [values(2), values(2)], fig_FullTS(i).YLim, 'k')];
            if isempty(win_lines)
                  win_lines=repmat(lines',length(fig_FullTS),1);
            end
            delete(win_lines(i,:));
            win_lines(i,:) = lines;
            for ch_fig = fig_chan
                ch_fig(i).XLim = fig_tseries(i).XLim;
            end
            calc_spectrum(i);
        end     
    catch
        disp('Error')
    end
end

function [flag] = pan_button_down(obj, ~)
    tag = obj.Tag;
    if(strcmpi(obj.Type, 'line') && ~strcmpi(obj.Parent.Tag, 'X'))
        flag = true;
        return
    end
    if((~isempty(tag) && length(tag) <= 1) || strcmpi(obj.Type, 'line')) 
       flag = false;
    else
       flag = true;
    end
end

function [flag] = zoom_button_down(obj, ~)
    global Ns;
    tag = obj.Parent.Tag;
    if(isempty(tag))
        flag = false;
        return;
    end
    flag = true;
    if length(tag) <= 1
       z = zoom(gcf);
       switch z.Motion
           case 'vertical'
               flag = false;
               return;
           otherwise
               if(strcmpi(z.Direction, 'out'))
                   Ns = Ns * 2;
               else
                   Ns = Ns / 2;
               end
               if Ns<1 
                   Ns=1; 
               end
               c = mean(obj.Parent.XLim);
               obj.Parent.XLim = [c-Ns/2; c+Ns/2];
               tmp.Axes = obj.Parent;
               post_pan(tmp, tmp);
       end
    end
end