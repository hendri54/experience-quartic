function saveS = aggr_stats(logWage_tsyM, wt_tsyM, yearV, ageMin, ageMax, cS)
% Compute aggregate stats, comparable to aggregate cps stats
%{
IN
   logWage_tsyM(age, school, year)
      log wages
   wt_tsyM(age, school, year)
      weights
   yearV
      years in matrices
   ageMin, ageMax
      ages to use, typically cS.dataS.aggrAgeRangeV
      must be sufficiently inclusive to compute all stats

OUT
   collPremAgeM(young/old, year)
      college premium young/old by year

Medians are simply taken across ages.

Checked: 2015-Dec-1
%}

%% Input check

% Years with wage data
nYr = length(yearV);

if cS.dbg > 10
   if ~v_check(logWage_tsyM, 'f', [ageMax,cS.nSchool,nYr], [],[])
      error('invalid');
   end
   if ~v_check(wt_tsyM, 'f', [ageMax,cS.nSchool,nYr], 0,[])
      error('invalid');
   end
   if ~v_check(yearV, 'i', [], 1930, 2040)
      error('invalid');
   end
   % Ages must be enough to compute young / old college premium
   if ~v_check(ageMin, 'i', [1,1], cS.demogS.workStartAgeV(1), min(cS.dataS.ageRangeYoungOldM(:)))
      error('invalid');
   end
   if ~v_check(ageMax, 'i', [1,1], max(cS.dataS.ageRangeYoungOldM(:)), cS.demogS.ageRetire)
      error('invalid');
   end
end



%% Allocate outputs

saveS.logMedianWage_tV = repmat(cS.missVal, [nYr, 1]);
saveS.meanLogWage_tV = repmat(cS.missVal, [nYr, 1]);
% saveS.stdLogWage_tV = repmat(cS.missVal, [nYr, 1]);


% Stats by school group
saveS.logMedianWage_stM = repmat(cS.missVal, [cS.nSchool, nYr]);
saveS.meanLogWage_stM = repmat(cS.missVal, [cS.nSchool, nYr]);
% saveS.stdLogWage_stM = repmat(cS.missVal, [cS.nSchool, nYr]);

% For young and old, so that college wage premium can be computed for them
ngAge = size(cS.dataS.ageRangeYoungOldM, 1);
saveS.logMedianWage_YoungOld_stM = repmat(cS.missVal, [ngAge, cS.nSchool, nYr]);
saveS.meanLogWage_YoungOld_stM = repmat(cS.missVal, [ngAge, cS.nSchool, nYr]);
% saveS.stdLogWage_YoungOld_stM = repmat(cS.missVal, [ngAge, cS.nSchool, nYr]);


%% Main

% Loop over years
for iy = 1 : nYr
   % Make a matrix of wages and weights by [age, school]
   logWage_tsM  = logWage_tsyM(ageMin:ageMax, :, iy);
   wt_tsM = wt_tsyM(ageMin:ageMax, :, iy) .* (logWage_tsM ~= cS.missVal);
   validateattributes(wt_tsM, {'double'}, {'finite', 'nonnan', 'nonempty', 'real', '>=', 0})
   
   % ***  Compute statistics for all
   idxV = find(wt_tsM > 0  &  logWage_tsM ~= cS.missVal);
   
   saveS.logMedianWage_tV(iy) = distrib_lh.weighted_median(logWage_tsM(idxV), wt_tsM(idxV), cS.dbg);
   saveS.meanLogWage_tV(iy) = sum(logWage_tsM(idxV) .* wt_tsM(idxV)) ./ sum(wt_tsM(idxV));
%    [saveS.stdLogWage_tV(iy), saveS.meanLogWage_tV(iy)] = stats_lh.std_w(logWage_tsM(idxV), wt_tsM(idxV), cS.dbg);
   
   % ***  By school group
   for iSchool = 1 : cS.nSchool
      syWt_tV = wt_tsM(:, iSchool);
      syWage_tV = logWage_tsM(:, iSchool);
      idxV = find(syWt_tV > 0);
      saveS.logMedianWage_stM(iSchool,iy) = distrib_lh.weighted_median(syWage_tV(idxV), syWt_tV(idxV), cS.dbg);
      saveS.meanLogWage_stM(iSchool,iy) = sum(syWage_tV(idxV) .* syWt_tV(idxV)) ./ sum(syWt_tV(idxV));
