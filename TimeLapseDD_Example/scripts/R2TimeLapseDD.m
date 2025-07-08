% Lena J. Schwebs
% Created on: 09/27/2024
% Last updated: 03/10/2025

% Execute R2 inversion for Lippmann measurement
% MUST have: R2.in, protocol.dat, mesh.dat 
% Workflow: Import and preprocess raw data file, write protocol.dat, 
% write mesh.dat, write R2.in, start R2 inversion

%% USER DEFINED INPUT
% data files and preprocessing parameters
files = dir(fullfile('data/', '*.tx0')); % find raw data files
minVal = 0; % minimum resistance value allowed
errRecip = 0.05; % reciprocal error threshold in DECIMAL units
errStack = 10; % stacking error threshold in TENTHS of a percent 

% INVERSION parameters
numel = 4025; % number of elements, first val from mesh file
reg_modeSTART = 1;    % regularization mode, need to use 1 for O&L doi calc
reg_modeTL = 2;
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

%% STARTING MODEL: preprocess raw data, write R2.in, and invert 
fLoc = files(1).name;
disp('preprocessing the initial dataset')
survey_type = 1; % 1 = starting or single survey

switch res_meter % use specified resistivity meter import function
    case 'Lippmann'
        imDat = importLippmann(fLoc); 
    case 'SuperSting'
        fprintf('code TBD')
    case 'DAS1'
        imDat = importDAS1(fLoc); 
    otherwise
        disp('Invalid resistivity meter')
end

switch full_recips
            case 'yes'
                [dataStart, gmean] = preproc_fr_Pwl(fLoc, imDat, minVal, errRecip, survey_type, dataStart); % preprocess raw data 
        
            case 'no'
                [dataStart, gmean] = preproc_SSerr_Pwl(fLoc, imDat, minVal, errRecip, errStack, survey_type, dataStart); % preprocess raw data 
        end

writeR2in(gmean, 1, numel, reg_modeSTART, alpha_s, alpha_aniso, num_electrodes, a_wgt, b_wgt) % write R2.in

disp('inverting the background data')
system('R2.exe')
copyfile([pwd '\f001_res.dat'],[pwd '\start_res.dat']);
movefile([pwd '\f001_res.dat'],[pwd '\results\start_res.dat']);
movefile([pwd '\f001_res.vtk'],[pwd '\results\start_res.vtk']);
movefile([pwd '\f001_err.dat'],[pwd '\results\start_err.dat']);
movefile([pwd '\R2.out'],[pwd '\results\R2out\R2_starting.out']);
movefile([pwd '\R2.in'],[pwd '\results\R2in\R2_starting.in']);
movefile([pwd '\protocol.dat'],[pwd '\results\protocol\protocol_starting.dat']);

%% Time-lapse inversion (data differencing)
survey_type = 2; % = 2 for time lapse
for i = 2:length(files)
    % preprocess raw data
    fLoc = files(i).name;

    switch res_meter % use specified resistivity meter import function
        case 'Lippmann'
            imDat = importLippmann(fLoc); 
        case 'SuperSting'
            fprintf('code TBD')
        case 'DAS1'
            imDat = importDAS1(fLoc); 
        otherwise
            disp('Invalid resistivity meter')
    end

    switch full_recips
            case 'yes'
                [data, gmean] = preproc_fr_Pwl(fLoc, imDat, minVal, errRecip, survey_type); % preprocess raw data 
        
            case 'no'
                [data, gmean] = preproc_SSerr_Pwl(fLoc, imDat, minVal, errRecip, errStack, survey_type); % preprocess raw data 
        end

    % write R2.in
    startModel = 'start_res.dat';
    writeR2in(startModel, 0, numel, reg_modeTL, alpha_s, alpha_aniso, num_electrodes, a_wgt, b_wgt) % write R2.in

    fprintf('inverting dataset %0.f/%0.f\n', i-1, length(files)-1)
    system('R2.exe')

    if i < 10
        formatSpec = 'f00%s';
        num = num2str(i-1);
    elseif i >= 10 && i < 100
        formatSpec = 'f0%s';
        num = num2str(i-1);
    else
        formatSpec = 'f%s';
        num = num2str(i-1);
    end

    str = sprintf(formatSpec, num);

    % delete iteration files
    datfiles = dir([pwd '\*.*_res.dat']);
    vtkfiles = dir([pwd '\*.*_res.vtk']);

    for j = 1:length(datfiles)
        delete([pwd '\' datfiles(j).name]);
        delete([pwd '\' vtkfiles(j).name]);
    end
   
    % move files to results folder with correct number
    movefile([pwd '\f001_res.dat'],[pwd strcat('\results\', str, '_res.dat')]);
    movefile([pwd '\f001_diffres.dat'],[pwd strcat('\results\', str, '_diffres.dat')]);
    movefile([pwd '\f001_res.vtk'],[pwd strcat('\results\', str, '_res.vtk')]);
    movefile([pwd '\f001_sen.dat'],[pwd strcat('\results\', str, '_sen.dat')]);
    movefile([pwd '\f001_err.dat'],[pwd strcat('\results\', str, '_err.dat')]);
    movefile([pwd '\R2.out'],[pwd strcat('\results\R2out\', str, '_R2.out')]);
    movefile([pwd '\R2.in'],[pwd strcat('\results\R2in\', str, '_R2.in')]);
    movefile([pwd '\protocol.dat'],[pwd strcat('\results\protocol\', str, '_protocol.dat')]);
end

%% move some remaining files around
movefile([pwd '\electrodes.dat'],[pwd '\results\ref\electrodes.dat']);
movefile([pwd '\electrodes.vtk'],[pwd '\results\ref\electrodes.vtk']);
copyfile([pwd '\mesh.dat'],[pwd '\results\ref\mesh.dat']);
