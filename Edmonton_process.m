colors
%% Load Data
% spacing_data = xlsread('D:\Documents\PhD\Edmonton\spacing.xlsx','C5:L9');
% spacing2 = spacing_data(1,~isnan(spacing_data(1,:)));
% spacing3 = spacing_data(3,~isnan(spacing_data(3,:)));
% spacing4 = spacing_data(5,~isnan(spacing_data(5,:)));
% 
% [~, data_sheets] = xlsfinfo('D:\Documents\PhD\Edmonton\data\data.xlsx');
% % while(isempty(cell2mat(strfind(data_sheets,sheet))))
% %     sheet=input('Sheet Name:','s');
% % end
% for csheet = data_sheets
%     sheet = cell2mat(csheet);
%     disp(sheet)
%     sheet_data = xlsread('D:\Documents\PhD\Edmonton\data\data.xlsx',sheet);
%     if(strfind(sheet,'E4'))
%         sec_id=3;
%         spacing = spacing4;
%         fig2=figure(4);
%     elseif(strfind(sheet,'E3'))
%         sec_id=2;
%         spacing = spacing3;
%         fig2=figure(3);
%     else
%         sec_id=1;
%         spacing = spacing2;        
%         fig2=figure(2);
%     end
%     
%     channels = strcat('ch',num2str(sheet_data(1,:)'));
%     Nch = length(channels);
%     data{sec_id}.Channels = channels; %#ok<*SAGROW>
%     data{sec_id}.Nch = Nch;
%     data{sec_id}.spacing = spacing;
%     
%     figure(1);clf
%     plot(sheet_data(2:end,:));
%     title(sheet);
%     [~, ~, button] = ginput(1);
%     if(button == 3)
%         continue;
%     end
%     idx = length(data{sec_id}.Test)+1;
%     data{sec_id}.Test(idx).Data = sheet_data(2:end,:);
%     data{sec_id}.Test(idx).Name = sheet;
% end

%% Get Peaks
Fs=1000;
for i=1:1:2
    section = data{i};
    color_set = mycolors(floor(linspace(1, length(mycolors), section.Nch)),:);
    for j = 6:1:length(section.Test)
        test = section.Test(j);
        ph=zeros(Nch,1);
        figure(10+j); clf;
        set(gcf, 'CurrentCharacter','a');
        for ch_id=section.Nch:-1:1
            ch_data = test.Data(:,ch_id);
            ch_color = color_set(ch_id, :);
            t = (1:1:length(ch_data))'/Fs;
            tt = repmat(t,1,min(size(data)));
            s2 = subplot(2,1,2);
            ph(ch_id) = plot(t, ch_data, 'DisplayName', section.Channels(ch_id,:),'Color',color_set(ch_id,:));
            set(gcf, 'CurrentCharacter','a');
            hold on; title(strcat(test.Name,'/',section.Channels(ch_id,:)));
            if(sum(data{i}.Test(j).Peaks{ch_id})~= 0)
                peaks = data{i}.Test(j).Peaks{ch_id};
                cursorMode = datacursormode(gcf);
                hTarget = handle(ph(ch_id));
                for peak = peaks'
                    hDatatip = cursorMode.createDatatip(hTarget);
                    set(hDatatip,'UIContextMenu',get(cursorMode,'UIContextMenu'));
                    set(hDatatip,'HandleVisibility','off');
                    set(hDatatip,'Host',hTarget);
                    set(hDatatip,'OrientationMode','manual');
                    set(hDatatip,'Orientation','topright');
                    set(hDatatip, 'MarkerSize',5, 'MarkerFaceColor','none', ...
                                  'MarkerEdgeColor','k', 'Marker','o', 'HitTest','off');                
                    hDatatip.Cursor.Position = peak';
                end
            end
            waitfor(gcf,'CurrentCharacter',char(13));
            set(gcf, 'CurrentCharacter','a');
            cursors = getCursorInfo(datacursormode(gcf));
            if(isempty(cursors))
                peaks = [0,0];
            else
                peaks = zeros(length(cursors),2);
                for k=1:1:length(cursors)
                    peaks(k,:) = cursors(k).Position;
                end
            end
            clear cursors;
            plot(peaks(:,1),peaks(:,2),'x','MarkerEdgeColor',color_set(ch_id,:),'DisplayName', section.Channels(ch_id,2:end));
            removeAllDataCursors(datacursormode(gcf));
            set(ph(ch_id),'Visible','off');
            [~, idx] = sort(peaks(:,1));
            peaks = peaks(idx,:);
            data{i}.Test(j).Peaks{ch_id} = peaks; %#ok<SAGROW>
            
            s1 = subplot(2,1,1);hold on
            set(gcf, 'CurrentCharacter','a');
            title(section.Test(j).Name);
            plot(t, ch_data, 'DisplayName', section.Channels(ch_id,:),'Color',color_set(ch_id,:));
            plot(peaks(:,1),peaks(:,2),'x','MarkerEdgeColor',color_set(ch_id,:),'DisplayName', section.Channels(ch_id,2:end));
            disp(section.Channels(ch_id,:))
            disp(peaks);
%             figure(10+j);
        end
        subplot(1,1,1,s1);
        for ch_id=1:1:Nch
            set(ph(1),'Visible','on');
        end
    end
end

%% Store Data
for i=1:1:length(data)
    section = data{i};
    color_set = mycolors(floor(linspace(1, length(mycolors), section.Nch)),:);
    output = cell(10+4*length(section.Test), section.Nch);
    sheet = strcat('E',num2str(i+1));
    output(1,:) = cellstr(section.Channels);
    output(2,:) = num2cell(section.spacing);
    k = 3;
    for j = 1:1:length(section.Test)
        test = section.Test(j);
        output(k,1) = cellstr(test.Name);
        max_pks=0;
        for ch_id=1:1:section.Nch
            peaks = test.Peaks{ch_id};
            if(isempty(peaks))
                continue;
            end
            max_pks = max(max_pks,length(peaks));
            output(k+1 :(k + length(peaks)), ch_id) = num2cell(peaks(:,2));
        end
        k=k+max_pks+1;
    end
    xlswrite('D:\Documents\PhD\Edmonton\peaks.xlsx', output, sheet);
end