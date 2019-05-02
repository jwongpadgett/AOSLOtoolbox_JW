function varargout = roc_desinusoid_batch_process_2(varargin)
% ROC_DESINUSOID_BATCH_PROCESS_2 M-file for roc_desinusoid_batch_process_2.fig
%      ROC_DESINUSOID_BATCH_PROCESS_2, by itself, creates a new ROC_DESINUSOID_BATCH_PROCESS_2 or raises the existing
%      singleton*.
%
%      H = ROC_DESINUSOID_BATCH_PROCESS_2 returns the handle to a new ROC_DESINUSOID_BATCH_PROCESS_2 or the handle to
%      the existing singleton*.
%
%      ROC_DESINUSOID_BATCH_PROCESS_2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ROC_DESINUSOID_BATCH_PROCESS_2.M with the given input arguments.
%
%      ROC_DESINUSOID_BATCH_PROCESS_2('Property','Value',...) creates a new ROC_DESINUSOID_BATCH_PROCESS_2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before roc_desinusoid_batch_process_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to roc_desinusoid_batch_process_2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help roc_desinusoid_batch_process_2

% Last Modified by GUIDE v2.5 04-Nov-2008 10:13:55

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @roc_desinusoid_batch_process_2_OpeningFcn, ...
                       'gui_OutputFcn',  @roc_desinusoid_batch_process_2_OutputFcn, ...
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

% --- Executes just before roc_desinusoid_batch_process_2 is made visible.
function roc_desinusoid_batch_process_2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to roc_desinusoid_batch_process_2 (see VARARGIN)

    % Choose default command line output for roc_desinusoid_batch_process_2
    handles.output                = hObject;

    % inilialising cell arrays
    handles.full_filenames_TODO   = {};
    handles.full_filenames_DONE   = {};
    handles.full_filenames_FAILED = {};

    set(handles.TODO_listbox_tag,                       'String', [])
    set(handles.DONE_listbox_tag,                       'String', [])
    set(handles.FAILED_listbox_tag,                     'String', [])
    set(handles.path_desinusoid_file_tag,               'string', [])
    set(handles.filename_desinusoid_file_tag,           'string', [])
    set(handles.select_desinusoid_data_file_button_tag, 'enable', 'on')
    set(handles.add_batch_files_to_TODO_button_tag,     'enable', 'off')
    set(handles.start_batch_processing_button_tag,      'enable', 'off')

    % adding application name to use as title for waitbars
    handles.application_name = 'ROC desinusoid batch processing (v2)';

    % Update handles structure
    guidata(hObject, handles);
end


% --- Outputs from this function are returned to the command line.
function varargout = roc_desinusoid_batch_process_2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;
end


% --- Executes on button press in select_desinusoid_data_file_button_tag.
function select_desinusoid_data_file_button_tag_Callback(hObject, eventdata, handles)
% hObject    handle to select_desinusoid_data_file_button_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % selecting a single desinusoid file
    [filename, path]            = uigetfile('*.mat', 'Select desinusoid data file');

    if filename ~= 0
        temp                    = load([path, filename]);

        % updating the GUI
        set(handles.path_desinusoid_file_tag,           'string', path(1:end-1))
        set(handles.filename_desinusoid_file_tag,       'string', filename)
        set(handles.add_batch_files_to_TODO_button_tag, 'enable', 'on')

        % adding the desinusoid data to the structure
        handles.desinusoid_data = temp.desinusoid_data;

        % updating handles structure
        guidata(hObject, handles);
    end
end


% --- Executes on button press in add_batch_files_to_TODO_button_tag.
function add_batch_files_to_TODO_button_tag_Callback(hObject, eventdata, handles)
% hObject    handle to add_batch_files_to_TODO_button_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % multiple selection of files
    [filenames,path] = uigetfile('*.avi','Select AVI movies to desinusoid','MultiSelect','on');

    % checking the filename is not empty
    [r, c]           = size(filenames);

    % if the file is not empty or its name is longer than one character
    if r * c > 1

        % adding files to the list 
        for k = 1 : length(filenames)

            if class(filenames) == 'char'
                % when only one file is read filenames is of class char
                current_full_name = [path, filenames];
            else
                % when multiple files are read filenames is of class cell
                current_full_name = strcat(path, filenames{k});
            end

            already_included  = 0;

            % checking that the file are not already included
            for i = 1 : length(handles.full_filenames_TODO)
                if strcmp(current_full_name,handles.full_filenames_TODO{i})
                    already_included = 1;
                end
            end

            % if not included, then add to the list
            if ~already_included
                handles.full_filenames_TODO{end + 1} = current_full_name;
            end
        end

        % updating the GUI
        set(handles.TODO_listbox_tag,'String',handles.full_filenames_TODO);

        if length(handles.full_filenames_TODO)
            set(handles.start_batch_processing_button_tag,'Enable','on')
        end

        % updating handles structure
        guidata(hObject, handles);
    end
end


