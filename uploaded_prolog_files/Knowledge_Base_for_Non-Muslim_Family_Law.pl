% Prolog Knowledge Base for Non-Muslim Family Law System (Malaysia)
% Based on the Law Reform (Marriage and Divorce) Act 1976
% -------------------------------
% PART I: Preliminary
% -------------------------------

% The Act applies exclusively to non-Muslims.
applies_to_non_muslims.

% The Act does not apply to Muslims or marriages under Islamic law.
does_not_apply_to_muslims.

% Marriages valid under any law, religion, custom, or usage before the appointed date are deemed registered under this Act.
deemed_registered_marriage(MarriageDate) :-
    valid_marriage_before_appointed_date(MarriageDate).

% -------------------------------
% PART II: Monogamous Marriages
% -------------------------------

% -------------------------------------------
% PART II-A: Disability to Contract Marriages
% Section 5
% -------------------------------------------

% A person married on the appointed date cannot remarry while previous marriage subsists
disqualified_from_marriage(Person) :-
    married_on_appointed_date(Person),
    marriage_continues(Person).

% A person who was married and then divorced/widowed is disqualified from a third marriage while second is ongoing
disqualified_from_third_marriage(Person) :-
    previously_married(Person),
    currently_married_again(Person),
    marriage_continues(Person).

% A person who was unmarried on the appointed date and married after it, cannot marry another while first marriage subsists
disqualified_from_second_marriage_after_act(Person) :-
    unmarried_on_appointed_date(Person),
    married_after_appointed_date(Person),
    marriage_continues(Person).

% No marriage can be solemnized under any law, religion, or custom except under Part III
must_follow_part_III_for_marriage.

% -------------------------------------------
% Section 6: Avoidance of Marriage by Prior Marriage
% -------------------------------------------

% A marriage in violation of Section 5 is void
marriage_void_due_to_prior_subsisting(Person1, Person2) :-
    disqualified_from_marriage(Person1);
    disqualified_from_marriage(Person2).

% No succession or inheritance rights for a second woman married while first wife is still alive
no_inheritance_rights(SecondWife, Husband) :-
    married_again_during_life(Husband, SecondWife),
    first_marriage_subsists(Husband).

% Maintenance obligation still applies despite void marriage
liable_for_maintenance(Person) :-
    ordered_by_court(Person).

% -------------------------------------------
% Section 7: Offense – Marrying Again
% -------------------------------------------

% Marrying again during the life of spouse is an offense
offense_marrying_again_during_lifetime(Person) :-
    marriage_continues(Person),
    married_again(Person),
    applies_section_494_penal_code(Person).

% The offense committed outside Malaysia can be prosecuted as if committed inside
offense_prosecutable_in_malaysia(Person) :-
    offense_marrying_again_during_lifetime(Person),
    committed_outside_malaysia(Person).

% Prior prosecution is a bar to re-prosecution under Extradition/Criminal Acts
prosecution_barred_if_already_charged(Person) :-
    previously_prosecuted(Person, section_494).

% -------------------------------------------
% Section 8: Continuance of Marriage
% -------------------------------------------

% A marriage continues unless dissolved by specific legal conditions
marriage_continues_until_dissolved(Person1, Person2) :-
    marriage_valid(Person1, Person2),
    not(marriage_void(Person1, Person2)),
    (
        dissolved_by_death(Person1, Person2);
        dissolved_by_court_order(Person1, Person2);
        declared_null_and_void(Person1, Person2)
    ).

% Legal grounds for dissolution
dissolved_by_death(Person1, Person2) :-
    (deceased(Person1); deceased(Person2)).

dissolved_by_court_order(Person1, Person2) :-
    court_dissolution(Person1, Person2).

declared_null_and_void(Person1, Person2) :-
    court_decree_null_void(Person1, Person2).

% -------------------------------------------
% PART III: Marriage – Law Reform (Marriage and Divorce) Act 1976
% -------------------------------------------

% Section 9: Solemnization authority
marriage_must_be_solemnized_by_registrar.

% Section 10: Minimum marriage age
marriage_void_if_under_18(Person1, Person2) :-
    (age(Person1, Age1), Age1 < 18, \+ licensed_under_21(Person1));
    (age(Person2, Age2), Age2 < 18, \+ licensed_under_21(Person2)).

licensed_under_21(Person) :-
    age(Person, Age), Age >= 16,
    licensed_by_chief_minister(Person).

% Section 11: Prohibited relationships
prohibited_relationship(X, Y) :-
    relation(X, Y, Relationship),
    forbidden_relationship(Relationship),
    \+ hindu_exception(X, Y, Relationship).

