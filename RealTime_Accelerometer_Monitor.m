function varargout = RealTime_Accelerometer_Monitor(varargin)

% Plots data (Time Domain and Frequency Domain) given by an accelerometer sensor.
% Also creates a log of the data every 2 minutes or when active connection
% is terminated.


% Mapua Institute of Technology
% School of Electrical, Electronics and Computer Engineering

%To do:
% - Log File creation should be in another thread to avoid disrupting the
%   periodic timer.
% - Every 6 minutes, clear all data to avoid memory overload since the data
%   is already stored in the log file.
% - Increase sampling rate without lag. Possible solution is to run the
%   function MainUpdate in a separate thread via MEX.
% - The nodeName must come from the sensors upon clicking the BTNConnect
% - Improve the GUI Design.

% Last Modified by GUIDE v2.5 17-Feb-2016 20:06:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RealTime_Accelerometer_Monitor_OpeningFcn, ...
                   'gui_OutputFcn',  @RealTime_Accelerometer_Monitor_OutputFcn, ...
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


% --- Executes just before RealTime_Accelerometer_Monitor is made visible.
function RealTime_Accelerometer_Monitor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RealTime_Accelerometer_Monitor (see VARARGIN)
global t;
global plotType;
global pausePlot;
global timeFrame;
global clockDisplay;
timeFrame = 0;
% Choose default command line output for RealTime_Accelerometer_Monitor
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes RealTime_Accelerometer_Monitor wait for user response (see UIRESUME)
% uiwait(handles.mainFigure);

%Timer Initialization
t = timer;
t.Period = 0.01;
t.plotCtr = 20;  %Every 20 period timeouts, update the plot
t.TimerFcn = {@MainUpdate,hObject,handles};
t.ExecutionMode = 'fixedRate';
%GUI Handles Initial Properties
set(handles.xPlot_axes,'xtick',[],'ytick',[]);
set(handles.yPlot_axes,'xtick',[],'ytick',[]);
set(handles.zPlot_axes,'xtick',[],'ytick',[]);
set(handles.BTNDisconnect, 'Visible', 'off');
set(handles.BTNResumePlot, 'Visible', 'off');
set(handles.BTNPausePlot, 'Visible', 'off');
set(handles.BTNTimePlot, 'Visible', 'off');
set(handles.BTNFreqPlot, 'Visible', 'off');
set(handles.BTNTimeFrame, 'Visible', 'off');
set(handles.STTimeFrame, 'Visible', 'off');
set(handles.timeFrame, 'Visible', 'off');
%Initial plotting properties
plotType = 0;
pausePlot = 0;
clockDisplay = uicontrol(handles.mainFigure, 'Style', 'Text',...
                        'String', datestr(now, 'dd-mmm-yyyy HH:MM:SS.FFF'),...
                        'Position', [775 600 120 40],...
                        'FontSize', 13);
set(clockDisplay, 'Visible', 'off');

% --- Outputs from this function are returned to the command line.
function varargout = RealTime_Accelerometer_Monitor_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function serialPort_Callback(hObject, eventdata, handles)
% hObject    handle to serialPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of serialPort as text
%        str2double(get(hObject,'String')) returns contents of serialPort as a double


% --- Executes during object creation, after setting all properties.
function serialPort_CreateFcn(hObject, eventdata, handles)
% hObject    handle to serialPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function timeFrame_Callback(hObject, eventdata, handles)
% hObject    handle to timeFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timeFrame as text
%        str2double(get(hObject,'String')) returns contents of timeFrame as a double


% --- Executes during object creation, after setting all properties.
function timeFrame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function MainUpdate(obj,event,hObject,handles)
% System Core
global xData;
global yData;
global zData;
global index;
global time;
global plotType;   %0 for time domain, 1 for freq domain
global pausePlot;
global t;
global lastLog;     %index at time of when the last data logging.
global lastLogMinute;
global timeFrame;
global nodeName;
global clockDisplay;
global s;

current = now;
time = [time current];
sec = second(current);
%********************* OBTAINING DATA ***********************
while (s.BytesAvailable >= 12)
    dataString = fscanf(s);
    xyzData = regexp(dataString, ',', 'split');
    newX = str2double(xyzData(1));
    newY = str2double(xyzData(2));
    newZ = str2double(xyzData(3));
    xData = [xData newX];
    yData = [yData newY];
    zData = [zData newZ];
    index = index + 1;
end

t.plotCtr = t.plotCtr + 1;

