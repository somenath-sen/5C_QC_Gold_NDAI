-- =============================================================================
-- NeuroDiscovery AI - Regulatory-Grade Data QC Queries (5C Model)
-- Table: rgd_gold_ad.radiology  (Gold Layer)
-- Prepared By: Somenath Sen - RWD Team
-- Date: August 2026
-- Framework: 5C (Completeness, Correctness, Concordance, Credibility, Currency)
-- IMPORTANT: img_date and result_date are VARCHAR(100) storing datetime strings
--            ('YYYY-MM-DD 00:00:00'). Use STR_TO_DATE(LEFT(col,10),'%Y-%m-%d') for
--            all date logic. VERIFIED: all populated values parse with this pattern.
--            enc_date is DATETIME; img_order_date is DATE (native, no cast needed).
-- Snapshot: cohort_run_id = 19, run 2026-07-30 (single load, 1:1 source mapping).
-- =============================================================================


-- #############################################################################
-- # BASELINE
-- #############################################################################

===========BASELINE: total records, patients, psids=======
SELECT COUNT(*) AS total_records,
       COUNT(DISTINCT ndid) AS unique_patients,
       COUNT(DISTINCT psid) AS unique_psids
FROM rgd_gold_ad.radiology;

===========BASELINE: records by psid=======
SELECT psid, COUNT(*) AS records, COUNT(DISTINCT ndid) AS patients,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM rgd_gold_ad.radiology
GROUP BY psid
ORDER BY records DESC;

===========BASELINE: cohort coverage=======
SELECT
    COUNT(DISTINCT p.ndid) AS total_cohort_patients,
    COUNT(DISTINCT r.ndid) AS patients_with_radiology,
    COUNT(DISTINCT p.ndid) - COUNT(DISTINCT r.ndid) AS patients_without_radiology
FROM rgd_gold_ad.patients p
LEFT JOIN rgd_gold_ad.radiology r ON p.ndid = r.ndid;


-- #############################################################################
-- # 1. COMPLETENESS
-- #############################################################################

