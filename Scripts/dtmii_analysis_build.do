********************************************************************************
* Project: DTMII
* Date:  June 2023
* Author: JGMalacarne
* Description: Builds Datasets for analysis
********************************************************************************
clear all
set more off

**Set Directories
global home "home pathway"
global dofiles "$home\Replication Scripts"
global data "$home\Replication Data"
** Guide to error codes: http://xkcd.com/1024/

********************************************************************************
/* 
This file combines baseline, midline, and endline data into an ANCOVA and Difference-in-difference dataset.

It also merges in relevant weather data.
*/

global hhchars country district village hh_id treatment_status refid year triad_id

global yvars maize_improved maize_dt_use maize_improved_kg maize_local_kg maize_total_kg ///
	maize_area_ha harvest_maize_kg yield_maize_kgha yield_kgperseeduse maize_dt_kg nonmaize_area_ha ///
	ag_fert_use fert_planting fert_top total_fert_kg ///
	food_secure  food_insecure_worst food_nofood food_reducemeals_children ///
	food_reducemeals_females food_reducemeals_males food_limitvariety food_lesspreferred food_24hoursnone dietarydiversity foodsecurity_HFIAS foodinsecurity_cont


global control sps_points asset_cattle credit_formal credit_informal_small credit_informal_medium credit_informal_large maize_local

********************************************************************************
cd "$data"
foreach y in baseline midline endline {

use dtmii_`y'_noid, clear

cap drop _merge
cap drop value
gen value = village
	label var value "Village code for matching to master village list"
	
merge m:1 value using dtmii_master_villagelist, keepusing(triad_id)
	keep if _merge == 3
	drop _merge

** Generate Additional Food Insecurity Measures
gen foodsecurity_HFIAS = 0
	label define HFIAS 0 "Missing" 1 "Secure" 2 "Mild Insecure"  3 "Moderate Insecure" 4 "Severe Insecure"
	label values foodsecurity_HFIAS HFIAS
	label var foodsecurity_HFIAS "Food Security HFIAS"
	
	foreach x in food_lesspreferred food_limitvariety food_reducemeals_males food_reducemeals_females food_reducemeals_children food_nofood food_24hoursnone {
		replace `x' = 0 if `x' == .
		}
		
	replace foodsecurity_HFIAS = 1 if food_secure == 1
	replace foodsecurity_HFIAS = 2 if food_lesspreferred >= 1 
		replace foodsecurity_HFIAS = 2 if food_limitvariety >= 1 
	replace foodsecurity_HFIAS = 3 if food_limitvariety >= 3
		replace foodsecurity_HFIAS = 3 if food_reducemeals_females >= 1 
		replace foodsecurity_HFIAS = 3 if food_reducemeals_males >= 1 
		replace foodsecurity_HFIAS = 3 if food_reducemeals_children >= 1 
	replace foodsecurity_HFIAS = 4 if food_reducemeals_males >= 5
		replace foodsecurity_HFIAS = 4 if food_reducemeals_females >= 5 
		replace foodsecurity_HFIAS = 4 if food_reducemeals_children >= 5 
		replace foodsecurity_HFIAS = 4 if food_nofood >= 1
		replace foodsecurity_HFIAS = 4 if food_24hoursnone >= 1
	
	replace foodsecurity_HFIAS = . if foodsecurity_HFIAS == 0

gen foodinsecurity_cont = (food_lesspreferred + 2*food_limitvariety + 3*food_reducemeals_females + 3*food_reducemeals_males + 3*food_reducemeals_children + 4*food_nofood + 4*food_24hoursnone) 
	label var foodinsecurity_cont "Continuous Food Security: 0 = food secure, bigger numbers worse"
	replace foodinsecurity_cont = 100 if foodinsecurity_cont >100


** Replace missing with zeroes on relevant quantity variables
replace maize_improved_kg = 0 if maize_improved == 0 & maize_improved_kg == .
replace maize_local_kg = 0 if maize_local==0 & maize_local_kg == .
replace fert_planting = 0 if ag_fert_use == 0 & fert_planting == .
replace fert_top = 0 if ag_fert_use == 0 & fert_top == .
replace total_fert_kg = 0 if ag_fert_use == 0 & total_fert_kg == .
replace maize_dt_kg = 0 if maize_dt_use == 0 & maize_dt_kg == .
replace yield_maize_kgha = . if harvest_maize_kg == .
replace yield_kgperseeduse = . if harvest_maize_kg == .

** Generate T1 and T2
tabulate treatment_status, g(t)
	rename(t1 t2 t3) (t0 t1 t2)
	label var t0 "Control"
	label var t1 "DTM"
	label var t2 "DTII"

gen mozambique = 0
	replace mozambique = 1 if country == "mozambique"

keep $hhchars $control $yvars t0 t1 t2

cd "$data"
save `y'_temp,replace
}

********************************************************************************
* Baseline Values Dataset
********************************************************************************
cd "$data"
use baseline_temp, clear

keep refid $yvars
foreach x in $yvars {
	rename `x' `x'_2016
	label var `x'_2016 "Y_{2016}"
	}
save temp2016,replace




********************************************************************************
* Best Plot Characteristics Dataset
********************************************************************************

** Add Number of Maize Plots, Best Plot Area, Best Plot Seed Quantities.
cd "$data"
use dtmii_baseline_noid, clear

keep refid maize_plots best_plot_ha best_plot_seeds_kg maize_local_quantity maize_local_quantity_unit seed_quantity_1 seed_quantity_unit_1 seed_quantity_2 seed_quantity_unit_2 seed_quantity_3 seed_quantity_unit_3 seed_quantity_4 seed_quantity_unit_4 seed_quantity_5 seed_quantity_unit_5


rename (maize_plots best_plot_ha best_plot_seeds_kg) (maize_plots_2016 best_plot_ha_2016 best_plot_seeds_kg_2016)
rename (maize_local_quantity maize_local_quantity_unit) (maize_local_quantity_2016 maize_local_quantity_unit_2016)
rename (seed_quantity_1 seed_quantity_unit_1 seed_quantity_2 seed_quantity_unit_2 seed_quantity_3 seed_quantity_unit_3 seed_quantity_4 seed_quantity_unit_4 seed_quantity_5 seed_quantity_unit_5) ///
		(seed_quantity_1_2016 seed_quantity_unit_1_2016 seed_quantity_2_2016 seed_quantity_unit_2_2016 seed_quantity_3_2016 seed_quantity_unit_3_2016 seed_quantity_4_2016 seed_quantity_unit_4_2016 seed_quantity_5_2016 seed_quantity_unit_5_2016)

local units maize_local_quantity_unit_2016 seed_quantity_unit_1_2016 seed_quantity_unit_2_2016 seed_quantity_unit_3_2016 seed_quantity_unit_4_2016 seed_quantity_unit_5_2016
foreach x in `units' {
	recode `x' (1 2 = 1) (3 = 4) (4 = 5) (5 = 20) (6 = 18)
	label var `x' "Conversion factor"
}

label drop maize_local_quantity_unit
	
save temp_best2016, replace

use dtmii_midline_noid, clear
keep year refid maize_plots best_plot_ha best_plot_seeds_kg ///
	seed_quantity1 seed_quantity_unit1 seed_quantity2 seed_quantity_unit2 seed_quantity3 seed_quantity_unit3 seed_quantity4 seed_quantity_unit4 ///
	maize_local_quantity maize_local_quantity_unit 

append using dtmii_endline_noid, keep(year refid maize_plots best_plot_ha best_plot_seeds_kg seed_quantity1 seed_quantity_unit1 seed_quantity2 seed_quantity_unit2 seed_quantity3 seed_quantity_unit3 maize_local_quantity maize_local_quantity_unit)

merge m:1 refid using temp_best2016
drop _merge
save temp_best, replace

********************************************************************************
*			Generate weather signal datasets
********************************************************************************

/*We want the following weather measures. 
"MSD" =	Rain (mm) in the second 40 days after planting (Dekads 5-8 )
"earlydrought" = Severe Early Season Drought Indicator (Rainfall < 70 mm in Dekads 1-4)
"middrought" = Less than 200 mm of rain in the second 40 days after planting
"fulldrought"  = Insufficient Full Season Rainfall Indicator (Rainfall < 500 mm over 120 Days)	
"Mid Season Rainfall bins" = Dummy variables for each 100 mm of rain received in the mid season.
*/



/* This data to run this section is supressed for the confidentiality of project participants.
	It requires household lattitude and longitude.
	
	
	The output is included as the dataset "msd_noid.dta"
	
	
	*/



/*
cd "$data"
*Use rainfall data specific to individuals
use dtmii_CHIRPS_all, clear

**Merge in Planting Dates
merge 1:1 refid using dtmii_baseline_all, keepusing(plant_month) /*Only month available in baseline*/
drop _merge
rename plant_month plantmonth2016
gen plantweek2016 = 2

