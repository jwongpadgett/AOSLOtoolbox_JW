clearvars; close all;
[fname, pname] = uigetfile('*.AVI;*.avi', 'Select stabilized AVI files for adding', 'MultiSelect', 'on');

[sfname, spname] = uigetfile('*.bmp*', 'Select stimulus');
if (iscell(fname)==0)
    a=fname;
    fname=cell(1);
    fname{1}=a;
end
nummovies = size(fname,2);

for movienum = 1:nummovies
    RemoveStimuli([pname fname{movienum}],[spname,sfname])
end