% Full list of prohibited blood or affinity relationships
forbidden_relationship(grandparent).
forbidden_relationship(parent).
forbidden_relationship(child).
forbidden_relationship(grandchild).
forbidden_relationship(sibling).
forbidden_relationship(great_aunt).
forbidden_relationship(great_uncle).
forbidden_relationship(aunt).
forbidden_relationship(uncle).
forbidden_relationship(niece).
forbidden_relationship(nephew).
forbidden_relationship(great_niece).
forbidden_relationship(great_nephew).
forbidden_relationship(step_parent).
forbidden_relationship(step_child).
forbidden_relationship(adopted).

% Hindu exceptions
hindu_exception(X, Y, niece) :- hindu(X), sister(X, Z), child(Z, Y).
hindu_exception(X, Y, uncle) :- hindu(X), mother(X, M), brother(M, Y).

% Section 12: Consent for marriage under 21
requires_consent(Person, ConsentGiver) :-
    age(Person, Age),
    Age < 21,
    (
        (has_father(Person), ConsentGiver = father);
        (is_illegitimate(Person); father_deceased(Person)), ConsentGiver = mother;
        (is_adopted(Person), has_adopted_father(Person), ConsentGiver = adopted_father);
        (adopted_father_deceased(Person), ConsentGiver = adopted_mother);
        (both_parents_deceased(Person), ConsentGiver = loco_parentis)
    ).

% Court can override consent if unreasonably withheld
court_can_grant_consent(Person) :-
    consent_unreasonably_withheld(Person);
    all_consent_givers_deceased(Person);
    impractical_to_get_consent(Person).

% Section 13–18: Preliminaries to marriage
requires_notice_of_marriage(Person) :-
    resident_for_7_days(Person).

notice_must_be_published(NoticeID) :-
    notice(NoticeID, _),
    published_on_board(NoticeID).

valid_declaration_for_notice(Person1, Person2) :-
    (
        (age(Person1, A1), A1 >= 21; widowed(Person1));
        (age(Person1, A1), A1 >= 16, has_valid_consent(Person1))
    ),
    (
        (age(Person2, A2), A2 >= 21; widowed(Person2));
        (age(Person2, A2), A2 >= 16, has_valid_consent(Person2))
    ),
    \+ prohibited_relationship(Person1, Person2),
    \+ currently_married_to_other(Person1, Person2).

certificate_issued_after_21_days(NoticeID) :-
    notice(NoticeID, Date),
    today(Today),
    days_passed(Date, Today, Days),
    Days >= 21.

certificate_expired(CertificateID) :-
    certificate(CertificateID, Date),
    today(Today),
    days_passed(Date, Today, Days),
    Days > 180.  % 6 months

% Caveats
caveat_entered(Person, Grounds).
caveat_prevents_certificate(Person) :-
    caveat_entered(Person, _),
    \+ caveat_removed(Person).

% Section 21: Licence
chief_minister_may_grant_licence(Person1, Person2) :-
    no_legal_impediment(Person1, Person2),
    necessary_consent_obtained_or_dispensed(Person1, Person2).

licence_granted_under_16_not_allowed(Person) :-
    age(Person, Age),
    Age < 16.

% Section 22: Solemnization
valid_solemnization(Person1, Person2) :-
    (has_certificate_or_licence(Person1, Person2);
     valid_statutory_declaration(Person1, Person2)),
    presence_of_two_witnesses,
    freely_consented(Person1),
    freely_consented(Person2).

% Section 23: Civil solemnization format
civil_marriage_declaration(Person1, Person2) :-
    affirm_free_will(Person1),
    affirm_free_will(Person2),
    informed_of_lifetime_commitment(Person1, Person2),
    affirmed_no_impediment(Person1, Person2),
    affirmed_marital_intent(Person1, Person2).

% Section 24: Religious or customary solemnization
religious_marriage_valid(Person1, Person2) :-
    declaration_delivered,
    religion_matched(Person1, Religion),
    religion_matched(Person2, Religion),
    no_legal_impediment(Person1, Person2),
    reminded_of_monogamy(Person1, Person2).

% Section 25: Marriage register entry
register_marriage(Person1, Person2) :-
    solemnized(Person1, Person2),
    witnesses_present,
    registrar_signed.

% Section 26: Foreign marriages at embassies
embassy_marriage_valid(Person1, Person2) :-
    malaysian_citizen(Person1); malaysian_citizen(Person2),
    both_have_capacity_to_marry,
    marriage_valid_in_country_of_domicile(Person1, Person2),
    notice_given_21_days_prior,
    no_caveat_received.

