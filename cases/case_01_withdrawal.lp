% case_01_withdrawal
% Two ventilators currently allocated to p1 and p2. A third patient p3
% arrives with substantially better outcomes than p1. The lex hierarchy
% recommends withdrawing the ventilator from p1 to reassign it to p3.
% Layer 2 must audit fidelity (clinical commitment already made) and
% the act/omission asymmetry of withdrawal.

ventilator(v1). ventilator(v2).
available(v1).  available(v2).
already_assigned(p1, v1).
already_assigned(p2, v2).

patient(p1). patient(p2). patient(p3).
idsa_eligible(p1). idsa_eligible(p2). idsa_eligible(p3).

age(p1, 68). sofa(p1, 8). cci(p1, 4).
age(p2, 45). sofa(p2, 7). cci(p2, 2).
age(p3, 38). sofa(p3, 6). cci(p3, 1).

survival_prob_pct(p1, 50). life_expectancy_years(p1, 12).
survival_prob_pct(p2, 75). life_expectancy_years(p2, 32).
survival_prob_pct(p3, 80). life_expectancy_years(p3, 40).

quality_weight_centi(p1, 85).
quality_weight_centi(p2, 90).
quality_weight_centi(p3, 95).