merge 1:1 refid using dtmii_midline_all, keepusing(plant_month plant_week)
rename plant_month plantmonth2017
rename plant_week plantweek2017
drop _merge

merge 1:1 refid using dtmii_endline_all, keepusing(plant_month plant_week)
rename plant_month plantmonth2018
rename plant_week plantweek2018
drop _merge

drop dek_1 - dek_1248 /*Prior to study period*/

/* Select 2016 Season Start Date. */

gen start16_1 = 1249   /*Dekad 1, Sept 2015*/
	replace start16_1 = 1255 if inlist(plantmonth2016,5,6,7,8) /*Replace nonsense months with most common month that year (November)*/
		replace start16_1 = start16_1 + 3 if plantmonth2016 == 10 /*October*/
		replace start16_1 = start16_1 + 6 if plantmonth2016 == 11 /*Novermber*/
		replace start16_1 = start16_1 + 9 if plantmonth2016 == 12 /*December*/
		replace start16_1 = start16_1 + 12 if plantmonth2016 == 1 /*Jan 2016*/
		replace start16_1 = start16_1 + 15 if plantmonth2016 == 2 /*Feb*/
		replace start16_1 = start16_1 + 18 if plantmonth2016 == 3 /*March*/
		replace start16_1 = start16_1 + 21 if plantmonth2016 == 4 /*April*/

gen start16_2 = 1250   /*Dekad 2, Sept 2015*/
	replace start16_2 = 1256 if inlist(plantmonth2016,5,6,7,8) /*Replace nonsense months with most common month that year (November)*/
		replace start16_2 = start16_2 + 4 if plantmonth2016 == 10 /*October*/
		replace start16_2 = start16_2 + 7 if plantmonth2016 == 11 /*Novermber*/
		replace start16_2 = start16_2 + 10 if plantmonth2016 == 12 /*December*/
		replace start16_2 = start16_2 + 13 if plantmonth2016 == 1 /*Jan 2016*/
		replace start16_2 = start16_2 + 16 if plantmonth2016 == 2 /*Feb*/
		replace start16_2 = start16_2 + 19 if plantmonth2016 == 3 /*March*/
		replace start16_2 = start16_2 + 22 if plantmonth2016 == 4 /*April*/

gen start16_3 = 1251   /*Dekad 3, Sept 2015*/
	replace start16_3 = 1257 if inlist(plantmonth2016,5,6,7,8) /*Replace nonsense months with most common month that year (November)*/
		replace start16_3 = start16_3 + 5 if plantmonth2016 == 10 /*October*/
		replace start16_3 = start16_3 + 8 if plantmonth2016 == 11 /*Novermber*/
		replace start16_3 = start16_3 + 11 if plantmonth2016 == 12 /*December*/
		replace start16_3 = start16_3 + 14 if plantmonth2016 == 1 /*Jan 2016*/
		replace start16_3 = start16_3 + 16 if plantmonth2016 == 2 /*Feb*/
		replace start16_3 = start16_3 + 20 if plantmonth2016 == 3 /*March*/
		replace start16_3 = start16_3 + 23 if plantmonth2016 == 4 /*April*/

/* Select 2017 Season Start Date.*/
gen start17_1 = 1285   /*Dekad 1, Sept 2016*/
	replace start17_1 = 1291 if inlist(plantmonth2017,5,6,7,8) /*Replace nonsense months with most common month that year (November)*/
		replace start17_1 = start17_1 + 3 if plantmonth2017 == 10 /*October*/
		replace start17_1 = start17_1 + 6 if plantmonth2017 == 11 /*Novermber*/
		replace start17_1 = start17_1 + 9 if plantmonth2017 == 12 /*December*/
		replace start17_1 = start17_1 + 12 if plantmonth2017 == 1 /*Jan 2017*/
		replace start17_1 = start17_1 + 15 if plantmonth2017 == 2 /*Feb*/
		replace start17_1 = start17_1 + 18 if plantmonth2017 == 3 /*March*/
		replace start17_1 = start17_1 + 21 if plantmonth2017 == 4 /*April*/

gen start17_2 = 1286   /*Dekad 2, Sept 2016*/
	replace start17_2 = 1292 if inlist(plantmonth2017,5,6,7,8) /*Replace nonsense months with most common month that year (November)*/
		replace start17_2 = start17_2 + 4 if plantmonth2017 == 10 /*October*/
		replace start17_2 = start17_2 + 7 if plantmonth2017 == 11 /*Novermber*/
		replace start17_2 = start17_2 + 10 if plantmonth2017 == 12 /*December*/
		replace start17_2 = start17_2 + 13 if plantmonth2017 == 1 /*Jan 2017*/
		replace start17_2 = start17_2 + 16 if plantmonth2017 == 2 /*Feb*/
		replace start17_2 = start17_2 + 19 if plantmonth2017 == 3 /*March*/
		replace start17_2 = start17_2 + 22 if plantmonth2017 == 4 /*April*/

gen start17_3 = 1287   /*Dekad 3, Sept 2016*/
	replace start17_3 = 1293 if inlist(plantmonth2017,5,6,7,8) /*Replace nonsense months with most common month that year (November)*/
		replace start17_3 = start17_3 + 5 if plantmonth2017 == 10 /*October*/
		replace start17_3 = start17_3 + 8 if plantmonth2017 == 11 /*Novermber*/
		replace start17_3 = start17_3 + 11 if plantmonth2017 == 12 /*December*/
		replace start17_3 = start17_3 + 14 if plantmonth2017 == 1 /*Jan 2017*/
		replace start17_3 = start17_3 + 16 if plantmonth2017 == 2 /*Feb*/
		replace start17_3 = start17_3 + 20 if plantmonth2017 == 3 /*March*/
		replace start17_3 = start17_3 + 23 if plantmonth2017 == 4 /*April*/

/* Select 2018 Season Start Date.*/
gen start18_1 = 1321   /*Dekad 1, Sept 2017*/
	replace start18_1 = 1327 if inlist(plantmonth2018,5,6,7,8) /*Replace nonsense months with most common month that year (November)*/
		replace start18_1 = start18_1 + 3 if plantmonth2018 == 10 /*October*/
		replace start18_1 = start18_1 + 6 if plantmonth2018 == 11 /*Novermber*/
		replace start18_1 = start18_1 + 9 if plantmonth2018 == 12 /*December*/
		replace start18_1 = start18_1 + 12 if plantmonth2018 == 1 /*Jan 2018*/
		replace start18_1 = start18_1 + 15 if plantmonth2018 == 2 /*Feb*/
		replace start18_1 = start18_1 + 18 if plantmonth2018 == 3 /*March*/
		replace start18_1 = start18_1 + 21 if plantmonth2018 == 4 /*April*/

gen start18_2 = 1322   /*Dekad 2, Sept 2017*/
	replace start18_2 = 1328 if inlist(plantmonth2018,5,6,7,8) /*Replace nonsense months with most common month that year (November)*/
		replace start18_2 = start18_2 + 4 if plantmonth2018 == 10 /*October*/
		replace start18_2 = start18_2 + 7 if plantmonth2018 == 11 /*Novermber*/
		replace start18_2 = start18_2 + 10 if plantmonth2018 == 12 /*December*/
		replace start18_2 = start18_2 + 13 if plantmonth2018 == 1 /*Jan 2018*/
		replace start18_2 = start18_2 + 16 if plantmonth2018 == 2 /*Feb*/
		replace start18_2 = start18_2 + 19 if plantmonth2018 == 3 /*March*/
		replace start18_2 = start18_2 + 22 if plantmonth2018 == 4 /*April*/

gen start18_3 = 1323   /*Dekad 3, Sept 2017*/
	replace start18_3 = 1329 if inlist(plantmonth2018,5,6,7,8) /*Replace nonsense months with most common month that year (November)*/
		replace start18_3 = start18_3 + 5 if plantmonth2018 == 10 /*October*/
		replace start18_3 = start18_3 + 8 if plantmonth2018 == 11 /*Novermber*/
		replace start18_3 = start18_3 + 11 if plantmonth2018 == 12 /*December*/
		replace start18_3 = start18_3 + 14 if plantmonth2018 == 1 /*Jan 2018*/
		replace start18_3 = start18_3 + 16 if plantmonth2018 == 2 /*Feb*/
		replace start18_3 = start18_3 + 20 if plantmonth2018 == 3 /*March*/
		replace start18_3 = start18_3 + 23 if plantmonth2018 == 4 /*April*/

/*Generate a bunch of empty variables: (Part of season)(Year)_(Dekad of planting month) */
foreach x in 16 17 18 {
	foreach y in 1 2 3 {
		gen full`x'_`y' = .
		gen early`x'_`y' = .
		gen mid`x'_`y' = .
		}
		}

