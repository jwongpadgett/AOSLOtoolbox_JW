function varargout = roc_create_desinusoid_matrix_2(varargin)
% ROC_CREATE_DESINUSOID_MATRIX_2 M-file for roc_create_desinusoid_matrix_2.fig
%      ROC_CREATE_DESINUSOID_MATRIX_2, by itself, creates a new ROC_CREATE_DESINUSOID_MATRIX_2 or raises the existing
%      singleton*.
%
%      H = ROC_CREATE_DESINUSOID_MATRIX_2 returns the handle to a new ROC_CREATE_DESINUSOID_MATRIX_2 or the handle to
%      the existing singleton*.
%
%      ROC_CREATE_DESINUSOID_MATRIX_2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ROC_CREATE_DESINUSOID_MATRIX_2.M with the given input arguments.
%
%      ROC_CREATE_DESINUSOID_MATRIX_2('Property','Value',...) creates a new ROC_CREATE_DESINUSOID_MATRIX_2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before roc_create_desinusoid_matrix_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to roc_create_desinusoid_matrix_2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help roc_create_desinusoid_matrix_2

    % Last Modified by GUIDE v2.5 03-Nov-2008 16:22:33

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @roc_create_desinusoid_matrix_2_OpeningFcn, ...
                       'gui_OutputFcn',  @roc_create_desinusoid_matrix_2_OutputFcn, ...
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

% --- Executes just before roc_create_desinusoid_matrix_2 is made visible.
function roc_create_desinusoid_matrix_2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to roc_create_desinusoid_matrix_2 (see VARARGIN)

    % Choose default command line output for roc_create_desinusoid_matrix_2
    handles.output = hObject;

    set(handles.horizontal_fringes_current_filename_tag,   'String',    '')
    set(handles.find_horizontal_fringes_minima_button_tag, 'enable', 'off')
    set(handles.horizontal_frame_range_tag,                'enable', 'off')
    set(handles.horizontal_DC_filter_radius_tag,           'enable', 'off')
    set(handles.horizontal_fringe_period_fraction_tag,     'enable', 'off')

    set(handles.h_linear_fitting_radio_button_tag,         'enable', 'off')
    set(handles.h_sinusoidal_fitting_radio_button_tag,     'enable', 'off')

    set(handles.vertical_fringes_current_filename_tag,     'String',    '')
    set(handles.find_vertical_fringes_minima_button_tag,   'enable', 'off')
    set(handles.vertical_frame_range_tag,                  'enable', 'off')
    set(handles.vertical_DC_filter_radius_tag,             'enable', 'off')
    set(handles.vertical_fringe_period_fraction_tag,       'enable', 'off')

    set(handles.create_n_save_desinusoid_matrix_button_tag,'enable', 'off')
    set(handles.select_v_fringes_AVI_file_button_tag,      'enable', 'off')
    set(handles.pixels_dropped_at_edges_tag,               'enable', 'off')

    % (re) initialising horizontal fringes-related axes
    axes(handles.h_fringes_grid_display_tag)
    colormap(gray(255))
    image(235*ones(5)), axis equal, axis tight, axis off

    axes(handles.h_fringes_spectrum_display_tag)
    image(235*ones(5)), axis tight, axis off

    axes(handles.h_fringes_curve_fit_tag)
    image(235*ones(5)), axis tight, axis off

    axes(handles.h_fringes_slice_display_tag)
    image(235*ones(5)), axis tight, axis off

    % (re) initialising vertical fringes-related axes
    axes(handles.v_fringes_grid_display_tag)
    image(235*ones(10)), axis equal, axis tight, axis off

    axes(handles.v_fringes_spectrum_display_tag)
    image(235*ones(5)), axis tight, axis off

    axes(handles.v_fringes_curve_fit_tag)
    image(235*ones(5)), axis tight, axis off

    axes(handles.v_fringes_slice_display_tag)
    image(235*ones(5)), axis tight, axis off

    % setting the plot marker size
    handles.plot_marker_size = 8;
    handles.plot_font_size   = 7;

    % creating data structure to store parameters and outputs
    handles.desinusoid_data  = struct();

    % adding application name to use as title for waitbars
    handles.application_name = 'ROC create desinusoid matrix (v2)';

    % Update handles structure
    guidata(hObject, handles);
end


% --- Outputs from this function are returned to the command line.
function varargout = roc_create_desinusoid_matrix_2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;
end


% --- Executes on button press in select_h_fringes_AVI_file_button_tag.
function select_h_fringes_AVI_file_button_tag_Callback(hObject, eventdata, handles)
% hObject    handle to select_h_fringes_AVI_file_button_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % reading file name and path
    [filename, path]                               = uigetfile('*.avi','Select AVI file with horizontal fringes');

    % do the following only if reading the file name was successful
    if (filename ~= 0)

        % reading movie info
        vidObj                                     = VideoReader([path,filename]);
        n_frames                                   = round(vidObj.FrameRate*vidObj.Duration);
        n_columns                                  = vidObj.Width;
        n_rows                                     = vidObj.Height;

        % adding movie info to data structure for record keeping
        handles.desinusoid_data.horizontal_fringes = struct( 'filename',  filename,...
                                                             'path',      path,...
                                                             'n_frames',  n_frames,...
                                                             'n_rows',    n_rows,...
                                                             'n_columns', n_columns);

        % initializing/updating GUI with movie information
        set(handles.horizontal_fringes_current_filename_tag, 'String', [path, filename])
        set(handles.horizontal_frame_range_tag,              'String', ['1:',num2str(n_frames)])

        % loading movie first frame. If RGB only reading the red component.        
        first_frame = double(readFrame(vidObj));

        % displaying the frame
        axes(handles.h_fringes_grid_display_tag)   
        imagesc(first_frame), axis equal, axis tight
        xlabel('pixels'), ylabel('pixels')
        title('calibration grid (frame # 1)')

        % resetting all other axes related to the horizontal fringes
        axes(handles.h_fringes_spectrum_display_tag)
        image(235*ones(5)), axis tight, axis off

        axes(handles.h_fringes_curve_fit_tag)
        image(235*ones(5)), axis tight, axis off

        axes(handles.h_fringes_slice_display_tag)
        image(235*ones(5)), axis tight, axis off

        % enabling "find minima" button and other controls
        set(handles.find_horizontal_fringes_minima_button_tag, 'enable', 'on')
        set(handles.horizontal_frame_range_tag,                'enable', 'on')
        set(handles.horizontal_DC_filter_radius_tag,           'enable', 'on')
        set(handles.horizontal_fringe_period_fraction_tag,     'enable', 'on')
        set(handles.h_linear_fitting_radio_button_tag,         'enable', 'on')
        set(handles.h_sinusoidal_fitting_radio_button_tag,     'enable', 'on')

        % updating data structure
        guidata(hObject,handles)        
    end
