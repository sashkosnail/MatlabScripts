% a=kml2struct('Wimont_Best_HVSR_Points.kml');
% b=sortkml(a);
clear
load('profile_layout2.mat')
points_mat = [points(:).Lat; points(:).Lon; points(:).Altitude]';
% points_mat = points_mat(end:-1:1,:);
% rock_drift(:,1) = max(rock_drift(:,1))-rock_drift(:,1);
% rock_drift = sortrows(rock_drift, 1);
% DEM(:,1) = max(DEM(:,1))-DEM(:,1);
% DEM = sortrows(DEM);
x = rock_drift(:,1);
r = rock_drift(:,3);
d = rock_drift(:,2);
dist=distance(repmat(points_mat(north_point,1:2),length(points_mat),1),points_mat(:,1:2));
[dist, ix] = sort(dist);
dist = dist*x(end)/dist(end);
points_by_distance = points(ix);
tmp_names = arrayfun(@(x) ['H' x.Name(5:end)], points_by_distance, 'UniformOutput', 0);
% tmp_names = arrayfun(@(x) ['WN' x.Name(end)], points_by_distance, 'UniformOutput', 0);
DEM(:,1) = DEM(:,1)*x(end)/DEM(end,1);
point_altitude = interp1(DEM(:,1), DEM(:,2), dist);

fig=figure(666);clf
set(fig,'color','w');
% subaxis(1,1,1,'ML',0.03,'MB',0.05,'MT',0.02)

profile(1) = patch([x; x(end); 0], [r; 0; 0],[53 42 134]/255); hold on
profile(2) = patch([x; x(end:-1:1);], [r+d;r(end:-1:1)],[248 250 15]/255);
% hatchfill(profile(1),'cross',-30,5,[53 42 134]/255);
% hatchfill(profile(2),'single',45,5,[248 250 15]/255);
h(1) = hatchfill(profile(1),'cross',-30,5);
h(1).Color = [53 42 134]/255;
h(2) = hatchfill(profile(2),'single',45,5);
h(2).Color = [200 200 50]/255;

plot(dist, point_altitude,'Marker', 'd', 'MarkerSize', 10, ...
	'MarkerFaceColor', 'r', 'LineStyle', 'none');
% plot(dist, points_mat(:,3),'sg--', 'LineWidth', 1);
plot(DEM(:,1), DEM(:,2),'k-', 'LineWidth', 2)
text(dist'+0.2*(-1).^(1:length(dist)), ...
    point_altitude'+4*(-1).^(1:length(dist)), ...
	cellstr(tmp_names), ...
	'HorizontalAlignment','center')
%     {points_by_distance(:).Name},...

grid on; grid minor
xlim([0 max(x)]);
title(line_title)
xlabel(sprintf('Distance From %s [km]',points(north_point).Name));
ylabel('Altitude [masl]');