/*Parts A, B, and C of the following code do this:
	A: Calculate the endpoints for each period of the season if the start date was dekad x
	B: Calculate rainfall for each period if the start date was dekad x
	C: Given the month of planting, calculate rainfall for each period corresponding to planting in the three dekads of that month
*/ 
forvalues x=1249(1)1348 {
	** Part A
	local end = `x' + 11
	local early = `x' + 3
	local midstart = `x' + 4
	local midend = `x' + 7
	
	** Part B
	egen full`x' = rowtotal(dek_`x' - dek_`end')
	egen early`x' = rowtotal(dek_`x' - dek_`early')
	egen mid`x' = rowtotal(dek_`midstart' - dek_`midend') 

	** Part C
	foreach z in 16 17 18 {
		foreach y in 1 2 3 {
			replace full`z'_`y' = full`x' if start`z'_`y' == `x' 
			replace early`z'_`y' = early`x' if start`z'_`y' == `x'
			replace mid`z'_`y' = mid`x' if start`z'_`y' == `x'
			}
			}
	
	}

** Now I will take advantage of the "week of planting" data to better hone in on the rainfall in each period

**2016

/* In 2016, we did not collect week of planting. So I'll average the totals of rainfall
	for each period across the three possible dekads in the known month of planting */
	
egen full2016 = rowmean(full16_1 full16_2 full16_3)	
	label var full2016 "120 Day Rainfall: 2016"

egen early2016 = rowmean(early16_1 early16_2 early16_3)	
	label var early2016 "Early Rainfall (First 40 days): 2016"

egen mid2016 = rowmean(mid16_1 mid16_2 mid16_3)	
	label var mid2016 "Mid Rainfall (Second 40 days): 2016"

	
**2017

/*If planting week:
	1 ->  use dekad 1 as starting point
	2 -> average rainfall using dekads 1 and 2
	3 -> average rainfall using dekads 2 and 3
	4 -> use dekad 3 as starting point
*/

egen full2017 = rowmean(full17_1 full17_2 full17_3)
	label var full2017 "120 Day Rainfall: 2017"
replace full2017 = full17_1 if plantweek2017 == 1
replace full2017 = (full17_1 + full17_2)/2 if plantweek2017 == 2
replace full2017 = (full17_2 + full17_3)/2 if plantweek2017 == 3
replace full2017 = full17_3 if plantweek2017 == 4


egen early2017 = rowmean(early17_1 early17_2 early17_3)
	label var early2017 "120 Day Rainfall: 2017"
replace early2017 = early17_1 if plantweek2017 == 1
replace early2017 = (early17_1 + early17_2)/2 if plantweek2017 == 2
replace early2017 = (early17_2 + early17_3)/2 if plantweek2017 == 3
replace early2017 = early17_3 if plantweek2017 == 4


egen mid2017 = rowmean(mid17_1 mid17_2 mid17_3)
	label var mid2017 "120 Day Rainfall: 2017"
replace mid2017 = mid17_1 if plantweek2017 == 1
replace mid2017 = (mid17_1 + mid17_2)/2 if plantweek2017 == 2
replace mid2017 = (mid17_2 + mid17_3)/2 if plantweek2017 == 3
replace mid2017 = mid17_3 if plantweek2017 == 4

**2018

/*If planting week:
	1 ->  use dekad 1 as starting point
	2 -> average rainfall using dekads 1 and 2
	3 -> average rainfall using dekads 2 and 3
	4 -> use dekad 3 as starting point
*/

egen full2018 = rowmean(full18_1 full18_2 full18_3)
	label var full2018 "120 Day Rainfall: 2018"
replace full2018 = full18_1 if plantweek2018 == 1
replace full2018 = (full18_1 + full18_2)/2 if plantweek2018 == 2
replace full2018 = (full18_2 + full18_3)/2 if plantweek2018 == 3
replace full2018 = full18_3 if plantweek2018 == 4


egen early2018 = rowmean(early18_1 early18_2 early18_3)
	label var early2018 "120 Day Rainfall: 2018"
replace early2018 = early18_1 if plantweek2018 == 1
replace early2018 = (early18_1 + early18_2)/2 if plantweek2018 == 2
replace early2018 = (early18_2 + early18_3)/2 if plantweek2018 == 3
replace early2018 = early18_3 if plantweek2018 == 4


egen mid2018 = rowmean(mid18_1 mid18_2 mid18_3)
	label var mid2018 "120 Day Rainfall: 2018"
replace mid2018 = mid18_1 if plantweek2018 == 1
replace mid2018 = (mid18_1 + mid18_2)/2 if plantweek2018 == 2
replace mid2018 = (mid18_2 + mid18_3)/2 if plantweek2018 == 3
replace mid2018 = mid18_3 if plantweek2018 == 4

** Only keep rainfall
keep country district village refid full2016 full2017 full2018 early2016 early2017 early2018 mid2016 mid2017 mid2018 locationlongitude locationlatitude

** Reshape so that rows are individual/year
reshape long full early mid, i(refid) j(year)

	label var full "120 Day Rainfall (mm)"
	label var early "40 Day Rainfall (mm)"
	label var mid "Mid Season Rainfall (mm)"


** Generate dummy variables for drought events
gen fulldrought = 0
	replace fulldrought = 1 if full < 500
	label var fulldrought "120 Day Rainfall Less Than 500 mm"

gen middrought = (mid<200)
	label var middrought "Mid Rain < 200 mm"		

gen earlydrought = 0
	replace earlydrought = 1 if early < 70
	label var earlydrought "40 Day Rainfall Less Than 70 mm"

replace early = . if early == 0
replace mid = . if mid == 0
replace full = . if full == 0
replace fulldrought = . if full == .
replace middrought = . if mid == .
replace earlydrought = . if early == .

** Bins 0(100)500+
gen middrought_severe = 0
	replace middrought_severe = 1 if mid < 100
	label var middrought_severe "Mid rain < 100"		
	
gen middrought_mod = 0
	replace middrought_mod = 1 if mid >= 100 & mid < 200
	label var middrought_mod "100 < Mid rain < 200"		

gen middrought_mild = 0
	replace middrought_mild = 1 if mid >= 200 & mid < 300
	label var middrought_mild "200 < Mid rain < 300"	
	
gen middrought_good = 0
	replace middrought_good = 1 if mid >= 300 & mid < 400
	label var middrought_good "300 < Mid rain < 400"	

gen middrought_great = 0
	replace middrought_great = 1 if mid >= 400
	label var middrought_great "Mid rain > 400"		

cd "$data"
save temp_msd, replace
*/





********************************************************************************
**	Pull Insurance Outcomes and Risk Indicators 
********************************************************************************

/* This data to run this section is supressed for the confidentiality of project participants.

	The output is included as the dataset "insurance_noid.dta"

 */


 /*
 cd "$data"
use dtmii_insurance_outcomes_long, clear

rename rain_40a rain_early

keep zone village year y_zt_est_pct payout_early payout_yield payout country rain_full ndvi_full ndvi_full_pct rain_early

rename y_zt_est_pct zone_yield_percent
	label var zone_yield_percent "Estimated Zone Yield as a percent of average"
	label var payout_early "Payout due to early season rain, rain_early < 70"
	label var payout_yield "Payout due to yield prediction, yield_percent < 0.65"
	label var payout "Either payout_early or payout_yield == 1"
	label var country "Country"
	label var village "Village"
	label var rain_full "Estimated Zone Rainfall, full season"
	label var ndvi_full "Zone NDVI, full season"
	label var ndvi_full_pct "Zone NDVI (pct), full season"
	label var rain_early "Estimated Early Season Rain in Zone"
	
xtset village year

foreach x in zone_yield_percent payout_early payout_yield payout rain_full ndvi_full ndvi_full_pct rain_early {

	gen `x'_tm1 = L.`x'
	label var `x'_tm1 "Previous Year's `x'"
	}

keep if inlist(year, 2016,2017,2018)

save insurance_noid, replace

*/



********************************************************************************
********************************************************************************
** Investment Variables
********************************************************************************
********************************************************************************


/*This Section does the following


	1) Imputes missing values for local seed expenditure and expenditure on improved varieties, where possible.
	2) Creates nominal USD Agricultural Investment using official exchange rates obtained from the World Bank (IMF/IFS) (https://data.worldbank.org/indicator/PA.NUS.FCRF)
	3) Creates (PPP) Agricultural Investment using World Bank Price level ratio PPP conversion factor (GDP) ( World Bank, International Comparison Program database)
				Note that it would have been preferable to use a consumer-focused PPP conversion factor, but that was not available for Mozambique.
	
	 Measures are annual. Investment metrics focus on the beginning of the agricultural season. 
	 For example, if the baseline year was 2015/16, investment would have taken place in 2015.
	
				PPP		Baseline (2015)	Midline (2016)	Endline (2017)
		Mozambique		17.4130091		19.58022947		20.68315671
		Tanzania		676.3490831		719.0234105		724.6891596
					
					
		Exchange Rate	Baseline		Mideline		Endline
		Mozambique		39.98247415		63.05623273		63.58432291
		Tanzania		1991.390964		2177.085954		2228.857629

	
	Fertilizer Prices (Stable of study period, just using one price)
		Tanzania:
			Urea- 1500 TS/kg
			NPK -1800 TS/kg
				
		Mozambique
			Urea - 36 MTS/kg
			NPK - 40 MTS/kg	
*/