%********************** PLOTTING ***************************
if ~(pausePlot) & t.plotCtr > 20
    t.plotCtr = 0;
    %Update Clock display
    set(clockDisplay, 'String', datestr(now, 'dd-mmm-yyyy HH:MM:SS.FFF'));
    if (plotType)
        %FFT
        nfft = 2^nextpow2(index - 1);
        %X Data
        magnitude = fft(xData(2:index), nfft)/(index - 1);
        freq = (1/t.period)*linspace(0, 1, nfft/2 + 1)/2;
        %Frequency Plot
        plot(handles.xPlot_axes, freq, 2*abs(magnitude(1:nfft/2 + 1)), 'r');
        xlabel(handles.xPlot_axes, 'Frequency (Hz)');
        ylabel(handles.xPlot_axes, 'Magnitude');
        %Y Data
        magnitude = fft(yData(2:index), nfft)/(index - 1);
        freq = (1/t.period)*linspace(0, 1, nfft/2 + 1)/2;
        %Frequency Plot
        plot(handles.yPlot_axes, freq, 2*abs(magnitude(1:nfft/2 + 1)), 'r');
        xlabel(handles.yPlot_axes, 'Frequency (Hz)');
        ylabel(handles.yPlot_axes, 'Magnitude');
        %Z Data
        magnitude = fft(zData(2:index), nfft)/(index - 1);
        freq = (1/t.period)*linspace(0, 1, nfft/2 + 1)/2;
        %Frequency Plot
        plot(handles.zPlot_axes, freq, 2*abs(magnitude(1:nfft/2 + 1)), 'r');
        xlabel(handles.zPlot_axes, 'Frequency (Hz)');
        ylabel(handles.zPlot_axes, 'Magnitude');
    else
        %Time plot
        if (timeFrame > 0)
            fIndex = index - timeFrame/t.Period;   %firstIndex
            if (fIndex < 1)
                fIndex = 1;
            end    
        else
            fIndex = 1;
        end
        plot(handles.xPlot_axes, time(fIndex:index), xData(fIndex:index), 'r');
        plot(handles.yPlot_axes, time(fIndex:index), yData(fIndex:index), 'r');
        plot(handles.zPlot_axes, time(fIndex:index), zData(fIndex:index), 'r');
        if fIndex > 1
            axis(handles.xPlot_axes, [time(fIndex) current -2 2]);
            axis(handles.yPlot_axes, [time(fIndex) current -2 2]);
            axis(handles.zPlot_axes, [time(fIndex) current -2 2]);
            datetick(handles.xPlot_axes, 'x','HH:MM:SS', 'keeplimits', 'keepticks');
            datetick(handles.yPlot_axes, 'x','HH:MM:SS', 'keeplimits', 'keepticks');
            datetick(handles.zPlot_axes, 'x','HH:MM:SS', 'keeplimits', 'keepticks');
        else
            datetick(handles.xPlot_axes, 'x','HH:MM:SS', 'keepticks');
            datetick(handles.yPlot_axes, 'x','HH:MM:SS', 'keepticks');
            datetick(handles.zPlot_axes, 'x','HH:MM:SS', 'keepticks');
        end
        xlabel(handles.xPlot_axes, 'Time (HH:MM:SS)');
        ylabel(handles.xPlot_axes, 'Magnitude');
        xlabel(handles.yPlot_axes, 'Time (HH:MM:SS)');
        ylabel(handles.yPlot_axes, 'Magnitude');
        xlabel(handles.zPlot_axes, 'Time (HH:MM:SS)');
        ylabel(handles.zPlot_axes, 'Magnitude');
    end
    set(handles.xPlot_axes, 'XGrid', 'on');
    set(handles.xPlot_axes, 'YGrid', 'on');
    set(handles.yPlot_axes, 'XGrid', 'on');
    set(handles.yPlot_axes, 'YGrid', 'on');
    set(handles.zPlot_axes, 'XGrid', 'on');
    set(handles.zPlot_axes, 'YGrid', 'on');
    drawnow;
end

