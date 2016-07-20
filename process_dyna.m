[FileName, PathName, ~] = uigetfile('*.txt','Pick File');
filename = strcat(PathName, FileName);

response = readtable(strcat(PathName, 'response.txt'), 'Headerlines', 1, 'Delimiter', '\t');
fileID = fopen(strcat(PathName, 'response.txt'));
fgetl(fileID);
response_col_names = strsplit(fgetl(fileID), '\t');
fclose(fileID);

stiffness = readtable(strcat(PathName, 'stiffness.txt'), 'Headerlines', 1, 'Delimiter', '\t');
fileID = fopen(strcat(PathName, 'stiffness.txt'));
fgetl(fileID);
stiffness_col_names = strsplit(fgetl(fileID), '\t');
fclose(fileID);

fig=figure(1);
[hax, sline, dline] = plotyy(response{:,1}, response{:,2:4}, response{:,1}, response{:,5:end-1});
for l = 1:1:length(dline)
    dline(l).LineStyle = '--';
    dline(l).LineWidth = 0.75;
    sline(l).LineWidth = 0.75;
end
grid minor
legend('CG - X', 'CG - Y', 'CG - Z', ...
    'CG-Rot-X', 'CG-Rot-Y', 'CG-Rot-Z')
set(hax(1), 'YMinorTick', 'on');
ylabel(hax(1), 'Translation[m]')
ylabel(hax(2), 'Rotation[Rad]')
xlabel('Frequency[rad/s]')
print(fig, strcat(PathName, 'Translation.png'), '-dpng', '-r0');

fig = figure(2);
[hax, sline, dline] = plotyy(stiffness{:,1}, stiffness{:,2:2:6}, ...
    stiffness{:,1}, stiffness{:,3:2:7});
for l = 1:1:length(dline)
    dline(l).LineStyle = '--';
    dline(l).LineWidth = 0.75;
    sline(l).LineWidth = 0.75;
end
grid minor
legend('X Stiffness', 'Y Stiffness', 'Z Stiffness', ...
    'X Damping', 'Y Damping', 'Z Damping')
xlabel('Frequency[rad/s]')
ylabel(hax(1), 'Stiffness[N/m]')
ylabel(hax(2), 'Damping[N/m/s]')
print(fig, strcat(PathName, 'XYZ.png'), '-dpng', '-r0');

fig = figure(3);
[hax, sline, dline] = plotyy(stiffness{:,1}, stiffness{:,8:2:end-1}, ...
    stiffness{:,1}, stiffness{:,9:2:end-1});
for l = 1:1:length(dline)
    dline(l).LineStyle = '--';
    dline(l).LineWidth = 0.75;
    sline(l).LineWidth = 0.75;
end
grid minor
legend('X Rocking', 'Y Rocking', 'Z Torision', ...
    'X Rocking Damping', 'Y Rocking Damping', 'Z Torsional Damping')
xlabel('Frequency[rad/s]')
ylabel(hax(1), 'Stiffness[Nm/rad]')
ylabel(hax(2), 'Damping[Nm/rad/s]')
print(fig, strcat(PathName, 'Rot.png'), '-dpng', '-r0');

resp = [resp;response{response{:,1}==380, :}];
stif = [stif; stiffness{stiffness{:,1}==380 ,:}];