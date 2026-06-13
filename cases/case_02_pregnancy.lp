% case_02_pregnancy
% Three eligible patients, two ventilators. p2 is at 28 weeks of
% gestation but has marginally worse outcomes than the alternatives.
% Layer 1 (which doesn't see pregnancy) excludes her. Layer 2 must
% construct the third-party-duty argument toward the fetus.
% The fetus is NOT modeled as a separate patient — pregnancy enters
% only as a contextual fact for Layer 2's deliberation (report §5.3).

ventilator(v1). ventilator(v2).
available(v1).  available(v2).

patient(p1). patient(p2). patient(p3).
idsa_eligible(p1). idsa_eligible(p2). idsa_eligible(p3).

age(p1, 42). sofa(p1, 7).  cci(p1, 1).
age(p2, 32). sofa(p2, 10). cci(p2, 2).
age(p3, 39). sofa(p3, 6).  cci(p3, 2).

survival_prob_pct(p1, 80). life_expectancy_years(p1, 38).
survival_prob_pct(p2, 55). life_expectancy_years(p2, 45).
survival_prob_pct(p3, 80). life_expectancy_years(p3, 35).

quality_weight_centi(p1, 90).
quality_weight_centi(p2, 90).
quality_weight_centi(p3, 90).

gestational_weeks(p2, 28).
