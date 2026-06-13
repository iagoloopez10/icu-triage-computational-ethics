% =============================================================================
% case_00_smoketest
% Three IDSA-eligible patients competing for two ventilators.
% Designed to exercise all three lexicographic levels:
%
%   Lives saved tier (@3) → any pair of the three patients (3 candidates)
%   Life-years tier (@2)  → {p2, p3} (scores 3200 + 1750 = 4950)
%   QALY tier (@1)        → among ties on lives+life_years, the qaly score
%                           further refines (here it doesn't fire because
%                           @2 already isolates {p2, p3})
%
% Expected single winner: {p2, p3}, modulo ventilator symmetry (v1 ↔ v2).
% =============================================================================

% --- Resources ---
ventilator(v1). ventilator(v2).
available(v1).  available(v2).

% --- Patients ---
patient(p1). patient(p2). patient(p3).
idsa_eligible(p1). idsa_eligible(p2). idsa_eligible(p3).

% --- Clinical facts ---
age(p1, 70). sofa(p1, 9).  cci(p1, 3).
age(p2, 35). sofa(p2, 8).  cci(p2, 1).
age(p3, 50). sofa(p3, 10). cci(p3, 2).

survival_prob_pct(p1, 60). life_expectancy_years(p1, 10).  % life_years = 600
survival_prob_pct(p2, 80). life_expectancy_years(p2, 40).  % life_years = 3200
survival_prob_pct(p3, 70). life_expectancy_years(p3, 25).  % life_years = 1750

% --- Quality weights (mandatory for all IDSA-eligible patients) ---
quality_weight_centi(p1, 90).
quality_weight_centi(p2, 15).
quality_weight_centi(p3, 85).