/* First task is to generate a dataset including, from all three rounds, all of the variables that 
	reference seed quantities, types, expenditures, ect */
	
cd "$data"
use dtmii_baseline_noid, clear

** Fertilizer
rename (ag_fert_quant_1 ag_fert_quant_2) (fert_npk fert_urea)
	label var fert_npk "kg of npk"
	label var fert_urea "kg of urea"
	
*Correct outlier/entry errors (body of evidence - area, seed, other investments, treatment gift packs - indicate coding error)
	replace fert_npk = 0.25 if country == "mozambique" & fert_npk == 250
	replace fert_urea = 0.25 if country == "mozambique" & fert_urea == 250
	
gen price_npk = .
	replace price_npk = 1800 if country == "tanzania"
	replace price_npk = 40 if country == "mozambique"
	label var price_npk "NPK price, local currency"

gen price_urea = .
	replace price_urea = 1500 if country == "tanzania"
	replace price_urea = 36 if country == "mozambique"
	label var price_urea "Urea price, local currency"
	
gen expend_npk = fert_npk*price_npk
	label var expend_npk "Expenditure on NPK, local currency"
	
gen expend_urea = fert_urea*price_urea
	label var expend_urea "Expenditure on Urea, local currency"
	
egen expend_fert = rowtotal(expend_npk expend_urea)
	label var expend_fert "Fertilizer Expenditure, local currency"
	
foreach x in 3 4 5 9 10 11 12 13 14 15 16 22 17 20 18 19 23 24 25 26 27 {
	gen improved`x'_price = .
		replace improved`x'_price =	seed_price_1	if variety_id_1 == `x'		
		replace improved`x'_price =	seed_price_2	if variety_id_2 == `x'
		replace improved`x'_price =	seed_price_3	if variety_id_3 == `x'
		replace improved`x'_price =	seed_price_4	if variety_id_4 == `x'
		replace improved`x'_price =	seed_price_5	if variety_id_5 == `x'

	gen improved`x'_purchased = .
		replace improved`x'_purchased = seed_purchase_1 if variety_id_1 == `x'
		replace improved`x'_purchased = seed_purchase_2 if variety_id_2 == `x'
		replace improved`x'_purchased = seed_purchase_3 if variety_id_3 == `x'
		replace improved`x'_purchased = seed_purchase_4 if variety_id_4 == `x'
		replace improved`x'_purchased = seed_purchase_5 if variety_id_5 == `x'

		
		rename improved`x'_quantity seed_quantity_kg_`x'
		}

keep country district year refid village treatment_status plant_maize ///
	expend_npk expend_urea expend_fert ///
	maize_improved maize_improved_kg maize_local maize_local_kg ///
	improved3 improved4 improved5 improved9 improved10 improved11 improved12 improved13 improved14 improved15 improved16 improved22 improved17 improved20 improved18 improved19 improved23 improved24 improved25 improved26 improved27 ///
	seed_quantity_kg_3 seed_quantity_kg_4 seed_quantity_kg_5 seed_quantity_kg_9 seed_quantity_kg_10 seed_quantity_kg_11 seed_quantity_kg_12 seed_quantity_kg_13 seed_quantity_kg_14 seed_quantity_kg_15 seed_quantity_kg_16 seed_quantity_kg_22 seed_quantity_kg_17 seed_quantity_kg_20 seed_quantity_kg_18 seed_quantity_kg_19 seed_quantity_kg_23 seed_quantity_kg_24 seed_quantity_kg_25 seed_quantity_kg_26 seed_quantity_kg_27 ///
	improved3_price improved4_price improved5_price improved9_price improved10_price improved11_price improved12_price improved13_price improved14_price improved15_price improved16_price improved22_price improved17_price improved20_price improved18_price improved19_price improved23_price improved24_price improved25_price improved26_price improved27_price ///
	improved3_purchased improved4_purchased improved5_purchased improved9_purchased improved10_purchased improved11_purchased improved12_purchased improved13_purchased improved14_purchased improved15_purchased improved16_purchased improved22_purchased improved17_purchased improved20_purchased improved18_purchased improved19_purchased improved23_purchased improved24_purchased improved25_purchased improved26_purchased improved27_purchased

save temp_inv16, replace

**
use dtmii_midline_noid, clear

*Fertilizer
rename (fertq1 fertq2) (fert_npk fert_urea)
	label var fert_npk "kg of npk"
	label var fert_urea "kg of urea"
	
gen price_npk = .
	replace price_npk = 1800 if country == "tanzania"
	replace price_npk = 40 if country == "mozambique"
	label var price_npk "NPK price, local currency"

gen price_urea = .
	replace price_urea = 1500 if country == "tanzania"
	replace price_urea = 36 if country == "mozambique"
	label var price_urea "Urea price, local currency"
	
gen expend_npk = fert_npk*price_npk
	label var expend_npk "Expenditure on NPK, local currency"
	
gen expend_urea = fert_urea*price_urea
	label var expend_urea "Expenditure on Urea, local currency"
	
egen expend_fert = rowtotal(expend_npk expend_urea)
	label var expend_fert "Fertilizer Expenditure, local currency"
	
**	
gen improved28 = 0
	replace improved28 = 1 if variety_id1 == 28
	replace improved28 = 1 if variety_id2 == 28
	replace improved28 = 1 if variety_id3 == 28
	replace improved28 = 1 if variety_id4 == 28

gen seed_quantity_kg_28 = .
	replace seed_quantity_kg_28 = seed_quant_1 if variety_id1 == 28
	replace seed_quantity_kg_28 = seed_quant_2 if variety_id2 == 28
	replace seed_quantity_kg_28 = seed_quant_3 if variety_id3 == 28
	replace seed_quantity_kg_28 = seed_quant_4 if variety_id4 == 28

gen seed_priceperkg_28 = .
	replace seed_priceperkg_28 = seed_price1 if variety_id1 == 28
	replace seed_priceperkg_28 = seed_price2 if variety_id2 == 28
	replace seed_priceperkg_28 = seed_price3 if variety_id3 == 28
	replace seed_priceperkg_28 = seed_price4 if variety_id4 == 28

foreach x in 3 4 5 9 10 11 12 13 14 15 16 22 17 20 18 19 23 24 25 26 27 28 {
	gen improved`x'_price = .
		replace improved`x'_price =	seed_price1	if variety_id1 == `x'		
		replace improved`x'_price =	seed_price2	if variety_id2 == `x'
		replace improved`x'_price =	seed_price3	if variety_id3 == `x'
		replace improved`x'_price =	seed_price4	if variety_id4 == `x'

	gen improved`x'_purchased = .
		replace improved`x'_purchased = seed_purchase1 if variety_id1 == `x'
		replace improved`x'_purchased = seed_purchase2 if variety_id2 == `x'
		replace improved`x'_purchased = seed_purchase3 if variety_id3 == `x'
		replace improved`x'_purchased = seed_purchase4 if variety_id4 == `x'
}


keep country district year refid village treatment_status plant_maize ///
	expend_npk expend_urea expend_fert ///
	maize_improved maize_improved_kg maize_local maize_local_kg ///
	improved3 improved4 improved5 improved9 improved10 improved11 improved12 improved13 improved14 improved15 improved16 improved22 improved17 improved20 improved18 improved19 improved23 improved24 improved25 improved26 improved27 improved28 ///
	seed_quantity_kg_3 seed_quantity_kg_4 seed_quantity_kg_5 seed_quantity_kg_9 seed_quantity_kg_10 seed_quantity_kg_11 seed_quantity_kg_12 seed_quantity_kg_13 seed_quantity_kg_14 seed_quantity_kg_15 seed_quantity_kg_16 seed_quantity_kg_22 seed_quantity_kg_17 seed_quantity_kg_20 seed_quantity_kg_18 seed_quantity_kg_19 seed_quantity_kg_23 seed_quantity_kg_24 seed_quantity_kg_25 seed_quantity_kg_26 seed_quantity_kg_27 seed_quantity_kg_28 ///
	improved3_price improved4_price improved5_price improved9_price improved10_price improved11_price improved12_price improved13_price improved14_price improved15_price improved16_price improved22_price improved17_price improved20_price improved18_price improved19_price improved23_price improved24_price improved25_price improved26_price improved27_price improved28_price ///
	improved3_purchased improved4_purchased improved5_purchased improved9_purchased improved10_purchased improved11_purchased improved12_purchased improved13_purchased improved14_purchased improved15_purchased improved16_purchased improved22_purchased improved17_purchased improved20_purchased improved18_purchased improved19_purchased improved23_purchased improved24_purchased improved25_purchased improved26_purchased improved27_purchased improved28_purchased

