function varargout = advantech_gui(varargin)
% ADVANTECH_GUI MATLAB code for advantech_gui.fig
%      ADVANTECH_GUI, by itself, creates a new ADVANTECH_GUI or raises the existing
%      singleton*.
%
%      H = ADVANTECH_GUI returns the handle to a new ADVANTECH_GUI or the handle to
%      the existing singleton*.
%
%      ADVANTECH_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ADVANTECH_GUI.M with the given input arguments.
%
%      ADVANTECH_GUI('Property','Value',...) creates a new ADVANTECH_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before advantech_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to advantech_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help advantech_gui

% Last Modified by GUIDE v2.5 02-Dec-2015 23:05:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @advantech_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @advantech_gui_OutputFcn, ...
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
end

% --- Executes just before advantech_gui is made visible.
function advantech_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to advantech_gui (see VARARGIN)

% Choose default command line output for advantech_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes advantech_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

end

% --- Outputs from this function are returned to the command line.
function varargout = advantech_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

function checkbox_callback(cid, toggle)
    global fig_tseries;
    global fig_FullTS;
    global fig_spectrum;
    global channel_enabled;
    nch = length(channel_enabled);
    channel_enabled(cid) = toggle;
    for i=1:1:nch
        vis = 'off';
        if(channel_enabled(i)) 
            vis = 'on'; 
        end
        for j=1:1:3
            childs = fig_tseries(j).Children;
            if(length(childs)<i)
                continue;
            end
            if(~isempty(childs))
                childs(i).Visible = vis;
            end
            childs = fig_FullTS(j).Children;
            if(~isempty(childs))
                childs(i).Visible = vis;
            end
            childs = fig_spectrum(j).Children;
            if(~isempty(childs))
                childs(nch-i+1).Visible = vis;
            end
        end
    end
end

function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
    global Ns;
    global Fs;
    global fig_tseries;
    Ns = str2double(get(hObject,'String'));
    for i = 1:1:3
        c = mean(fig_tseries(i).XLim);
        fig_tseries(i).XLim = [c-Ns/Fs/2; c+Ns/Fs/2];
    end
end

% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    global Ns_field;
    Ns_field = hObject;
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1
checkbox_callback(1, get(hObject,'Value'));
end

% --- Executes on button press in checkbox2.
function checkbox2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox2
checkbox_callback(2, get(hObject,'Value'));
end

% --- Executes on button press in checkbox3.
function checkbox3_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox3
checkbox_callback(3, get(hObject,'Value'));
end

% --- Executes on button press in checkbox4.
function checkbox4_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox4
checkbox_callback(4, get(hObject,'Value'));
end

% --- Executes on button press in checkbox5.
function checkbox5_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox5
checkbox_callback(5, get(hObject,'Value'));
end

function set_colors(obj, id)
    global fig_tseries;
    obj.Value = 1;
    obj.BackgroundColor = fig_tseries(2).Children(id).Color;
    obj.String = fig_tseries(2).Children(id).DisplayName;
end

% --- Executes during object creation, after setting all properties.
function checkbox5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to checkbox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% set_colors(hObject, 5);
end


% --- Executes during object creation, after setting all properties.
function checkbox4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to checkbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% set_colors(hObject, 4);
end


% --- Executes during object creation, after setting all properties.
function checkbox3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to checkbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% set_colors(hObject, 3);
end


% --- Executes during object creation, after setting all properties.
function checkbox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set_colors(hObject, 2);
end

function checkbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set_colors(hObject, 1);
end
