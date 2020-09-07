function tesstConeCompensation_CIA()
	cone_angle = 30;
	tilt_angle = 0;
	radius = 120;
	coneHeight = 160;
	elevation = 0;
	
	cone_line = 0;
	tilt_line = 0;

	fig1 = figure(111);clf
	
	start_position = [10 10];
    next_size = [100 35];
	coneAngleEdit = uicontrol('Style','edit', 'Parent', fig1, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(cone_angle));
	start_position(1) = start_position(1) + next_size(1) + 50;
	tiltAngleEdit = uicontrol('Style','edit', 'Parent', fig1, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(tilt_angle));
	elevationEdit = uicontrol('Style','edit', 'Parent', fig1, ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(elevation));
		
	start_position = [10 50];
    next_size = [35 400];
	tiltSlider = uicontrol('Style','slider', 'Parent', fig1, ...
		'Min', 0, 'Max', 89, 'SliderStep', [0.0333 0.1667], ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(tilt_angle));
	start_position(1) = start_position(1) + next_size(1) + 10;
	elevSlider = uicontrol('Style','slider', 'Parent', fig1, ...
		'Min', -coneHeight/2, 'Max', coneHeight/4, 'SliderStep', [0.0333 0.1667], ...
		'Units', 'pixels', 'Position', [start_position next_size], ...
		'Callback', @value_change, 'UserData', 1, ...
		'String', num2str(tilt_angle));
		
	ax1 = axes('Parent', fig1);
	axis([-radius radius -coneHeight coneHeight/2]);
	grid on; hold on;
	value_change(tiltSlider);
	
	function value_change(sender, ~)
		if(sender == tiltAngleEdit)
			tiltSlider.Value = str2double(sender.String);
		elseif(sender == elevationEdit)
			elevSlider.Value = str2double(sender.String);
		else
			elevationEdit.String = num2str(elevSlider.Value);
			tiltAngleEdit.String = num2str(tiltSlider.Value);
		end
		beta = deg2rad(str2double(coneAngleEdit.String));
		alpha = deg2rad(tiltSlider.Value);
		h = elevSlider.Value;
		x=-radius:1:0;
		cone_slope = -(x+radius)*cot(beta);
		lov_slope = h+x*tan(alpha);
		
		a=radius*tan(alpha);
		d=(a-h)/(1+tan(alpha)*tan(beta));
		b=d*tan(beta);
		
		cla(ax1)
		axis([-radius radius -coneHeight coneHeight/2]);
		grid on; hold on;
		plot(ax1, 0, h, 'gd');
		plot(ax1, x, cone_slope,'k');
		plot(ax1, x, lov_slope, 'k-');
		plot(ax1, -radius+b, -d, 'ro');
	end
end