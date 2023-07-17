# dtmii
This repository contains data and code related to the MRR Innovation Lab project "Bundling Innovative Risk Management Technologies to Improve Nutritional Outcomes of Vulnerable Agricultural Households". 

Survey instruments and their associated SurveyCTO code can be found in the "Survey Instruments" folder.  There are three survey rounds, each consisting of an individual household survey and a community survey.

The de-identified datasets associated with each survey can be found in the "Data" folder. They include
+ Baseline (dtmii_baseline_noid.dta and dtmii_baseline_community_noid.dta)
+ Midline (dtmii_midline_noid.dta and dtmii_midline_community_noid.dta)
+ Endline (dtmii_endline_noid.dta and dtmii_endline_community_noid.dta)

The "Scripts" folder contains two scripts. One showing the process of de-identifying the data (noid.do) and one processing the three waves of survey data for analysis using both an ANCOVA approach and a Difference-in-Differences approach (dtmii_analysis_build.do).  This second script also merges in weather and investment data for analysis of the impact of weather shocks on the households in the sample.  The user will note that some of the code is commented out, as it requires identified household locations to run. In such cases, the resulting de-identified outputs have been included (sat_weather_noid.dta, for example).

Users can merge additional household characteristics into the dtmii_analysis_ancova.dta and dtmii_analysis_did.dta files using refid/year as a unique identifier. 

This study was made possible through the generous support of the American people through the United States Agency for International Development Cooperative Agreement No. AID-OAA-L-12-00001 with the BASIS Feed the Future Innovation Lab. The contents are the responsibility of the authors and should not be construed to represent any official U.S. government determination or policy. Additional financial support was provided by the Consultative Group on International Agriculturla Research through its Special Program on Impact Evaluation. We thank our research managers and teams in both countries–especially Osmund Lupindu and Aniceto Matias–for their excellent contributions to this project. We also thank our survey respondents and our commercial partners who made this work possible.

The project's activities in both countrieswere ruled Exempt under Category 2 by the IRB at the University of California, Davis. Project numbers: 905582-1 (Mozambique), 905584-1 (Tanzania). Tanzania research permits issued by the Tanzanian Commission on Science and Technology, No. 2016-83-NA-2015-272, No. 2017-106-NA-2015-272, and No. 2018-237-NA-2015-272. This RCT was registered in the American Economic Association Registry for randomized controlled trials under trial numbers 2700 and 2702.

For more details on the project, please visit: https://basis.ucdavis.edu/project/bundling-innovative-risk-management-technologies-improve-nutritional-outcomes-africa 