end


% --- Executes on button press in select_v_fringes_AVI_file_button_tag.
function select_v_fringes_AVI_file_button_tag_Callback(hObject, eventdata, handles)
% hObject    handle to select_v_fringes_AVI_file_button_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % reading file name and path
    [filename, path]                             = uigetfile('*.avi','Select AVI file with vertical fringes');

    % do the following only if reading the file name was successful
    if (filename ~= 0)

        % reading movie info
        vidObj                                     = VideoReader([path,filename]);
        n_frames                                   = round(vidObj.FrameRate*vidObj.Duration);
        n_columns                                  = vidObj.Width;
        n_rows                                     = vidObj.Height;

        % adding movie info to data structure for record keeping
        handles.desinusoid_data.vertical_fringes = struct('filename',  filename,...
                                                          'path',      path,...
                                                          'n_frames',  n_frames,...
                                                          'n_rows',    n_rows,...
                                                          'n_columns', n_columns);

        % initializing/updating GUI with sequence information
        set(handles.vertical_fringes_current_filename_tag, 'String', [path, filename])
        set(handles.vertical_frame_range_tag,              'String', ['1:',num2str(n_frames)])

        % loading movie first frame. If RGB only reading the red component.
        first_frame                              = double(readFrame(vidObj));

       % displaying the frame
        axes(handles.v_fringes_grid_display_tag);
        imagesc(first_frame), axis equal,axis tight
        xlabel('pixels'), ylabel('pixels')
        title('calibration grid (frame # 1)')

        % resetting all other axes related to the vertical fringes
        axes(handles.v_fringes_spectrum_display_tag)
        image(235*ones(5)), axis tight, axis off

        axes(handles.v_fringes_curve_fit_tag)
        image(235*ones(5)), axis tight, axis off

        axes(handles.v_fringes_slice_display_tag)
        image(235*ones(5)), axis tight, axis off

        % enabling "find minima" button and other controls
        set(handles.find_vertical_fringes_minima_button_tag, 'enable', 'on')
        set(handles.vertical_frame_range_tag,                'enable', 'on')
        set(handles.vertical_DC_filter_radius_tag,           'enable', 'on')
        set(handles.vertical_fringe_period_fraction_tag,     'enable', 'on')

        % updating data structure
        guidata(hObject,handles)
    end
end


