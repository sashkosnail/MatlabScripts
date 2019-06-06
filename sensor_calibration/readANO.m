[FileName, PathName, ~] = uigetfile([PathName, '*.ano'], ...
	'Pick File','MultiSelect','off');
if(FileName == 0)
	return; 
end

combined_output = [];
new_table = [];
count = 0;

fid = fopen([PathName FileName],'r');
while(~feof(fid))
	data_line = fgetl(fid);
	if(data_line==-1)
		break;
	elseif(isempty(data_line))
		continue;
	elseif(strcmp(data_line,'Waveform Values'))
		combined_output = [combined_output new_table(:,2:end)]; %#ok<*AGROW>
		new_table = []; count = count+1;
		fgetl(fid);fgetl(fid);fgetl(fid);
	elseif(data_line(1) == ' ')
		data_vals = sscanf(data_line,'%g')';
		data_vals(2:4) = 10.^(data_vals(2:4)/20.00);
		dvtab = data_vals(1);
		for n=2:1:(length(data_vals)+1)/2
			dvtab = [dvtab data_vals(:,n:3:end)];
		end
		new_table = [new_table; dvtab];
	end
end

fclose(fid);
disp(count)
combined_output = [new_table(:,1) combined_output new_table(:,2:end)];
%%
f=combined_output(:,1);
A = combined_output(:,2:2:end);
p = combined_output(:,3:2:end);
tmp = [1 2 4 5 7 8 9];
A = A(:,tmp);
p = p(:,tmp);

figure(888);
subplot(2,1,1)
h=loglog(f, A, 'Linewidth', 2);
h(end).LineStyle = '--';
legend('e','u1','u2','u3','u4','u5','u6')
xlim([0.1 1000])
ylim([1e-3, 10])
subplot(2,1,2)
semilogx(f, p, 'LineWidth', 2);
legend('e','u1','u2','u3','u4','u5','u6')
xlim([0.1 1000])

%%
tA = array2table([f, A], ...
	'VariableNames', {'f','e','u1','u2','u3','u4','u5','u6'});
tp = array2table([f, p], ...
	'VariableNames', {'f','e','u1','u2','u3','u4','u5','u6'});

writetable(tA, [PathName 'ano_out.xlsx'], 'Range', 'A1');
writetable(tp, [PathName 'ano_out.xlsx'], 'Range', 'I1');