% ---------------------------------------------------
% PART IV: REGISTRATION OF MARRIAGES
% ---------------------------------------------------

% Section 27: Marriage registration obligation
must_register_marriage(Person) :-
    (ordinarily_resident_in_malaysia(Person);
     (resident_abroad(Person), malaysian_citizen(Person))).

% Section 28: Appointments
registrar_general(Appointee) :- appointed_by(ydpa, Appointee).
assistant_registrar(Appointee, Group) :- appointed_by(minister, Appointee), represents(Group).
superintendent_registrar(Appointee) :- appointed_by(minister, Appointee).
registrar_of_marriages(Appointee) :- appointed_by(minister, Appointee).
assistant_registrar_of_marriages(Appointee) :- appointed_by(minister, Appointee).

% Diplomats as registrars abroad
diplomatic_registrar(Country, Person) :- appointed_in_gazette(Person, Country).

% Marriage district declaration
marriage_district_declared(State, Area) :- declared_by_minister(State, Area).

% Section 29: Marriage registers must be kept
marriage_register_kept_by(Registrar) :-
    registrar_of_marriages(Registrar).

% Section 30: Delivery of copies
copy_of_entry_to_registrar_general(Registrar, Entry) :-
    solemnized_by(Registrar),
    marriage_entry(Entry).

copy_of_entry_to_superintendent(Registrar, Entry) :-
    solemnized_by(Registrar),
    marriage_entry(Entry).

% Section 31: Registration of foreign marriages
must_register_foreign_marriage(Person) :-
    malaysian_citizen(Person);
    domiciled_in_malaysia(Person).

foreign_marriage_register(Person, Location, Date) :-
    foreign_marriage(Person, Location, Date),
    within_registration_period(Date).

within_registration_period(Date) :-
    today(Today),
    date_difference(Today, Date, Days),
    Days =< 180.

% Conditions to register foreign marriage
valid_foreign_marriage_registration(Person1, Person2, Evidence) :-
    (certificate(Evidence); oral_or_documentary_evidence(Evidence)),
    furnish_required_particulars(Person1, Person2),
    declaration_signed(Person1, Person2).

% Allow exception if one party absent with reason
one_party_absent_allowed(Person, Reason) :-
    good_sufficient_reason(Reason),
    entered_in_register_with_reason(Person, Reason).

% Penalty for late registration
late_registration_with_penalty(Person1, Person2) :-
    missed_registration_deadline(Person1, Person2),
    paid_prescribed_penalty.

% Section 32: Unlawful registers
offense_unlawful_register(Person) :-
    keeps_fake_register(Person);
    issues_fake_certificate(Person).

% Section 33: Voluntary registration of pre-Act marriages
may_voluntarily_register_pre_act_marriage(Person1, Person2) :-
    marriage_solenmnized_pre_act(Person1, Person2),
    not_registered_yet(Person1, Person2).

register_pre_act_marriage(Person1, Person2) :-
    may_voluntarily_register_pre_act_marriage(Person1, Person2),
    evidence_provided(Person1, Person2),
    registrar_satisfied(Person1, Person2),
    not_void_under_act(Person1, Person2).

% Deliver copies after voluntary registration
voluntary_register_copies(Person1, Person2, Registrar) :-
    register_pre_act_marriage(Person1, Person2),
    deliver_to_party(triplicate_copy, Person1, Person2),
    deliver_to_registrar_general(original_copy, Registrar),
    deliver_to_superintendent_registrar(duplicate_copy, Registrar).

% Section 34: Legal effect of registration
registration_does_not_alter_validity(Marriage) :-
    valid_by_other_means(Marriage);
    invalid_by_other_means(Marriage).

% ---------------------------------------------------
% PART V: PENALTIES AND MISCELLANEOUS PROVISIONS
% ---------------------------------------------------

% Section 35: Omission to appear before Registrar
offense_omission_to_appear(Person) :-
    required_to_appear_under_31(Person),
    failed_to_appear_within_time(Person),
    penalty(omission_to_appear, fine(1000), prison(1)).

% Section 36: Contravention of section 32
offense_contravene_section_32(Person, Count) :-
    contravened_section_32(Person),
    (
        Count = 1 -> penalty(section_32, fine(1000), prison(1));
        Count > 1 -> penalty(section_32_repeat, fine(2000), prison(2))
    ).

% Section 37: Interference with marriage
offense_interfere_with_marriage(Person, Type) :-
    (Type = force_to_marry;
     Type = prevent_marriage_over_21),
    penalty(interference, fine(3000), prison(3)).

