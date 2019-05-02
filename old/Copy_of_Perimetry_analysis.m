% Microperimetry thresholds export to Excel file with RGB vals for color
% mapping to overlays. 
clear all; close all;

subjectID = 'JT_L'; % update here - must be the same ID as in threshold_data.mat file. 

% columns are data folder, retinal location
% script adds thresholds and RGB value for heat map 
% to last columns and exports to excel file
datacells = {'D:\Video_Folder\JT_L\1_17_2018_14_35_14' 'Left Fovea Loc 6'   % update here - use same formatting as shown here in a new line 
    % First '' should be the name of a folder with the threshold_data.mat
    % file in it, second '' is the eye/retinal location. 
    '7_31_2017_12_32_17' 'Left Fovea Loc 1'  
    '7_31_2017_12_32_17' 'Left Fovea Loc 1'  
    '7_31_2017_12_32_17' 'Left Fovea Loc 1'  
    '7_31_2017_12_32_17' 'Left Fovea Loc 1'  
    };

dirpath = 'D:\Video_Folder'; % update here - the parent folder where all of the data folders are (videos and .mat files) 
addpath('D:\codetotransfer\AOMcontrol_V3_2_cleaned\Psychtoolbox-3.0.9\Psychtoolbox\Quest') % update here - folder that has QuestMean.m function 
 
thresholds = [];
for i = 1:size(datacells,1)
    filepath = [dirpath,filesep,char(datacells(i,1)),filesep,subjectID,'_',char(datacells(i,1)),'_threshold_data.mat'];
    load(filepath);
    thresholds(i) = QuestMean(q);
    clear q
end

datacells(:,end+1) = num2cell(thresholds');
thresholds(thresholds<0) = 0;
thresholds(thresholds>1) = 1;
datacells(:,end+1) = num2cell(thresholds');

cmap = autumn;
cmap = flipud(cmap);
ng = 20;
cmap2 = [[linspace(0,1,ng)',ones(ng,1) zeros(ng,1)];cmap];

idx = round(thresholds*length(cmap2));
RGBs = [cmap2(idx,:)];
c=figure; colormap(cmap2); colorbar
saveas(c,'Colorbar','tif')
saveas(c,'Colorbar','eps')

datacells(:,end+1:end+3) = num2cell(RGBs);

xlswrite([subjectID, '_microperimetry'],datacells) 