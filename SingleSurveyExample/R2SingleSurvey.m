% Lena J. Schwebs
% Created on: 09/27/2024
% Last updated: 10/07/2024

% Execute R2 inversion for Lippmann measurement
% MUST have: R2.in, protocol.dat, mesh.dat 
% Workflow: Import and preprocess raw data file, write protocol.dat, 
% write mesh.dat, write R2.in, start R2 inversion

%% USER DEFINED INPUT
% data file and preprocessing parameters
fLoc = '2024-05-29_16-26-47.tx0'; % raw data file
minVal = 0; % minimum resistance value allowed
errRecip = 0.05; % reciprocal error threshold in DECIMAL units

% INVERSION parameters
numel = 54744; % number of elements, first val from mesh file
reg_mode = 0;    % regularixation mode, need to use 1 for O&L doi calc
alpha_s = 1;    % regularization parameter, use >1 for O&L
a_wgt = 0.01; % calcualted from measured data errors
b_wgt = 0.02; % calculate from measured data errors
num_electrodes = 128;   % number of electrodes in the survey
elecSep = 1;    % electrode separation in meters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% preprocess raw data and write R2.in
[data, gmean] = preprocLipp(fLoc, minVal, errRecip); % preprocess raw data
startRes = gmean; % geometric mean of apparent resistivities 
writeR2in(startRes, numel, reg_mode, alpha_s, num_electrodes, a_wgt, b_wgt) % write R2.in

%% execute R2
system('R2.exe')


