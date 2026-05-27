% preprocLippDD imports, removes bad data based on reciprocals, removes
% NANS, removes negative values 
% minVal is the smallest R value that will be kept
% errRecip is the reciprocal error threshold that will be retained in DECIMAL UNITS
% dataStart is resistance from starting dataset

function [procData, gmean, prefilterDAT] = preproc_fr(data, CR, minVal, errRecip, a_wgt, b_wgt)

%% import file and create data matrices
D = data; % load raw data array
abmn = [D(:,1) D(:,2) D(:,3) D(:,4)]; % takes electrode locations from raw data
R = D(:,5); % takes resistance from raw data
rho = D(:,6); % takes apparent resistivity from raw data
dat = [abmn R rho]; % makes a single matrix out of all raw data (NO ERRORS RIGHT NOW)
a_wgt = a_wgt;
b_wgt = b_wgt;

%% clean up negative or NaN values
dat_a = sortrows(dat,5); % sort based on column that will have NaNs

if any(dat_a(:,5) < minVal)
    firstD = find(dat_a(:,5) < minVal, 1, 'last') + 1; % finds the last negative val, +1 for first positive value. used to delete negative R vals
else
    firstD = 1; % sets first row as row 1 of data matrix if there are NO negatives
end

lastD = find(~isnan(dat_a(:,5)), 1, 'last'); % finds the beginning of the NaN rows to delete

dat = dat_a(firstD:lastD,:); % take only rows >0 and without NaN R values

%% loop through all quadrapoles to find reciprocals
inst = dat;

for i = 1:length(inst)
    tx = sort(inst(i,1:2)); % AB forward
    rx = sort(inst(i,3:4)); % MN forward
        
    for j = 1:length(inst)
        Tx = sort(inst(j,1:2)); % AB recip
        Rx = sort(inst(j,3:4)); % MN recip
            
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
  
RECIPS = [reciprocal Xr' Zr']; % mnab, Rf, Rr, rhof, rhor, observed error, add on pseudolocations for plotting
RECIPS = [RECIPS RECIPS(:,9)./mean(RECIPS(:,5:6),2)]; % add on a column of percent reciprocal error in decimal units

cnt = 1; 
for i = 1:length(RECIPS)
    prefilterDAT(cnt,:) = [RECIPS(i,1:4), mean(RECIPS(i,5:6)), mean(RECIPS(i, 7:8)), RECIPS(i,9), RECIPS(i,12)]; % abmn, resistance, apparent resistivity, observed error, recip error
    cnt = cnt+1;
end
%% remove any U% above XX% reciprocal error
cnt = 1;

for i = 1:length(RECIPS)

    if RECIPS(i,12) < errRecip % reciprocal error
        DAT(cnt,:) = [RECIPS(i,1:4), mean(RECIPS(i,5:6)), mean(RECIPS(i, 7:8)), RECIPS(i,9), RECIPS(i,12)]; % loop through and keep all columns in each row below threshold
        cnt = cnt+1;
    end
end

%% calculate average CR for each quadrupole 
for i = 1:length(DAT)
    elecs = [DAT(i, 1) DAT(i, 2) DAT(i, 3) DAT(i, 4)]; % mnab
    CRquad(i,:) = mean(CR(elecs,2), 'omitmissing');
end

%% write out
procData = [DAT CRquad]; % abmn, resistance, apparent resistivity, observed error, recip error, CRquad

gmean = geomean(DAT(:, 6)); % geometric mean

fprintf('Percent of Measurements Remaining = %2.2f%% \n', 100 .* length(DAT) ./ (length(abmn)./2))
fprintf('Geometric Mean = %2.2f \n', gmean)
fprintf('Length of data array = %2.f\n', length(DAT))