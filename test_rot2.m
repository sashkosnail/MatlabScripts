data = [1 0; 0 1; -1 0; 0 -1];
figure(7777); clf
plot(data(:,1), data(:,2),'x'); hold on
for az=0:2:360
	rotM = [cosd(az) -sind(az); sind(az) cosd(az)];
	Rdata = data*rotM';
	plot(Rdata(:,1),Rdata(:,2),'x')
end