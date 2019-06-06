function plot3comp(data, x)
figure(888); clf
	for n=1:1:3
		subplot(3,1,n)
		semilogx(x,data(:,n),'-k');
	end
end