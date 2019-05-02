% scaleCorrection.m
% Allows user to input trial lens, original scaling, and desired scaling to
% calculate the percentage by which montage needs to be scaled.
% Calculations and all original data stored in a [acronym]_scaling.txt file saved in the same
% folder as this script.

clear all;
close all;

code = inputdlg('Input patient code and imaging date in the following format: XXXXXX_MM_DD_YYYY (i.e. 10001R_02_25_2011)');
choice = questdlg('Which AOSLO system were these images taken with?', 'AOSLO System', 'AOSLOI','AOSLOII','AOSLOIII','AOSLOIII');

switch choice
    case 'AOSLOI'
        system = 1;
    case 'AOSLOII'
        system = 2;
    case 'AOSLOIII'
        system = 3;
end

sys_ds = 0;

% SYSTEM PRESCRIPTION
if system == 1
    sys_dc = -0.75;
    sys_axis = 90;
elseif system == 2
    choice = questdlg('Were these images acquired AFTER Feb 2011?', 'Prompt', 'Yes','No','No');
    switch choice
        case 'Yes'
            sys_dc = 0;
            sys_axis = 0;
        case 'No'
            sys_dc = -1.00;
            sys_axis = 90;
    end
else
    sys_dc = 0;
    sys_axis = 0;
end

% ORIGINAL SCALING
prompt = {'Enter original x-scale:','Enter original y-scale:'};
dlg_title = 'Original';
num_lines = 1;
answer = inputdlg(prompt,dlg_title,num_lines);
xscale = str2num(answer{1});
yscale = str2num(answer{2});

% DESIRED SCALING
prompt = {'Desired x-scale:','Desired y-scale:'};
dlg_title = 'Final';
num_lines = 1;
def = {'420','420'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
final_xscale = str2num(answer{1});
final_yscale = str2num(answer{2});

% TRIAL LENS
answer = inputdlg('Input spherical (ds) lens used for patient:');
trial_ds = str2num(answer{1});
answer = inputdlg('Input cylindrical lens (dc) used:');
trial_dc = str2num(answer{1});
answer = inputdlg('Input axis for cyl. lens:');
trial_axis = str2num(answer{1});

% SYSTEM FOURIER
sf_M = sys_ds + (sys_dc + 0.000001)/2;
sf_J0 = -0.5*(sys_dc + 0.000001)*cos(2*pi*sys_axis/180);
sf_J45 = -0.5*(sys_dc + 0.000001)*sin(2*pi*sys_axis/180);

% TRIAL LENS FOURIER
tf_M = trial_ds + (trial_dc + 0.000001)/2;
tf_J0 = -0.5*(trial_dc + 0.000001)*cos(2*pi*trial_axis/180);
tf_J45 = -0.5*(trial_dc + 0.000001)*sin(2*pi*trial_axis/180);

% DIFFERENCE
diff_M = tf_M - sf_M; 
diff_J0 = tf_J0 - sf_J0; 
diff_J45 = tf_J45 - sf_J45; 

% Subject's Correction
subj_dc = -2*sqrt(diff_J0*diff_J0 + diff_J45*diff_J45);
subj_ds = diff_M - subj_dc/2;
if diff_J0 == 0
    subj_axis = 0;
else 
    subj_axis = 0.5*atan(diff_J45/diff_J0)*180/pi;
end

vert_power = subj_ds + subj_dc*(sin((pi/180)*90-subj_axis)*sin((pi/180)*90-subj_axis));
horiz_power = subj_ds + subj_dc*(sin((pi/180)*subj_axis)*sin((pi/180)*subj_axis));
sph_equiv = subj_ds + (subj_dc/2);

% Spectacle Magnification
mag_horiz = 1/(1-0.014*horiz_power);
mag_vert = 1/(1-0.014*vert_power);

% Adjusted Scale
adj_xscale = xscale/mag_horiz;
adj_yscale = yscale/mag_vert;

% Final scaling parameters
x_percent = final_xscale/adj_xscale*100;
y_percent = final_yscale/adj_yscale*100;


filename = [code{1} '_scaling.txt'];
fid = fopen(filename,'wt'); 
fprintf(fid,'%s\t%i','AOSLO System:',system);
fprintf(fid,'\n\n%s\t%i%s%i%s%s%i','Patient''s trials lens:',trial_ds,' ds ',trial_dc,' dc ','x ',trial_axis);
fprintf(fid,'\n\n%s\t%i\n%s\t%i\n\n%s\t%i\n%s\t%i\n\n%s\t%.2f\n%s\t%.2f','Original X-scale:',xscale,'Original Y-scale:',yscale, 'Final X-scale:', final_xscale, 'Final Y-scale:', final_yscale, 'Width Conversion (%):', x_percent,'Height Conversion (%):', y_percent);
fprintf(fid,'\n\n\n\n%s','To convert montage to final scaling, go to Photoshop -> Image -> Image Size. Change dimension units from pixels to percent, and input conversion values for width and height. When saving file, append final scaling values to end of montage name (i.e. 10001R_Final_2_21_2011_420x420.tif)');
fclose(fid);


    
    
    
    
    
    
    