% Section 38: False declarations
offense_false_declaration(Person) :-
    made_false_declaration_to_procure_marriage(Person),
    penalty(false_oath, fine(3000), prison(3)).

% Section 39: False caveat
offense_false_caveat(Person) :-
    caveat_with_false_representation(Person);
    falsely_claimed_consent_role(Person),
    penalty(false_caveat, fine(3000), prison(3)).

% Section 40: Unauthorized solemnization
offense_unauthorized_solemnization(Person) :-
    not_authorized_to_solemnize(Person),
    solemnized_marriage(Person),
    penalty(unauthorized_solemnization, fine(15000), prison(10)).

% Section 41: Offenses relating to solemnization
offense_invalid_solemnization_by_officiant(Person) :-
    (
        no_certificate_or_licence(Person);
        no_two_witnesses_present(Person);
        notice_expired_before_marriage(Person)
    ),
    penalty(invalid_solemnization, fine(5000), prison(3)).

offense_invalid_certificate_by_registrar(Registrar) :-
    (
        failed_to_publish_notice(Registrar);
        ignored_caveat_procedures(Registrar);
        violated_section_16(Registrar)
    ),
    penalty(invalid_certificate_issue, fine(5000), prison(3)).

offense_marriage_against_act(Person) :-
    violated_part_III(Person),
    penalty(illegal_marriage, fine(5000), prison(3)).

% Section 42: Falsifying or destroying marriage records
offense_falsify_or_destroy_register(Person, Type) :-
    (
        Type = destroy_register;
        Type = counterfeit_entry;
        Type = insert_false_entry
    ),
    penalty(destroy_falsify_register, fine(10000), prison(7)).

% Section 43: Public Prosecutor authorization required
requires_prosecution_authority(Offense) :-
    offense_requires_authorization(Offense),
    authorized_by(public_prosecutor).

% Section 44: Correction of errors
may_correct_register_error(Register, ErrorDetails) :-
    authorized_by(registrar_general),
    margin_entry(Register, ErrorDetails),
    copy_sent_to([registrar_general, superintendent_registrar]).

% Section 45: Inspection and search
may_inspect_register(Applicant) :-
    stated_reason(Applicant),
    paid_fee(Applicant),
    approved_by(registrar_general; superintendent_registrar).

may_receive_certified_extract(Applicant) :-
    may_inspect_register(Applicant),
    certified_extract_issued(Applicant).

% Section 46: Proof of registration
valid_marriage_proof(RegisterEntry) :-
    certified_by_registrar(RegisterEntry),
    prima_facie_evidence(RegisterEntry).

% Section 46A: Damaged registers
transfer_damaged_register(OldRegister, NewRegister) :-
    damaged_or_illegible(OldRegister),
    registrar_general_approved_transfer(NewRegister).

preserve_registers_digital :-
    registrar_general_authorized,
    (
        photographed_on_microfilm;
        digitally_recorded
    ).

% Section 46B: Missing registers
re_register_missing_entry(MarriageEntry) :-
    register_missing_or_destroyed,
    registrar_general_satisfied_from_evidence(MarriageEntry).

% ---------------------------------------------------
% PART VI: DIVORCE
% ---------------------------------------------------

% Section 47: Principles of law
valid_principles_for_divorce_case :-
    conforms_to_high_court_principles_in_England.

% Section 48: Extent of power to grant relief
valid_divorce_grounds(MarriageID) :-
    marriage_registered(MarriageID),
    marriage_monogamous(MarriageID),
    domicile(MarriageID, _, malaysia),
    domicile(MarriageID, _, malaysia).

valid_judicial_separation_grounds(MarriageID) :-
    marriage_registered(MarriageID),
    marriage_monogamous(MarriageID),
    both_parties_reside_in_malaysia(MarriageID).

% Section 49: Additional jurisdiction in proceedings by a wife
valid_jurisdiction_wife(MarriageID) :-
    wife_resident_in_malaysia(MarriageID),
    been_resident_for_two_years(MarriageID).

valid_jurisdiction_wife_deported(MarriageID) :-
    wife_resident_in_malaysia(MarriageID),
    husband_deported(MarriageID, _),
    husband_domiciled_in_malaysia(MarriageID).

% Section 50: Restriction on petitions within two years of marriage
can_petition_divorce_early(MarriageID) :-
    marriage_duration(MarriageID, Duration),
    Duration >= 2,
    exceptional_circumstances(MarriageID),
    hardship_suffered(MarriageID),
    reasonable_probability_of_reconciliation(MarriageID).

