figure(99); clf
t = D(:,1);
data = D(:,2:end);
DATA = struct();
DATA.X = data(:,1:3:end);
DATA.Y = data(:,2:3:end);
[DATA.Theta, DATA.Rho, DATA.Vert] = ...
    cart2pol(data(:,1:3:end), data(:,2:3:end), data(:,3:3:end));
for idx = 0:1:7
%     plots(idx, 1) = subaxis(8,8,1,idx, 1 , 1, 'SH', 0, 'SV', 0.025, 'P', 0, 'ML', 0);
%     plots(idx, 2) = subaxis(8,8,2,idx, 7, 1, 'S', 0.025, 'P', 0, 'MR', 0);
    hpol = subplot('Position',[0.01,.125*idx,0.10,0.12]);
    plots(8-idx,1) = animatedline(); %#ok<*SAGROW>
    axis([-10 10 -10 10]);
    hvert = subplot('Position',[0.15,.125*idx,0.75,0.12], ...
        'Xgrid','on','Ygrid','on');
    plots(8-idx,2) = animatedline('Color', 'k','LineWidth',1);
    axis([t(1) t(end) -10 10]);
end
step_size = 2;%length(t)-1;
for tt = step_size+1:step_size:length(t)
    for idx = 1:1:8
        addpoints(plots(idx,1), DATA.X(tt-step_size:tt,idx), DATA.Y(tt-step_size:tt,idx))
        addpoints(plots(idx,2), t(tt-step_size:tt), DATA.Vert(tt-step_size:tt,idx))
    end
    drawnow limitrate
end