% --- Executes on button press in start_batch_processing_button_tag.
function start_batch_processing_button_tag_Callback(hObject, eventdata, handles)
% hObject    handle to start_batch_processing_button_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % disabling the add files button while processing data
    set(handles.select_desinusoid_data_file_button_tag, 'enable', 'off')
    set(handles.add_batch_files_to_TODO_button_tag,     'enable', 'off')
    set(handles.start_batch_processing_button_tag,      'enable', 'off')

    % getting the desinusoid matrix from the data structure
    if handles.desinusoid_data.horizontal_warping
        desinusoid_matrix             = single(handles.desinusoid_data.vertical_fringes.desinusoid_matrix');
    else
        desinusoid_matrix             = single(handles.desinusoid_data.horizontal_fringes.desinusoid_matrix);
    end

    [n_rows_matrix, n_columns_matrix] = size(desinusoid_matrix);

    % creating the colormap to be used for the movies
    aux_cmap                          = [[0:1/255:1]',[0:1/255:1]',[0:1/255:1]'];

    % iterating through selected movies
    for file_index = 1 : length(handles.full_filenames_TODO)

        % dealing with the first file on the list
        current_full_name             = handles.full_filenames_TODO{1};

        [pathstr, name, ext]   = fileparts(current_full_name);

        % reading movie info only once per movie
        vidObj                        = VideoReader(current_full_name);
        n_frames                      = round(vidObj.FrameRate*vidObj.Duration);
        n_columns_image               = vidObj.Width;
        n_rows_image                  = vidObj.Height;

        % moving movie to failed list if movie and matrix sizes don't match
        if ( handles.desinusoid_data.horizontal_warping & (n_columns_image ~= n_rows_matrix)) | ...
           (~handles.desinusoid_data.horizontal_warping & (n_rows_image    ~= n_columns_matrix))

            % removing this filename from the TODO list
            handles.full_filenames_TODO            = handles.full_filenames_TODO(2:end);

            % adding the filename to the FAILED list
            handles.full_filenames_FAILED{end + 1} = current_full_name;        

            % updating GUI lists
            set(handles.TODO_listbox_tag,   'String', handles.full_filenames_TODO);
            set(handles.FAILED_listbox_tag, 'String', handles.full_filenames_FAILED);
        else
            % creating the movie object
            mov = VideoWriter([current_full_name(1:end-4), '_desinusoided.avi'], 'Grayscale AVI');
            mov.FrameRate = vidObj.FrameRate;
            open(mov);
            
            % creating an avi frame
            if handles.desinusoid_data.horizontal_warping
                avi_frame           = struct('cdata', zeros(n_rows_matrix, n_columns_image),...
                                             'colormap', aux_cmap);
            else
                avi_frame           = struct('cdata', zeros(n_rows_image, n_rows_matrix),...
                                             'colormap', aux_cmap);
            end

            % creating waitbar indicating current file
            h_wait                  = waitbar(0,['desinusoiding ' strrep(name,'_','\_')],...
                                                 'name', handles.application_name);
            for frame_index = 1 : n_frames,

                % loading frame
                current_frame       = single(readFrame(vidObj));

                % dewarping and copying the data directly to the frame
                if handles.desinusoid_data.horizontal_warping
                    avi_frame.cdata = uint8(current_frame * desinusoid_matrix);
                else
                    avi_frame.cdata = uint8(desinusoid_matrix * current_frame);
                end

                % adding the frame to the movie
                writeVideo(mov, avi_frame.cdata);

                % I only update the waitbar every 5 frames to increase speed
                if mod(frame_index, 10) == 0
                    waitbar(frame_index/n_frames,h_wait)
                end
            end

            % closing the waitbar
            close(h_wait)

            % closing the movie
            close(mov);

            % removing this filename from the TODO list
            handles.full_filenames_TODO          = handles.full_filenames_TODO(2:end);

            % adding the filename to the DONE list
            handles.full_filenames_DONE{end + 1} = current_full_name;        

            set(handles.TODO_listbox_tag, 'String', handles.full_filenames_TODO);
            set(handles.DONE_listbox_tag, 'String', handles.full_filenames_DONE);
        end

        % Update handles structure
        guidata(hObject, handles);
    end

    % re-enabling the add files buttont
    set(handles.select_desinusoid_data_file_button_tag, 'enable', 'on')
    set(handles.add_batch_files_to_TODO_button_tag,     'enable', 'on')
    set(handles.start_batch_processing_button_tag,      'enable', 'on')
end


% --- Executes on button press in help_button_tag.
function help_button_tag_Callback(hObject, eventdata, handles)
% hObject    handle to help_button_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % getting the current working directory
    initial_folder          = pwd;

    temp_path               = [';' path ';'];

    path_separation_indices = find( temp_path == ';');

    n_folders = length(path_separation_indices)-1;

    for k = 1 : n_folders-1

        % creating a string with each folder in the path
        current_folder = temp_path(path_separation_indices(k)+1:path_separation_indices(k+1)-1);

        % checking if the manual is in the current directory
        cd(current_folder)    
        aux = dir('roc_desinusoid_v2_manual.doc');
        if length(aux)
            open('roc_desinusoid_v2_manual.doc')
            return
        end

    end

    % going back to initial folder
    cd(initial_folder)
end
    
