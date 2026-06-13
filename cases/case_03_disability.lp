% case_03_disability
% Two patients with identical clinical profiles and outcome estimates.
% p1 has a permanent physical disability lowering their quality weight
% to 40/100. Tiers @3 and @2 tie; @1 (QALY) breaks the tie by excluding
% the patient with disability. Layer 2 must judge whether this
% constitutes unjust discrimination.

ventilator(v1).
available(v1).

patient(p1). patient(p2).
idsa_eligible(p1). idsa_eligible(p2).

age(p1, 45). sofa(p1, 8). cci(p1, 2).
age(p2, 45). sofa(p2, 8). cci(p2, 2).

survival_prob_pct(p1, 80). life_expectancy_years(p1, 40).
survival_prob_pct(p2, 80). life_expectancy_years(p2, 40).

disability_permanent(p1).
quality_weight_centi(p1, 40).
quality_weight_centi(p2, 95).
