[fname pname] = uigetfile('*.*','Please select the file with conespacing data');
inData= readtable(strcat(pname,fname));

%get string portion with coords
coordlist = cellfun(@(fName)strsplit(fName(strfind(fName,'ref')+7:strfind(fName,'_deg')-1),'_'),inData.Filename,'UniformOutput',false);

try
    inData.x = cellfun(@(splitCoords)splitCoords{2},coordlist,'UniformOutput',false);
    inData.y = cellfun(@(splitCoords)splitCoords{3},coordlist,'UniformOutput',false);
catch
    inData.x = cellfun(@(splitCoords)splitCoords{1},coordlist,'UniformOutput',false);
    inData.y = cellfun(@(splitCoords)splitCoords{2},coordlist,'UniformOutput',false);

end
if strcmpi(fname(6),'R')
    inData.eye(1:size(inData,1))="Right";
elseif strcmpi(fname(6),'L')
    inData.eye(1:size(inData,1))="Left";
else
    opts = ["Right","Left"];
    eyeChoice = menu('Select an eye',opts);
    inData.eye(1:size(inData,1))=opts(eyeChoice);
end

writetable(inData,strcat(pname,strtok([fname(1:end-4),'_prepped'],'.'),'.xls'),'Sheet','raw_prepped');