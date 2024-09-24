% Lena J. Schwebs
% Created: 09/23/2024
% Updated:

% Determine best reciprocal error % to filter at

clear; close all; clc

%% load files
files = dir(fullfile('Good', '*.tx0')) ;    % get all dat files in the folder 
D = {};

for i = 1:length(files)
    D{i} = preprocLipp(files(i).name, 0, 0.1); % load raw data array
end

%% find percent remaining
nm = 2230; % number of measurements in raw data file
pRem = [];

for i = 1:length(files)
    pRem(i) = 100 .* length(D{1,i}) ./ (nm ./ 2); % percent of measurements remaining 
end