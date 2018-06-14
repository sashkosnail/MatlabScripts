%% Save Data
print(fig, strcat(xls_file(1:end-5), '.png'), '-dpng', '-r0');
writetable(summaryT, xls_file, 'Sheet', 'Averages', 'Range', 'A2');
writetable(cdrT, xls_file, 'Sheet', 'CDR', 'Range', 'A2');
writetable(fitT, xls_file, 'Sheet', 'Details', 'Range', 'K1');

% writetable(summaryT, strcat(xlsfile(1:lis),'summary.csv'));
% writetable(cdrT, strcat(xlsfile(1:lis),'cdr.csv'));
% writetable(fitT, strcat(xlsfile(1:lis),'out.csv'));

save(strcat(xls_file(1:end-5), '.mat'));
disp('DONE');