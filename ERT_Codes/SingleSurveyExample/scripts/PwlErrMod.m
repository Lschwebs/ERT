% Lena J. Schwebs
% Created on: 10/20/2024
% Last updated: 10/28/2024
% Adapted from Dr. Andrew D. Parsekian 'err_mod.m'
% Must have Curve Fitting Toolbox installed

function [P] = PwlErrMod( data )
% calculate error function based on reciprocal errors in Lippmann file
D = data;
d = [D(:,5) D(:,7)]; % filtered resistance, filtered reciprocal errors 
res = abs(d(:,1)); % resistance
err = abs(res.*d(:,2)); % error in Ohms 

n = 20; % number of bins
binsize = n; % number of samples in a bin (default to n)
nbins = round(length(D)/binsize); % max 20 bins

if nbins > n % we want max 20 bins
    binsize = round(length(D)/n); % at least 20 samples per bin
    nbins = n;
end

bins = zeros(nbins,2); % initialize array

for i = 1:nbins % bining 
    ns = (i-1)*binsize; % first row for bin i
    ne = ns+binsize; % last row for bin i

    if ne < length(d) % prevent loop from going over length(d)
        bins(i,1) = mean(res(ns+1:ne,1));
        bins(i,2) = mean(err(ns+1:ne,1));
    else
        bins(i,1) = mean(res(ns+1:length(d),1));
        bins(i,2) = mean(err(ns+1:length(d),1));  
    end
end

%% fit LOG10 data with first-order polynomial fit
lbins = log10(bins);
lres = log10(res);
lerr = log10(err);

[P gof] = polyfit(lbins(:,1), lbins(:,2), 1); % fit LOG10 data

% fy = 10.^P(2) .* bins(:, 1).^P(1); % equation to convert to Power Law

Fp = polyval(P, lbins(:,1)); % calculate y-values from fit equation

%% plot and save
figure(1)
plot(lres, lerr,'+b')
hold on;
plot(lbins(:,1), lbins(:,2), '.r', 'MarkerSize', 18);
% plot(lbins(:, 1), log10(fy),'LineWidth', 4)
plot(lbins(:,1), Fp, 'LineWidth', 2)

xlabel('R_{avg} (\Omega)')
ylabel('R_{err} (\Omega)')
title(['R_{err} = ', num2str(10.^P(2)) ,'*R_{avg}**', num2str(P(1))], [' R2 = ', num2str(gof.rsquared)])
hold off;

end
