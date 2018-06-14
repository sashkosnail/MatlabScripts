function cdr(xlsfile, peaks, polarity, ax)
    fi = @(varargin)varargin{length(varargin)-varargin{1}};
    res_data = xlsread(xlsfile, 'Details');      
    num_pts = 5;
%     num_samples = 10*fi(polarity=='b',2,1);
    
    summary_table = table;
    max_peaks = 0;
    for i=1:1:size(peaks,1)
        Rin = res_data(1,1);
        Rsh = res_data(i,4);
        Rdaq = res_data(num_pts,4);
        summary_table(i,1:3)={mat2cell(peaks(i,1).Name,1), Rin, Rsh};
        if(i==num_pts) 
            Rtmp = Rdaq;
        else
            Rtmp = Rsh*Rdaq/(Rsh+Rdaq);
        end
        Req = Rin+Rtmp;
        num_peaks = 0;
        for j=1:1:size(peaks,2)
            if(isempty(peaks(i,j).Name)||~peaks(i,j).Accepted)
                continue
            end
            num_peaks = num_peaks + 1;
            cdr_data(i).D(j,:) = [Req 1/Req peaks(i,j).GOF.rmse peaks(i,j).D peaks(i,j).Fn peaks(i,j).A];
            summary_table(i,(4+3*(num_peaks-1)):(6+3*(num_peaks-1))) = {peaks(i,j).Fn, peaks(i,j).D, peaks(i,j).A}; %#ok<*AGROW>
        end
        max_peaks = fi(max_peaks<num_peaks, num_peaks, max_peaks);
    end
    
    summary_row_names = {'Channel', 'Rin', 'Rsh'};
    tmp = {'Fn', 'D', 'A'};
    for pid=1:1:max_peaks
        summary_row_names = [summary_row_names, strcat(tmp, num2str(pid))];
    end
    summary_table.Properties.VariableNames = summary_row_names;
    
    cdrPlot=zeros(num_pts*size(peaks,2),6);
    idx = 1;
    for i=1:1:num_pts
        cdrD = sortrows(cdr_data(i).D, 5);
    %     cdrD = cdrD(3:end-2,:);
        cdrD = sortrows(cdrD, 3);
        cdrD = cdrD(cdrD(:,1)~=0,:);
        cdrDfilt = cdrD(1:end,:);
        cdrPlot(idx:(idx+size(cdrDfilt,1)-1),:) = cdrDfilt;
        idx = idx + size(cdrDfilt,1);
    end

    cdrPlot = sortrows(cdrPlot(cdrPlot(:,1)~=0,:),[2 4]);

    cdrDfit = fit(cdrPlot(:,2), cdrPlot(:,4), 'poly1');
    cdrFfit = fit(cdrPlot(:,2), cdrPlot(:,5), 'poly1');
    
    CDR_table = array2table(cdrPlot);
    CDR_table.Properties.VariableNames = strcat({'Req', 'iReq', 'RMSe', 'D', 'Fn',	'A'}, '_', polarity);
    
    global summaryT;
    wt = width(summaryT);
    if(polarity~='b')
        row0 = array2table(zeros(1, max([width(summaryT),width(summary_table)])));
        plug2 = array2table(zeros(height(summary_table), abs(width(summary_table)-wt)));
        if(numel(plug2) ~= 0 && numel(summaryT) ~= 0 && width(summary_table)-wt<0)
            row0.Properties.VariableNames = summaryT.Properties.VariableNames;
            plug2.Properties.VariableNames = summaryT.Properties.VariableNames(end-width(plug2)+1:end);
            summaryT = [summaryT; [summary_table plug2]; row0];
        elseif(width(summary_table)-wt>0 && wt ~= 0)
            plug2 = array2table(zeros(height(summaryT), abs(width(summary_table)-wt)));
            row0.Properties.VariableNames = summary_table.Properties.VariableNames;
            plug2.Properties.VariableNames = summary_table.Properties.VariableNames(end-width(plug2)+1:end);
            summaryT = [[summaryT plug2]; summary_table; row0];
        else
            row0.Properties.VariableNames = summary_table.Properties.VariableNames;
            summaryT = [summaryT; summary_table; row0];
        end
    end
    
    global cdrT;
    ht = height(cdrT);
    if(ht~=0&&ht<height(CDR_table))
        plug = array2table(zeros(height(CDR_table) - height(cdrT), width(cdrT)));
        plug.Properties.VariableNames = cdrT.Properties.VariableNames;
        cdrT = [[cdrT; plug] CDR_table];
    else
        plug = array2table(zeros(height(cdrT) - height(CDR_table), width(cdrT)));
        if(numel(plug) ~= 0)
            plug.Properties.VariableNames = CDR_table.Properties.VariableNames;
            cdrT = [cdrT [CDR_table; plug]];
        else
            cdrT = [cdrT CDR_table];
        end
    end
    
    global fitT;
    Fn = cdrFfit.p2;
    D = cdrDfit.p2;
    CDR = cdrDfit.p1;
    new_row = array2table([Fn, D, CDR, CDR/(sqrt(0.5)-D)-Rin]);
    new_row.Properties.VariableNames = {'Fn', 'D', 'CDR', 'Rsh'};
    fitT = [fitT; new_row];
    
    rrang = [0.75*min(cdrPlot(:,2)) 1.25*max(cdrPlot(:,2))];
    
    axes(ax(1));
    plot(cdrPlot(:,2), cdrPlot(:,4), 'k+-');hold on
    plot(cdrDfit, 'r--');
    text(1.1*min(cdrPlot(:,2)), max(cdrPlot(:,4)), sprintf('%3.2fx + %3.2f', cdrDfit.p1, cdrDfit.p2));
%     axis([min(cdrPlot(:,2)) max(cdrPlot(:,2)) min(cdrPlot(:,4)) max(cdrPlot(:,4))])
    axis([rrang 0.5 0.8]);
    grid minor; ylabel('Damping');
    legend off;
    
    axes(ax(end));
    plot(cdrPlot(:,2),cdrPlot(:,5),'k+-');hold on
    plot(cdrFfit, 'r--');
    text(1.1*min(cdrPlot(:,2)), max(cdrPlot(:,5)), sprintf('%3.2fx + %3.2f', cdrFfit.p1, cdrFfit.p2));
%     axis([min(cdrPlot(:,2)) max(cdrPlot(:,2)) min(cdrPlot(:,5)) max(cdrPlot(:,5))])
    global frange
    frange = floor(100*(min(cdrPlot(:,5))+[-0.1 range(cdrPlot(:,5))+0.1]))/100;
    axis([rrang frange]);
    grid minor; xlabel('1/R'); ylabel('Fn[Hz]');
    legend off;
end