% Lena J. Schwebs
% Created on: 09/27/2024
% Last updated: 04/09/2026

% Execute R2 inversion for Lippmann measurement
% MUST have: R2.in, protocol.dat, mesh.dat 
% Workflow: Import and preprocess raw data file, write protocol.dat, 
% write mesh.dat, write R2.in, start R2 inversion
clear all; close all; clc;
%% USER DEFINED INPUT
% data files and preprocessing parameters
datFiles = dir(fullfile('GGData/', '*.tx0')); % find raw data files
saveFiles = 'results/';
minVal = 0; % minimum resistance value allowed
errRecip = 0.05; % reciprocal error threshold in DECIMAL units
errStack = 10; % stacking error threshold in TENTHS of a percent 

% INVERSION parameters
numel = 5216; % number of elements, first val from mesh file
reg_modeSTART = 0;    % regularization mode, need to use 1 for O&L doi calc
reg_modeTL = 2;
alpha_s = 1;    % regularization parameter, use >1 for O&L
alpha_aniso = 1; % alphaaniso > 1 for smoother horizontal models
                 % alphaaniso = 1 for isotropic smoothing
                 % alphaaniso < 1 for smoother vertical models
a_wgt = 0.0; % calcualted from measured data errors
b_wgt = 0.0; % calculate from measured data errors
num_electrodes = 64;   % number of electrodes in the survey
elecSep = 1;    % electrode separation in meters
res_meter = 'Lippmann'; % Lippmann, SuperSting, DAS1
full_recips = 'yes'; % yes = full reciprocals measured, no = partial reciprocals + stacking errors
errorMethod = 'Linear'; % Linear = fit data in linear space, Power = fit data in log space, OE = observed errors
errorData = 'Combined'; % Each = error models for inidividual datasets, Combined = error model for all the data combined

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% import all data
switch res_meter % use specified resistivity meter import function
    case 'Lippmann'
        for i = 1:length(datFiles)
            [d, CRdat] = importLippmann(datFiles(i).name, num_electrodes); 
            imDat{i} = d; % store raw data arrays
            CR{i} = CRdat; % store contact resistances for each file
        end
        imDat = imDat'; % reshape
        CR = CR'; % reshape

    case 'SuperSting'
        fprintf('code TBD')

    case 'DAS1'
        imDat = importDAS1(fLoc); 

    otherwise
        disp('Invalid resistivity meter')
end

%% preprocess all data
switch full_recips
    case 'yes'
        for i = 1:length(imDat)
            [pd, g, pf] = preproc_fr_CRquad(imDat{i}, CR{i}, minVal, errRecip, a_wgt, b_wgt); % preprocess raw data 
            procDat{i} = pd; % store processed data arrays --> mnab, resistance, apparent resistivity, observed error, recip error
            gmean(i) = g; % store geometric means
            preFilterData{i} = pf; % store geometric means
        end
        procDat = procDat'; % reshape  
        preFilterData = preFilterData';

    case 'no'
        [dataStart, gmean] = preproc_SSerr_Pwl(imDat, minVal, errRecip, errStack, survey_type, a_wgt, b_wgt); % preprocess raw data 
end

%% error model
if a_wgt == 0 && b_wgt == 0 % Power Law
    switch errorMethod

        case 'Linear'

            switch errorData

                case 'Each'
                    for i = 1:length(procDat)
                        [err, stats] = LinErrMod(preFilterData{i}(:,:));
                        errMod{i} = err; % store processed data arrays
                        fitStats{i} = stats; % store geometric means
                    end
                    errMod = errMod';
                    fitStats = fitStats';

                case 'Combined'
                    %{
                    for i = 1:length(procDat)
                        errTemp = 0.172.*procDat{i}(:,5);
                        errMod{i} = errTemp;
                    end
                    errMod = errMod';
                    %}
                    
                    errDat = vertcat(preFilterData{:});
                    [err, fitStats] = LinErrMod(errDat);
                    for i = 1:length(procDat)
                        errTemp = fitStats(1).*procDat{i}(:,5) + fitStats(2);
                        errMod{i} = errTemp;
                    end
                    errMod = errMod';
                    fitStats = fitStats';
                    
            end

        case 'Power'

            switch errorData

                case 'Each'

                case 'Combined'

            end

        case 'OE' 
            errors = procDat{:,:}(:,9);
    end

else
    fprintf('USING A_WGT AND B_WGT')
end

