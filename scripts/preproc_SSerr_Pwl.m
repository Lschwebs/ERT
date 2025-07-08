% Lena J. Schwebs
% Created on: 10/28/2024
% Last updated: 03/07/2025
% Adapted from Dr. Andrew D. Parsekian 'preprocMPT.m'

% USE FOR SINGLE SURVEY OR DATA DIFFERENCING INVERSION WITH POWER LAW ERROR MODEL
% preprocLippDD imports, removes bad data based on reciprocals, removes
% NANS, removes negative values 
% writes Protocol.dat with extra column from initial dataset

% minVal is the smallest R value that will be kept
% errRecip is the reciprocal error threshold that will be retained in
% DECIMAL UNITS
% dataStart is resistance from starting dataset

function [protocolData, gmean] = preproc_SSerr_Pwl(fLoc, data, minVal, errRecip, errStack, survey_type, dataStart)

%% import file and create data matrices
D = data; % load raw data array
abmn = [D(:,1) D(:,2) D(:,3) D(:,4)]; % takes electrode locations from raw data
R = D(:,5); % takes resistance from raw data
rho = D(:,7); % takes apparent resistivity from raw data
Rerr = D(:,6); % percent error in tenths of a percent
dat = [abmn R rho Rerr]; % makes a single matrix out of all raw data 
survey_type = survey_type; % switch case for incoporating starting dataset into protocol.dat

%% clean up negative or NaN values 
dat_a = sortrows(dat,5); % sort based on column that will have NaNs
firstD = max(find(dat_a(:,5) < minVal)) + 1; % finds the last negative val, +1 for first positive value. used to delete negative R vals
lastD = find(~isnan(dat_a(:,5)), 1, 'last'); % finds the beginning of the NaN rows to delete

dat = dat_a(firstD:lastD,:); % take only rows >0 and without NaN R values

%% loop through all quadrapoles to find reciprocals
inst = dat;

for i = 1:length(inst)
    tx = sort(inst(i,1:2)); % AB
    rx = sort(inst(i,3:4)); % MN
        
    for j = 1:length(inst)
        Tx = sort(inst(j,1:2));
        Rx = sort(inst(j,3:4));
            
        if rx == Tx & tx == Rx
            reciprocal(i,:) = [tx rx Tx Rx inst(i,5) inst(j,5) inst(i,6) inst(j,6)]; % inst(:, 5) = resistance, inst(:, 6) = apparent resistivity
        end
    
    end
end
    
for i = 1:length(reciprocal)
    holder = reciprocal(i,:);
    reciprocal(i,:) = [0 0 0 0 0 0 0 0 0 0 0 0];

    for j = 1:length(reciprocal)
        if reciprocal(j,1:8) == [holder(5:8) holder(1:4)]
            reciprocal(j,:) = [0 0 0 0 0 0 0 0 0 0 0 0];    
        end
    end
        
        reciprocal(i,:) = holder; 
end

reciprocal = reciprocal(find(reciprocal(:,1)),:);
reciprocal = [reciprocal(:,1:4) reciprocal(:,9:12)]; % abmn forward(R) reciprocal(R) forward(rho) reciprocal(rho)
reciprocal(:,9) = abs(reciprocal(:,5) - reciprocal(:,6)); % adds column 9 which is the abs.diff between FWD/RECIP

for i = 1:length(reciprocal)
    if max(reciprocal(i,1:2)) > max(reciprocal(i,3:4))
        reciprocal(i,1:4) = [sort(reciprocal(i,3:4),2) sort(reciprocal(i,1:2),2)];
    else
        reciprocal(i,1:4) = [sort(reciprocal(i,1:2),2) sort(reciprocal(i,3:4),2)];
    end  
end

for R = 1:length(reciprocal)
    Xr(R) = mean([mean(reciprocal(R,1:2)) mean(reciprocal(R,3:4))]);
    Zr(R) = abs((max(reciprocal(R,1:2))-min(reciprocal(R,3:4))))+abs(reciprocal(R,1)-reciprocal(R,2));
end
  
RECIPS = [reciprocal Xr' Zr']; % reciprocal electrode locations, Rf, Rr, rhof, rhor, absolute deviation, add on pseudolocations for plotting
RECIPS = [RECIPS RECIPS(:,9)./mean(RECIPS(:,5:6),2)]; % add on a column of percent reciprocal error in decimal units

%% remove any U% above XX% reciprocal error
cnt = 1;

for i = 1:length(RECIPS)

    if RECIPS(i,12) < errRecip % reciprocal error
        DAT(cnt,:) = [RECIPS(i,1:4), mean(RECIPS(i,5:6)), mean(RECIPS(i, 7:8)), RECIPS(i,12)]; % loop through and keep all columns in each row below threshold
        cnt = cnt+1;
    end
end


%% stacking errors
dat_b = find(dat(:,7) <= errStack);
data = dat(dat_b,:); % abmn, resistance, apparent resistivity, resistance error
 
gmean = geomean(data(:, 6)); % geometric mean of app res

fprintf('Percent of Measurements Remaining = %2.2f%% \n', 100 .* length(data) ./ (length(abmn)))
fprintf('Geometric Mean = %2.2f \n', gmean)
fprintf('Length data = %2.f\n', length(data))

%% calculate Power Law Error Model
P = PwlErrMod(DAT, fLoc);
data(:, 8) = 10.^P(2) .* data(:, 5).^P(1);

%% switch case for starting/single survey or time lapse
if survey_type == 1 % single or starting survey
    % assemble R2 protocol.dat
    pro_data = [data(:,1:5) data(:,8)];
    out = zeros(1,6); % initialize output matrix
    out = [out; pro_data(:, 1:6)]; % abmn, and resistance (FILTERED DATA)
    nums = 1:length(out)-1; % create measurement # vector
    out = [nums' out(2:end,:)]; % add measurement # vector to output array
    mn = max(nums); % total number of measurements
    protocolData = out;
    newfile = [pwd '/protocol.dat']; % create protocol.dat file
    dlmwrite(newfile, mn); % write first line of protocol.dat
    dlmwrite(newfile, protocolData, '-append','delimiter','\t'); % write line 2-mn filtered data to protocol.dat
    clear newfile;
    fprintf('protocol.dat written\n')

elseif survey_type == 2
    % find intersection of initial dataset and current dataset
    [dataN, id, idS] = intersect(data(:, 1:4), dataStart(:, 2:5), 'rows');
    fprintf('Length data = %2.f\n', length(data))
    fprintf('Length dataStart = %2.f\n', length(dataStart))
    % assemble R2 protocol.dat
    pro_data = [data(id,1:5) dataStart(idS, 6) data(id,8)];
    fprintf('Length pro_data = %2.f\n', length(pro_data))
    out = zeros(1,7); % initialize output matrix
    out = [out; pro_data(:, 1:7)]; % abmn, resistance (FILTERED DATA), starting resistance
    nums = 1:length(out)-1; % create measurement # vector
    out = [nums' out(2:end,:)]; % add measurement # vector to output array
    mn = max(nums); % total number of measurements
    protocolData = out;
    newfile = [pwd '/protocol.dat']; % create protocol.dat file
    dlmwrite(newfile, mn); % write first line of protocol.dat
    dlmwrite(newfile, protocolData, '-append','delimiter','\t'); % write line 2-mn filtered data to protocol.dat
    clear newfile;

    fprintf('protocol.dat written\n')
else
    fprintf('ERROR WRITING PROTOCOL.DAT\n')
end

end