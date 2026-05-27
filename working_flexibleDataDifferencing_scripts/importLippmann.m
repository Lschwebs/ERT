% Lena J. Schwebs
% Created on: 06/07/2024
% Updated on: 09/30/2024
% Adapted from Dr. Andrew D. Parsekian 'importLip.m'
% Import data from Lippmann *.tx0 file

function [data, CR] = importLippmann(fLoc, num_electrodes)

%% load file into working variable
fname = fLoc; % file name
fID = fopen(fname,'r'); % open and read file
fdat = textscan(fID, '%s', 'Delimiter', '\n'); % load file contents into working variable
fclose(fID) % close file
fdat = fdat{:}; % reshape into single column vector
fprintf('Length of data file = %d \n', length(fdat))

%% find and define Contact Resistance data array
CR_start_point = ~cellfun(@isempty, strfind(fdat, '* # R')); % search for beginning of data block
CR_start_row = find(CR_start_point == 1) + 1; % determine starting row
CR_end_row = find(CR_start_point == 1) + num_electrodes; % define ending row
CRStr = string(fdat(CR_start_row:CR_end_row)); % create string array of contact resistance section in Lippmann file

    
for j = 1:length(CRStr)
    tempStr = strsplit(CRStr(j)); % split string for row j in CRStr
    if ~contains(CRStr(j), "->") && any(regexp(CRStr(j),'[0-9]')) && tempStr(2) ~= "" % get CR value for actual measurements only
        CRdata(j,1:2) = tempStr(1:2);
    else
        CRdata(j,1:2) = [tempStr(1) 'NA']; % transmitter overload and blank measurements set to NA
    end
end

CR(:,1) = str2double(CRdata(:,1)); % add electrode numbers to contact resistance array
CR(:,2) = str2double(CRdata(:,2)); % add contact resistance to contact resistance array

fprintf('Length of contact resistance test = %d \n', length(CR))

%% find and define raw data array
start_point = ~cellfun(@isempty, strfind(fdat, '* num')); % search for beginning of data block
start_row = find(start_point == 1) + 2; % determine starting row
end_row = length(fdat); % define ending row
rawdata = split(fdat(start_row:end_row)); % create array with raw data block
fprintf('Length of raw data array = %d \n', length(rawdata))

%% convert numeric text to numbers for cols 1:4 (A, B, M, N) and col 7/6 (V/I) and col 11 (rho)
for j = 1:11 % columns 1:11
    for i = 1:length(rawdata) % # of rows
       if strcmpi(rawdata(i, j), '-') == 1
           dt(i, j) = NaN;
       else
           dt(i, j) = str2double(rawdata(i,j));
       end
    end
end

dt(:, 12) = dt(:, 7) ./ dt(:, 6); % calculate resistance

data = [dt(:,2:5) dt(:,12) dt(:,11)];

end