%********************* DATA LOGGING ************************
currentMinute = minute(current);
if (~mod(currentMinute, 2) && currentMinute > lastLogMinute && floor(second(current)) == 0) %Log data every 2 minutes
    lastLogMinute = currentMinute;
    %j = batch('CreateLogFile', 0, {time, xData, xData, xData, lastLog, index});
    %CreateLogFile(time, xData, xData, xData, lastLog, index)
    %Create a file and store Data(lastLog:index)
    logFile = fopen(strcat(nodeName,' Log\', datestr(time(lastLog), 'yyyy-mmm-dd'), ' @', datestr(time(lastLog), 'HH.MM.SS'), '-', datestr(time(index-1), 'HH.MM.SS'),'.log'), 'wt');
    fprintf(logFile, '%s Data\r\n%s\r\n', nodeName, datestr(now, 'dd-mmm-yyyy'));
    fprintf(logFile, 'Time\t\tX-Axis\t\tY-Axis\t\tZ-Axis\r\n');
    for i = lastLog:(index-1)
        fprintf(logFile, '%s\t%d\t%d\t%d\r\n', datestr(time(i), 'HH:MM:SS.FFF'), xData(i), yData(i), zData(i));
    end
    fclose(logFile);
    lastLog = index;
end

%==========================================================================
%=========================== BUTTON CALLBACKS =============================
%==========================================================================

% --- Executes on button press in BTNConnect.
function BTNConnect_Callback(hObject, eventdata, handles)
% hObject    handle to BTNConnect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%global s;
global t; %timer
global index;
global xData;
global yData;
global zData;
global time;
global lastLog;
global lastLogMinute;
global pausePlot;
global nodeName;
global clockDisplay;
global s;
%Initialize variables in plotting
index = 1;
time = now;
lastLog = index;
lastLogMinute = minute(now);
pausePlot = 0;
xData = 0;
yData = 0;
zData = 0;
portNum = get(handles.serialPort, 'String');
serialStatus = 0;
%Status Bar
wb = waitbar(0, 'Connecting to Accelerometer device...');
try
    %Serial IO
    s = serial(portNum, 'BaudRate', 9600);
    serialStatus = 1;
    waitbar(0.33, wb);
    if (s.Status == 'closed')
        fopen(s);
    end
    waitbar(0.66, wb);
catch
    delete(wb);
    if (serialStatus)
        if ~(s.Status == 'closed')
            fclose(s);
        end
        delete(s);
        clear s;
    end
    %clear plot areas
    cla(handles.xPlot_axes);
    cla(handles.yPlot_axes);
    cla(handles.zPlot_axes);
    set(handles.xPlot_axes,'xtick',[],'ytick',[]);
    set(handles.yPlot_axes,'xtick',[],'ytick',[]);
    set(handles.zPlot_axes,'xtick',[],'ytick',[]);
    msgbox(strcat('Cannot connect to the ', {' '}, portNum,' port. Possible reasons are another application is connected to the port or the port does not exist.'), 'Serial Connection', 'error');
    beep;
    return;
end
delete(wb);
nodeName = 'Sensor1';   %temporary assign sensor name


%GUI Handles manipulation
set(handles.BTNDisconnect, 'Visible', 'on');
set(handles.BTNConnect, 'Visible', 'off');
set(handles.BTNPausePlot, 'Visible', 'on');
set(handles.BTNFreqPlot, 'Visible', 'on');
set(handles.BTNTimeFrame, 'Visible', 'on');
set(handles.STTimeFrame, 'Visible', 'on');
set(handles.timeFrame, 'Visible', 'on');
set(clockDisplay, 'Visible', 'on');

%Initially create Log folder
if ~(exist(strcat(nodeName, ' Log'), 'file') == 7)
    mkdir(strcat(nodeName, ' Log'));
end

%Start the Single-thread periodic timer
start(t);

% --- Executes on button press in BTNDisconnect.
function BTNDisconnect_Callback(hObject, eventdata, handles)
% hObject    handle to BTNDisconnect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global t;
global index
global time;
global lastLog;
global xData;
global yData;
global zData;
global pausePlot;
global indexAtPause;
global nodeName;
global clockDisplay;
global s;

pausePlot = 1;
indexAtPause = index;
stop(t);
%GUI Handles manipulation
set(handles.BTNDisconnect, 'Visible', 'off');
set(handles.BTNConnect, 'Visible', 'on');
set(handles.BTNPausePlot, 'Visible', 'off');
set(handles.BTNResumePlot, 'Visible', 'off');
set(handles.BTNTimeFrame, 'Visible', 'off');
set(handles.STTimeFrame, 'Visible', 'off');
set(handles.timeFrame, 'Visible', 'off');
set(clockDisplay, 'Visible', 'off');

%Serial IO
 if (s.Status == 'open')
     fclose(s);
 end
 delete(s);
 clear s;

%Log the remaining data
logFile = fopen(strcat(nodeName,' Log\', datestr(time(lastLog), 'yyyy-mmm-dd'), ' @', datestr(time(lastLog), 'HH.MM.SS'), '-', datestr(time(index-1), 'HH.MM.SS'),'.log'), 'w+');
fprintf(logFile, '%s Data\r\n%s\r\n', nodeName, datestr(now, 'dd-mmm-yyyy'));
fprintf(logFile, 'Time\t\tX-Axis\t\tY-Axis\t\tZ-Axis\r\n');
for i = lastLog:index
    fprintf(logFile, '%s\t%d\t%d\t%d\r\n', datestr(time(i), 'HH:MM:SS.FFF'), xData(i), yData(i), zData(i));
end
fclose(logFile);



% --- Executes on button press in BTNTimePlot.
function BTNTimePlot_Callback(hObject, eventdata, handles)
% hObject    handle to BTNTimePlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global plotType;
global pausePlot;
global time;
global xData;
global yData;
global zData;
global indexAtPause;
global timeFrame;
global t;
global index;

%GUI Handles manipulation
set(handles.BTNTimePlot, 'Visible', 'off');
set(handles.BTNFreqPlot, 'Visible', 'on');
if (pausePlot)
    set(handles.BTNTimeFrame, 'Visible', 'off');
    set(handles.STTimeFrame, 'Visible', 'off');
    set(handles.timeFrame, 'Visible', 'off');
else
    set(handles.BTNTimeFrame, 'Visible', 'on');
    set(handles.STTimeFrame, 'Visible', 'on');
    set(handles.timeFrame, 'Visible', 'on');
end
%If the plotting is paused and the plot type is in frequency domain
if (pausePlot && plotType)
    %Then update the axes
    if (timeFrame > 0)
        fIndex = index - timeFrame/t.Period;   %firstIndex
        if (fIndex < 1)
            fIndex = 1;
        end
    else
        fIndex = 1;
    end
    plot(handles.xPlot_axes, time(fIndex:indexAtPause), xData(fIndex:indexAtPause), 'r');
    datetick(handles.xPlot_axes, 'x','HH:MM:SS', 'keepticks');
    plot(handles.yPlot_axes, time(fIndex:indexAtPause), yData(fIndex:indexAtPause), 'r');
    datetick(handles.yPlot_axes, 'x','HH:MM:SS', 'keepticks');
    plot(handles.zPlot_axes, time(fIndex:indexAtPause), zData(fIndex:indexAtPause), 'r');
    datetick(handles.zPlot_axes, 'x','HH:MM:SS', 'keepticks');
    xlabel(handles.xPlot_axes, 'Time (HH:MM:SS)');
    ylabel(handles.xPlot_axes, 'Magnitude');
    xlabel(handles.yPlot_axes, 'Time (HH:MM:SS)');
    ylabel(handles.yPlot_axes, 'Magnitude');
    xlabel(handles.zPlot_axes, 'Time (HH:MM:SS)');
    ylabel(handles.zPlot_axes, 'Magnitude');
    set(handles.xPlot_axes, 'XGrid', 'on');
    set(handles.xPlot_axes, 'YGrid', 'on');
    set(handles.yPlot_axes, 'XGrid', 'on');
    set(handles.yPlot_axes, 'YGrid', 'on');
    set(handles.zPlot_axes, 'XGrid', 'on');
    set(handles.zPlot_axes, 'YGrid', 'on');
    drawnow;
end
plotType = 0;

% --- Executes on button press in BTNFreqPlot.
function BTNFreqPlot_Callback(hObject, eventdata, handles)
% hObject    handle to BTNFreqPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global plotType;
global pausePlot;
global t;
global xData;
global yData;
global zData;
global indexAtPause;

%GUI Handles manipulation
set(handles.BTNTimePlot, 'Visible', 'on');
set(handles.BTNFreqPlot, 'Visible', 'off');
set(handles.BTNTimeFrame, 'Visible', 'off');
set(handles.STTimeFrame, 'Visible', 'off');
set(handles.timeFrame, 'Visible', 'off');

%If the plotting is paused and the plot type is in time domain
if (pausePlot && ~plotType)
    %Then update the axes
    nfft = 2^nextpow2(indexAtPause - 1);
    %X Data
    magnitude = fft(xData(2:indexAtPause), nfft)/(indexAtPause - 1);
    freq = (1/t.period)*linspace(0, 1, nfft/2 + 1)/2;
    %Frequency Plot
    plot(handles.xPlot_axes, freq, 2*abs(magnitude(1:nfft/2 + 1)), 'r');
    xlabel(handles.xPlot_axes, 'Frequency (Hz)');
    ylabel(handles.xPlot_axes, 'Magnitude');
    set(handles.xPlot_axes, 'XGrid', 'on');
    set(handles.xPlot_axes, 'YGrid', 'on');
    %Y Data
    magnitude = fft(yData(2:indexAtPause), nfft)/(indexAtPause - 1);
    freq = (1/t.period)*linspace(0, 1, nfft/2 + 1)/2;
    %Frequency Plot
    plot(handles.yPlot_axes, freq, 2*abs(magnitude(1:nfft/2 + 1)), 'r');
    xlabel(handles.yPlot_axes, 'Frequency (Hz)');
    ylabel(handles.yPlot_axes, 'Magnitude');
    set(handles.yPlot_axes, 'XGrid', 'on');
    set(handles.yPlot_axes, 'YGrid', 'on');
    %Z Data
    magnitude = fft(zData(2:indexAtPause), nfft)/(indexAtPause - 1);
    freq = (1/t.period)*linspace(0, 1, nfft/2 + 1)/2;
    %Frequency Plot
    plot(handles.zPlot_axes, freq, 2*abs(magnitude(1:nfft/2 + 1)), 'r');
    xlabel(handles.zPlot_axes, 'Frequency (Hz)');
    ylabel(handles.zPlot_axes, 'Magnitude');
    set(handles.zPlot_axes, 'XGrid', 'on');
    set(handles.zPlot_axes, 'YGrid', 'on');
    drawnow;
end
plotType = 1;

% --- Executes on button press in BTNPausePlot.
function BTNPausePlot_Callback(hObject, eventdata, handles)
% hObject    handle to BTNPausePlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global pausePlot;
global indexAtPause;
global index;
if ~(pausePlot)     %Only on the first click
    indexAtPause = index;
end
pausePlot = 1;
set(handles.BTNPausePlot, 'Visible', 'off');
set(handles.BTNResumePlot, 'Visible', 'on');
set(handles.BTNTimeFrame, 'Visible', 'off');
set(handles.STTimeFrame, 'Visible', 'off');
set(handles.timeFrame, 'Visible', 'off');

% --- Executes on button press in BTNResumePlot.
function BTNResumePlot_Callback(hObject, eventdata, handles)
% hObject    handle to BTNResumePlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global pausePlot;
global plotType;
pausePlot = 0;
set(handles.BTNPausePlot, 'Visible', 'on');
set(handles.BTNResumePlot, 'Visible', 'off');

if (plotType)
    set(handles.BTNTimeFrame, 'Visible', 'off');
    set(handles.STTimeFrame, 'Visible', 'off');
    set(handles.timeFrame, 'Visible', 'off');
else
    set(handles.BTNTimeFrame, 'Visible', 'on');
    set(handles.STTimeFrame, 'Visible', 'on');
    set(handles.timeFrame, 'Visible', 'on');
end


% --- Executes on button press in BTNBrowse.
function BTNBrowse_Callback(hObject, eventdata, handles)
% hObject    handle to BTNBrowse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global index;
global indexAtPause;
global time;
global xData;
global yData;
global zData;
global s;
global plotType;
global pausePlot;
global t;

if (isvalid(s))
    beep;
    msgbox('Cannot Browse Data log file on active connection', 'Invalid Browse', 'error');
else
    pausePlot = 1;
    %If not connected, then proceed, else show error message
    [filename pathname] = uigetfile({'*.log'},'Browse Log File');
    if ~(pathname == 0)
        logFile = fopen(strcat(pathname, filename), 'r');
        tline = fgets(logFile);
        lineCtr = 1;
        failToRead = 0;
        %Initialize Plot
        index = 1;
        time = now;
        xData = sin(second(now));
        while ischar(tline)
            dataStr = cell2mat(cellstr(tline));
            if (lineCtr == 2)
                try
                    dateArray = datevec(dataStr);
                catch
                    msgbox('Invalid Log Data', 'Read Error', 'error');
                    failToRead = 1; beep;
                    break;
                end
            elseif (lineCtr >= 4)
                splitLine = regexp(dataStr, '\s', 'split');
                timeStr = regexp(cell2mat(splitLine(1)), '[:]', 'split');
                try
                    timeValues = str2double(timeStr);
                    xData(index) = str2double(splitLine(2));
                catch
                    msgbox('Invalid Log Data', 'Read error', 'error');
                    failToRead = 1; beep;
                    break;
                end
                %Add the time value to the dateArray
                dateArray = [dateArray(1:3) timeValues];
                time(index) = datenum(dateArray);
                index = index + 1;
            end
            %update the new tLine
            tline = fgets(logFile);
            lineCtr = lineCtr + 1;
        end
        fclose(logFile);
    else
        failToRead = 1;
    end


    %if the data extraction succeed
    if ~failToRead
        indexAtPause = index - 1;

        %GUI Handles Manipulation
        if plotType
            set(handles.BTNTimePlot, 'Visible', 'on');
            set(handles.BTNFreqPlot, 'Visible', 'off');
        else
            set(handles.BTNTimePlot, 'Visible', 'off');
            set(handles.BTNFreqPlot, 'Visible', 'on');
        end
        set(handles.BTNTimeFrame, 'Visible', 'off');
        set(handles.STTimeFrame, 'Visible', 'off');
        set(handles.timeFrame, 'Visible', 'off');
        %Plot
        if (plotType)
            %FFT
            nfft = 2^nextpow2(index);
            %X
            magnitude = fft(xData, nfft)/index;
            freq = (1/t.period)*linspace(0, 1, nfft/2 + 1)/2;
            %Frequency Plot
            plot(handles.xPlot_axes, freq, 2*abs(magnitude(1:nfft/2 + 1)), 'r');
            xlabel(handles.xPlot_axes, 'Frequency (Hz)');
            ylabel(handles.xPlot_axes, 'Magnitude');
            %Y
            magnitude = fft(yData, nfft)/index;
            freq = (1/t.period)*linspace(0, 1, nfft/2 + 1)/2;
            %Frequency Plot
            plot(handles.yPlot_axes, freq, 2*abs(magnitude(1:nfft/2 + 1)), 'r');
            xlabel(handles.yPlot_axes, 'Frequency (Hz)');
            ylabel(handles.yPlot_axes, 'Magnitude');
            %Z
            magnitude = fft(zData, nfft)/index;
            freq = (1/t.period)*linspace(0, 1, nfft/2 + 1)/2;
            %Frequency Plot
            plot(handles.zPlot_axes, freq, 2*abs(magnitude(1:nfft/2 + 1)), 'r');
            xlabel(handles.zPlot_axes, 'Frequency (Hz)');
            ylabel(handles.zPlot_axes, 'Magnitude');
         else
            %Time plot
            plot(handles.xPlot_axes, time, xData, 'r');
            datetick(handles.xPlot_axes, 'x','HH:MM:SS', 'keepticks');
            xlabel(handles.xPlot_axes, 'Time (HH:MM:SS)');
            ylabel(handles.xPlot_axes, 'Magnitude');
            plot(handles.yPlot_axes, time, xData, 'r');
            datetick(handles.yPlot_axes, 'x','HH:MM:SS', 'keepticks');
            xlabel(handles.yPlot_axes, 'Time (HH:MM:SS)');
            ylabel(handles.yPlot_axes, 'Magnitude');
            plot(handles.zPlot_axes, time, xData, 'r');
            datetick(handles.zPlot_axes, 'x','HH:MM:SS', 'keepticks');
            xlabel(handles.zPlot_axes, 'Time (HH:MM:SS)');
            ylabel(handles.zPlot_axes, 'Magnitude');
         end
         set(handles.xPlot_axes, 'XGrid', 'on');
         set(handles.xPlot_axes, 'YGrid', 'on');
         set(handles.yPlot_axes, 'XGrid', 'on');
         set(handles.yPlot_axes, 'YGrid', 'on');
         set(handles.zPlot_axes, 'XGrid', 'on');
         set(handles.zPlot_axes, 'YGrid', 'on');
         drawnow;
    end
end
    


% --- Executes on button press in BTNTimeFrame.
function BTNTimeFrame_Callback(hObject, eventdata, handles)
% hObject    handle to BTNTimeFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global timeFrame;
global index;
global t;

try
    timeFrame = str2double(get(handles.timeFrame, 'String'));
catch
    msgbox('Invalid Time Frame!', 'Time Frame error', 'error');
    beep;
end
timeFrame = round(timeFrame);
if (timeFrame > index/t.Period)
    msgbox('Time Frame value is too high!', 'Time Frame error', 'error');
    beep;
    timeFrame = 0;
end
