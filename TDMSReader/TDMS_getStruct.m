function [output,metaStruct] = TDMS_getStruct(filePath,structVersion,readOptions,structConvOptions)
%TDMS_getStruct  A wrapper for simplifying data retrieval from TDMS_readTDMSFile
%
%   output = TDMS_getStruct(*filePath,*structVer,*readOptions,*structConvOptions)
%
%   OPTIONAL INPUTS
%   ===============================================
%   filePath          : (default prompts for file)
%   structVersion     : (default ??, see code), determines which struct conversion
%                       function to use
%   readOptions       : (default {}), gets passed into TDMS_readTDMSFile
%   structConvOptions : (default {}), gets passed into conversion function
%
%   See Also: TDMS_readTDMSFile, 
%             TDMS_dataToGroupChanStruct_v1,
%             TDMS_dataToGroupChanStruct_v2,
%             TDMS_dataToGroupChanStruct_v3,
%             TDMS_dataToGroupChanStruct_v4

%LOCAL CONSTANTS
DEFAULT_STRUCT_VERSION = 4;  %Feel free to change me if you'd like something different
%This is particular to my lab, although you might prefer 3
CONV_RANGE = [1 6];

%filePath input handling
if nargin < 1 || isempty(filePath)
   [filename,pathname] = uigetfile({'*.tdms'},'Choose TDMS file to read'); 
   if isequal(filename,0) || isequal(pathname,0) 
      return
   else
      filePath = fullfile(pathname,filename); 
   end
end

%structVer handling
if nargin < 2 || isempty(structVersion)
    structVersion = DEFAULT_STRUCT_VERSION;
end

%readOptions
if nargin < 3 || isempty(readOptions)
    readOptions = {};
end

%structConvOptions
if nargin < 4 || isempty(structConvOptions)
    structConvOptions = {};
end

if ~isnumeric(structVersion) || structVersion < CONV_RANGE(1) || structVersion > CONV_RANGE(2)
    error('The output structure version must be numeric and be between %d & %d',CONV_RANGE(1),CONV_RANGE(2))
end


%ACTUAL FILE READING
%==============================================================
[temp,metaStruct] = TDMS_readTDMSFile(filePath,readOptions{:});

%POST PROCESSING
%==============================================================
if (structVersion == 6 && length(temp.data) == 28) %must be PITA
    structVersion = 5;
end
switch structVersion
    case 1
        output = TDMS_dataToGroupChanStruct_v1(temp,structConvOptions{:});
    case 2
        output = TDMS_dataToGroupChanStruct_v2(temp,structConvOptions{:});
    case 3
        output = TDMS_dataToGroupChanStruct_v3(temp,structConvOptions{:});
    case 4
        output = TDMS_dataToGroupChanStruct_v4(temp,structConvOptions{:});
    case 5
        time = temp.propValues{1,3}{1,3}*(1:1:temp.numberDataPointsRaw(end))';
        data = [time cell2mat(temp.data(metaStruct.isChan)')'];
        varnames = ['Time' temp.chanNames{1}];
        output = array2table(data, 'VariableNames', varnames);
    case 6
        time_id=find(metaStruct.isChan,1,'first');
        t=temp.data{time_id}; 
        t={t(1:length(temp.data{time_id+1}))};
        temp.data(time_id) = t;
        output.DATA = array2table(cell2mat(temp.data(metaStruct.isChan)')', 'VariableNames', temp.chanNames);
        propV = temp.propValues{1,1};
        propN = strrep(temp.propNames{1,1}, ' ', '');
        output.Properties = cell2table(propV, 'VariableNames', propN);
end