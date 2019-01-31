figure(1245);clf
pwr= [] ;
mabs = [];

station = [43.964310, -79.071430]; %PKRO
event = [44.677, -80.482]; %2005

station = [44.243720, -81.442250]; %BRCO
event = [43.672, -78.232]; %2004

station = [43.923560, -78.396990]; %WLVO

global HVSR
data = HVSR.Data{1}(:,1:2);
t=(0:1:length(data)-1)/HVSR.Fs;
% data = rand(1000, 1)*0.3-0.15;
% t=(0:1:length(data)-1)./100;
% data = data + sin(2*pi*t)';
% data = [data zeros(size(data))];

az = azimuth(station, event);
rotM = [cosd(az) -sind(az); sind(az) cosd(az)];
% data=[-data*sind(az) data*cosd(az)];
% data = data*rotM;

subplot(3,2,2)
plot(t, data)
legend('E','N');
ylim(2*[-1 1])
axis([100 160 -1.2 1.2])

points = [1 1]'*station + [0 0.5; 0.5 0];
tmp = [points(1,:); station; points(2,:)];

subplot(3,2,[1,3]);
mapshow(tmp(:,2), tmp(:,1), 'Color', 'k', 'LineStyle', '-')
hold on
mapshow(points(2,2), points(2,1), 'DisplayType', 'point');
mapshow(event(:,2),event(:,1),'DisplayType','point', 'Color','black')

rpoints = [1 1]'*station + [0 0.5; 0.5 0]*rotM';
tmp = [rpoints(1,:); station; rpoints(2,:)];
% data = data*rotM;

mapshow(tmp(:,2), tmp(:,1), 'Color', 'g', 'LineStyle', '-');
mapshow(rpoints(2,2), rpoints(2,1), 'DisplayType', 'point');
axis([-81 -76 42 45]);
title(num2str(az));
g=[];

for baz=az:90:az+360
	rotM = [cosd(baz) -sind(baz); sind(baz) cosd(baz)];
	tmp = data*rotM';
	rpoints = [1 1]'*station + [0 0.5; 0.5 0]*rotM';
	
	pwr=[pwr; rms(tmp(:,1:2))]; %#ok<*AGROW>
	mabs = [mabs; max(abs(tmp(:,1:2)))];
	
	a1=subplot(3,2,4); cla
	plot(t, tmp(:,1));
% 	legend('T');
	title(['T' num2str(baz)])
	ylim(1.2*[-2 2])
	axis([100 160 -2 2])
	a2=subplot(3,2,6); cla
	plot(t, tmp(:,2));
% 	legend('R');
	title(['R' num2str(baz)])
	ylim(1.2*[-1 1])
	axis([100 160 -2 2])
	
	if(~isempty(g))
		delete(g)
	end
	tmp = [station; rpoints(2,:)];
	subplot(3,2,[1, 3]);
	g = mapshow(tmp(:,2), tmp(:,1), 'Color', 'b', 'LineStyle', '-');
	
	drawnow()
	ginput(1)
% 	pause(0.003);
end
linkaxes([a1,a2]);
subplot(3, 2, 5)
plot(0:1:360, pwr);

