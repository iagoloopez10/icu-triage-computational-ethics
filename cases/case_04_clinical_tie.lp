% case_04_clinical_tie
% Three patients identical across all dimensions. Two ventilators.
% The lex hierarchy cannot distinguish them. The lottery is the only
% defensible tie-breaker. Layer 2 should declare the result defensible
% regardless of which patient was unlucky.

ventilator(v1). ventilator(v2).
available(v1).  available(v2).

patient(p1). patient(p2). patient(p3).
idsa_eligible(p1). idsa_eligible(p2). idsa_eligible(p3).

age(p1, 50). sofa(p1, 8). cci(p1, 2).
age(p2, 50). sofa(p2, 8). cci(p2, 2).
age(p3, 50). sofa(p3, 8). cci(p3, 2).

survival_prob_pct(p1, 70). life_expectancy_years(p1, 30).
survival_prob_pct(p2, 70). life_expectancy_years(p2, 30).
survival_prob_pct(p3, 70). life_expectancy_years(p3, 30).

quality_weight_centi(p1, 90).
quality_weight_centi(p2, 90).
quality_weight_centi(p3, 90).
