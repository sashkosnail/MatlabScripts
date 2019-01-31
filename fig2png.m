global PathName
if((PathName == 0) | (~exist('PathName', 'var'))) %#ok<OR2>
	PathName = ''; end
[FileName, PathName, ~] = uigetfile([PathName, '\*.fig'],'Pick File','MultiSelect','on');
if(~iscell(FileName))
	FileName = {FileName}; end
if(FileName{1} == 0)
	return; 
end

for n=1:1:length(FileName)
	fn = [PathName FileName{n}];
	fig = open(fn);
	fig.Color = 'w';
	title(FileName{n}(1:end-4),'Interpreter','none');
	WindowAPI(fig, 'Maximize');
	export_fig([fn(1:end-4) '.png'], '-c[0 0 0 0]', fig);
	close(fig)
end