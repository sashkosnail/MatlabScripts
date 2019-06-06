data = [0.001	4.93826E-08
0.002	1.97529E-07
0.004	7.90102E-07
0.007	2.41955E-06
0.01	4.93742E-06
0.02	1.97394E-05
0.04	7.8794E-05
0.07	0.000239945
0.1	0.000485478
0.2	0.001851045
0.4	0.00633596
0.7	0.014724888
1	0.023353111
2	0.05114641
4	0.104534841
7	0.18196057
10	0.25593424
20	0.468345847
40	0.727535073
70	0.88033628
100	0.935658676
200	0.982678515
400	0.99558391
700	0.998551558
1000	0.999289477
];

out = [];
tstart = 0;
tend = 0;
Np = 10;
Os = 10;
for n=1:1:size(data,1)
	line = data(n,:);
	Fs = Os*line(1);
	tend = tstart + Np/line(1);
	t = (tstart:1/Fs:tend)';
	tt = t-tstart;
	out = [out; t t line(2)*sin(2*pi*line(1)*tt)];
	tstart = tend;
end

header = sprintf(['[Main]\n' ...
'FileType=USR\n' ...
'Version=2.00\n' ...
'Program=Micro-Cap\n' ...
'[Menu]\n' ...
'WaveformMenu=V\n' ...
'[Waveform]\n' ...
'Label=label vs T\n' ...
'MainX=T\n' ...
'LabelX=T\n' ...
'LabelY=label vs T\n' ...
'Format=Simple\n' ...
'Data Point Count=' num2str(length(out))]);

fid = fopen('signal.USR','w');
fprintf(fid, '%s\n', header);
fprintf(fid, '%10.5f, %10.5f, %10.5f\n', out');
fclose(fid);





