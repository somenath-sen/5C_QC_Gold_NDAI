# Gold Layer QC Queries — rgd_gold_ad
**Prepared by:** Somenath Sen — RWD Team  
**Date:** July 2026  
**Schema:** rgd_gold_ad  

## Overview
Six SQL query files covering the Gold layer QC for the AD/MCI cohort. Each file corresponds to one table and is structured by the 5C framework (Completeness, Correctness, Concordance, Credibility, Currency).

## Files
| File | Table |
|---|---|
| QC_Procedures.sql | rgd_gold_ad.procedures |
| QC_Labs.sql | rgd_gold_ad.labs |
| QC_Radiology.sql | rgd_gold_ad.radiology |
| QC_Surgical_History.sql | rgd_gold_ad.surgical_history |
| QC_Family_History.sql | rgd_gold_ad.family_history |
| QC_Past_Medical_History.sql | rgd_gold_ad.past_medical_history |

## Structure
Each file is organized as follows:
- **BASELINE** — total records, psid breakdown, cohort coverage
- **1. COMPLETENESS** — null counts, fill rates, encounterid coverage by psid
- **2. CORRECTNESS** — date plausibility, placeholder/sentinel value checks, non-standard entries
- **3. CONCORDANCE** — coding system distributions, value distributions, top field values
- **4. CREDIBILITY** — duplicate counts by psid, orphan ndid check
- **5. CURRENCY** — udm_active_flag, date range confirmation

## Notes
- All queries are written for MySQL (AWS VPN required)
- Fill rates reference staging.fill_rate_report_gold where available
- radiology img_date and result_date are VARCHAR(100) — STR_TO_DATE() or LEFT() casting required
- StarRocks compatible versions: replace COUNT(*) with COUNT(1) and remove SELECT *
