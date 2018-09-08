function myui
f = figure('Visible','off','SizeChangedFcn',@sbar); 
u = uicontrol('Style','edit','Tag','StatusBar');
f.Visible = 'on';
    function sbar(src,callbackdata)
       old_units = src.Units;
       src.Units = 'pixels';
       sbar_units = u.Units;
       u.Units = 'pixels';
       fpos = src.Position;
       upos = [1 fpos(4) - 20 fpos(3) 20];
       u.Position = upos;
       u.Units = sbar_units;
       src.Units = old_units;
       u.Visible = 'on';
    end
end