save temp_inv17, replace


** Endline
use dtmii_endline_noid, clear

*Fertilizer

rename (fertq1 fertq2) (fert_npk fert_urea)
	label var fert_npk "kg of npk"
	label var fert_urea "kg of urea"

** Fertilizer
gen price_npk = .
	replace price_npk = 1800 if country == "tanzania"
	replace price_npk = 40 if country == "mozambique"
	label var price_npk "NPK price, local currency"

gen price_urea = .
	replace price_urea = 1500 if country == "tanzania"
	replace price_urea = 36 if country == "mozambique"
	label var price_urea "Urea price, local currency"
	
gen expend_npk = fert_npk*price_npk
	label var expend_npk "Expenditure on NPK, local currency"
	
gen expend_urea = fert_urea*price_urea
	label var expend_urea "Expenditure on Urea, local currency"
	
egen expend_fert = rowtotal(expend_npk expend_urea)
	label var expend_fert "Fertilizer Expenditure, local currency"

foreach x in 3 4 5 9 10 11 12 13 14 15 16 22 17 20 18 19 23 24 25 26 27 28 {
	
	gen improved`x' = 0
		replace improved`x' = 1 if variety_id1 == `x'
		replace improved`x' = 1 if variety_id2 == `x'
		replace improved`x' = 1 if variety_id3 == `x'

	gen seed_quantity_kg_`x' = .
		replace seed_quantity_kg_`x' = seed_quant_kg_1 if variety_id1 == `x'
		replace seed_quantity_kg_`x' = seed_quant_kg_2 if variety_id2 == `x'
		replace seed_quantity_kg_`x' = seed_quant_kg_3 if variety_id3 == `x'
	
	gen improved`x'_price = .
		replace improved`x'_price =	seed_price1	if variety_id1 == `x'		
		replace improved`x'_price =	seed_price2	if variety_id2 == `x'
		replace improved`x'_price =	seed_price3	if variety_id3 == `x'

	gen improved`x'_purchased = .
		replace improved`x'_purchased = seed_purchase1 if variety_id1 == `x'
		replace improved`x'_purchased = seed_purchase2 if variety_id2 == `x'
		replace improved`x'_purchased = seed_purchase3 if variety_id3 == `x'
}


keep country district year refid village treatment_status plant_maize ///
	expend_npk expend_urea expend_fert ///
	maize_improved maize_improved_kg maize_local maize_local_kg ///
	improved3 improved4 improved5 improved9 improved10 improved11 improved12 improved13 improved14 improved15 improved16 improved22 improved17 improved20 improved18 improved19 improved23 improved24 improved25 improved26 improved27 improved28 ///
	seed_quantity_kg_3 seed_quantity_kg_4 seed_quantity_kg_5 seed_quantity_kg_9 seed_quantity_kg_10 seed_quantity_kg_11 seed_quantity_kg_12 seed_quantity_kg_13 seed_quantity_kg_14 seed_quantity_kg_15 seed_quantity_kg_16 seed_quantity_kg_22 seed_quantity_kg_17 seed_quantity_kg_20 seed_quantity_kg_18 seed_quantity_kg_19 seed_quantity_kg_23 seed_quantity_kg_24 seed_quantity_kg_25 seed_quantity_kg_26 seed_quantity_kg_27 seed_quantity_kg_28 ///
	improved3_price improved4_price improved5_price improved9_price improved10_price improved11_price improved12_price improved13_price improved14_price improved15_price improved16_price improved22_price improved17_price improved20_price improved18_price improved19_price improved23_price improved24_price improved25_price improved26_price improved27_price improved28_price ///
	improved3_purchased improved4_purchased improved5_purchased improved9_purchased improved10_purchased improved11_purchased improved12_purchased improved13_purchased improved14_purchased improved15_purchased improved16_purchased improved22_purchased improved17_purchased improved20_purchased improved18_purchased improved19_purchased improved23_purchased improved24_purchased improved25_purchased improved26_purchased improved27_purchased improved28_purchased

save temp_inv18, replace

** append
append using temp_inv16 temp_inv17

** clean up a bit
drop maize_improved_kg
egen maize_improved_kg = rowtotal(seed_quantity_kg_3 seed_quantity_kg_4 seed_quantity_kg_5 seed_quantity_kg_9 seed_quantity_kg_10 seed_quantity_kg_11 seed_quantity_kg_12 seed_quantity_kg_13 seed_quantity_kg_14 seed_quantity_kg_15 seed_quantity_kg_16 seed_quantity_kg_22 seed_quantity_kg_17 seed_quantity_kg_20 seed_quantity_kg_18 seed_quantity_kg_19 seed_quantity_kg_23 seed_quantity_kg_24 seed_quantity_kg_25 seed_quantity_kg_26 seed_quantity_kg_27 seed_quantity_kg_28)

replace maize_local_kg = 0 if maize_local == 0

egen numvars = rowtotal(improved3 improved4 improved5 improved9 improved10 improved11 improved12 improved13 improved14 improved15 improved16 improved22 improved17 improved20 improved18 improved19 improved23 improved24 improved25 improved26 improved27 improved28)
	label var numvars "How many varieties did a HH report?"


foreach x in 3 4 5 9 10 11 12 13 14 15 16 22 17 20 18 19 23 24 25 26 27 28 {

gen price`x' = 0
	replace price`x' = 1 if improved`x'_price != .
	label var price`x' "Reported a price for improved`x'"
	
}

egen numprices = rowtotal(price3 price4 price5 price9 price10 price11 price12 price13 price14 price15 price16 price22 price17 price20 price18 price19 price23 price24 price25 price26 price27 price28)
	label var  numprices "Number of prices reported"

gen allvars_prices = 0
	replace allvars_prices = 1 if numvars >=1 & numprices == numvars
	label var allvars_prices "Prices for all varieties."

gen vars_incomplete = 0
	replace vars_incomplete = 1 if numvars >=1 & numprices < numvars & numprices >= 1
	label var vars_incomplete "Missing at least one price"
	
gen var_noprice = 0
	replace var_noprice = 1 if numvars >=1 & numprices == 0
	label var var_noprice "Reported some varieties, no prices"

gen novars_noprice = 0
	replace novars_noprice = 1 if maize_improved == 1 & numvars == 0
	label var novars_noprice "Improved = 1, no varieties named"

********************************************************************************
** Entry Error
replace improved9_price = 185 if improved9_price == 1850
********************************************************************************

********************************************************************************
** Impute Improved Seed Prices
********************************************************************************	

drop if country == ""

global vars 3 4 5 9 10 11 12 13 14 15 16 22 17 20 18 19 23 24 25 26 27 28

**Fill in Zeros for Quantities instead of missing
foreach x in $vars {
	sum seed_quantity_kg_`x',detail
	replace seed_quantity_kg_`x' = 0 if seed_quantity_kg_`x' == .
	}	
	
/*I'm going to do three versions
	1) Country/Year Prices: Median variety prices by country/year
	2) Community/Year Prices: If available, median price in community each year
							  If not, median price in district/year.
							  If not, median price in country/year.
	3) Fixed prices:
			Local seed (2015 PPP - adjusted)
					0.55/kg Mozambique
					0.84/kg Tanzania
			Improved seed - Median price for a variety by country (pooled across years)
			Fert 		  - Prices are already fixed.
	
	4) Prices for a Lespereyers Index - Uses a variety's baseline PPP price for all years, with median improved prices
										in baseline substituted if there is insufficient price data at baseline for
										a variety that appears later.
*/

	*generate price variables (cty = country, type, year)
	foreach x in $vars {
	
		egen impute_constant`x' = median(improved`x'_price), by(country)
			label var impute_constant`x' "Median Price, Var `x', pooled years, by country"
	
		egen impute_cty`x' = median(improved`x'_price), by(country year)
			label var impute_cty`x' "Median Price, Var `x', country/year"
			
		egen impute_dty`x' = median(improved`x'_price), by(district year)
			label var impute_dty`x' "Median Price, Var `x', district/year"
		
		egen impute_comty`x' = median(improved`x'_price), by(village year)
			label var impute_comty`x' "Median Price, Var `x', community/year"
		
		gen price_cty`x' = improved`x'_price
			label var price_cty`x' "Country, Year, Price, Var `x'"
			replace price_cty`x' = impute_cty`x' if price_cty`x' == .
			
		gen price_comty`x' = improved`x'_price
			label var price_comty`x' "Community, Year, Price, Var `x'"
			replace price_comty`x' = impute_comty`x' if price_comty`x' == .
			replace price_comty`x' = impute_dty`x' if price_comty`x' == .
			replace price_comty`x' = impute_cty`x' if price_comty`x' == .
			
		gen price_constant`x' = impute_constant`x'
			label var price_constant`x' "Constant Price, country, var `x'"

		
		egen temp_lesp`x' = median(improved`x'_price) if year == 2016, by(country)
		gen price_lesp`x' = .
			label var price_lesp`x' "Median Baseline Prices, by variety/country"
		sum temp_lesp`x' if country == "tanzania"
			replace price_lesp`x' = r(mean) if country == "tanzania"
		sum temp_lesp`x' if country == "mozambique"
			replace price_lesp`x' = r(mean) if country == "mozambique"
			}

	*Fix data insufficiencies in lesp prices
		replace price_lesp12 = 60 if country == "mozambique"   /*median improved price 2016 moz, local*/
		replace price_lesp14 = 60 if country == "mozambique"/*median improved price 2016 moz, local*/
		replace price_lesp28 = price_lesp9 if country == "mozambique" /* ZM 521 is the same price as ZM 523*/
		replace price_lesp5 = 5500 if country == "tanzania" /*median improved price 2016 tz, local*/

		
