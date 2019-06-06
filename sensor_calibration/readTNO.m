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
		new_table = [new_table; data_vals];
	end
end

fclose(fid);
disp(count)
combined_output = [new_table(:,1) combined_output new_table(:,2:end)];
%%
e=num2cell(2:.1:4);
upm = combined_output(:,2:2:end);
u1 = combined_output(:,3:2:end);
ratio = u1./upm;

lnames = cellfun(@(x) strcat({'u1_e'; 'upm_e'}, num2str(x)), e, ...
	'UniformOutput', 0);
lnames = vertcat(lnames{:});

subplot(2,2,[1 2])
plot(combined_output(:,1), combined_output(:,2:end));
axis tight; xlabel('Time[s]');
subplot(2,2,3)
plot(combined_output(:,1), ratio)
axis tight; xlabel('Time[s]');
title('U1 / U+-')
legend(cellfun(@(x) strcat('e=', num2str(x)), e, 'UniformOutput', 0));
subplot(2,2,4)
plot(cell2mat(e), mean(ratio(90:384,:)));
axis tight; xlabel('e[V]')
title('Mean U1/U+-');