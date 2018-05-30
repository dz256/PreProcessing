function varargout = TTankInterfacesExample(varargin)
% TTANKINTERFACESEXAMPLE M-file for TTankInterfacesExample.fig
%      TTANKINTERFACESEXAMPLE, by itself, creates a new TTANKINTERFACESEXAMPLE or raises the existing
%      singleton*.
%
%      H = TTANKINTERFACESEXAMPLE returns the handle to a new TTANKINTERFACESEXAMPLE or the handle to
%      the existing singleton*.
%
%      TTANKINTERFACESEXAMPLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TTANKINTERFACESEXAMPLE.M with the given input arguments.
%
%      TTANKINTERFACESEXAMPLE('Property','Value',...) creates a new TTANKINTERFACESEXAMPLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TTankInterfacesExample_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TTankInterfacesExample_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TTankInterfacesExample

% Last Modified by GUIDE v2.5 04-Dec-2012 09:15:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TTankInterfacesExample_OpeningFcn, ...
                   'gui_OutputFcn',  @TTankInterfacesExample_OutputFcn, ...
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


% --- Executes just before TTankInterfacesExample is made visible.
function TTankInterfacesExample_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TTankInterfacesExample (see VARARGIN)

% Choose default command line output for TTankInterfacesExample
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TTankInterfacesExample wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = TTankInterfacesExample_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

global CurrentServer;
global CurrentTank;
global CurrentBlock;
global CurrentEvent;
CurrentServer = handles.activex1.ActiveServer;
CurrentTank = handles.activex2.ActiveTank;
CurrentBlock = handles.activex3.ActiveBlock;
CurrentEvent = handles.activex4.ActiveEvent;


% --------------------------------------------------------------------
function activex1_ServerChanged(hObject, eventdata, handles)
% hObject    handle to activex1 (see GCBO)
% eventdata  structure with parameters passed to COM event listener
% handles    structure with handles and user data (see GUIDATA)

% Process Server selection information for TTankInterfaces.TankSelect
handles.activex2.UseServer = eventdata.NewServer;
handles.activex2.Refresh;
global CurrentServer;
CurrentServer = eventdata.NewServer;

% --------------------------------------------------------------------
function activex2_TankChanged(hObject, eventdata, handles)
% hObject    handle to activex2 (see GCBO)
% eventdata  structure with parameters passed to COM event listener
% handles    structure with handles and user data (see GUIDATA)

% Process Server and Tank selection information for TTankInterfaces.BlockSelect
handles.activex3.UseServer = eventdata.ActServer;
handles.activex3.UseTank = eventdata.ActTank;

% Deselects the previously selected Block if the current Tank is changed
handles.activex3.ActiveBlock = '';
handles.activex3.Refresh;

% Deselects the previously selected Event and clears the event list if the current Tank is changed
handles.activex4.UseBlock = '';
handles.activex4.ActiveEvent = '';
handles.activex4.Refresh;

global CurrentTank;
CurrentTank = eventdata.ActTank;

% --------------------------------------------------------------------
function activex3_BlockChanged(hObject, eventdata, handles)
% hObject    handle to activex3 (see GCBO)
% eventdata  structure with parameters passed to COM event listener
% handles    structure with handles and user data (see GUIDATA)
% Process Server, Tank, and Block selection information for TTankInterfaces.EventSelect
handles.activex4.UseServer = eventdata.ActServer;
handles.activex4.UseTank = eventdata.ActTank;
handles.activex4.UseBlock = eventdata.ActBlock;

% Deselects the previously selected Event if the current Block is changed
handles.activex4.ActiveEvent = '';
handles.activex4.Refresh;
global CurrentBlock;
CurrentBlock = eventdata.ActBlock;


% --------------------------------------------------------------------
function activex4_ActEventChanged(hObject, eventdata, handles)
% hObject    handle to activex4 (see GCBO)
% eventdata  structure with parameters passed to COM event listener
% handles    structure with handles and user data (see GUIDATA)

% Process Event Selection and refresh
global CurrentEvent;
CurrentEvent = eventdata.NewActEvent;
handles.activex4.Refresh;

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% This calls the RunAnalysis function in RunAnalysis.m
RunAnalysis;