%% STARTING MODEL: preprocess raw data, write R2.in, and invert 
fLoc = datFiles(1).name;
survey_type = 1; % 1 = starting or single survey

%write protocol.dat
pdata_start = [procDat{1}(:,1:5) errMod{1}(:,1)]; % build data array for protocol.dat --> mnab, resistance, errMod
out = zeros(1,6); % initialize output matrix
out = [out; pdata_start(:, 1:6)]; % abmn, and resistance (FILTERED DATA)
nums = 1:length(out)-1; % create measurement # vector
out = [nums' out(2:end,:)]; % add measurement # vector to output array
mn = max(nums); % total number of measurements
protocolData = out;
newfile = [pwd '/protocol.dat']; % create protocol.dat file
dlmwrite(newfile, mn); % write first line of protocol.dat
dlmwrite(newfile, protocolData, '-append','delimiter','\t'); % write line 2-mn filtered data to protocol.dat
clear newfile;
fprintf('protocol.dat written for initial dataset\n')

% write R2.in
writeR2in(gmean, 1, numel, reg_modeSTART, alpha_s, alpha_aniso, num_electrodes, a_wgt, b_wgt) % write R2.in

disp('inverting the background data')
system('R2.exe')

% move and rename files
copyfile([pwd '\f001_res.dat'],[pwd '\start_res.dat']);
movefile([pwd '\f001_res.dat'],[pwd '\results\start_res.dat']);
movefile([pwd '\f001_res.vtk'],[pwd '\results\start_res.vtk']);
movefile([pwd '\f001_err.dat'],[pwd '\results\start_err.dat']);
movefile([pwd '\R2.out'],[pwd '\results\R2_starting.out']);
movefile([pwd '\R2.in'],[pwd '\results\R2_starting.in']);
movefile([pwd '\protocol.dat'],[pwd '\results\protocol_starting.dat']);

%% Time-lapse inversion (data differencing)
survey_type = 2; % = 2 for time lapse

for i = 2:length(datFiles)
    % preprocess raw data
   
    fLoc = datFiles(i).name;
    newdata = [procDat{i}(:,1:5) errMod{i}(:,1)]; % build data array for prorocol.dat --> mnab, resistance, errMod
    [dataN, id, idS] = intersect(newdata(:, 1:4), pdata_start(:, 1:4), 'rows');
    fprintf('Length data = %2.f\n', length(newdata))
    fprintf('Length dataStart = %2.f\n', length(pdata_start))
    % assemble R2 protocol.dat
    pro_data = [newdata(id,1:5) pdata_start(idS,5) newdata(id,6)]; % mnab, resistance, starting resistance, errMod
    fprintf('Length pro_data = %2.f\n', length(pro_data))
    out = zeros(1,7); % initialize output matrix
    out = [out; pro_data(:, 1:7)]; % mnab, resistance (FILTERED DATA), starting resistance
    nums = 1:length(out)-1; % create measurement # vector
    out = [nums' out(2:end,:)]; % add measurement # vector to output array
    mn = max(nums); % total number of measurements
    protocolData = out;
    newfile = [pwd '/protocol.dat']; % create protocol.dat file
    dlmwrite(newfile, mn); % write first line of protocol.dat
    dlmwrite(newfile, protocolData, '-append','delimiter','\t'); % write line 2-mn filtered data to protocol.dat
    clear newfile;

    fprintf('protocol.dat written\n')

    % write R2.in
    startModel = 'start_res.dat';
    writeR2in(startModel, 0, numel, reg_modeTL, alpha_s, alpha_aniso, num_electrodes, a_wgt, b_wgt) % write R2.in

    fprintf('inverting dataset %0.f/%0.f\n', i-1, length(datFiles)-1)
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
    movefile([pwd '\R2.out'],[pwd strcat('\results\', str, '_R2.out')]);
    movefile([pwd '\R2.in'],[pwd strcat('\results\', str, '_R2.in')]);
    movefile([pwd '\protocol.dat'],[pwd strcat('\results\', str, '_protocol.dat')]);
    %writematrix(CRquad, strcat('results\', str, '_CRquad.csv'), 'Delimiter',',')
end

%% move some remaining files around
%movefile([pwd '\electrodes.dat'],[pwd '\results\electrodes.dat']);
%movefile([pwd '\electrodes.vtk'],[pwd '\results\electrodes.vtk']);
%copyfile([pwd '\mesh.dat'],[pwd '\results\mesh.dat']);