can_petition_after_specified_period(MarriageID) :-
    marriage_duration(MarriageID, Duration),
    Duration >= 2.

% Section 51: Dissolution on ground of conversion to Islam
divorce_due_to_conversion(MarriageID) :-
    converted_to_islam(_, MarriageID),
    not(converted_to_islam(_, MarriageID)),
    three_months_period_passed(MarriageID).

% Section 52: Dissolution by mutual consent
divorce_mutual_consense(MarriageID) :-
    both_parties_agree(MarriageID),
    marriage_duration(MarriageID, Duration),
    Duration >= 2,
    satisfactory_provision_for_children(MarriageID).

% Section 53: Breakdown of marriage to be sole ground for divorce
divorce_due_to_breakdown(MarriageID) :-
    marriage_duration(MarriageID, Duration),
    breakdown_of_marriage(MarriageID),
    reasonable_inquiry(MarriageID).

% Section 54: Proof of breakdown
valid_reasons_for_breakdown(MarriageID) :-
    committed_adultery(_),
    intolerable_to_live_with(_),
    continuous_desertion(_, MarriageID, _),
    lived_apart_for_at_least_two_years(MarriageID, _).

% Section 55: Provisions designed to encourage reconciliation
reconciliation_attempt_required(MarriageID) :-
    petitioner_has_recourceto_assistance(MarriageID),
    court_can_delay_proceedings_for_reconciliation(MarriageID).

% Section 56: Rules to provide for agreements to be referred to court
can_refer_agreement_to_court(MarriageID) :-
    parties_in_dispute(MarriageID),
    agreement_between_parties(MarriageID),
    court_can_assess_reasonableness(MarriageID).

% Section 57: Contents of divorce petition
valid_divorce_petition(MarriageID) :-
    includes_marriage_details(MarriageID),
    includes_previous_matrimonial_proceedings(MarriageID),
    includes_allegations(MarriageID),
    includes_agreement_for_support(MarriageID),
    includes_steps_taken_for_reconciliation(MarriageID).

% Section 58: Damages for adultery may be claimed against co-respondent
can_claim_damages_for_adultery(MarriageID) :-
    adultery_alleged(MarriageID),
    co_respondent_involved(MarriageID),
    sufficient_evidence_for_adultery(MarriageID).

% Section 59: Powers of court on claim to damages for adultery
court_can_award_damages(MarriageID) :-
    adultery_proven(MarriageID),
    co_respondent_awarded_damages(MarriageID),
    court_can_direct_payment_for_minor_children(MarriageID).

% Section 60: Hearing of petition
court_can_grant_relief(MarriageID) :-
    evidence_sufficient_for_respondent(MarriageID),
    respondent_entitled_to_relief(MarriageID).

% Section 61: Decree nisi and proceedings thereafter
decree_nisi(MarriageID) :-
    divorce_granted(MarriageID),
    decree_nisi_issued(MarriageID),
    three_months_period_passed(MarriageID).

can_apply_for_decree_absolute(MarriageID) :-
    decree_nisi_granted(MarriageID),
    no_appeal(MarriageID),
    three_months_passed(MarriageID).

% Section 62: Remarriage of divorced persons
remarriage_possible(MarriageID) :-
    decree_absolute(MarriageID),
    no_appeal_right(MarriageID),
    no_appeal_after_time_period(MarriageID).

% Section 63: Proceedings for decree nisi of presumption of death and divorce
can_declare_dead_and_divorce(MarriageID) :-
    married_person_missing(MarriageID),
    reasonable_grounds_for_death(MarriageID),
    seven_years_absence(MarriageID).

% Section 64: Judicial separation
judicial_separation_possible(MarriageID) :-
    marital_difficulties(MarriageID),
    desertion_or_intolerable_behavior(MarriageID),
    judicial_separation_approved(MarriageID).

% Section 65: Judicial separation no bar to petition for divorce
can_divorce_after_judicial_separation(MarriageID) :-
    judicial_separation(MarriageID),
    no_resumption_of_cohabitation(MarriageID).

% Section 66: Property of wife after judicial separation
wife_property_after_separation(MarriageID, Property) :-
    judicial_separation_granted(MarriageID),
    wife_death(MarriageID),
    wife_dies_intestate(MarriageID),
    property_divided_as_if_husband_dead(MarriageID, Property).

% Section 67: Nullity of marriage
valid_nullity_case(MarriageID) :-
    marriage_registered(MarriageID),
    marriage_monogamous(MarriageID),
    both_parties_reside_in_malaysia(MarriageID).

