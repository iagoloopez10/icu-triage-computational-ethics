% =============================================================================
% engine/rules.lp
% ICU ventilator triage — constrained consequentialism with lexicographic
% aggregation of consequentialist objectives.
%
% Architecture:
%   Hard deontological constraints (non-negotiable, enforced by :-)
%   subject to
%   Lexicographic optimization (lives > life_years > qalys)
%
% Layer 2 (Arg2P) audits the resulting decision against Ross's prima
% facie duties and may flag it as questionable or indefensible.
% =============================================================================


% -----------------------------------------------------------------------------
% Vocabulary (documentation; predicates come from the case .lp file)
% -----------------------------------------------------------------------------
% patient(P).                       atom denoting a patient
% ventilator(V).                    atom denoting a ventilator
% available(V).                     V is available for allocation
% already_assigned(P, V).           P is currently on V (extubation cases)
%
% Clinical facts (per patient):
%   age(P, Years).                  integer years
%   sofa(P, Score).                 integer 0..24
%   cci(P, Score).                  Charlson Comorbidity Index 0..37
%   survival_prob_pct(P, Pct).      0..100
%   life_expectancy_years(P, Y).    integer years remaining if survives
%   idsa_eligible(P).               binary clinical floor
%   quality_weight_centi(P, W).     0..100 — health-state quality weight x100
%
% Contextual facts (used by Layer 2 / Arg2P, not all enter the optimizer):
%   gestational_weeks(P, Weeks).            only when pregnant
%   dependents(P, N).
%   healthcare_worker(P).
%   disability_permanent(P).
%   instrumental_lives_factor(P, N).        rule-utilitarian boost in @3 tier
% -----------------------------------------------------------------------------

#defined already_assigned/2.
#defined gestational_weeks/2.
#defined dependents/2.
#defined healthcare_worker/1.
#defined disability_permanent/1.
#defined instrumental_lives_factor/2.


% =============================================================================
% Derived predicates
% =============================================================================

% --- Age bands (defended in report §3.2) ---
age_band(P, child)        :- patient(P), age(P, A), A <  18.
age_band(P, young_adult)  :- patient(P), age(P, A), A >= 18, A <  40.
age_band(P, adult)        :- patient(P), age(P, A), A >= 40, A <  65.
age_band(P, elderly)      :- patient(P), age(P, A), A >= 65, A <  80.
age_band(P, very_elderly) :- patient(P), age(P, A), A >= 80.

% --- SOFA bands ---
sofa_band(P, low)    :- patient(P), sofa(P, S), S <=  7.
sofa_band(P, medium) :- patient(P), sofa(P, S), S >=  8, S <= 10.
sofa_band(P, high)   :- patient(P), sofa(P, S), S >= 11.

% --- Comorbidity bands ---
comorbidity_band(P, low)    :- patient(P), cci(P, C), C <= 2.
comorbidity_band(P, medium) :- patient(P), cci(P, C), C >= 3, C <= 5.
comorbidity_band(P, high)   :- patient(P), cci(P, C), C >= 6.

% --- Instrumental lives contribution ---
% Default contribution = 1 per patient. Patients with an
% instrumental_lives_factor/2 fact (e.g. healthcare workers) contribute
% N effective lives at the @3 tier of the hierarchy. This encodes the
% rule-utilitarian argument EXPLICITLY in Layer 1, where Layer 2 then
% audits whether it overrides equal consideration. See report §4.4.
has_instrumental_factor(P) :- instrumental_lives_factor(P, _).
effective_lives_contribution(P, N) :-
    patient(P), instrumental_lives_factor(P, N).
effective_lives_contribution(P, 1) :-
    patient(P), not has_instrumental_factor(P).

% --- Outcome scores ---
% life_years_score = survival_prob_pct * life_expectancy_years.
% Unit: centi-years. Comparison-only.
life_years_score(P, Score) :-
    patient(P),
    survival_prob_pct(P, S),
    life_expectancy_years(P, L),
    Score = S * L.

% qaly_score = survival_prob_pct * life_expectancy_years * quality_weight_centi.
% Requires quality_weight_centi/2 to be present for every IDSA-eligible
% patient; missing weight = silent 0 score.
qaly_score(P, Score) :-
    patient(P),
    survival_prob_pct(P, S),
    life_expectancy_years(P, L),
    quality_weight_centi(P, W),
    Score = S * L * W.


% =============================================================================
% Generation
% =============================================================================
{ assign(P, V) : patient(P), idsa_eligible(P) } 1 :- ventilator(V), available(V).
{ assign(P, V) : ventilator(V), available(V) } 1 :- patient(P), idsa_eligible(P).

assigned_patient(P)    :- assign(P, _).
assigned_ventilator(V) :- assign(_, V).

% Withdrawal: a previously-assigned patient absent from the new assignment.
% The act/omission asymmetry of withdrawal vs non-allocation is NOT
% encoded here. Layer 2 (Arg2P, Ross) is responsible for that audit.
withdrawal(P, V) :- already_assigned(P, V), not assigned_patient(P).


% =============================================================================
% Hard constraints (deontological floor)
% =============================================================================

% (H1) Clinical eligibility floor — IDSA.
%      Enforced syntactically by `: idsa_eligible(P)` in the choice rules.

% (H2) Resource conservation.
%      Enforced syntactically by `: ventilator(V), available(V)`.

% (H3) Non-fungibility of persons (1 patient <-> 1 ventilator).
%      Enforced syntactically by `} 1` upper bounds.

% (H4) No-waste: a ventilator may not stay idle while an eligible patient
%      remains unassigned.
:- ventilator(V), available(V), not assigned_ventilator(V),
   patient(P), idsa_eligible(P), not assigned_patient(P).

% (H5) Non-discrimination: architectural — the vocabulary contains no
%      predicates for sex, race, religion, or sexual orientation.


% =============================================================================
% Lexicographic consequentialist objectives
% =============================================================================
% @3 — Effective lives saved (lives + rule-utilitarian instrumental factor)
% @2 — Expected life-years
% @1 — Expected QALYs
%
% Clingo resolves in cascade. Ties surviving all three levels are
% emitted as multiple optimal models; the runner's lottery picks one.

#maximize { N@3, P, V : assign(P, V), effective_lives_contribution(P, N) }.
#maximize { Y@2, P, V : assign(P, V), life_years_score(P, Y) }.
#maximize { Q@1, P, V : assign(P, V), qaly_score(P, Q) }.


% =============================================================================
% Output
% =============================================================================
#show assign/2.
#show withdrawal/2.
