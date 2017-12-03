% a=kml2struct('Wimont_Best_HVSR_Points.kml');
% b=sortkml(a);
load('profile_layout.mat')
points = [b(:).Lat; b(:).Lon]';
dd=distance(repmat(points(1,:),length(points),1),points);
[dd, ix] = sort(dd);
dist = dd*x(end)/dd(end);
points_by_distance = b(ix);
point_altitude = interp1(ele(:,1), ele(:,2), dist);
figure(555);clf
subaxis(1,1,1,'ML',0.03,'MB',0.05,'MT',0.02)
profile(1) = patch([x; x(end); 0], [r; 0; 0],[53 42 134]/255); hold on
profile(2) = patch([x; x(end:-1:1);], [r+d;r(end:-1:1)],[248 250 15]/255);
% hatchfill(profile(1),'cross',-30,5,[53 42 134]/255);
% hatchfill(profile(2),'single',45,5,[248 250 15]/255);
h(1) = hatchfill(profile(1),'cross',-30,5);
h(1).Color = [53 42 134]/255;
h(2) = hatchfill(profile(2),'single',45,5);
h(2).Color = [200 200 50]/255;

a=plot(dist, point_altitude,'sk--', 'LineWidth', 1);
plot(ele(:,1)*11.65/ele(end,1), ele(:,2),'k-', 'LineWidth', 1)
text(dist'+0.2*(-1).^(1:length(dd)), ...
    point_altitude'+4*(-1).^(1:length(dd)), ...
    {points_by_distance(:).Name},'HorizontalAlignment','center')

grid on; grid minor
axis([0 max(x) 100 400]);
title(t)
xlabel('Distance From W17N [km]');
ylabel('Altitude [masl]');
