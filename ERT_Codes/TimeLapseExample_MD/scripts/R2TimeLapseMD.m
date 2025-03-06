% Lena J. Schwebs
% Created on: 10/15/2024
% Last updated: 10/28/2024

% Execute R2 inversion for Lippmann measurement
% MUST have: R2.in, protocol.dat, mesh.dat 
% Workflow: Import and preprocess raw data file, write protocol.dat, 
% write mesh.dat, write R2.in, start R2 inversion

%% USER DEFINED INPUT
% data files and preprocessing parameters
files = dir(fullfile('data/', '*.tx0')); % find raw data files
minVal = 0; % minimum resistance value allowed
errRecip = [0.05 0.1 0.05]; % reciprocal error threshold in DECIMAL units

% INVERSION parameters
numel = 4025; % number of elements, first val from mesh file
reg_modeSTART = 1;    % regularization mode, need to use 1 for O&L doi calc
reg_modeTL = 1;
alpha_s = 2;    % regularization parameter, use >1 for O&L
alpha_aniso = 2; % alphaaniso > 1 for smoother horizontal models
                 % alphaaniso = 1 for isotropic smoothing
                 % alphaaniso < 1 for smoother vertical models
a_wgt = 0.0; % calcualted from measured data errors
b_wgt = 0.0; % calculate from measured data errors
num_electrodes = 128;   % number of electrodes in the survey
elecSep = 1;    % electrode separation in meters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% STARTING MODEL: preprocess raw data, write R2.in, and invert 
for i = 1:length(files)
    % preprocess raw data
    fLoc = files(i).name;

    if i == 1
        disp('preprocessing the initial dataset')
        [dataStart, gmean] = preprocLipp_Pwl(fLoc, minVal, errRecip(1)); % preprocess raw data 
        writeR2in(gmean, 1, numel, reg_modeSTART, alpha_s, alpha_aniso, num_electrodes, a_wgt, b_wgt) % write R2.in
    else
        startModel = 'start_res.dat';
        [data, gmean] = preprocLipp_Pwl(fLoc, minVal, errRecip(i));
        writeR2in(startModel, 0, numel, reg_modeTL, alpha_s, alpha_aniso, num_electrodes, a_wgt, b_wgt) % write R2.in
    end

    fprintf('inverting dataset %0.f/%0.f\n', i-1, length(files)-1)
    system('R2.exe')

    copyfile([pwd '\f001_res.dat'],[pwd '\start_res.dat']);
    
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

    datfiles = dir([pwd '\*.*_res.dat']);
    vtkfiles = dir([pwd '\*.*_res.vtk']);

    for j = 1:length(datfiles)
        delete([pwd '\' datfiles(j).name]);
        delete([pwd '\' vtkfiles(j).name]);
    end

    movefile([pwd '\f001_res.dat'],[pwd strcat('\results\', str, '_res.dat')]);
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