%       [saveS.stdLogWage_stM(iSchool,iy), saveS.meanLogWage_stM(iSchool,iy)] = ...
%          stats_lh.std_w(syWage_tV(idxV), syWt_tV(idxV), cS.dbg);
   end
   
   % ***  by school / age
   for iSchool = 1 : cS.nSchool
      for iAge = 1 : ngAge
         % Age range for this group
         ageRangeV = cS.dataS.ageRangeYoungOldM(iAge, 1) : cS.dataS.ageRangeYoungOldM(iAge, 2);
         % Indices into matrices
         ageIdxV  = ageRangeV - ageMin + 1;
         syWt_tV    = wt_tsM(ageIdxV, iSchool);
         syWage_tV  = logWage_tsM(ageIdxV, iSchool);
         idxV = find(syWt_tV > 0);
         if length(idxV) > 2
            saveS.logMedianWage_YoungOld_stM(iAge,iSchool,iy) = ...
               distrib_lh.weighted_median(syWage_tV(idxV), syWt_tV(idxV), cS.dbg);
            saveS.meanLogWage_stM(iSchool,iy) = sum(syWage_tV(idxV) .* syWt_tV(idxV)) ./ sum(syWt_tV(idxV));
%             [saveS.stdLogWage_YoungOld_stM(iAge,iSchool,iy), saveS.meanLogWage_YoungOld_stM(iAge,iSchool,iy)] = ...
%                stats_lh.std_w(syWage_tV(idxV), syWt_tV(idxV), cS.dbg);
         end
      end
   end
end


% For simplicity of access
if cS.useMedianWage
   saveS.logWage_tV = saveS.logMedianWage_tV;
   saveS.logWage_stM = saveS.logMedianWage_stM;
   saveS.logWage_YoungOld_stM = saveS.logMedianWage_YoungOld_stM;
else
   error('Not implemented');
end



%% College premium

% Young and old college premium
saveS.collPrem_YoungOld_tM = repmat(cS.missVal, [ngAge, nYr]);
for iAge = 1 : ngAge
   cgV  = saveS.logWage_YoungOld_stM(iAge, cS.iCG, :);
   hsgV = saveS.logWage_YoungOld_stM(iAge, cS.iHSG, :);
   cgV  = cgV(:);
   hsgV = hsgV(:);
   idxV = find(cgV ~= cS.missVal  &  hsgV ~= cS.missVal);
   saveS.collPrem_YoungOld_tM(iAge, idxV) = cgV(idxV) - hsgV(idxV);
end

% Aggregate college premium by year
saveS.collPrem_tV = repmat(cS.missVal, [nYr, 1]);
cgV  = saveS.logWage_stM(cS.iCG, :);
hsgV = saveS.logWage_stM(cS.iHSG, :);
idxV = find(cgV ~= cS.missVal  &  hsgV ~= cS.missVal);
saveS.collPrem_tV(idxV) = cgV(idxV) - hsgV(idxV);


% Save
saveS.yearV = yearV;
%var_save_so1(saveS, varS.vAggrStats, cS);


%% Output check
if cS.dbg > 10
   if ~v_check(saveS.meanLogWage_stM, 'f', [cS.nSchool, nYr], -10, 10, cS.missVal)
      error_so1('Invalid');
   end
   if ~v_check(saveS.logMedianWage_stM, 'f', [cS.nSchool, nYr], -10, 10, cS.missVal)
      error_so1('Invalid');
   end
   validateattributes(saveS.collPrem_YoungOld_tM, {'double'}, {'finite', 'nonnan', 'nonempty', 'real', ...
      'size', [ngAge, nYr]})
end


end