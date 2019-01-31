global HVSR

figure(193756);clf;

d=HVSR.Data{1}(:,:);
tp = subplot(1,2,1);
t=(0:1:length(d)-1)/HVSR.Fs;
plot(t,d); hold on

subplot(1,2,2)
plot3(d(:,1),d(:,2),d(:,3));
xlabel('X')
ylabel('Y')
zlabel('Z')
axis equal

l=[];
lines=[];
while 1
	[x, y, b] = ginput(1);
	switch b
		case 1
			l(1) = x;
		case 2
			break;
		case 3
			l(2) = x;
	end
	if(~isempty(lines))
		delete(lines)
	end
	if(length(l)<2)
		continue;
	end
	l=sort(l);
	subplot(1,2,1);
	lines = plot([l; l], [2 -2]);
	subplot(1,2,2); cla
	idx = ceil(l(1)*HVSR.Fs):1:floor(l(2)*HVSR.Fs);
	plot3(d(idx,1),d(idx,2),d(idx,3));
	hold on
	p=polyfit(d(idx,1),d(idx,2),1);
	tmp = [min(d(idx,1)) max(d(idx,1))];
	plot3(tmp, polyval(p,tmp), zeros(size(tmp)),'r')
	
	xlabel('X')
	ylabel('Y')
	zlabel('Z')
	axis(0.2*[-1 1 -1 1 -1 1]);
	title(num2str(90-atand(p(1))))
	view(2)
end