% Section 68: Petition for nullity of marriage
valid_nullity_petition(MarriageID) :-
    petitioner_requesting_nullity(MarriageID),
    reasonable_grounds_for_nullity(MarriageID).

% Section 69: Grounds on which a marriage is void
marriage_void(MarriageID) :-
    already_married(MarriageID),
    party_underage(MarriageID),
    parties_in_prohibited_degrees(MarriageID),
    not_both_male_female(MarriageID).

% Section 70: Grounds on which a marriage is voidable
marriage_voidable(MarriageID) :-
    nonconsummation_due_to_incapacity(MarriageID),
    nonconsummation_due_to_wilful_refusal(MarriageID),
    invalid_consent(MarriageID),
    mentally_disordered_person(MarriageID),
    suffering_from_venereal_disease(MarriageID),
    respondent_pregnant_by_someone_else(MarriageID).

% Section 71: Bars to relief where marriage is voidable
can_grant_nullity(MarriageID) :-
    not(approbation_by_petitioner(MarriageID)),
    not(knowledge_of_voidable_marriage(MarriageID)),
    unjust_to_grant_decree(MarriageID).

% Section 72: Marriages governed by foreign law or celebrated abroad under Malaysian law
foreign_marriage_validity(MarriageID) :-
    marriage_abroad(MarriageID),
    private_international_law(MarriageID),
    not_applied_inapplicable_groungs(MarriageID).

% Section 73: Effect of decree of nullity in case of voidable marriage
nullity_decree_effect(MarriageID) :-
    valid_nullity_case(MarriageID),
    decree_of_nullity(MarriageID),
    marriage_treated_as_valid_until_decree(MarriageID).

% Section 74: Collusion not to be bar to relief in cases of nullity
collusion_not_bar(MarriageID) :-
    no_collusion_found(MarriageID),
    nullity_granted(MarriageID).

% Section 75: Legitimacy where nullity decree made
child_legitimate_after_nullity(MarriageID, Child) :-
    valid_marriage(MarriageID),
    child_born_after_nullity(MarriageID, Child).

% ---------------------------------------------------
% PART VII: MATTERS INCIDENTAL TO MATRIMONIAL PROCEEDINGS
% ---------------------------------------------------

% Section 76: Power for court to order division of matrimonial assets
court_can_order_division_of_assets(MarriageID) :-
    decree_granted(MarriageID),
    assets_acquired_by_joint_effort(MarriageID),
    division_based_on_contributions(MarriageID).

court_can_order_division_of_sole_assets(MarriageID) :-
    decree_granted(MarriageID),
    assets_acquired_by_sole_effort(MarriageID),
    division_based_on_welfare_of_family(MarriageID).

% Court considers contributions, debts, and needs of children when dividing assets
division_based_on_contributions(MarriageID) :-
    contributions_of_both_parties(MarriageID),
    debts_owed_by_parties(MarriageID),
    needs_of_minor_children(MarriageID),
    equality_in_asset_division(MarriageID).

division_based_on_welfare_of_family(MarriageID) :-
    contributions_of_non_acquiring_party(MarriageID),
    needs_of_minor_children(MarriageID),
    greater_proportion_to_acquiring_party(MarriageID).

% Section 77: Power for court to order maintenance of spouse
court_can_order_spouse_maintenance(MarriageID) :-
    divorce_granted(MarriageID),
    spouse_needs_maintenance(MarriageID).

court_can_order_wife_to_pay_maintenance(MarriageID) :-
    wife(MarriageID),
    husband_incapacitated(MarriageID),
    wife_ability_to_pay(MarriageID).

% Section 78: Assessment of maintenance
court_assesses_maintenance(MarriageID) :-
    means_of_parties(MarriageID),
    needs_of_parties(MarriageID),
    degree_of_responsibility_for_breakdown(MarriageID).

% Section 79: Power for court to order security for maintenance
court_can_order_security_for_maintenance(MarriageID) :-
    maintenance_ordered(MarriageID),
    maintenance_security_required(MarriageID),
    property_vested_in_trustees(MarriageID).

% Section 80: Compounding of maintenance
agreement_for_compounding_maintenance(MarriageID) :-
    capital_sum_agreement(MarriageID),
    court_approval_required(MarriageID).

% Section 81: Duration of orders for maintenance
maintenance_duration(MarriageID) :-
    unsecured_maintenance(MarriageID),
    death_of_spouse(MarriageID).

secured_maintenance_ends_on_death(MarriageID) :-
    secured_maintenance(MarriageID),
    death_of_spouse(MarriageID).

