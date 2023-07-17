********************************************************************************
** Annonymize 


use dtmii_baseline_all, clear

drop locationlatitude locationlongitude locationaltitude locationaccuracy ag_name ag_respondent hh_name hh_respondent hh_head_name mobile_primary mobile_secondary loc_I loc_P loc_C
drop enumerator_name
label drop supervisor
label drop enumerator
label drop village

save dtmii_baseline_noid, replace


use dtmii_midline_all, clear

drop enumerator_name village_label survey_name ag_name hh_decision_name ag_respondent hh_respondent mobile_primary mobile_secondary loc_I loc_P loc_C
drop label merge_villagelist

save dtmii_midline_noid, replace


use dtmii_endline_all, clear
drop enumerator_name survey_name ag_name hh_decision_name ag_name_age hh_respondent mobile_primary mobile_secondary
drop ag_respondent 
label drop supervisor
label drop enumerator
drop image_endline key image_midline label merge_* dup_tag

save dtmii_endline_noid, replace