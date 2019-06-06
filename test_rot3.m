function test_rot3()
global TMP
	Fs = 100;
% 	data = TMP(70000:120000,:);
data = TMP;
	t=(0:1:(length(data)-1))/Fs;
	
	fig = figure(999);clf
	slider = uicontrol('Parent', fig, 'Style', 'slider', ...
		'Min', 0, 'Max', 360, 'Value', 270, 'units', 'normalized', ...
		'Position', [0.01 0.01 0.98 0.01], 'SliderStep', [1/360 1/36]);
	addlistener(slider, 'Value', 'PostSet', @slider_move);
	for n=1:1:3
		ax(n) = subplot(3,1,n);
		hold(ax(n), 'on');
		plot(ax(n),t, data(:,n),'-k')
		grid on
% 		axis(ax(n), [0 500 -2 2]);
	end
	linkaxes(ax);
	slider_move()

	function slider_move(~, ~)
		az=slider.Value;
		rotM = [cosd(az) -sind(az) 0; sind(az) cosd(az) 0; 0 0 1];
		tmp = data*rotM';
		for n=1:1:3
			if(length(ax(n).Children)>1)
				delete(ax(n).Children(1));
			end
			plot(ax(n), t, tmp(:,n), '-r');
% 			axis(ax(n), [0 500 -2 2]);
		end
		title(ax(1), num2str(az))
	end
end