**Five Expenditure Variables for each variety: Constant OWN CTY COMTY lesp
foreach x in $vars{
	gen seedexp_constant`x' = seed_quantity_kg_`x'*price_constant`x'
		label var seedexp_constant`x' "Exp. on seed `x', constant prices"

	gen seedexp_own`x' = seed_quantity_kg_`x'*improved`x'_price
		replace seedexp_own`x' = 0 if seedexp_own`x' == .
		label var seedexp_own`x' "Exp. on seed `x', self-reported price"
		
	gen seedexp_cty`x' = seed_quantity_kg_`x'*price_cty`x'
		replace seedexp_cty`x' = 0 if seedexp_cty`x' == .
		label var seedexp_cty`x' "Exp. on seed `x', country/year price"
		
	gen seedexp_comty`x' = seed_quantity_kg_`x'*price_comty`x'
		replace seedexp_comty`x' = 0 if seedexp_comty`x' == .
		label var seedexp_comty`x' "Exp. on seed `x', community/year price"
		
	gen seedexp_lesp`x' = seed_quantity_kg_`x'*price_lesp`x'
		replace seedexp_lesp`x' = 0  if seedexp_lesp`x' == .
		label var seedexp_lesp`x' "Exp. on seed `x', lesp prices"
	}


**Five Seed Investment Variables: Constant OWN CTY COMTY lesp
	egen expend_constant = rowtotal(seedexp_constant*)
		label var expend_constant "Improved Seed Expenditure, constant prices"

	egen expend_own = rowtotal(seedexp_own*)
		label var expend_own "Improved Seed Expenditure, own prices only"

	egen expend_cty = rowtotal(seedexp_cty*)
		label var expend_cty "Improved Seed Expenditure, country/year prices"
	
	egen expend_comty = rowtotal(seedexp_comty*)
		label var expend_comty "Improved Seed Expenditure, community/year prices"
	
	egen expend_lesp = rowtotal(seedexp_lesp*)
		label var expend_lesp "Improved Seed Expenditure, lesp prices"
	
	
	
**What is there and what's missing (own seed prices reported)
gen complete = 1
	replace complete = 0 if expend_own == .
	replace complete = 0 if expend_fert == .
	label var complete "=0 if seed or fert exp is missing"
	
********************************************************************************
** Impute Local Maize (Opportunity Cost)
********************************************************************************
/* We will use grain price from the pervious year as the opportunity cost of local
	seed at planting time:
		
			Grain Price			 --> 		Local Seed Price
			Summer 2015						Ag 2015/2016 (Baseline)
			Summer 2016 (Baseline)			Ag 2016/2017 (Midline)
			Summer 2017 (Midline)			Ag 2017/2018 (Endline)
			
	To do this, we need grain prices for summer 2015. I'll get them here:
	
	http://www.fao.org/giews/food-prices/price-tool/en/
	
	Using the Arusha market in Tanzania and the Manica market in Mozambique, I 
	calculate the average local currency maize price for the period June - Sept.
	See 'maize grain prices - baseline.xls' for the calculation and PPP conversion.
	
	
	Combing this with our survey data for Midline and Endline (PPP)
	
						Baseline	Midline		Endline
	Mozambique			0.55		 1.49		  0.46
	Tanzania			0.84		 0.67		  0.70
	
*/
/*	
PPP				Baseline (2015)	Midline (2016)	Endline (2017)
Mozambique		17.4130091		19.58022947		20.68315671
Tanzania		676.3490831		719.0234105		724.6891596
*/	
	
gen ppp_adjust = .
	replace ppp_adjust = 17.4130091 if country == "mozambique" & year == 2016 
	replace ppp_adjust = 19.58022947 if country == "mozambique" & year == 2017 
	replace ppp_adjust = 20.68315671 if country == "mozambique" & year == 2018 
	replace ppp_adjust = 676.3490831 if country == "tanzania" & year == 2016 
	replace ppp_adjust = 719.0234105 if country == "tanzania" & year == 2017 
	replace ppp_adjust = 724.6891596 if country == "tanzania" & year == 2018  
	
gen ppp_adjustC = .
	label var ppp_adjustC "PPP adjustment for constant price and lesp(2016)"
	replace ppp_adjustC = 17.4130091 if country == "mozambique"
	replace ppp_adjustC = 676.3490831 if country == "tanzania"
	
	
** Local Maize Prices -- in PPP terms
gen local_price = .
	replace local_price = 0.55 if country == "mozambique" 	& year == 2016
	replace local_price = 0.84 if country == "tanzania" 	& year == 2016
	replace local_price = 1.49 if country == "mozambique" 	& year == 2017
	replace local_price = 0.67 if country == "tanzania" 	& year == 2017
	replace local_price = 0.46 if country == "mozambique" 	& year == 2018
	replace local_price = 0.70 if country == "tanzania" 	& year == 2018

gen local_constant = .
	replace local_constant = 0.55 if country == "mozambique"
	replace local_constant = 0.84 if country == "tanzania"
	label var local_constant "constant local seed price"
	
gen local_lesp = local_constant
	label var local_lesp "Baseline year maize price"
	
	
** Local seed expenditure variables. NOTE: these start in PPP terms. To get to local prices, 
*											I multiply by ppp_adjust, rather than divide by it
*											as I do elsewhere.

* Time-varying prices and PPP
gen expend_localPPP = local_price*maize_local_kg
	label var expend_localPPP "Expenditure on local seed, PPP"
	replace expend_localPPP = 0 if expend_localPPP == .
	
gen expend_local = expend_localPPP*ppp_adjust
	label var expend_local "Expenditure on local seed, (local currency)"
	replace expend_local = 0 if expend_local == .
	
* Constant prices, time varying PPP
gen expend_localCPPP = local_constant*maize_local_kg
	label var expend_localCPPP "Expenditure on local seed, constant price PPP"
	
gen expend_localC = expend_localCPPP*ppp_adjustC
	label var expend_localC "Expenditure on local seed, constant local currency price"
	
* Lesp -- prices and PPP fixed at baseline levels
gen expend_local_lespPPP = local_lesp*maize_local_kg
	label var expend_local_lespPPP "Expenditure on local seed, lesp PPP prices"

gen expend_local_lesp  = expend_local_lespPPP*ppp_adjustC
	label var expend_local_lesp "Expenditure on local seed, (local currency)"
	
	
