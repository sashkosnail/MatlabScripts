function [time_series, dt, npts] = readPEER(varargin)
%% This program is used to read ground motion data from PEER database

%% Written by

%% GOPI

%% Input

% varargin(1) - filefolder - where peer ground motion data file is located 
% varargin(1) - filefolder- example - 'D:/Thesis/extra' (with quotes)

% varargin(2) - file_name - name of the file along with the extension
% varargin(2) - file_name - example - 'RSN982_NORTHR_JEN022.AT2' (with quotes)

%% Example input
% [time_series, dt, npts] = readPEER('C:\Users\IIT\Google Drive\Thesis\Northridge', 'RSN982_NORTHR_JEN022');

%% Output

% time_series - vector of any quantity 
% time_series - (be it acceleration or velocity or displacement)
% ACCELERATION TIME SERIES IN UNITS OF g (9.81)
% VELOCITY TIME SERIES IN UNITS OF cm/sec
% DISPLACEMENT TIME SERIES IN UNITS OF cm

% dt - sampling time in seconds
% npts - no of sampling point in the time_series (length of time_series)

%% Program starts from here

if isempty(varargin) == 1
    
    [file_name, filefolder] = uigetfile({'*', 'File Selector'});
    
else
    
    filefolder = varargin{1};
    file_name = varargin{2};
    
end

fid = fopen([filefolder '/' file_name], 'r');
datacell = textscan(fid, '%f%f%f%f%f', 'Delimiter', ',', 'Headerlines', 4, 'CollectOutput', 1) ;
fclose(fid);

a = datacell{1};
a = a';
a = a(:);
a(isnan(a)) = [];
time_series = a;

fid = fopen([filefolder '/' file_name], 'r');
data_2 = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);

time_data = data_2{1};
numbers = sscanf(char(time_data(4)), 'NPTS=   %f, DT=   %f SEC');
dt = numbers(2);
npts = numbers(1);



end
