% Lena J. Schwebs
% Created on: 09/27/2024
% Last updated: 03/10/2025

% Execute R2 inversion for Lippmann measurement
% MUST have: R2.in, protocol.dat, mesh.dat 
% Workflow: Import and preprocess raw data file, write protocol.dat, 
% write mesh.dat, write R2.in, start R2 inversion

%% USER DEFINED INPUT
% data file and preprocessing parameters
fLoc = '2024-05-29_16-26-47.tx0'; % raw data file
minVal = 0; % minimum resistance value allowed
errRecip = 0.05; % reciprocal error threshold in DECIMAL units
errStack = 10; % stacking error threshold in TENTHS of a percent 

% INVERSION parameters
numel = 4025; % number of elements, first val from mesh file
reg_mode = 0;    % regularixation mode, need to use 1 for O&L doi calc
alpha_s = 1;    % regularization parameter, use >1 for O&L
alpha_aniso = 1; % alphaaniso > 1 for smoother horizontal models
                 % alphaaniso = 1 for isotropic smoothing
                 % alphaaniso < 1 for smoother vertical models
a_wgt = 0.0; % calcualted from measured data errors
b_wgt = 0.0; % calculate from measured data errors
num_electrodes = 128;   % number of electrodes in the survey
elecSep = 1;    % electrode separation in meters
res_meter = 'Lippmann'; % Lippmann, SuperSting, DAS1
full_recips = 'yes'; % yes = full reciprocals measured, no = partial reciprocals + stacking errors

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% preprocess raw data and write R2.in
switch res_meter % use specified resistivity meter import function
            case 'Lippmann'
                imDat = importLippmann(fLoc); 
            case 'SuperSting'
                imDat = importSS(fLoc);
            case 'DAS1'
                imDat = importDAS1(fLoc); 
            otherwise
                disp('Invalid resistivity meter')
end

survey_type = 1; % 1 = starting or single survey

switch full_recips
            case 'yes'
                [data, gmean] = preproc_fr_Pwl(fLoc, imDat, minVal, errRecip, survey_type); % preprocess raw data 
        
            case 'no'
                [data, gmean] = preproc_SSerr_Pwl(fLoc, imDat, minVal, errRecip, errStack, survey_type); % preprocess raw data 
end

startRes = gmean; % geometric mean of apparent resistivities 
writeR2in(startRes, 1, numel, reg_mode, alpha_s, alpha_aniso, num_electrodes, a_wgt, b_wgt) % write R2.in

%% execute R2
system('R2.exe')

%% move files
datfiles = dir([pwd '\*.*_res.dat']);
vtkfiles = dir([pwd '\*.*_res.vtk']);

for i = 1:length(datfiles)
    movefile([pwd '\' datfiles(i).name],[pwd '\results\ref\' datfiles(i).name]);
    movefile([pwd '\' vtkfiles(i).name],[pwd '\results\ref\' vtkfiles(i).name]);
end

movefile([pwd '\f001_res.dat'],[pwd '\results\f001_res.dat']);
movefile([pwd '\f001_res.vtk'],[pwd '\results\f001_res.vtk']);
movefile([pwd '\f001_sen.dat'],[pwd '\results\f001_sen.dat']);
movefile([pwd '\f001_err.dat'],[pwd '\results\f001_err.dat']);
movefile([pwd '\R2.out'],[pwd '\results\R2out\R2.out']);
movefile([pwd '\R2.in'],[pwd '\results\R2in\R2.in']);
movefile([pwd '\protocol.dat'],[pwd '\results\protocol\protocol.dat']);
movefile([pwd '\electrodes.dat'],[pwd '\results\ref\electrodes.dat']);
movefile([pwd '\electrodes.vtk'],[pwd '\results\ref\electrodes.vtk']);
copyfile([pwd '\mesh.dat'],[pwd '\results\ref\mesh.dat']);
