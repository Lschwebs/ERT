% Lena J. Schwebs
% Created on: 09/27/2024
% Last updated: 10/08/2024

% Execute R2 inversion for Lippmann measurement
% MUST have: R2.in, protocol.dat, mesh.dat 
% Workflow: Import and preprocess raw data file, write protocol.dat, 
% write mesh.dat, write R2.in, start R2 inversion

clear all; close all; clc;
%% USER DEFINED INPUT
% data files and preprocessing parameters
files = dir(fullfile('data/', '*.tx0')); % find raw data files
minVal = 0; % minimum resistance value allowed
errRecip = [0.05 0.1 0.05]; % reciprocal error threshold in DECIMAL units

% INVERSION parameters
numel = 4025; % number of elements, first val from mesh file
reg_modeSTART = 1;    % regularization mode, need to use 1 for O&L doi calc
reg_modeTL = 2;
alpha_s = 1;    % regularization parameter, use >1 for O&L
a_wgt = 0.01; % calcualted from measured data errors
b_wgt = 0.02; % calculate from measured data errors
num_electrodes = 128;   % number of electrodes in the survey
elecSep = 1;    % electrode separation in meters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% STARTING MODEL: preprocess raw data, write R2.in, and invert 
fLoc = files(1).name;
disp('preprocessing the initial dataset')
[dataStart, gmean] = preprocLipp(fLoc, minVal, errRecip(1)); % preprocess raw data 

writeR2in(gmean, 1, numel, reg_modeSTART, alpha_s, num_electrodes, a_wgt, b_wgt) % write R2.in

disp('inverting the background data')
system('R2.exe')

copyfile([pwd '\f001_res.dat'],[pwd '\start_res.dat']);
copyfile([pwd '\f001_res.dat'],[pwd '\results\start_res.dat']);
copyfile([pwd '\f001_res.vtk'],[pwd '\results\start_res.vtk']);
copyfile([pwd '\f001_err.dat'],[pwd '\results\start_err.dat']);
copyfile([pwd '\R2.out'],[pwd '\results\R2out\R2_starting.out']);
copyfile([pwd '\R2.in'],[pwd '\results\R2in\R2_starting.in']);
copyfile([pwd '\protocol.dat'],[pwd '\results\protocol\protocol_starting.dat']);

%% Time-lapse inversion (data differencing)
for i = 2:length(files)
    % preprocess raw data
    fLoc = files(i).name;
    [data, gmean] = preprocLippTL(fLoc, minVal, errRecip(i), dataStart);

    % write R2.in
    startModel = 'start_res.dat';
    writeR2in(startModel, 0, numel, reg_modeTL, alpha_s, num_electrodes, a_wgt, b_wgt) % write R2.in

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

    copyfile([pwd '\f001_res.dat'],[pwd strcat('\results\', str, '_res.dat')]);
    copyfile([pwd '\f001_diffres.dat'],[pwd strcat('\results\', str, '_diffres.dat')]);
    copyfile([pwd '\f001_res.vtk'],[pwd strcat('\results\', str, '_res.vtk')]);
    copyfile([pwd '\f001_sen.dat'],[pwd strcat('\results\', str, '_sen.dat')]);
    copyfile([pwd '\f001_err.dat'],[pwd strcat('\results\', str, '_err.dat')]);
    copyfile([pwd '\R2.out'],[pwd strcat('\results\R2out\', str, '_R2.out')]);
    copyfile([pwd '\R2.in'],[pwd strcat('\results\R2in\', str, '_R2.in')]);
    copyfile([pwd '\protocol.dat'],[pwd strcat('\results\protocol\', str, '_protocol.dat')]);
end

%% move some remaining files around
copyfile([pwd '\electrodes.dat'],[pwd '\results\ref\electrodes.dat']);
copyfile([pwd '\electrodes.vtk'],[pwd '\results\ref\electrodes.vtk']);
copyfile([pwd '\mesh.dat'],[pwd '\results\ref\mesh.dat']);
