% Lena J. Schwebs
% Created on: 03/08/2025
% Updated on: 09/30/2024
% Adapted from Dr. Andrew D. Parsekian 'importAGI.m'
% Import data from Lippmann *.tx0 file

%function data = importSS(fLoc)
fLoc = 'MRSPA5C.stg';
%% load file into working variable
fname = fLoc; % file name
fID = fopen(fname,'r'); % open and read file
fdat = textscan(fID, '%s', 'Delimiter', '\n'); % load file contents into working variable
fclose(fID) % close file
fdat = fdat{:}; % reshape into single column vector
fprintf('Length of data file = %d \n', length(fdat))

%% find and define raw data array
start_point = ~cellfun(@isempty, strfind(fdat, 'Unit')); % search for beginning of data block
start_row = find(start_point == 1) + 1; % determine starting row
end_row = length(fdat); % define ending row
rawdata = split(fdat(start_row:end_row), ','); % create array with raw data block
fprintf('Length of raw data array = %d \n', length(rawdata))

%% convert numeric text to numbers 
for j = 1:21 % columns 1:21
    for i = 1:length(rawdata) % # of rows
      dt(i, j) = str2double(rawdata(i,j));
    end
end

data = [dt(:,10) dt(:,13) dt(:,16) dt(:,19) dt(:,5) dt(:,6) dt(:,8)]; % ABMN, V/I, % error in tenths of percent, app Res

%end