% Section 82: Right to maintenance to cease on remarriage
maintenance_ceases_on_remarriage(MarriageID) :-
    remarriage_of_divorced_person(MarriageID),
    maintenance_order_in_place(MarriageID).

maintenance_ceases_on_adultery(MarriageID) :-
    living_in_adultery(MarriageID),
    maintenance_order_in_place(MarriageID).

% Section 83: Power for court to vary orders for maintenance
court_can_vary_maintenance_order(MarriageID) :-
    existing_maintenance_order(MarriageID),
    material_change_in_circumstances(MarriageID),
    misrepresentation_or_mistake(MarriageID).

% Section 84: Power for court to vary agreements for maintenance
court_can_vary_maintenance_agreement(MarriageID) :-
    maintenance_agreement_in_place(MarriageID),
    material_change_in_circumstances(MarriageID).

% Section 85: Maintenance payable under order of court to be inalienable
maintenance_non_transferable(MarriageID) :-
    maintenance_order_in_place(MarriageID),
    maintenance_cannot_be_levied(MarriageID).

% Section 86: Recovery of arrears of maintenance
arrears_of_maintenance_recoverable(MarriageID) :-
    arrears_due(MarriageID),
    maintenance_debt(MarriageID),
    maintenance_due_before_death_or_bankruptcy(MarriageID).

arrears_recoverable_by_representatives(MarriageID) :-
    arrears_due_before_death(MarriageID),
    legal_personal_representatives(MarriageID).

arrears_time_limit(MarriageID) :-
    arrears_due_more_than_three_years_ago(MarriageID),
    not_recoverable_in_suit(MarriageID).

% ---------------------------------------------------
% PART VIII: PROTECTION OF CHILDREN
% ---------------------------------------------------

% Section 87: Meaning of "child"
child_of_marriage(Child) :-
    under_age(Child, 18).

% Section 88: Power for court to make order for custody
court_can_order_custody(MarriageID, Child) :-
    decree_granted(MarriageID),
    welfare_of_child(MarriageID, Child),
    consider_parent_wishes(MarriageID, Child),
    consider_child_wishes(MarriageID, Child).

% Section 89: Orders subject to conditions
court_can_impose_conditions_on_custody(MarriageID, Child) :-
    decree_granted(MarriageID),
    conditions_for_custody(MarriageID, Child),
    parent_rights(MarriageID, Child).

% Section 90: Declaratory order as to unfitness of parent to have custody
court_can_declare_unfit_parent(MarriageID) :-
    decree_granted(MarriageID),
    unfit_parent(MarriageID),
    rescind_order_possible(MarriageID).

% Section 91: Custody of children deemed legitimate
mother_entitled_to_custody(Child) :-
    child_legitimate(Child),
    no_agreement_or_order(MarriageID, Child).

% Section 92: Duty to maintain children
parent_duty_to_maintain(Parent, Child) :-
    duty_to_maintain_child(Parent, Child),
    provision_of_accommodation(Parent, Child),
    provision_of_clothing_and_food(Parent, Child).

% Section 93: Power for court to order maintenance for children
court_can_order_child_maintenance(MarriageID, Child) :-
    decree_granted(MarriageID),
    neglect_or_refusal_to_provide(Parent, Child),
    child_in_care_of_other(MarriageID),
    maintenance_ordered(MarriageID, Child).

% Section 94: Power for court to order security for maintenance
court_can_order_security_for_child_maintenance(MarriageID, Child) :-
    maintenance_ordered(MarriageID, Child),
    property_vested_in_trustees(MarriageID, Child).

% Section 95: Duration of orders for custody and maintenance
duration_of_custody_or_maintenance(MarriageID, Child) :-
    custody_order(MarriageID, Child),
    child_age(Child, 18),
    child_disability(Child).

% Section 96: Power for court to vary orders for custody or maintenance
court_can_vary_orders_for_custody_or_maintenance(MarriageID, Child) :-
    existing_order(MarriageID, Child),
    misrepresentation_or_mistake_in_order(MarriageID),
    material_change_in_circumstances(MarriageID, Child).

% Section 97: Power for court to vary agreement for custody or maintenance
court_can_vary_agreement_for_custody_or_maintenance(MarriageID, Child) :-
    existing_agreement(MarriageID, Child),
    material_change_in_circumstances(MarriageID, Child).

% Section 98: Recovery of arrears of maintenance
arrears_of_child_maintenance_recoverable(MarriageID, Child) :-
    arrears_due(MarriageID, Child),
    maintenance_debt(MarriageID, Child),
    maintenance_due_before_death_or_bankruptcy(MarriageID).

