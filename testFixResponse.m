function testFixResponse_GUI()
	fig = figure(777);
	D1_slider = uicontrol('Parent', fig, 'Style', 'slider', ...
		'Units', 'pixels', 'Position', [400 20 120 20], ...
		'Callback', @slider, 'Min',1,'Max',50,'Value',41,'Tag',1);
	D2_slider = uicontrol('Parent', fig, 'Style', 'slider', ...
		'Units', 'pixels', 'Position', [400 20 120 20], ...
		'Callback', @slider, 'Min',1,'Max',50,'Value',41,'Tag',2);
	ax = axes;
	function slider(hObject, ed)
		s=tf('s');
		%sensor response
		w1 = 2*pi*4.5;
		Sensor_Response = s^2/(s^2+2*0.7*s*w1+w1^2);
		H_inv = 1/Sensor_Response;
		
		w_new = 2*pi*1;
		zeta1 = D1_slider.Value;
		H_newfreq = (s/w_new)^2/((s/w_new)^2+2*zeta1*s/w_new+1);
		
		w_hp = 2*pi*0.5;
		zeta2 = D2_slider.Value;
		H_highpass = (s/w_hp)^2/((s/w_hp)^2+2*zeta2*s/w_hp+1);
		
		H_total = H_inv*H_newfreq*H_highpass;
		
		p=bodeoptions;
		p.FreqUnits = 'Hz';
		p.Grid = 'on';
		cla(ax)
		bodeplot(ax, H_inv, p); hold on
		bodeplot(ax, H_newfreq, p)
		bodeplot(ax, H_highpass, p)
		bodeplot(ax, H_total, p)
		legend('H inv','H newfreq','H highpass','H total')
	end
end