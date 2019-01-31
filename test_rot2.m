global TMP
Fs = 100;
data = TMP(70000:120000,:);
t=(0:1:(length(data)-1))/Fs;
fig=figure(51);clf
for n=1:1:3
	ax(n) = subplot(3,2,2*n-1);
	hold(ax(n), 'on');
	axm(n) = subplot(3,2,2*n);
	plot(ax(n),t, data(:,n),'-k')

	axis(ax(n), [0 500 -2 2]);
end
linkaxes(ax);
azs = 260:2:280;
mxs=zeros(length(azs),3);
ttt = [0 0 0; 0 1 0];
for k=1:1:length(azs)
	az=azs(k);
	rotM = [cosd(az) -sind(az) 0; sind(az) cosd(az) 0; 0 0 1];
	tmp = data*rotM';
	rttt = ttt*rotM';
	mxs(k,:) = rms(tmp);
	for n=1:1:3
		cla(axm(n))
		if(length(ax(n).Children)>1)
			delete(ax(n).Children(1));
		end
		plot(ax(n), t, tmp(:,n), '-r');
		plot(axm(n), azs, mxs(:,n))
		axis(ax(n), [0 500 -2 2]);
	end
	title(ax(1), num2str(az))
 	pause(0.5)
	figure(52)
	plot(rttt(:,1),rttt(:,2))
	axis([-1 1 -1 1])
drawnow
end