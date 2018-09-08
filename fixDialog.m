function choice = fixDialog(targetFc)
    d = dialog('Units', 'normalized', 'Position', [0.4 0.4 0.1 0.1], ...
        'Name', 'Sensor Correction');
    d.Units = 'pixels';
    d.Position(3:4) = [375 100];
    
    uicontrol('Parent', d, 'Style', 'text', 'Position', [20 50 335 40], ...
        'String', ['Correct sensor reponse to ' num2str(targetFc) 'Hz?'], ...
        'FontSize', 14);
    
    start_position = [20 20];
    next_size = [80 30];
    uicontrol('Parent', d, 'Position', [start_position next_size], ...
        'Callback', @makechoice, 'String', 'Yes');
    start_position(1) = start_position(1) + next_size(1) + 5;
    next_size = [80 30];
    uicontrol('Parent', d, 'Position', [start_position next_size], ...
        'Callback', @makechoice, 'String', 'Yes to All');
    start_position(1) = start_position(1) + next_size(1) + 5;
    next_size = [80 30];
    uicontrol('Parent', d, 'Position', [start_position next_size], ...
        'Callback', @makechoice, 'String', 'No to All');
    start_position(1) = start_position(1) + next_size(1) + 5;
    next_size = [80 30];
    uicontrol('Parent', d, 'Position', [start_position next_size], ...
        'Callback', @makechoice, 'Tag', 'No', 'String', 'No');
    uiwait(d);
    function makechoice(button, ~)
        choice = button.String;
        delete(button.Parent);
    end
end