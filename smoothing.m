function varargout = smoothing(varargin)
% SMOOTHING MATLAB code for smoothing.fig
%      SMOOTHING, by itself, creates a new SMOOTHING or raises the existing
%      singleton*.
%
%      H = SMOOTHING returns the handle to a new SMOOTHING or the handle to
%      the existing singleton*.
%
%      SMOOTHING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SMOOTHING.M with the given input arguments.
%
%      SMOOTHING('Property','Value',...) creates a new SMOOTHING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before smoothing_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to smoothing_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help smoothing

% Last Modified by GUIDE v2.5 03-May-2018 11:37:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @smoothing_OpeningFcn, ...
                   'gui_OutputFcn',  @smoothing_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before smoothing is made visible.
function smoothing_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to smoothing (see VARARGIN)

% Choose default command line output for smoothing
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes smoothing wait for user response (see UIRESUME)
% uiwait(handles.figure1);

slider3_Callback(hObject, eventdata, handles);


% --- Outputs from this function are returned to the command line.
function varargout = smoothing_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function slider3_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

b = get(handles.slider3,'Value');
b = round(b);
handles.slider3.Value = b;
handles.text2.String = num2str(b);

D = str2double(handles.edit1.String);
Fs = 1000;
freq = 0.01:0.05:Fs/2;
f0s = 2.^(-1:1:6);

axes(handles.axes1); cla;
for i = 1:1:length(f0s)
    f0 = f0s(i);
    func = spec_smooth(freq,f0,b,D);
    loglog(freq,func,'LineWidth',2);hold on
end
ylim([0.0001 1]);xlim([0.1 Fs/2])
grid on

% --- Executes during object creation, after setting all properties.
function slider3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
slider3_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
