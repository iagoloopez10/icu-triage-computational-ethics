% case_06_extreme_scarcity
% Five IDSA-eligible patients, one ventilator. The decision saves one
% while four are denied. Layer 1 picks p1 (best outcome). Operationally
% this stress-tests the optimizer. Ethically the system should flag this
% case for human deliberation regardless of which individual is chosen.

ventilator(v1).
available(v1).

patient(p1). patient(p2). patient(p3). patient(p4). patient(p5).
idsa_eligible(p1). idsa_eligible(p2). idsa_eligible(p3).
idsa_eligible(p4). idsa_eligible(p5).

age(p1, 30). sofa(p1, 6). cci(p1, 0).
age(p2, 55). sofa(p2, 9). cci(p2, 3).
age(p3, 40). sofa(p3, 7). cci(p3, 1).
age(p4, 62). sofa(p4, 8). cci(p4, 4).
age(p5, 35). sofa(p5, 6). cci(p5, 1).

survival_prob_pct(p1, 85). life_expectancy_years(p1, 50).
survival_prob_pct(p2, 55). life_expectancy_years(p2, 22).
survival_prob_pct(p3, 75). life_expectancy_years(p3, 40).
survival_prob_pct(p4, 50). life_expectancy_years(p4, 18).
survival_prob_pct(p5, 80). life_expectancy_years(p5, 45).

quality_weight_centi(p1, 95).
quality_weight_centi(p2, 80).
quality_weight_centi(p3, 90).
quality_weight_centi(p4, 75).
quality_weight_centi(p5, 92).