===========COMPLETENESS: rgd_gold_ad.radiology - full column fill rate=======
WITH cohort_rad AS (
    SELECT * FROM rgd_gold_ad.radiology WHERE udm_active_flag = 'Y'
)
SELECT 'ndid' AS column_name, COUNT(*) AS denominator, ROUND(SUM(CASE WHEN ndid IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_present FROM cohort_rad
UNION ALL
SELECT 'encounterid', COUNT(*), ROUND(SUM(CASE WHEN encounterid IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad
UNION ALL
SELECT 'resultid', COUNT(*), ROUND(SUM(CASE WHEN resultid IS NOT NULL AND TRIM(resultid) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad
UNION ALL
SELECT 'enc_date', COUNT(*), ROUND(SUM(CASE WHEN enc_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad
UNION ALL
SELECT 'img_order_date', COUNT(*), ROUND(SUM(CASE WHEN img_order_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad
UNION ALL
SELECT 'img_date', COUNT(*), ROUND(SUM(CASE WHEN img_date IS NOT NULL AND TRIM(img_date) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad
UNION ALL
SELECT 'result_date', COUNT(*), ROUND(SUM(CASE WHEN result_date IS NOT NULL AND TRIM(result_date) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad
UNION ALL
SELECT 'study_name', COUNT(*), ROUND(SUM(CASE WHEN study_name IS NOT NULL AND TRIM(study_name) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad
UNION ALL
SELECT 'img_modality', COUNT(*), ROUND(SUM(CASE WHEN img_modality IS NOT NULL AND TRIM(img_modality) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad
UNION ALL
SELECT 'img_body_part', COUNT(*), ROUND(SUM(CASE WHEN img_body_part IS NOT NULL AND TRIM(img_body_part) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad
UNION ALL
SELECT 'img_contrast_type', COUNT(*), ROUND(SUM(CASE WHEN img_contrast_type IS NOT NULL AND TRIM(img_contrast_type) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad
UNION ALL
SELECT 'img_tracer_name', COUNT(*), ROUND(SUM(CASE WHEN img_tracer_name IS NOT NULL AND TRIM(img_tracer_name) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad
UNION ALL
SELECT 'cpt_code', COUNT(*), ROUND(SUM(CASE WHEN cpt_code IS NOT NULL AND TRIM(cpt_code) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad
UNION ALL
SELECT 'cpt_code_source', COUNT(*), ROUND(SUM(CASE WHEN cpt_code_source IS NOT NULL AND TRIM(cpt_code_source) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad
UNION ALL
SELECT 'img_report_status', COUNT(*), ROUND(SUM(CASE WHEN img_report_status IS NOT NULL AND TRIM(img_report_status) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad
UNION ALL
SELECT 'img_report_text', COUNT(*), ROUND(SUM(CASE WHEN img_report_text IS NOT NULL AND TRIM(img_report_text) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad
UNION ALL
SELECT 'img_finding', COUNT(*), ROUND(SUM(CASE WHEN img_finding IS NOT NULL AND TRIM(img_finding) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_rad;

===========COMP-001: ndid completeness (Critical, threshold 0% missing)=======
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN ndid IS NULL THEN 1 ELSE 0 END) AS n_missing_ndid,
       ROUND(SUM(CASE WHEN ndid IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_missing_ndid
FROM rgd_gold_ad.radiology;

===========COMP-002: encounterid completeness (Critical, threshold 0% missing)=======
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS n_missing_encounterid,
       ROUND(SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_missing_encounterid
FROM rgd_gold_ad.radiology;

===========COMP-002b: encounterid null by psid (source-structural pattern)=======
SELECT psid,
       SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS n_missing,
       COUNT(*) AS total,
       ROUND(SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_missing
FROM rgd_gold_ad.radiology
GROUP BY psid
ORDER BY n_missing DESC;

===========COMP-003: img_date completeness (Major, threshold >=95%) - VARCHAR, use populated check=======
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN img_date IS NULL OR TRIM(img_date) = '' THEN 1 ELSE 0 END) AS n_missing_img_date,
       ROUND(SUM(CASE WHEN img_date IS NOT NULL AND TRIM(img_date) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_present
FROM rgd_gold_ad.radiology;

===========COMP-005: study_name completeness (Major, threshold >=95%)=======
SELECT COUNT(*) AS total_rows,
       ROUND(SUM(CASE WHEN study_name IS NOT NULL AND TRIM(study_name) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_present_study_name
FROM rgd_gold_ad.radiology;

===========COMP-017: sparse / near-empty columns (Major) - img_order_date, img_tracer_name=======
-- VERIFIED: img_order_date 3.25% populated; img_tracer_name 0.28% populated (expected -
-- only PET/nuclear studies carry a tracer). Documented as structural, not corrective.
SELECT 'img_order_date' AS column_name, ROUND(SUM(CASE WHEN img_order_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_present FROM rgd_gold_ad.radiology
UNION ALL
SELECT 'img_tracer_name', ROUND(SUM(CASE WHEN img_tracer_name IS NOT NULL AND TRIM(img_tracer_name) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM rgd_gold_ad.radiology
UNION ALL
SELECT 'img_finding', ROUND(SUM(CASE WHEN img_finding IS NOT NULL AND TRIM(img_finding) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM rgd_gold_ad.radiology
UNION ALL
SELECT 'img_report_status', ROUND(SUM(CASE WHEN img_report_status IS NOT NULL AND TRIM(img_report_status) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM rgd_gold_ad.radiology
UNION ALL
SELECT 'img_report_text', ROUND(SUM(CASE WHEN img_report_text IS NOT NULL AND TRIM(img_report_text) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM rgd_gold_ad.radiology;

===========COMP-020: udm_unq_id completeness (Critical, threshold 0% missing)=======
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN udm_unq_id IS NULL OR TRIM(udm_unq_id) = '' THEN 1 ELSE 0 END) AS n_missing_udm_unq_id
FROM rgd_gold_ad.radiology;


-- #############################################################################
-- # 2. CORRECTNESS
-- #############################################################################

===========CORR-006: date-type conformance (img_date / result_date are VARCHAR)=======
-- VERIFIED: all populated img_date/result_date values parse via STR_TO_DATE(LEFT(col,10),'%Y-%m-%d').
-- Stored as 'YYYY-MM-DD 00:00:00' text. Casting mandatory for all date logic.
SELECT
    SUM(CASE WHEN img_date IS NOT NULL AND TRIM(img_date) != '' THEN 1 ELSE 0 END) AS img_date_populated,
    SUM(CASE WHEN STR_TO_DATE(LEFT(img_date,10), '%Y-%m-%d') IS NOT NULL THEN 1 ELSE 0 END) AS img_date_parses,
    SUM(CASE WHEN result_date IS NOT NULL AND TRIM(result_date) != '' THEN 1 ELSE 0 END) AS result_date_populated,
    SUM(CASE WHEN STR_TO_DATE(LEFT(result_date,10), '%Y-%m-%d') IS NOT NULL THEN 1 ELSE 0 END) AS result_date_parses
FROM rgd_gold_ad.radiology;

===========CORR-011a: img_date plausibility classification (cast VARCHAR)=======
SELECT
    CASE
        WHEN img_date IS NULL OR TRIM(img_date) = '' THEN 'NULL/EMPTY'
        WHEN STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') > CURDATE() THEN 'FUTURE_DATE'
        WHEN STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') < '1900-01-01' THEN 'TOO_OLD (<1900)'
        ELSE 'PLAUSIBLE'
    END AS img_date_category,
    COUNT(*) AS n_rows,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM rgd_gold_ad.radiology
GROUP BY img_date_category
ORDER BY n_rows DESC;

===========CORR-011b: implausible img_date detail (future + ancient)=======
SELECT ndid, psid, encounterid, img_date, study_name, img_modality
FROM rgd_gold_ad.radiology
WHERE STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') > CURDATE()
   OR STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') < '1900-01-01'
ORDER BY STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') DESC
LIMIT 100;

===========CORR-011c: valid img_date range=======
SELECT
    MIN(CASE WHEN STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') >= '1900-01-01' THEN STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') END) AS min_valid_img_date,
    MAX(CASE WHEN STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') <= CURDATE() THEN STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') END) AS max_valid_img_date
FROM rgd_gold_ad.radiology;

===========CORR-012: primary key uniqueness (udm_unq_id)=======
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT udm_unq_id) AS distinct_udm_unq_id,
       COUNT(*) - COUNT(DISTINCT udm_unq_id) AS duplicate_pk
FROM rgd_gold_ad.radiology;

===========CORR-013: duplicate record check (img_date cast via LEFT, exclude null eid/date)=======
SELECT COUNT(*) AS duplicate_groups, SUM(cnt - 1) AS excess_rows
FROM (
    SELECT ndid, encounterid, LEFT(img_date,10) AS img_d, study_name,
           img_modality, img_body_part, cpt_code, COUNT(*) AS cnt
    FROM rgd_gold_ad.radiology
    WHERE udm_active_flag = 'Y'
      AND encounterid IS NOT NULL
      AND img_date IS NOT NULL AND TRIM(img_date) != ''
    GROUP BY ndid, encounterid, LEFT(img_date,10), study_name,
             img_modality, img_body_part, cpt_code
    HAVING COUNT(*) > 1
) t;


-- #############################################################################
-- # 3. CONCORDANCE
-- #############################################################################

===========CONC-001: referential integrity - orphan ndids (Critical, threshold 0%)=======
SELECT COUNT(DISTINCT r.ndid) AS orphan_ndids
FROM rgd_gold_ad.radiology r
LEFT JOIN rgd_gold_ad.patients p ON r.ndid = p.ndid
WHERE p.ndid IS NULL;

===========CONC-005: cpt_code_source standard-value distribution=======
-- VERIFIED: NULL 54.70% / probable_cpt 34.39% / proc_code 10.91%. Where coded, the code
-- is mostly 'probable' (inferred, not source-verified) - flag for downstream use.
SELECT COALESCE(cpt_code_source, 'NULL') AS cpt_code_source, COUNT(*) AS cnt,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM rgd_gold_ad.radiology
GROUP BY cpt_code_source
ORDER BY cnt DESC;

===========CONC-005b: img_modality distribution (standardization + retired composite labels)=======
-- VERIFIED: MR 32.68% + CT 16.77% dominate (appropriate for AD/neuro brain imaging).
-- Note messy 'retired' composite labels (e.g. 'MA - Retired', 'EC - Retired') needing
-- standardization. img_modality 32.87% null.
SELECT COALESCE(img_modality, 'NULL') AS img_modality, COUNT(*) AS cnt,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM rgd_gold_ad.radiology
GROUP BY img_modality
ORDER BY cnt DESC
LIMIT 25;

===========CONC-011: img_body_part distribution=======
SELECT COALESCE(img_body_part, 'NULL') AS img_body_part, COUNT(*) AS cnt,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM rgd_gold_ad.radiology
GROUP BY img_body_part
ORDER BY cnt DESC
LIMIT 20;


-- #############################################################################
-- # 4. CREDIBILITY
-- #############################################################################

===========PLAUS-MODALITY: modality clinical plausibility (brain imaging dominance)=======
SELECT COALESCE(img_modality, 'NULL') AS img_modality, COUNT(*) AS cnt,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM rgd_gold_ad.radiology
GROUP BY img_modality
ORDER BY cnt DESC
LIMIT 15;

===========PLAUS-FREQ: records per patient=======
SELECT
    MIN(rad_count) AS min_per_patient,
    MAX(rad_count) AS max_per_patient,
    ROUND(AVG(rad_count), 1) AS avg_per_patient,
    SUM(CASE WHEN rad_count = 1 THEN 1 ELSE 0 END) AS patients_with_1,
    SUM(CASE WHEN rad_count > 50 THEN 1 ELSE 0 END) AS patients_over_50
FROM (
    SELECT ndid, COUNT(*) AS rad_count
    FROM rgd_gold_ad.radiology
    GROUP BY ndid
) t;

===========PLAUS-STUDY: top study_name values=======
SELECT study_name, COUNT(*) AS cnt
FROM rgd_gold_ad.radiology
WHERE study_name IS NOT NULL AND TRIM(study_name) != ''
GROUP BY study_name
ORDER BY cnt DESC
LIMIT 20;


-- #############################################################################
-- # 5. CURRENCY
-- #############################################################################

===========CURR-013: historical data stability (udm_active_flag)=======
SELECT COALESCE(udm_active_flag, 'NULL') AS udm_active_flag, COUNT(*) AS cnt,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM rgd_gold_ad.radiology
GROUP BY udm_active_flag
ORDER BY cnt DESC;

===========CURR-014: future-dated events (Critical, threshold 0)=======
SELECT
    SUM(CASE WHEN STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') > CURDATE() THEN 1 ELSE 0 END) AS future_img_date,
    SUM(CASE WHEN enc_date > NOW() THEN 1 ELSE 0 END) AS future_enc_date
FROM rgd_gold_ad.radiology;

===========CURRENCY: run summary and load lineage=======
SELECT run_id, cohort_run_id,
       COUNT(*) AS total_records,
       COUNT(DISTINCT ndid) AS unique_patients,
       COUNT(DISTINCT source_udm_inc_id) AS distinct_source_records,
       MIN(gold_created_datetime) AS gold_created_min,
       MAX(gold_created_datetime) AS gold_created_max,
       SUM(CASE WHEN gold_updated_datetime IS NULL THEN 1 ELSE 0 END) AS never_updated
FROM rgd_gold_ad.radiology
GROUP BY run_id, cohort_run_id
ORDER BY cohort_run_id DESC;

-- =============================================================================
-- END OF FILE
-- =============================================================================