% Section 99: Duty to maintain child accepted as member of family
father_duty_to_maintain_accepted_child(Child) :-
    accepted_as_family_member(Child),
    failure_of_biological_parents_to_maintain(Child),
    maintain_child_as_family_member(Child).

arrears_recoverable_from_biological_parents(MarriageID, Child) :-
    sums_expenditures_recoverable(MarriageID, Child).

% Section 100: Court to have regard to advice of welfare officers, etc.
court_can_take_advice_on_welfare(MarriageID, Child) :-
    advice_on_welfare(MarriageID, Child),
    court_is_not_bound_to_follow_advice(MarriageID).

% Section 101: Power for court to restrain taking of child out of Malaysia
court_can_issue_injunction_restrain_child_out_of_Malaysia(MarriageID, Child) :-
    pending_matrimonial_proceedings(MarriageID),
    custody_agreement_in_place(MarriageID, Child),
    injunction_to_restrain(MarriageID, Child).

court_can_grant_leave_for_travel(MarriageID, Child) :-
    leave_for_travel_granted(MarriageID, Child),
    conditional_leave(MarriageID, Child).

% Section 102: Power for court to set aside and prevent dispositions intended to defeat claims to maintenance
court_can_set_aside_disposition(MarriageID) :-
    matrimonial_proceeding_pending(MarriageID),
    maintenance_ordered(MarriageID),
    disposition_made_to_defeat_maintenance_claim(MarriageID).

court_can_prevent_intended_disposition(MarriageID) :-
    disposition_intended_to_defeat_maintenance(MarriageID),
    injunction_granted(MarriageID).

% Section 103: Injunction against molestation
court_can_order_injunction_against_molestation(MarriageID) :-
    matrimonial_proceedings_pending(MarriageID),
    decree_granted(MarriageID),
    injunction_ordered(MarriageID).

% ---------------------------------------------------
% PART IX: MISCELLANEOUS
% ---------------------------------------------------

% Section 104: Recognition of marriage contracted abroad
valid_abroad_marriage(MarriageID) :-
    marriage_contracted_abroad(MarriageID),
    form_required_by_law(MarriageID),
    capacity_to_marry_in_country_of_domicile(MarriageID),
    capacity_to_marry_under_Malaysian_law(MarriageID).

% Section 105: Recognition of marriages contracted in Embassies, etc., in Malaysia
valid_embassy_marriage(MarriageID) :-
    marriage_contracted_in_embassy(MarriageID),
    form_required_by_law_of_country(MarriageID),
    capacity_to_marry_under_law_of_country(MarriageID),
    capacity_to_marry_under_Malaysian_law(MarriageID).

% Section 106: Requirement of reference to conciliatory body before petition for divorce
reference_to_conciliatory_body_required(MarriageID) :-
    petition_for_divorce(MarriageID),
    conciliatory_body_certification(MarriageID),
    not_exceptional_case(MarriageID).

exceptional_case_for_divorce(MarriageID) :-
    petitioner_deserted(MarriageID);
    respondent_residing_abroad(MarriageID);
    respondent_refuses_to_attend(MarriageID);
    respondent_imprisoned_for_five_years_or_more(MarriageID);
    respondent_has_incurable_mental_illness(MarriageID);
    exceptional_circumstances(MarriageID).

% Section 107: Maintenance of register of divorces and annulments
register_divorce_or_annulment(MarriageID) :-
    divorce_granted(MarriageID),
    annulment_granted(MarriageID),
    certified_copy_sent_to_registrar(MarriageID).

register_divorce_abroad(MarriageID) :-
    divorce_granted_abroad(MarriageID),
    registrar_satisfied_with_foreign_decree(MarriageID).

mark_marriage_dissolved(MarriageID) :-
    divorce_granted(MarriageID),
    registrar_marks_as_dissolved(MarriageID).

% Section 108: Power to make rules
rules_for_matrimonial_proceedings(MarriageID) :-
    rules_commitee(MarriageID),
    fees_and_costs_regulation(MarriageID).

ministerial_rules(MarriageID) :-
    ministerial_rules_for_marriage(MarriageID),
    rules_for_registrar_exercises(MarriageID),
    rules_for_certificate_and_register_storage(MarriageID),
    rules_for_marriage_searches_and_copies(MarriageID).

% Section 109: Repeal
proceedings_under_previous_laws(MarriageID) :-
    proceeding_under_previous_law(MarriageID),
    continuation_under_new_act(MarriageID),
    petition_for_divorce_stayed_pending_conciliation(MarriageID),
    decree_nisi_proceeding_as_if_Act_not_passed(MarriageID).