** Make adjustment for gifted inputs in baseline year 
	gen gift_seed = 0
	gen gift_npk = 0
	gen gift_urea = 0
	* Tanzania (2kg seed) 
			/* District		Variety			Price/kg (Local)	Value of 2kg (Local)
				Singida		Lubango/Iffa	5000				10000
				Iramba		Lubango/Iffa	5000				10000
				Kiteto		HB513/Meru		5000				10000
				Morogoro	HB513/Meru		5000				10000
				Kongwa		TZH536/Suba		5000				10000
				Mvomero		TZH536/Suba		5000				10000
				*/
	replace gift_seed = 10000 if country == "tanzania" & treatment_status != 0 & year == 2016
	
	* Mozambique (1kg seed, 0.25 kg NPK, 0.25 kg UREA)
			 /*
				Seed value				65 (local)			
				NPK value		0.25 x 40 (local) = 10 (local) 
				Urea value		0.25 x 36 (local) = 9 (local)
			*/
	replace gift_seed = 65 if country == "mozambique" & treatment_status != 0 & year == 2016
	replace gift_npk = 10 if country == "mozambique" & treatment_status != 0 & year == 2016
	replace gift_urea = 9 if country == "mozambique" & treatment_status != 0 & year == 2016


	* Generate "with gifts" investment variables before subtracting gift values
	
	foreach x in expend_own expend_cty expend_comty expend_constant expend_npk expend_urea expend_fert {
		gen `x'_withTP = `x'
		label var `x'_withTP " `x' Including Value of Trial Pack (2016)"
		}
	
	gen expend_fert_withTP_C = expend_fert
		label var expend_fert_withTP_C "Fert. expenditure withTP & constant prices"
	
	gen expend_fert_lesp = expend_fert
		label var expend_fert_lesp "expenditure on fertilizer, lesp prices"
		
	** generate lesp variables without trial pack value
	gen expend_lesp_wo = expend_lesp
		label var expend_lesp_wo "Lesp improved seed expenditure without trial pack value"
	gen expend_fert_lesp_wo = expend_fert_lesp
		label var expend_fert_lesp_wo "Lesp fert expenditure without trial pack value"
	
	
	** Adjust investment for the value of seed packs
	foreach x in expend_own expend_cty expend_comty expend_constant expend_lesp_wo{
		replace `x' = `x' - gift_seed
		replace `x' = 0 if `x' < 0
		}
	
	replace expend_npk = expend_npk - gift_npk
		replace expend_npk = 0 if expend_npk < 0
	replace expend_urea = expend_urea - gift_urea
		replace expend_urea = 0 if expend_urea < 0
	replace expend_fert = expend_fert - gift_npk - gift_urea
		replace expend_fert = 0 if expend_fert < 0 
	replace expend_fert_lesp_wo = expend_fert
		
	*Note fert prices were already constant"	
	gen expend_fertC = expend_fert
		label var expend_fertC "Fert. expenditure with constant prices"
		
gen expend_ownPPP = expend_own/ppp_adjust
	label var expend_ownPPP "PPP-adjusted expend_ownn"
gen expend_ctyPPP = expend_cty/ppp_adjust
	label var expend_ctyPPP "PPP-adjusted expend_cty"
gen expend_comtyPPP = expend_comty/ppp_adjust
	label var expend_comtyPPP "PPP-adjusted expend_comty"
gen expend_lespPPP_wo = expend_lesp_wo/ppp_adjustC
	label var expend_lespPPP_wo "PPP-adjusted expend_lesp_wo"

gen expend_own_withTP_PPP = expend_own_withTP/ppp_adjust
	label var expend_own_withTP_PPP "PPP-adjusted expend_ownn_withTP"
gen expend_cty_withTP_PPP = expend_cty_withTP/ppp_adjust
	label var expend_cty_withTP_PPP "PPP-adjusted expend_cty_withTP"
gen expend_comty_withTP_PPP = expend_comty_withTP/ppp_adjust
	label var expend_comty_withTP_PPP "PPP-adjusted expend_comty_withTP"	
gen expend_lespPPP = expend_lesp/ppp_adjustC
	label var expend_lespPPP "PPP-adjusted expend_lesp"
	
	
gen expend_constantPPP = expend_constant/ppp_adjustC
	label var expend_constantPPP "PPP-adjusted expend_constant"

gen expend_constant_withTP_PPP = expend_constant_withTP/ppp_adjustC
	label var expend_constant_withTP_PPP "PPP-adjusted expend_constant_withTP"
	
gen expend_fertPPP = expend_fert/ppp_adjust
	label var expend_fertPPP "PPP-adjusted expend_fert"

gen expend_fert_withTP_PPP = expend_fert_withTP/ppp_adjust
	label var expend_fert_withTP_PPP "PPP-adjusted expend_fert_withTP"


gen expend_fert_lespPPP = expend_fert_lesp/ppp_adjustC
	label var expend_fert_lespPPP "PPP adjusted expend_fert_lesp"
	
gen expend_fert_lespPPP_wo = expend_fert_lesp_wo/ppp_adjustC
	label var expend_fert_lespPPP_wo "PPP adjusted expend_fert_lesp_wo"
	
gen expend_fertCPPP = expend_fertC/ppp_adjustC
	label var expend_fertCPPP "PPP-adjust expend_fertC"
	
gen expend_fert_withTP_CPPP = expend_fert_withTP_C/ppp_adjustC
	label var expend_fertCPPP "PPP-adjust expend_fert_withTP_C"
		
