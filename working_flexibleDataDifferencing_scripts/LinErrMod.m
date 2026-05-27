% Lena J. Schwebs
% Created on: 03/10/2026
% Last updated: 03/10/2026
% Adapted from Dr. Andrew D. Parsekian 'err_mod.m'
% Must have Curve Fitting Toolbox installed

function [err, stats] = LinErrMod(data)
% calculate error function based on reciprocal errors in Lippmann file
D = data;
d = [D(:,5) D(:,7)]; % filtered resistance, observed errors
d = sortrows(d);
res = abs(d(:,1)); % resistance
Oerr = abs(d(:,2)); % observed error in Ohms 

n = 20; % number of bins
binsize = n; % number of samples in a bin (default to n)
nbins = round(length(D)/binsize); % max 20 bins

if nbins > n % we want max 20 bins
    binsize = round(length(D)/n); % at least 20 samples per bin
    nbins = n;
end

bins = zeros(nbins,2); % initialize array

for i = 1:nbins % binning 
    ns = (i-1)*binsize; % first row for bin i
    ne = ns+binsize; % last row for bin i

    if ne < length(d) % prevent loop from going over length(d)
        bins(i,1) = mean(res(ns+1:ne,1));
        bins(i,2) = mean(Oerr(ns+1:ne,1));
    else
        bins(i,1) = mean(res(ns+1:length(d),1));
        bins(i,2) = mean(Oerr(ns+1:length(d),1));  
    end
end

%% fit LINEAR data with first-order polynomial fit
lbins = log10(bins);
lres = log10(res);
lOerr = log10(Oerr);

[P, gof] = polyfit(bins(:,1), bins(:,2), 2); % fit LINEAR data

Fp = polyval(P, bins(:,1)); % calculate y-values from fit equation

R_squared = 1 - (gof.normr/norm(bins(:,2) - mean(bins(:,2))))^2;

%% plot and save
stats = [P(1) P(2) R_squared]; % m b R2 value where mx + b
err = P(1).*res + P(2);

lbins = log10(bins);
lres = log10(res);
lerr = log10(err);

figure(1)
loglog(res, Oerr,'+b')
hold on;
plot(bins(:,1), bins(:,2), '.r', 'MarkerSize', 18);
plot(res, err, 'LineWidth', 2)
plot(bins(:,1), Fp, 'LineWidth', 2)

xlabel('R_{avg} (\Omega)')
ylabel('R_{err} (\Omega)')
title(['R_{err} = ', num2str(P(1)) ,'*R_{avg} + ', num2str((P(2)))], [' R2 = ', num2str(R_squared)])
hold off;
%[pathstr,name,ext] = fileparts(fLoc);
%saveas(figure(1), strcat('results\errMod\', name, '_errMod.png'))

end
