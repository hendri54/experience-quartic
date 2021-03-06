classdef QuarticModel
% Sets default properties of the model to be estimated
   
properties
   % Use weights in wage regression?
   useWeights

   % What type of cohort effects
   %{
   dummies
      Simple cohort effects don't work
      The result fits really well, but the model buys that fit by essentially ignoring the constraint
      that the first/last cohort have the same dummy (big jumps in dummies at start/end of cohorts)
   schooling
      Use cohort school fractions as regressor to get cohort effects
   schoolYears
      Use cohort years of school
   none
      nothing in the regression
   expost
      nothing in regression, but compute cohort effects afterwards
   %}
   cohortEffects
   
   % Age effects
   % Possible values 'ageDummies', 'poly2', 'poly4'
   ageEffects
   
   % Highest age to use
   ageMax
   
   % Substitution elasticities
   substElastOuter
   substElastInner
end

methods
   %% Constructor
   function qS = QuarticModel
      qS.useWeights = false;
      
      % Cohort effects
      qS.cohortEffects = EnumLH('schoolYears', {'none', 'schooling', 'schoolYears', 'dummies', 'expost'});
      
      % Age effects
      qS.ageEffects = EnumLH('poly4', {'ageDummies', 'poly2', 'poly4'});

      qS.ageMax = 60;
      
      qS.substElastOuter = 3;
      qS.substElastInner = 4;
   end
end
   
end