** create ag investment variable (local seed, fertilizer, improved seed (comty)
egen expend_ag = rowtotal(expend_local expend_fert expend_comty)
		label var expend_ag "Ag Investment (local currency)"
		
egen expend_agPPP = rowtotal(expend_localPPP expend_fertPPP expend_comtyPPP)
	label var expend_agPPP "Ag Investment (PPP)"
	
egen expend_agC = rowtotal(expend_localC expend_fertC expend_constant)
	label var expend_agC "Ag investment (constant local currency)"
	
egen expend_agCPPP = rowtotal(expend_localCPPP expend_fertCPPP expend_constantPPP)
	label var expend_agCPPP "Ag investment (constant PPP)"
	
egen expend_ag_lesp = rowtotal(expend_local_lesp expend_lesp_wo expend_fert_lesp_wo)
	label var expend_ag_lesp "Ag investment (2016 prices, local currency)"
	
egen expend_ag_lespPPP = rowtotal(expend_local_lespPPP expend_lespPPP_wo expend_fert_lespPPP_wo)
	label var expend_ag_lespPPP "Ag Investment (2016 PPP prices)"
	
** create ag investment variables that include the value of baseline seed packs.

egen expend_ag_withTP = rowtotal(expend_local expend_fert_withTP expend_comty_withTP)
		label var expend_ag_withTP "Ag Investment (local currency)"
		
egen expend_ag_withTP_PPP = rowtotal(expend_localPPP expend_fert_withTP_PPP expend_comty_withTP_PPP)
	label var expend_ag_withTP_PPP "Ag Investment (PPP)"
	
egen expend_ag_withTP_C = rowtotal(expend_localC expend_fert_withTP_C expend_constant_withTP)
	label var expend_ag_withTP_C "Ag investment (constant local currency)"
	
egen expend_ag_withTP_CPPP = rowtotal(expend_localCPPP expend_fert_withTP_CPPP expend_constant_withTP_PPP)
	label var expend_ag_withTP_CPPP "Ag investment (constant PPP)"

egen expend_ag_withTP_lesp = rowtotal(expend_local_lesp expend_lesp expend_fert_lesp)
	label var expend_ag_withTP_lesp "Ag investment (2016 prices, local currency)"
	
egen expend_ag_withTP_lespPPP = rowtotal(expend_local_lespPPP expend_lespPPP expend_fert_lespPPP)
	label var expend_ag_withTP_lespPPP "Ag Investment (2016 PPP prices)"

	
** Dataset to Merge with in later
keep country district village year refid plant_maize ppp_adjust ppp_adjustC   ///
	expend_own expend_cty expend_comty expend_constant expend_local expend_localC ///
	expend_npk expend_urea expend_fert expend_fertC ///
	expend_ownPPP expend_ctyPPP expend_comtyPPP expend_localPPP expend_fertPPP expend_constantPPP expend_localCPPP expend_fertCPPP ///
	expend_ag expend_agPPP expend_agC expend_agCPPP ///
	expend_own_withTP expend_cty_withTP expend_comty_withTP expend_constant_withTP ///
	expend_npk_withTP expend_urea_withTP expend_fert_withTP expend_fert_withTP_C ///
	expend_own_withTP_PPP expend_cty_withTP_PPP expend_comty_withTP_PPP expend_constant_withTP_PPP ///
	expend_fert_withTP_PPP expend_fert_withTP_CPPP expend_ag_withTP expend_ag_withTP_PPP ///
	expend_ag_withTP_C expend_ag_withTP_CPPP ///
	expend_local_lespPPP expend_local_lesp ///
	expend_fert_lesp expend_fert_lesp_wo expend_fert_lespPPP expend_fert_lespPPP_wo ///
	expend_lesp expend_lesp_wo expend_lespPPP_wo expend_lespPPP ///
	expend_ag_lesp expend_ag_lespPPP expend_ag_withTP_lesp expend_ag_withTP_lespPPP	complete	
**
	
save dtmii_investment_noid, replace


********************************************************************************
********************************************************************************
** Put data together 
********************************************************************************
********************************************************************************

********************************************************************************
/* Difference-in-Difference (dtmii_analysis_did)
	Three Year Panel with indicators for post treatment periods 
	and interactions between treatment x post
*/

cd "$data"
use baseline_temp, clear
append using midline_temp, force
append using endline_temp, force

*rain 
cap drop _merge
merge 1:1 refid year using msd_noid
	drop if _merge == 2
	drop _merge
*shocks
cap drop _merge
merge m:1 village year using insurance_noid
	drop _merge

* Post
gen post = (year != 2016)
	label var post "Post Treatment"
	
gen t1post = t1*post
	label var t1post "Post x DTM"
	
gen t2post = t2*post
	label var t2post "Post x DTMII"
	
**Correct Some Variable Stuff
gen maize_total_kg2 = maize_improved_kg + maize_local_kg

**ag fert
replace total_fert_kg = . if ag_fert_use == .

**nonmaize-area
/*drop those where maize area is missing*/
replace nonmaize_area_ha = . if maize_area_ha == .

**food security
replace foodinsecurity_cont = . if food_secure == .

cd "$data"
save dtmii_analysis_did, replace

********************************************************************************
** Ancova (dtmii_analysis_ancova)

use dtmii_analysis_did, clear
	keep hh_id refid country village year early full mid
		replace year = 2019 if year == 2018
		replace year = 2018 if year == 2017
		replace year = 2017 if year == 2016
		keep if inlist(year, 2018, 2017)
		rename early early_lag
		rename full full_lag
		rename mid mid_lag
		save temp_lagdrought, replace

cd "$data"
use midline_temp, clear
append using endline_temp, force

*rain 
cap drop _merge
merge 1:1 refid year using msd_noid
	drop if _merge == 2
	drop _merge

cap drop _merge
		merge 1:1 year refid using temp_lagdrought, keepusing(early_lag full_lag mid_lag)
		keep if _merge == 3
		cap drop _merge
	
*shocks
cap drop _merge
merge m:1 village year using insurance_noid
keep if _merge == 3
drop _merge
	
*best plot characteristics	
merge 1:1 refid year using temp_best
keep if _merge == 3
drop _merge

** Merge in baseline values
merge m:1 refid using temp2016
	drop _merge
	
** Gerenate time control
gen time = 0
	replace time = 1 if year == 2018
	label var time "year = 2018"

gen maize_total_kg2 = maize_improved_kg + maize_local_kg

**ag fert
replace total_fert_kg = . if ag_fert_use == .

**nonmaize-area
/*drop those where maize area is missing*/
replace nonmaize_area_ha = . if maize_area_ha == .

**food security
replace foodinsecurity_cont = . if food_secure == .

drop if year == 2016

cd "$data"
save dtmii_analysis_ancova, replace








********************************************************************************
* Update Controls 
********************************************************************************

cd "$data"

	use dtmii_baseline_noid, clear
	keep hh_id refid country village hh_education ag_education
	save temp_edu, replace

	use dtmii_baseline_noid, clear
	keep hh_id refid country village year sps_points ag_intercropping
	save temp_base, replace
	
	rename ag_intercropping intercropping_2016
	rename sps_points sps_points_2016
	drop year
	save temp_base2, replace
	
	use dtmii_midline_noid, clear
	keep hh_id refid country village year sps_points ag_intercropping
	save temp_mid, replace

	use dtmii_endline_noid, clear
	keep hh_id refid country village year sps_points ag_intercropping
	save temp_end, replace

	use temp_base, clear
		append using temp_mid temp_end
		save temp_control, replace

use dtmii_analysis_did, clear
	keep hh_id refid country village year middrought
		replace year = 2019 if year == 2018
		replace year = 2018 if year == 2017
		replace year = 2017 if year == 2016
		keep if inlist(year, 2018, 2017)
		rename middrought midtm1
		label var midtm1 "Imidtm1"
		save temp_lagdrought, replace
	
use dtmii_analysis_ancova, clear
		merge 1:1 year refid using temp_control, keepusing(ag_intercropping)
		keep if _merge == 3
		cap drop _merge
		merge m:1 refid using temp_edu, keepusing(hh_education ag_education)
		cap drop _merge
		merge m:1 refid using temp_base2, keepusing(intercropping_2016 sps_points_2016)
		cap drop _merge
		merge 1:1 year refid using temp_lagdrought, keepusing(midtm1)
		keep if _merge == 3
		cap drop _merge
			
save dtmii_analysis_ancova, replace

********************************************************************************

** Use Historical Satellite Data to Add Lagged Mid Season Rainfall to dtmii_analysis_did


/*
This data to run this section is supressed for the confidentiality of project participants.
	It requires household lattitude and longitude.
	
	
	The output is included as the dataset "mds_noid.dta"
	*/

	/*
use satellite_weather_history_long, clear

gen bump_year = year + 1 /*Now 2015 rain will match with 2016*/

drop year
rename bump_year year

gen mid_rain2 = mid_rain
rename (mid_rain) (rain_mid_tm1)
	label var rain_mid_tm1 "Previous Year's rain_mid"
rename (mid_rain2) (mid_lag)
rename (mid_drought) (middrought_lag)

rename (full_rain) (full_lag)
rename (full_drought) (fulldrought_lag)

rename (early_rain) (early_lag)
rename (early_drought) (earlydrought_lag)

keep year refid rain_mid_tm1 mid_lag middrought_lag full_lag fulldrought_lag early_lag earlydrought_lag

save sat_weather_noid, replace
*/

use sat_weather_noid, clear

preserve
keep year refid rain_mid_tm1
keep if inlist(year, 2016,2017,2018)
save temp_mid_tm1, replace
restore

drop rain_mid_tm1

keep if year == 2016
save temp_rain_lag16, replace

use dtmii_analysis_did, clear

keep year refid mid early full ///
	middrought fulldrought earlydrought
	
gen bump_year = year + 1
	drop year
	rename bump_year year
	
rename (full early mid fulldrought middrought earlydrought) (full_lag early_lag mid_lag fulldrought_lag middrought_lag earlydrought_lag)
	
append using temp_rain_lag16
	drop if year == 2019
	
merge 1:1 year refid using temp_mid_tm1
	drop if _merge == 2
	drop _merge
	
save temp_mid_lag, replace


use dtmii_analysis_did, clear

merge 1:1 refid year using temp_mid_lag
	drop if _merge == 2
	drop _merge
	
	label var rain_mid_tm1 "Previous Year's rain_mid"
	
save dtmii_analysis_did, replace


********************************************************************************
********************************************************************************
** Merge Investment Variables into dtmii_analysis_ancova.dta & dtmii_analysis_did.dta
cd "$data"
use dtmii_analysis_did, clear

merge 1:1 year refid using dtmii_investment_noid, keepusing(plant_maize expend*)
	keep if _merge == 3
	drop _merge
	
save dtmii_analysis_did, replace
	
**Save 2016 investment
keep if year == 2016
keep country refid expend_localPPP expend_comtyPPP expend_agPPP expend_localCPPP expend_constantPPP expend_agCPPP ///
	expend_comty_withTP_PPP expend_ag_withTP_PPP expend_constant_withTP_PPP expend_ag_withTP_CPPP ///
	expend_local_lespPPP expend_local_lesp ///
	expend_fert_lesp expend_fert_lesp_wo expend_fert_lespPPP expend_fert_lespPPP_wo ///
	expend_lesp expend_lesp_wo expend_lespPPP_wo expend_lespPPP ///
	expend_ag_lesp expend_ag_lespPPP expend_ag_withTP_lesp expend_ag_withTP_lespPPP
		
rename (expend_localPPP expend_comtyPPP expend_agPPP expend_localCPPP expend_constantPPP expend_agCPPP) (expend_localPPP_2016 expend_comtyPPP_2016 expend_agPPP_2016 expend_localCPPP_2016 expend_constantPPP_2016 expend_agCPPP_2016)
rename (expend_comty_withTP_PPP expend_ag_withTP_PPP expend_constant_withTP_PPP expend_ag_withTP_CPPP) (expend_comty_withTP_PPP_2016 expend_ag_withTP_PPP_2016 expend_constant_withTP_PPP_2016 expend_ag_withTP_CPPP_2016)
rename (expend_lespPPP_wo expend_lespPPP expend_ag_lespPPP expend_ag_withTP_lespPPP) (expend_lespPPP_wo_216 expend_lespPPP_2016 expend_ag_lespPPP_2016 expend_ag_withTP_lespPPP_2016)
rename (expend_fert_lesp expend_fert_lesp_wo expend_fert_lespPPP expend_fert_lespPPP_wo) (expend_fert_lesp_2016 expend_fert_lesp_wo_2016 expend_fert_lespPPP_2016 expend_fert_lespPPP_wo_2016)
rename (expend_lesp expend_lesp_wo) (expend_lesp_2016 expend_lesp_wo_2016)
rename (expend_ag_lesp expend_ag_lespPPP expend_ag_withTP_lesp expend_ag_withTP_lespPPP) (expend_ag_lesp_2016 expend_ag_lespPPP_2016 expend_ag_withTP_lesp_2016 expend_ag_withTP_lespPPP_2016)
save temp_inv16_v2, replace


use dtmii_analysis_ancova, clear

**6210 obs (all match!)
merge 1:1 year refid using dtmii_investment_noid, keepusing(plant_maize expend*)
	keep if _merge == 3
	drop _merge

merge m:1 refid using temp_inv16_v2, keepusing(expend*)
drop _merge

save dtmii_analysis_ancova, replace

********************************************************************************
********************************************************************************


********************************************************************************
* Delete Temp Files


********************************************************************************