% --- Executes on button press in find_horizontal_fringes_minima_button_tag.
function find_horizontal_fringes_minima_button_tag_Callback(hObject, eventdata, handles)
% hObject    handle to find_horizontal_fringes_minima_button_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %    getting frame range from the GUI and eliminating repeated frames     %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % reading frame range from GUI
    eval(['frame_range          = [',get(handles.horizontal_frame_range_tag, 'String'),'];'])

    % sorting the frame range in ascending order
    sorted_range                = sort(frame_range);

    % removing repeated frames
    nonrep_sorted_range         = sorted_range(1);

    for k = 2 : length(sorted_range)
        if sorted_range(k) ~= sorted_range(k-1)
            nonrep_sorted_range(end + 1)                   = sorted_range(k);
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                          averaging frame range                          %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % reading from the data structure
    filename                    = handles.desinusoid_data.horizontal_fringes.filename;
    path                        = handles.desinusoid_data.horizontal_fringes.path;
    n_columns                   = handles.desinusoid_data.horizontal_fringes.n_columns;
    n_rows                      = handles.desinusoid_data.horizontal_fringes.n_rows;

    % creating frame average
    average_frame               = zeros(n_rows, n_columns);

    % initializing waitbar
    h_wait                      = waitbar(0,'Averaging frames for minima estimation...',...
                                            'name', handles.application_name);

    % adding frames
    vidObj = VideoReader([path, filename]);
    for frame_index             = 1 : length(frame_range),
        average_frame           = average_frame + double(readFrame(vidObj));
        % updating the waitbar
        waitbar(frame_index/length(frame_range), h_wait)
    end
    close(h_wait)

    % calculating the mean frame
    average_frame               = average_frame / length(frame_range);

    % displaying average frame
    axes(handles.h_fringes_grid_display_tag);
    imagesc(average_frame), axis equal, axis tight
    xlabel('pixels'),       ylabel('pixels')
    title('calibration grid (frame average)')

    % averaging the fringes along the row dimension
    averaged_frame_fringes      = mean(average_frame,2)'; 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                coarse estimation of the fringes period                  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % reading from the GUI
    DC_filter_radius_in_pixels  = str2double(get(handles.horizontal_DC_filter_radius_tag,       'String'));
    fringe_period_fraction      = str2double(get(handles.horizontal_fringe_period_fraction_tag, 'String'));

    % calculating the normalized 1D spectrum along the column dimension
    fringes_spectrum            = abs(ifftshift(fft(fftshift(averaged_frame_fringes))));
    normalized_fringes_spectrum = fringes_spectrum/max(fringes_spectrum);

    % creating frequency vector (this works for even and odd # of pixels)
    if (rem(n_rows,2) == 0)
        frequency_shift         = (n_rows    )/2;
    else
        frequency_shift         = (n_rows + 1)/2;
    end

    % the units are cycles/pixel
    frequency_vector            = ([0 : n_rows - 1] - frequency_shift)/n_rows;

    % creating DC-removal (binary) mask
    DC_mask_row                 = (frequency_vector > 1/DC_filter_radius_in_pixels);

    % estimating fringe frequency as the high-pass filtered spectrum maximum
    [max_value, max_index]      = max(fringes_spectrum .* DC_mask_row);
    frequency_maximum           = frequency_vector(max_index);
    fringes_period              = 1 / frequency_maximum;

    % estimating the fringe period uncertainty
    fringes_period_uncertainty  = 1 / frequency_maximum^2 * (frequency_vector(2)-frequency_vector(1))/2;

    % generating DC-removal mask (only for display in the plot with log axis)
    DC_high_pass_filter         = (abs(frequency_vector) <  1/DC_filter_radius_in_pixels) + ...
                                  (abs(frequency_vector) >= 1/DC_filter_radius_in_pixels) * ...
                                   min(normalized_fringes_spectrum);

    % displaying the spectrum, the DC filter and the estimated fringe frequency
    axes(handles.h_fringes_spectrum_display_tag);
    semilogy(frequency_vector,  normalized_fringes_spectrum,            'b',...
             frequency_vector,  DC_high_pass_filter,                    'r')
    hold on
    semilogy(frequency_maximum, normalized_fringes_spectrum(max_index), 'rx',...
             'markersize', handles.plot_marker_size, 'linewidth', 2) 
    hold off
    axis square, axis tight
    set(gca, 'yticklabel', [])
    title(['1D spectrum (coarse fringes period \approx ' num2str(fringes_period,3)...
           '\pm ' num2str(fringes_period_uncertainty,1) ' pix)'])
    xlabel('cycles')

    % adjusting the plot axes to show only the positive side of the spectrum
    temp_axis                   = axis;
    temp_axis(1)                = 0;
    temp_axis(2)                = 0.5;
    axis(temp_axis)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                           finding minima                                %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    indices_minima              = [];
    x                           = 1 : length(averaged_frame_fringes);

    % finding all local minima
    for k = 2 : length(averaged_frame_fringes) - 1, 
        if ((averaged_frame_fringes(k)   - averaged_frame_fringes(k-1) <= 0) & ...
            (averaged_frame_fringes(k+1) - averaged_frame_fringes(k)   >= 0))
            indices_minima(end + 1) = k;
        end
    end

    % removing unwanted local minima using the estimated fringe period
    indices_minima              = remove_local_minima_that_are_too_close(...
                                      averaged_frame_fringes,...
                                      indices_minima,...
                                      fringe_period_fraction * fringes_period);

    % displaying local minima separated by the given fringe period fraction 
    axes(handles.h_fringes_slice_display_tag);
    plot(x, averaged_frame_fringes)
    hold on

    % notice that we need to keep track of the handle to the plotted markers
    % so that we can do the interactive addition/removal of markers by
    % responding to mouse clicks on the plot
    handle_to_markers           = plot(x(indices_minima), averaged_frame_fringes(indices_minima), 'rx',...
                                      'markersize', handles.plot_marker_size, 'linewidth', 2);
    hold off
    grid on
    set(gca, 'ytick', [])
    title('1D fringes average')
    xlabel('pixels')

    % adjusting axis limits so that the curve is not against the top and bottom edges
    axis([min(x), max(x), min(averaged_frame_fringes) ...
          - 0.05 * max(averaged_frame_fringes), 1.05 * max(averaged_frame_fringes)])

    % setting button down function. The Mathworks tech support has confirmed
    % that this needs to be re-done every time a new curve is plotted.
    set(handles.h_fringes_slice_display_tag, 'ButtonDownFcn', @button_down_on_h_fringes_axis)

    % disabling the axis children response to the mouse pointer
    children_handles            = get(gca, 'children');

    for k = 1 : length(children_handles)
        set(children_handles(k), 'HitTest', 'off')
    end

    % adding data to the structure for record-keeping
    handles.desinusoid_data.horizontal_fringes.frame_range                = nonrep_sorted_range;
    handles.desinusoid_data.horizontal_fringes.average_frame              = average_frame;
    handles.desinusoid_data.horizontal_fringes.DC_filter_radius_in_pixels = DC_filter_radius_in_pixels;
    handles.desinusoid_data.horizontal_fringes.fringe_period_fraction     = fringe_period_fraction;
    handles.desinusoid_data.horizontal_fringes.indices_minima             = indices_minima;

    % adding data to the structure for interactive editing of the minima plot
    handles.handle_to_horizontal_fringes_markers_plot                     = handle_to_markers;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %             estimating and plotting the linear/sinudoidal fit           %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if get(handles.h_linear_fitting_radio_button_tag,'value'),

        % removing previous fields from data if created
        if isfield(handles.desinusoid_data.horizontal_fringes,      'sinusoid_amplitude')
            handles.desinusoid_data.horizontal_fringes = ...
                rmfield(handles.desinusoid_data.horizontal_fringes, 'sinusoid_amplitude');
        end

        if isfield(handles.desinusoid_data.horizontal_fringes,      'sinusoid_n_samples')
            handles.desinusoid_data.horizontal_fringes = ...
                rmfield(handles.desinusoid_data.horizontal_fringes, 'sinusoid_n_samples');
        end

        if isfield(handles.desinusoid_data.horizontal_fringes,      'sinusoid_phase')
            handles.desinusoid_data.horizontal_fringes = ...
                rmfield(handles.desinusoid_data.horizontal_fringes, 'sinusoid_phase');
        end

        if isfield(handles.desinusoid_data.horizontal_fringes,      'sinusoid_offset')
            handles.desinusoid_data.horizontal_fringes = ...
                rmfield(handles.desinusoid_data.horizontal_fringes, 'sinusoid_offset');
        end

        % performing the fit
        [slope, intercept] = perform_linear_fit(....
                                handles.desinusoid_data.horizontal_fringes.indices_minima,...
                                handles.h_fringes_curve_fit_tag,...
                                handles.plot_marker_size);

        % adding new data to the structure
        handles.desinusoid_data.horizontal_fringes.slope          = slope;
        handles.desinusoid_data.horizontal_fringes.intercept      = intercept;

        % replacing the coarse DFT fringe period estimation with the more
        % accurate least-squares estimation
        handles.desinusoid_data.horizontal_fringes.fringes_period = 1/slope;
    else
        % removing previous fields from data if created
        if isfield(handles.desinusoid_data.horizontal_fringes,      'fringe_period')
            handles.desinusoid_data.horizontal_fringes = ...
                rmfield(handles.desinusoid_data.horizontal_fringes, 'slope');
        end

        if isfield(handles.desinusoid_data.horizontal_fringes,      'intercept')
            handles.desinusoid_data.horizontal_fringes = ...
                rmfield(handles.desinusoid_data.horizontal_fringes, 'intercept');
        end

        % performing the fit
        [sinusoid_amplitude, sinusoid_n_samples, sinusoid_phase, sinusoid_offset] = ...
                                perform_sinusoidal_fit(...
                                handles.desinusoid_data.horizontal_fringes.indices_minima,...
                                handles.h_fringes_curve_fit_tag,...
                                handles.plot_marker_size);

        % adding data to the structure
        handles.desinusoid_data.horizontal_fringes.sinusoid_amplitude = sinusoid_amplitude;
        handles.desinusoid_data.horizontal_fringes.sinusoid_n_samples = sinusoid_n_samples;
        handles.desinusoid_data.horizontal_fringes.sinusoid_phase     = sinusoid_phase;
        handles.desinusoid_data.horizontal_fringes.sinusoid_offset    = sinusoid_offset;    

        % adding the coarse DFT fringe period for adding removing minima
        handles.desinusoid_data.horizontal_fringes.fringes_period     = fringes_period;
    end

    % enabling load vertical fringes AVI button
    set(handles.select_v_fringes_AVI_file_button_tag, 'enable', 'on');

    % updating data structure
    guidata(hObject, handles)
end


% --- Executes on button press in find_vertical_fringes_minima_button_tag.
function find_vertical_fringes_minima_button_tag_Callback(hObject, eventdata, handles)
% hObject    handle to find_vertical_fringes_minima_button_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                   getting and setting the frame range                   %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % reading the frame range from the GUI
    eval(['frame_range          = [',get(handles.vertical_frame_range_tag,'String'),'];'])

    % sorting the range in ascending order
    sorted_range                = sort(frame_range);

    % removing repeated frames
    nonrep_sorted_range         = sorted_range(1);

    for k = 2:length(sorted_range)
        if sorted_range(k) ~= sorted_range(k-1)
            nonrep_sorted_range(end + 1)                 = sorted_range(k);
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                          averaging frame range                          %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % reading from the data structure
    filename                   = handles.desinusoid_data.vertical_fringes.filename;
    path                       = handles.desinusoid_data.vertical_fringes.path;
    n_columns                  = handles.desinusoid_data.vertical_fringes.n_columns;
    n_rows                     = handles.desinusoid_data.vertical_fringes.n_rows;

    % creating frame average
    average_frame              = zeros(n_rows, n_columns);

    % initializing waitbar
    h_wait                     = waitbar(0,'Averaging frames for minima estimation...',...
                                           'name',handles.application_name);                                   
    % adding frames
    vidObj = VideoReader([path, filename]);
    for frame_index = 1 : length(frame_range),
        average_frame          = average_frame + double(readFrame(vidObj));

        % updating the waitbar
        waitbar(frame_index/length(frame_range),h_wait)
    end
    close(h_wait)

    % calculating the mean frame
    average_frame              = average_frame / length(frame_range);

    % displaying average frame
    axes(handles.v_fringes_grid_display_tag);
    imagesc(average_frame), axis equal,axis tight
    xlabel('pixels'),       ylabel('pixels')
    title('calibration grid (frame average)')

    % averaging the fringes along the column dimension
    averaged_frame_fringes      = mean(average_frame,1);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                coarse estimation of the fringes period                  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % reading data from the GUI
    DC_filter_radius_in_pixels = str2double(get(handles.vertical_DC_filter_radius_tag,      'String'));
    fringe_period_fraction     = str2double(get(handles.vertical_fringe_period_fraction_tag,'String'));

    % calculating the normalized 1D spectrum along the column dimension
    fringes_spectrum            = abs(ifftshift(fft(fftshift(averaged_frame_fringes))));
    normalized_fringes_spectrum = fringes_spectrum/max(fringes_spectrum);

    % creating frequency vector (this works for even and odd # of pixels)
    if (rem(n_columns,2) == 0)
        frequency_shift         = (n_columns    )/2 ;
    else
        frequency_shift         = (n_columns + 1)/2;
    end

    % the units are cycles/pixel
    frequency_vector            = ([0 : n_columns - 1] - frequency_shift)/n_columns;

    % creating DC-removal (binary) mask
    DC_mask_column              = (frequency_vector > 1/DC_filter_radius_in_pixels);

    % coarsely estimating the fringe frequency as the spectrum maximum
    [max_value, max_index]      = max(fringes_spectrum .* DC_mask_column);
    frequency_maximum           = frequency_vector(max_index);
    fringes_period              = 1 / frequency_maximum;

    % estimating the fringe period uncertainty
    fringes_period_uncertainty  = 1 / frequency_maximum^2 * (frequency_vector(2)-frequency_vector(1))/2;

    % generating DC-removal mask (only for display in the plot with log axis)
    DC_high_pass_filter         = (abs(frequency_vector) <  1/DC_filter_radius_in_pixels) + ...
                                  (abs(frequency_vector) >= 1/DC_filter_radius_in_pixels) * ...
                                   min(normalized_fringes_spectrum);

    % displaying the spectrum, the DC filter and the estimated fringe frequency
    axes(handles.v_fringes_spectrum_display_tag);
    semilogy(frequency_vector, normalized_fringes_spectrum,            'b',...
             frequency_vector, DC_high_pass_filter,                    'r')
    hold on
    semilogy(frequency_maximum, normalized_fringes_spectrum(max_index),'rx',...
             'markersize', handles.plot_marker_size, 'linewidth', 2) 
    hold off
    axis square, axis tight
    set(gca, 'yticklabel', [])
    title(['1D spectrum (coarse fringe period \approx ' num2str(fringes_period,3)...
           '\pm ' num2str(fringes_period_uncertainty,1) ' pix)'])
    xlabel('cycles')

    % showing only the positive side of the spectrum
    temp_axis                   = axis;
    temp_axis(1)                = 0;
    temp_axis(2)                = 0.5;
    axis(temp_axis)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                           finding minima                                %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    indices_minima              = [];
    x                           = 1 : length(averaged_frame_fringes);

    % finding al local minima
    for k = 2 : length(averaged_frame_fringes)-1, 
        if ((averaged_frame_fringes(k)   - averaged_frame_fringes(k-1) <= 0) & ...
            (averaged_frame_fringes(k+1) - averaged_frame_fringes(k)   >= 0))
            indices_minima(length(indices_minima) + 1) = k;
        end
    end

    % removing unwanted local minima using the estimated fringe period
    indices_minima              = remove_local_minima_that_are_too_close(...
                                      averaged_frame_fringes,...
                                      indices_minima,...
                                      fringe_period_fraction * fringes_period);

    % displaying local minima separated by the given fringe period fraction 
    axes(handles.v_fringes_slice_display_tag)
    plot(x, averaged_frame_fringes)
    hold on

    % notice that we need to keep track of the handle to the plotted markers
    % so that we can do the interactive addition/removal of markers by
    % responding to mouse clicks on the plot
    h_markers_plot              = plot(x(indices_minima), averaged_frame_fringes(indices_minima),'rx',...
                                      'markersize', handles.plot_marker_size, 'linewidth', 2);
    hold off
    grid on
    set(gca, 'ytick', [])
    title('1D fringes average')
    xlabel('pixels')

    % adjusting axis limits so that the curve is not against the top and bottom edges
    axis([min(x), max(x), min(averaged_frame_fringes) ...
          - 0.05 * max(averaged_frame_fringes), 1.05 * max(averaged_frame_fringes)])

    % setting button down function. The Mathworks tech support has confirmed
    % that this needs to be re-done every time a new curve is plotted.
    set(handles.v_fringes_slice_display_tag, 'ButtonDownFcn', @button_down_on_v_fringes_axis)

    % disabling the axis children response to the mouse pointer
    children_handles            = get(gca,'children');

    for k = 1 : length(children_handles)
        set(children_handles(k), 'HitTest', 'off')
    end

    % adding data to the structure for record-keeping
    handles.desinusoid_data.vertical_fringes.frame_range                = nonrep_sorted_range;
    handles.desinusoid_data.vertical_fringes.average_frame              = average_frame;  
    handles.desinusoid_data.vertical_fringes.DC_filter_radius_in_pixels = DC_filter_radius_in_pixels;
    handles.desinusoid_data.vertical_fringes.fringe_period_fraction     = fringe_period_fraction;
    handles.desinusoid_data.vertical_fringes.indices_minima             = indices_minima;

    % adding data to the structure for interactive editing of the minima plot
    handles.handle_to_vertical_fringes_markers_plot                     = h_markers_plot;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %             estimating and plotting the linear/sinudoidal fit           %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % note that this is the horizontal fringes case negated
    if ~get(handles.h_linear_fitting_radio_button_tag,'value'),

        % removing previous fields from data if created
        if isfield(handles.desinusoid_data.vertical_fringes,      'sinusoid_amplitude')
            handles.desinusoid_data.vertical_fringes = ...
                rmfield(handles.desinusoid_data.vertical_fringes, 'sinusoid_amplitude');
        end

        if isfield(handles.desinusoid_data.vertical_fringes,      'sinusoid_n_samples')
            handles.desinusoid_data.vertical_fringes = ...
                rmfield(handles.desinusoid_data.vertical_fringes, 'sinusoid_n_samples');
        end

        if isfield(handles.desinusoid_data.vertical_fringes,      'sinusoid_phase')
            handles.desinusoid_data.vertical_fringes = ...
                rmfield(handles.desinusoid_data.vertical_fringes, 'sinusoid_phase');
        end

        if isfield(handles.desinusoid_data.vertical_fringes,      'sinusoid_offset')
            handles.desinusoid_data.vertical_fringes = ...
                rmfield(handles.desinusoid_data.vertical_fringes, 'sinusoid_offset');
        end

        % performing the fit
        [slope, intercept] = perform_linear_fit(....
                                handles.desinusoid_data.vertical_fringes.indices_minima,...
                                handles.v_fringes_curve_fit_tag,...
                                handles.plot_marker_size);

        % adding data to the structure
        handles.desinusoid_data.vertical_fringes.slope            = slope;
        handles.desinusoid_data.vertical_fringes.intercept        = intercept;

        % replacing the coarse DFT fringe period estimation with the more
        % accurate least-squares estimation
        handles.desinusoid_data.vertical_fringes.fringes_period = 1/slope;
    else
        % removing previous fields from data if created
        if isfield(handles.desinusoid_data.vertical_fringes, 'slope')
            handles.desinusoid_data.vertical_fringes = ...
                rmfield(handles.desinusoid_data.vertical_fringes, 'slope');
        end

        if isfield(handles.desinusoid_data.vertical_fringes, 'intercept')
            handles.desinusoid_data.vertical_fringes = ...
                rmfield(handles.desinusoid_data.vertical_fringes, 'intercept');
        end

        % performing the fit
        [sinusoid_amplitude, sinusoid_n_samples, sinusoid_phase, sinusoid_offset] = ...
                                perform_sinusoidal_fit(...
                                handles.desinusoid_data.vertical_fringes.indices_minima,...
                                handles.v_fringes_curve_fit_tag,...
                                handles.plot_marker_size);

        % adding data to the structure
        handles.desinusoid_data.vertical_fringes.sinusoid_amplitude = sinusoid_amplitude;
        handles.desinusoid_data.vertical_fringes.sinusoid_n_samples = sinusoid_n_samples;
        handles.desinusoid_data.vertical_fringes.sinusoid_phase     = sinusoid_phase;
        handles.desinusoid_data.vertical_fringes.sinusoid_offset    = sinusoid_offset;

        % adding the coarse DFT fringe period for adding removing minima
        handles.desinusoid_data.vertical_fringes.fringes_period     = fringes_period;
    end

    % enabling create and save desinusoid matrix control
    set(handles.create_n_save_desinusoid_matrix_button_tag,         'enable','on')
    set(handles.pixels_dropped_at_edges_tag,                        'enable','on')

    % updating data structure
    guidata(hObject,handles)
end



% --- Executes on button press in create_n_save_desinusoid_matrix_button_tag.
function create_n_save_desinusoid_matrix_button_tag_Callback(hObject, eventdata, handles)
% hObject    handle to create_n_save_desinusoid_matrix_button_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % getting the number of pixels to drop on each side to account for the 
    % finite number of samples used for the sinc interpolation formula
    n_edge_pixels_dropped          = str2double(get(handles.pixels_dropped_at_edges_tag, 'string'));

    % getting desinusoid data from structure
    if isfield(handles.desinusoid_data.vertical_fringes, 'sinusoid_amplitude')
        warped_frame               = handles.desinusoid_data.vertical_fringes.average_frame;
        n_samples_experimental     = handles.desinusoid_data.vertical_fringes.n_columns;
        n_warped_lines             = handles.desinusoid_data.vertical_fringes.n_rows;
        sinusoid_amplitude         = handles.desinusoid_data.vertical_fringes.sinusoid_amplitude;
        sinusoid_n_samples         = handles.desinusoid_data.vertical_fringes.sinusoid_n_samples;
        sinusoid_phase             = handles.desinusoid_data.vertical_fringes.sinusoid_phase;
        sinusoid_offset            = handles.desinusoid_data.vertical_fringes.sinusoid_offset;
        fringe_period_fraction     = handles.desinusoid_data.vertical_fringes.fringe_period_fraction;
        other_fringes_period       = handles.desinusoid_data.horizontal_fringes.fringes_period;
        horizontal_warping         = 1;
    else
        warped_frame               = handles.desinusoid_data.horizontal_fringes.average_frame;
        n_samples_experimental     = handles.desinusoid_data.horizontal_fringes.n_rows;
        n_warped_lines             = handles.desinusoid_data.horizontal_fringes.n_columns;
        sinusoid_amplitude         = handles.desinusoid_data.horizontal_fringes.sinusoid_amplitude;
        sinusoid_n_samples         = handles.desinusoid_data.horizontal_fringes.sinusoid_n_samples;
        sinusoid_phase             = handles.desinusoid_data.horizontal_fringes.sinusoid_phase;
        sinusoid_offset            = handles.desinusoid_data.horizontal_fringes.sinusoid_offset;
        fringe_period_fraction     = handles.desinusoid_data.horizontal_fringes.fringe_period_fraction;
        other_fringes_period       = handles.desinusoid_data.vertical_fringes.fringes_period;
        horizontal_warping         = 0;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                    generating desinusoid matrix                     %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % In what follows x represents the spatial coordinate of the pixels
    % recorded at a time t.

    % calculating the x-values corresponding to (1 + n_edge_pixels_dropped) and
    % (n_samples_experimental - n_edge_pixels_dropped). This is to avoid edge
    % artifacts in the interpolation
    x_min                        = sinusoid_amplitude * sin((2 * pi / sinusoid_n_samples) *...
                                  (       1       + n_edge_pixels_dropped) + sinusoid_phase) + sinusoid_offset;

    x_max                        = sinusoid_amplitude * sin((2 * pi / sinusoid_n_samples) *...
                                  (n_samples_experimental - n_edge_pixels_dropped) + sinusoid_phase) + sinusoid_offset;

    % note the step here will make the pixels square
    x_calculated_pixels          = x_min : 1 / other_fringes_period : x_max;                        

    n_pixels_calculated          = length(x_calculated_pixels);


    % calculating corresponding pixel times using the sinusoidal fit
    t_calculated_pixels          = ( asin( (x_calculated_pixels - sinusoid_offset) / sinusoid_amplitude ) - sinusoid_phase )...
                                    / ( 2 * pi / sinusoid_n_samples );

    % remember that the experimental pixels were acquired periodically...
    t_experimental_pixels        = 1 : n_samples_experimental;

    % creating the interpolation matrix using the sinc reconstruction formula
    h_wait                       = waitbar(0, 'Calculating desinusoid matrix...',...
                                              'name', handles.application_name);

    % the eps is for avoiding the discontinuity in the sinc at t = 0
    for k = 1 : n_pixels_calculated,
        desinusoid_matrix(k,:)   = sin(pi * (t_calculated_pixels(k) - t_experimental_pixels - eps))...
                                    ./(pi * (t_calculated_pixels(k) - t_experimental_pixels - eps));

        % updating the waitbar only every 20 iterations for faster display
        if rem(k, 20) == 0
            waitbar(k/n_pixels_calculated,h_wait)
        end
    end
    close(h_wait)

    % initializing new figure to display calculation outputs
    figure(2), clf, colormap('pink')

    % displaying warped average frame
    subplot(221)
    imagesc(warped_frame)
    axis equal, axis tight, axis off
    title('warped fringes')

    % keeping axis dimensions so that they can be used for the dewarped image
    temp_axis                       = axis;

    % displaying the interpolation matrix
    subplot(212)
    imagesc(log(abs(desinusoid_matrix)))
    axis equal, axis tight
    xlabel(['experimental pixels ({\itN} = ' num2str(n_samples_experimental) ')'])
    ylabel(['calculated pixels ({\itN} = ' num2str(n_pixels_calculated) ')'])
    title(  'log(|desinusoid matrix|) ')
    caxis([-6, 0])

    % calculating desinusoided frame
    if horizontal_warping
        desinusoided_image          = warped_frame * desinusoid_matrix';

        % averaging fringes along the columns
        averaged_frame_fringes      = mean(desinusoided_image,1); 
    else
        desinusoided_image          = desinusoid_matrix * warped_frame;

        % averaging fringes along the rows
        averaged_frame_fringes      = mean(desinusoided_image,2)'; 
    end

    % creating frequency vector
    if (rem(n_pixels_calculated,2) == 0)
        frequency_shift             = (n_pixels_calculated    )/2;
    else
        frequency_shift             = (n_pixels_calculated + 1)/2;
    end

    % the units are cycles/pixel
    frequency_vector_calculated     = ([0 : n_pixels_calculated - 1] - frequency_shift)/n_pixels_calculated;

    % calculating normalized spectrum
    spectrum                        = abs(ifftshift(fft(fftshift(averaged_frame_fringes))));
    normalized_spectrum             = spectrum/max(spectrum);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % coarse estimation of the desinusoided fringes period using the DFT  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % creating DC-removal mask
    DC_mask                        = (frequency_vector_calculated > 1/(2*other_fringes_period));

    % estimating the fringe frequency
    [not_used, max_index]          = max(spectrum .* DC_mask);
    frequency_maximum              = frequency_vector_calculated(max_index);
    new_fringes_period             = 1 / frequency_maximum;    
    new_fringes_period_uncertainty = 1 / frequency_maximum^2 * ...
                                    (frequency_vector_calculated(2) - frequency_vector_calculated(1))/2;

    % displaying dewarped frame
    subplot(222)
    imagesc(desinusoided_image)
    axis equal, axis off
    title('dewarped fringes')
    axis(temp_axis)

    % adding new data to the structure
    if horizontal_warping
        handles.desinusoid_data.vertical_fringes.x_calculated_pixels           = x_calculated_pixels;
        handles.desinusoid_data.vertical_fringes.t_calculated_pixels           = t_calculated_pixels;
        handles.desinusoid_data.vertical_fringes.desinusoid_matrix             = desinusoid_matrix;   
    else
        handles.desinusoid_data.horizontal_fringes.x_calculated_pixels         = x_calculated_pixels;
        handles.desinusoid_data.horizontal_fringes.t_calculated_pixels         = t_calculated_pixels;
        handles.desinusoid_data.horizontal_fringes.desinusoid_matrix           = desinusoid_matrix;   
    end

    handles.desinusoid_data.horizontal_warping                                 = horizontal_warping;

    % saving data    
    [filename, path] = uiputfile('*.mat', 'Enter filename for saving dewarp data','');

    if (filename ~= 0)

        % saving MAT file
        desinusoid_data                               = handles.desinusoid_data;

        save([path, filename], 'desinusoid_data')
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                estimating and plotting the polynomial fit               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [slope, intercept]  = perform_linear_fit(indices_minima, linear_fit_axes, ...
                                                  marker_size)

    n_minima                     = length(indices_minima);
    minima_time_vector           = 1 : n_minima;

    % performing the fit
    fit_coefficients             = polyfit(indices_minima, minima_time_vector,1);

    % evaluating the fitting parameters and the fitting uncertainty
    fit_time_vector              = polyval(fit_coefficients, indices_minima);

    relative_fitting_uncertainty = sqrt(sum((minima_time_vector - fit_time_vector).^2))/ ...
                                   sqrt(sum((minima_time_vector).^2));

    % displaying fitted line
    axes(linear_fit_axes)

    plot(indices_minima, minima_time_vector, 'rx', 'markersize', marker_size, 'linewidth', 2)
    hold on
    plot(indices_minima, fit_time_vector,'b-')
    hold off
    axis square
    temp = [minima_time_vector, fit_time_vector];
    axis([min(indices_minima),  max(indices_minima), min(temp), max(temp)])
    title(['fringe period = ' num2str(1/fit_coefficients(1),4) ' pix'])

    % adding current parameters to the plot
    line_0                       = ['{\it t} = {\itA} x + {\itB}'];
    line_1                       = ['{\itA}  = '    num2str(fit_coefficients(1))];
    line_2                       = ['{\itB}  = '    num2str(fit_coefficients(2))];
    line_3                       = ['\epsilon   = ' num2str(100*relative_fitting_uncertainty,2) '%'];
    text_x                       = min(indices_minima) + 0.07*(max(indices_minima) - min(indices_minima));
    text_y                       = max(temp)           - 0.19 *(max(temp)           - min(temp));    
    text(text_x, text_y, {line_0; line_1; line_2; line_3}, 'fontsize', get(gca,'fontsize'))
    ylabel('{\itx}_{minima} (a.u.)')
    xlabel('{\itt}_{minima} (a.u.)')

    % returned values. Note that the inverse of the slope is the fringe period
    slope                        = fit_coefficients(1);
    intercept                    = fit_coefficients(2);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                estimating and plotting the sinusoidal fit               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [sinusoid_amplitude, sinusoid_n_samples, sinusoid_phase, sinusoid_offset] =...
          perform_sinusoidal_fit(indices_minima, sinusoidal_fit_axes, marker_size)

    n_minima                     = length(indices_minima);
    minima_time_vector           = 1 : n_minima;

    % performing the fitting
    [sinusoid_amplitude, sinusoid_n_samples, sinusoid_phase, sinusoid_offset ] = ...
                                   fit_semi_sinusoid(minima_time_vector, indices_minima);

    %evaluating the fitting parameters and the fitting uncertainty
    fit_time_vector              = sinusoid_amplitude * sin(2 * pi / sinusoid_n_samples * ...
                                   indices_minima + sinusoid_phase) + sinusoid_offset;

    relative_fitting_uncertainty = sqrt(sum((minima_time_vector - fit_time_vector).^2))/ ...
                                   sqrt(sum((minima_time_vector).^2));

    % displaying fitted sinusoid
    axes(sinusoidal_fit_axes)

    plot(indices_minima, minima_time_vector, 'rx', 'markersize', marker_size, 'linewidth', 2)
    hold on
    plot(indices_minima, fit_time_vector,'b-')
    hold off
    axis square
    temp = [minima_time_vector, fit_time_vector];
    axis([min(indices_minima),  max(indices_minima), min(temp), max(temp)])

    % adding current parameters to the plot
    line_0                       = ['x = {\itA} sin(2\pi t / N + \phi) + {\itB}'];
    line_1                       = ['{\itA}  = ' num2str(sinusoid_amplitude)];
    line_2                       = ['N  = '      num2str(sinusoid_n_samples)];
    line_3                       = ['\phi = '  num2str(sinusoid_phase)];
    line_4                       = ['{\itB}  = ' num2str(sinusoid_offset)];
    line_5                       = ['\epsilon   = ' num2str(100*relative_fitting_uncertainty,2) '%'];
    text_x                       = min(indices_minima) + 0.07*(max(indices_minima) - min(indices_minima));
    text_y                       = max(temp)           - 0.29 *(max(temp)           - min(temp));
    text(text_x,text_y, {line_0; line_1; line_2; line_3; line_4; line_5} ,'fontsize', get(gca,'fontsize'))
    ylabel('{\itx}_{minima} (a.u.)')
    xlabel('{\itt}_{minima} (a.u.)')

end 
 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       auxiliary functions                               %                       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [sinusoid_amplitude, sinusoid_n_samples,   ...
          sinusoid_phase,     sinusoid_offset   ] = ...
              fit_semi_sinusoid(minima_time_vector, minima_indices_vector)

% As a starting point for the fit we assume we are dealing with a semi-cycle 
initial_sinusoid_amplitude    = max(minima_time_vector)-min(minima_time_vector)/2;
initial_sinusoid_n_samples    = 2 * (max(minima_indices_vector) - min(minima_indices_vector));
initial_sinusoid_phase        = -pi/2;
initial_sinusoid_offset       = mean(minima_time_vector);
boolean_display_while_fitting = 0;

% performing the fit
coefficients_fit              = fminsearch('SLO_sinusouidal_fit_aux_function', ...
                                [initial_sinusoid_amplitude, ...
                                 initial_sinusoid_n_samples, ...
                                 initial_sinusoid_phase,...
                                 initial_sinusoid_offset], ...
                                 optimset('MaxFunEvals',1000),...
                                 minima_time_vector,...
                                 minima_indices_vector,...
                                 boolean_display_while_fitting); 

sinusoid_amplitude            = coefficients_fit(1);
sinusoid_n_samples            = coefficients_fit(2);
sinusoid_phase                = coefficients_fit(3);
sinusoid_offset               = coefficients_fit(4);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       auxiliary function for removing minima that are too close         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function indices_minima = remove_local_minima_that_are_too_close(y_samples,...
                                                                 indices_minima,...
                                                                 minimum_minima_separation)
    x_samples             = 1 : length(y_samples);
    current_minimum_index = 1;

    while (current_minimum_index < length(indices_minima)) 

        % whenever two consecutive minima are closer than the minimum separation
        while ((current_minimum_index < length(indices_minima) & ...
              ( x_samples(indices_minima(current_minimum_index + 1)) ...
              - x_samples(indices_minima(current_minimum_index    )) ...
              < minimum_minima_separation)))

             % ...find the one with the lower value...
             if y_samples(indices_minima(current_minimum_index)) ...
             >  y_samples(indices_minima(current_minimum_index + 1))

                % ...and remove the other one
                 if (current_minimum_index == 1)
                     indices_minima = indices_minima(2:end);
                 else
                     indices_minima = [indices_minima(1:current_minimum_index - 1),...
                                       indices_minima(  current_minimum_index + 1 : end)];
                 end
             else             
                 % ...and remove the other one
                 if (current_minimum_index + 1 == length(indices_minima))
                     indices_minima = indices_minima(1:end-1);
                 else
                     indices_minima = [indices_minima(1:current_minimum_index),...
                                       indices_minima(  current_minimum_index+2:end)];
                 end
             end
        end
        current_minimum_index = current_minimum_index + 1;
    end   

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    auxiliary functions for detecting the location of the mouse button   % 
%                  down and creating/removing a minimum                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function button_down_on_h_fringes_axis(hObject, eventdata)

    % getting the handles data
    handles                = guidata(hObject);

    % calculating minimum acceptable separation between markers
    fringes_period         = handles.desinusoid_data.horizontal_fringes.fringes_period;
    fringe_period_fraction = handles.desinusoid_data.horizontal_fringes.fringe_period_fraction;

    % figuring out whether another marker should be added/removed
    handles.desinusoid_data.horizontal_fringes.indices_minima = ...
                             add_and_remove_markers_from_plot(...
                             handles.handle_to_horizontal_fringes_markers_plot,...
                             fringes_period * fringe_period_fraction,...
                             mean(handles.desinusoid_data.horizontal_fringes.average_frame,2)');

    % re-fitting the line/sinusoid
    if isfield(handles.desinusoid_data.horizontal_fringes, 'slope')
        [slope, intercept] = perform_linear_fit(....
                                handles.desinusoid_data.horizontal_fringes.indices_minima,...
                                handles.h_fringes_curve_fit_tag,...
                                handles.plot_marker_size);                        

        % adding new data to the structure
        handles.desinusoid_data.horizontal_fringes.slope          = slope;
        handles.desinusoid_data.horizontal_fringes.intercept      = intercept;
        handles.desinusoid_data.horizontal_fringes.fringes_period = 1/slope;
    else
        % re-fitting the sinusoid
        [sinusoid_amplitude, sinusoid_n_samples, sinusoid_phase, sinusoid_offset] = ...
                                perform_sinusoidal_fit(...
                                handles.desinusoid_data.horizontal_fringes.indices_minima,...
                                handles.h_fringes_curve_fit_tag,...
                                handles.plot_marker_size);

        % adding data to the structure
        handles.desinusoid_data.horizontal_fringes.sinusoid_amplitude = sinusoid_amplitude;
        handles.desinusoid_data.horizontal_fringes.sinusoid_n_samples = sinusoid_n_samples;
        handles.desinusoid_data.horizontal_fringes.sinusoid_phase     = sinusoid_phase;
        handles.desinusoid_data.horizontal_fringes.sinusoid_offset    = sinusoid_offset;
    end

    % updating data structure
    guidata(hObject,handles)

end 



function button_down_on_v_fringes_axis(hObject, eventdata)

    % getting the handles data
    handles                       = guidata(hObject);

    % calculating minimum acceptable separation between markers
    fringes_period                = handles.desinusoid_data.vertical_fringes.fringes_period;
    fringe_period_fraction        = handles.desinusoid_data.vertical_fringes.fringe_period_fraction;

    % figuring out whether another marker should be added/removed
    handles.desinusoid_data.vertical_fringes.indices_minima = add_and_remove_markers_from_plot(...
                                    handles.handle_to_vertical_fringes_markers_plot,...
                                    fringes_period * fringe_period_fraction,...
                                    mean(handles.desinusoid_data.vertical_fringes.average_frame,1));

    % re-fitting the line/sinusoid
    if isfield(handles.desinusoid_data.vertical_fringes, 'slope')
        [slope, intercept] = perform_linear_fit(....
                                handles.desinusoid_data.vertical_fringes.indices_minima,...
                                handles.v_fringes_curve_fit_tag,...
                                handles.plot_marker_size);

        % adding new data to the structure
        handles.desinusoid_data.vertical_fringes.slope            = slope;
        handles.desinusoid_data.vertical_fringes.intercept        = intercept;
        handles.desinusoid_data.horizontal_fringes.fringes_period = 1/slope;
    else
        % re-fitting the sinusoid
        [sinusoid_amplitude, sinusoid_n_samples, sinusoid_phase, sinusoid_offset] = ...
                                perform_sinusoidal_fit(...
                                handles.desinusoid_data.vertical_fringes.indices_minima,...
                                handles.v_fringes_curve_fit_tag,...
                                handles.plot_marker_size);

        % adding data to the structure
        handles.desinusoid_data.vertical_fringes.sinusoid_amplitude = sinusoid_amplitude;
        handles.desinusoid_data.vertical_fringes.sinusoid_n_samples = sinusoid_n_samples;
        handles.desinusoid_data.vertical_fringes.sinusoid_phase     = sinusoid_phase;
        handles.desinusoid_data.vertical_fringes.sinusoid_offset    = sinusoid_offset;
    end

    % updating data structure
    guidata(hObject,handles)
end



function x_markers = add_and_remove_markers_from_plot(handle_to_plot, ...
                                                      min_h_separation_between_markers,...
                                                      y_samples)
    % getting the markers from the plot
    x_markers          = get(handle_to_plot, 'xdata');
    y_markers          = get(handle_to_plot, 'ydata');

    % getting the current point on the plot
    current_point      = get(gca,'CurrentPoint');
    x_current_point    = round(current_point(1,1));
    y_current_point    = round(current_point(1,2));

    % finding the neares marker to the current point
    [distance_to_nearest_marker, nearest_marker_index] = min(abs(x_markers - x_current_point));

    % if close to a marker, then remove it
    if distance_to_nearest_marker < min_h_separation_between_markers / 2
        if nearest_marker_index == 1        
            x_markers  = x_markers(2:end);
            y_markers  = y_markers(2:end);

        elseif nearest_marker_index == length(x_markers)
            x_markers  = x_markers(1:end-1);
            y_markers  = y_markers(1:end-1);

        else
            x_markers  = [x_markers(1:nearest_marker_index-1), x_markers(nearest_marker_index+1:end)];
            y_markers  = [y_markers(1:nearest_marker_index-1), y_markers(nearest_marker_index+1:end)];
        end

    else
        % finding the local minima
        indices_minima = [];
        x              = 1:length(y_samples);

        % finding local minima
        for k = 2 : length(y_samples) - 1, 
            if ((y_samples(k)   - y_samples(k-1) <= 0) & ...
                (y_samples(k+1) - y_samples(k)> 0))
                indices_minima(end + 1) = k;
            end
        end

        % finding the nearest to the current point    
        [not_used, nearest_minimum_index] = min(abs(indices_minima - x_current_point));
        x_markers(end + 1)                = indices_minima(nearest_minimum_index);                                           
        y_markers                         = y_samples(x_markers);
    end

    % sorting the markers and removing repeated ones
    [x_markers_temp, sorting_indices]     = sort(x_markers);
    y_markers_temp                        = y_markers(sorting_indices);

    % removing repeated frames
    x_markers                             = x_markers_temp(1);
    y_markers                             = y_markers_temp(1);

    for k = 2 : length(x_markers_temp)
        if x_markers_temp(k) ~= x_markers_temp(k-1)
            x_markers(length(x_markers)+1) = x_markers_temp(k);
            y_markers(length(y_markers)+1) = y_markers_temp(k);
        end
    end

    set(handle_to_plot,'xdata',x_markers, 'ydata',y_markers)
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
    
