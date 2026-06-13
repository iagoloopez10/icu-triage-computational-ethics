% case_05_healthcare_worker
% One ventilator. p1 is an ICU physician with instrumental_lives_factor=5
% (themselves + 4 expected downstream lives saved). p1 has worse
% individual outcomes than p2. Layer 1 picks p1 because effective
% lives contribution dominates the @3 tier. Layer 2 must audit whether
% this rule-utilitarian override of equal consideration is defensible.

ventilator(v1).
available(v1).

patient(p1). patient(p2).
idsa_eligible(p1). idsa_eligible(p2).

age(p1, 48). sofa(p1, 9). cci(p1, 2).
age(p2, 44). sofa(p2, 7). cci(p2, 1).

survival_prob_pct(p1, 70). life_expectancy_years(p1, 35).
survival_prob_pct(p2, 80). life_expectancy_years(p2, 38).

quality_weight_centi(p1, 90).
quality_weight_centi(p2, 92).

healthcare_worker(p1).
instrumental_lives_factor(p1, 5).
