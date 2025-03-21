% Lena J. Schwebs
% Created on: 06/07/2024
% Updated on: 03/08/2025
% Adapted from Dr. Andrew D. Parsekian 'importLip.m'
% Import data from Lippmann *.tx0 file

function data = importLippmann(fLoc)

%% load file into working variable
fname = fLoc; % file name
fID = fopen(fname,'r'); % open and read file
fdat = textscan(fID, '%s', 'Delimiter', '\n'); % load file contents into working variable
fclose(fID) % close file
fdat = fdat{:}; % reshape into single column vector
fprintf('Length of data file = %d \n', length(fdat))

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

% calculate resistance
dt(:, 12) = dt(:, 7) ./ dt(:, 6);

data = [dt(:,2:5) dt(:,12) dt(:,11)];

end