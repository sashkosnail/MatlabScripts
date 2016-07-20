function output = apply_window(wind, signal)
    N = length(signal);
    Nch = size(signal,2);
    win_size = length(wind);
%     n = 0:1:N-1;
%     
%     fig1=figure(101);clf
%     plot(n, signal, '-', 'LineWidth',0.01);hold on
%     axis tight
    
    mid_point = ceil(win_size/2);
    output = zeros(size(signal));
    for idx=1:1:N
        if(idx<mid_point+1)
            w = wind(mid_point-idx+1:end)/sum(wind(mid_point-idx+1:end));
            s = signal(1:idx+mid_point-1,:);
        elseif(idx>N-mid_point)
            w = wind(1:mid_point+N-idx)/sum(wind(1:mid_point+N-idx));
            s = signal(idx-mid_point+1:end,:);
        else
            w = wind/sum(wind);
            s = signal(idx-win_size+mid_point:idx+win_size-mid_point,:);
        end
        w = repmat(w, 1, Nch);
        output(idx,:) = sum(s.*w);
    end
%     plot(output,':', 'LineWidth', 2)
        
%         output_start(cwl,:) = sum(signal(1:cwl+ss-1,:).*win(ss-cwl+1:end,:))/cwl;
%         output_end(ss-cwl,:) = sum(signal(N-ss-cwl+2:end,:).*win(1:ss+cwl-1,:))/cwl;
%         subaxis(2,1,1);
%         aat = 0:length(output_start)-cwl-1;
%         bbt = ss-cwl-2:length(output_end)-1;
%         aa = plot(aat, output_start(1:cwl),'rx');
%         bb = plot(bbt, output_end(ss-cwl),'rx');
%         subaxis(2,1,2)
%         plot([(0:cwl+ss-2)' (N-ss-cwl+1:N-1)'], [win(ss-cwl+1:end,:) win(1:ss+cwl-1,:)]);
%         axis tight
%         ginput(1)
%         delete(aa)
%         delete(bb)
%     end
%     output_mid = filter(win, 1, signal)/win_size; 
%     output_mid = output_mid(length(output_start)+1:end-length(output_end),:);
%     output = [output_start; zeros(size(output_mid)); output_end];
end