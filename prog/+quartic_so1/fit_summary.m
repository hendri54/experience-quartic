function fit_summary(gNo)
% Summary table with model fit

cS = const_data_so1(gNo);
minObs = 10;

tgS = var_load_so1(cS.varNoS.vCalTargets, cS);
loadS = var_load_so1(cS.varNoS.vQuarticModel, cS);

qPctV = [0.25, 0.5, 0.75];
nq = length(qPctV);


%% Calculate measures of fit by [school, cohort]

% Rsquared, weighted by sqrt of no of obs in each cell
r2_scM = repmat(cS.missVal, [cS.nSchool, cS.nCohorts]);

% r2Median_sV = nan([cS.nSchool, 1]);
r2Quantile_qsM = nan([nq, cS.nSchool]);
r2Std_sV = nan([cS.nSchool, 1]);
r2Min_sV = nan([cS.nSchool, 1]);
r2Max_sV = nan([cS.nSchool, 1]);
r2Low_sV = nan([cS.nSchool, 1]);
r2High_sV = nan([cS.nSchool, 1]);
n_sV = nan([cS.nSchool, 1]);

for iSchool = 1 : cS.nSchool
   ageV = cS.demogS.workStartAgeV(iSchool) : cS.quarticS.ageMax;
   for ic = 1 : cS.nCohorts
      yV = tgS.logWage_tscM(ageV, iSchool, ic);
      yPredV = loadS.pred_tscM(ageV, iSchool, ic);
      wtV = sqrt(tgS.nObs_tscM(ageV, iSchool, ic));
      idxV = find(yV ~= cS.missVal  &  yPredV ~= cS.missVal  &  wtV > 0);
      if length(idxV) >= minObs
         r2_scM(iSchool, ic) = statsLH.rsquared(yV(idxV), yPredV(idxV), wtV(idxV) ./ sum(wtV(idxV)), cS.dbg);
      end
   end
   
   idxV = find(r2_scM(iSchool,:) ~= cS.missVal);
   r2V = r2_scM(iSchool, idxV);
%    r2Median_sV(iSchool) = median(r2V);
   r2Quantile_qsM(:, iSchool) = quantile(r2V, qPctV);
   r2Std_sV(iSchool) = std(r2V);
   r2Min_sV(iSchool) = min(r2V);
   r2Max_sV(iSchool) = max(r2V);
   n_sV(iSchool) = length(r2V);
end




%% Latex table

cMean = 0;
cStd = 0;
cMin = 0;
cMax = 0;

colHeaderV = cell(10, 1);
ic = 1;  cMedian = ic;  colHeaderV{cMedian} = 'Median';
% ic = ic + 1;   cStd = ic;
% ic = ic + 1;   cMin = ic;
% ic = ic + 1;   cMax = ic;
ic = ic + 1;   cLow = ic;  colHeaderV{cLow} = sprintf('%.0fth', qPctV(1) * 100);
ic = ic + 1;   cHigh = ic; colHeaderV{cHigh} = sprintf('%.0fth', qPctV(nq) * 100);
ic = ic + 1;   cN = ic; colHeaderV{cN} = 'N';
nc = ic;
colHeaderV = colHeaderV(1 : nc);

nr = cS.nSchool;

tbS = LatexTableLH(nr, nc, 'colHeaderV', colHeaderV,  'rowHeaderV', cS.schoolLabelV, ...
   'filePath', fullfile(cS.dirS.quarticDir,  'fit_r2.tex'));

fmtStr = '%.2f';
if cMean > 0
   tbS.fill_col(cMean, r2Mean_sV, fmtStr);
end
if cStd > 0
   tbS.fill_col(cStd, r2Std_sV, fmtStr);
end
if cMedian > 0
   tbS.fill_col(cMedian, r2Quantile_qsM(2,:), fmtStr);
end
tbS.fill_col(cLow, r2Quantile_qsM(1,:), fmtStr);
tbS.fill_col(cHigh, r2Quantile_qsM(nq,:), fmtStr);
tbS.fill_col(cN, n_sV, '%i');

tbS.write_table;
tbS.write_text_table;



end