
function varargout = program(varargin)
% PROGRAM MATLAB code for program.fig
%      PROGRAM, by itself, creates a new PROGRAM or raises the existing
%      singleton*.
%
%      H = PROGRAM returns the handle to a new PROGRAM or the handle to
%      the existing singleton*.
%
%      PROGRAM('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PROGRAM.M with the given input arguments.
%
%      PROGRAM('Property','Value',...) creates a new PROGRAM or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before program_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to program_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help program

% Last Modified by GUIDE v2.5 18-Dec-2016 14:03:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @program_OpeningFcn, ...
    'gui_OutputFcn',  @program_OutputFcn, ...
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

% --- Executes just before program is made visible.
function program_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);
end

% --- Outputs from this function are returned to the command line.
function varargout = program_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
end

% --- Executes on button press in fileDialog.
function fileDialog_Callback(hObject, eventdata, handles)
[fileName,pathName] = uigetfile({'*.mp4'; '*.mkv'; '*.avi'},'Select the video');
set(handles.filenameText, 'String', fileName);
setappdata(0, 'file_name', fileName);
setappdata(0, 'path_name', pathName);
videoSrc = vision.VideoFileReader(strcat(pathName, fileName));
[hFig, hAxes] = createFigureAndAxes();
insertButtons(hFig, hAxes, videoSrc);
end

% --- Executes on button press in proceedButton.
function proceedButton_Callback(hObject, eventdata, handles)
x = getappdata(0, 'file_name')
y = getappdata(0, 'path_name')
end

function log_Callback(hObject, eventdata, handles)
end

% --- Executes during object creation, after setting all properties.
function log_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function [hFig, hAxes] = createFigureAndAxes()

% Close figure opened by last run
figTag = 'CVST_VideoOnAxis_9804532';
close(findobj('tag',figTag));

% Create new figure
hFig = figure('numbertitle', 'off', ...
    'name', 'Video In Custom GUI', ...
    'menubar','none', ...
    'toolbar','none', ...
    'resize', 'on', ...
    'tag',figTag, ...
    'renderer','painters', ...
    'position',[680 678 480 240]);

% Create axes and titles
hAxes.axis1 = createPanelAxisTitle(hFig,[0.1 0.2 0.36 0.6],'Original Video'); % [X Y W H]
hAxes.axis2 = createPanelAxisTitle(hFig,[0.5 0.2 0.36 0.6],'Rotated Video');
end

function hAxis = createPanelAxisTitle(hFig, pos, axisTitle)

% Create panel
hPanel = uipanel('parent',hFig,'Position',pos,'Units','Normalized');

% Create axis
hAxis = axes('position',[0 0 1 1],'Parent',hPanel);
hAxis.XTick = [];
hAxis.YTick = [];
hAxis.XColor = [1 1 1];
hAxis.YColor = [1 1 1];
titlePos = [pos(1)+0.02 pos(2)+pos(3)+0.3 0.3 0.07];
uicontrol('style','text',...
    'String', axisTitle,...
    'Units','Normalized',...
    'Parent',hFig,'Position', titlePos,...
    'BackgroundColor',hFig.Color);
end

function insertButtons(hFig,hAxes,videoSrc)

% Play button with text Start/Pause/Continue
uicontrol(hFig,'unit','pixel','style','pushbutton','string','Start',...
    'position',[10 10 75 25], 'tag','PBButton123','callback',...
    {@playCallback,videoSrc,hAxes});

% Exit button with text Exit
uicontrol(hFig,'unit','pixel','style','pushbutton','string','Exit',...
    'position',[100 10 50 25],'callback', ...
    {@exitCallback,videoSrc,hFig});
end

function playCallback(hObject,~,videoSrc,hAxes)
try
    % Check the status of play button
    isTextStart = strcmp(hObject.String,'Start');
    isTextCont  = strcmp(hObject.String,'Continue');
    if isTextStart
        % Two cases: (1) starting first time, or (2) restarting
        % Start from first frame
        if isDone(videoSrc)
            reset(videoSrc);
        end
    end
    if (isTextStart || isTextCont)
        hObject.String = 'Pause';
    else
        hObject.String = 'Continue';
    end
    
    % Rotate input video frame and display original and rotated
    % frames on figure
    angle = 0;
    while strcmp(hObject.String, 'Pause') && ~isDone(videoSrc)
        % Get input video frame and rotated frame
        [frame,rotatedImg,angle] = getAndProcessFrame(videoSrc,angle);
        % Display input video frame on axis
        showFrameOnAxis(hAxes.axis1, frame);
        % Display rotated video frame on axis
        showFrameOnAxis(hAxes.axis2, rotatedImg);
    end
    
    % When video reaches the end of file, display "Start" on the
    % play button.
    if isDone(videoSrc)
        hObject.String = 'Start';
    end
catch ME
    % Re-throw error message if it is not related to invalid handle
    if ~strcmp(ME.identifier, 'MATLAB:class:InvalidHandle')
        rethrow(ME);
    end
end
end

function [frame,rotatedImg,angle] = getAndProcessFrame(videoSrc,angle)

% Read input video frame
frame = step(videoSrc);

% Pad and rotate input video frame
paddedFrame = padarray(frame, [30 30], 0, 'both');
rotatedImg  = imrotate(paddedFrame, angle, 'bilinear', 'crop');
angle       = angle + 1;
end

function exitCallback(~,~,videoSrc,hFig)

% Close the video file
release(videoSrc);
% Close the figure window
close(hFig);
end
