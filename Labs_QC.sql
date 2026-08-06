-- =============================================================================
-- NeuroDiscovery AI - Regulatory-Grade Data QC Queries (5C Model)
-- Table: rgd_gold_ad.labs  (Gold Layer)
-- Prepared By: Somenath Sen - RWD Team
-- Date: August 2026
-- Framework: 5C (Completeness, Correctness, Concordance, Credibility, Currency)
-- Refresh note: result_name_full column added - REQUIRED in duplicate key.
--               test_code is 100% NULL in current refresh (excluded from key).
-- =============================================================================


-- #############################################################################
-- # BASELINE
-- #############################################################################

===========BASELINE: total records, patients, psids=======
SELECT COUNT(*) AS total_records,
       COUNT(DISTINCT ndid) AS unique_patients,
       COUNT(DISTINCT psid) AS unique_psids
FROM rgd_gold_ad.labs;

===========BASELINE: records by psid=======
SELECT psid, COUNT(*) AS records, COUNT(DISTINCT ndid) AS patients,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM rgd_gold_ad.labs
GROUP BY psid
ORDER BY records DESC;

===========BASELINE: cohort coverage=======
SELECT
    COUNT(DISTINCT p.ndid) AS total_cohort_patients,
    COUNT(DISTINCT l.ndid) AS patients_with_labs,
    COUNT(DISTINCT p.ndid) - COUNT(DISTINCT l.ndid) AS patients_without_labs
FROM rgd_gold_ad.patients p
LEFT JOIN rgd_gold_ad.labs l ON p.ndid = l.ndid;


-- #############################################################################
-- # 1. COMPLETENESS
-- #############################################################################

===========COMPLETENESS: rgd_gold_ad.labs - full column fill rate=======
WITH cohort_labs AS (
    SELECT * FROM rgd_gold_ad.labs WHERE udm_active_flag = 'Y'
)
SELECT 'ndid' AS column_name, COUNT(*) AS denominator, SUM(CASE WHEN ndid IS NOT NULL THEN 1 ELSE 0 END) AS present_count, ROUND(SUM(CASE WHEN ndid IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_present FROM cohort_labs
UNION ALL
SELECT 'encounterid', COUNT(*), SUM(CASE WHEN encounterid IS NOT NULL THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN encounterid IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'resultid', COUNT(*), SUM(CASE WHEN resultid IS NOT NULL THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN resultid IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'enc_date', COUNT(*), SUM(CASE WHEN enc_date IS NOT NULL THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN enc_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'lab_order_date', COUNT(*), SUM(CASE WHEN lab_order_date IS NOT NULL THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN lab_order_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'sample_collection_date', COUNT(*), SUM(CASE WHEN sample_collection_date IS NOT NULL THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN sample_collection_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'result_date', COUNT(*), SUM(CASE WHEN result_date IS NOT NULL THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN result_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'test_panel_name', COUNT(*), SUM(CASE WHEN test_panel_name IS NOT NULL AND TRIM(test_panel_name) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN test_panel_name IS NOT NULL AND TRIM(test_panel_name) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'test_parameter', COUNT(*), SUM(CASE WHEN test_parameter IS NOT NULL AND TRIM(test_parameter) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN test_parameter IS NOT NULL AND TRIM(test_parameter) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'test_code', COUNT(*), SUM(CASE WHEN test_code IS NOT NULL AND TRIM(test_code) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN test_code IS NOT NULL AND TRIM(test_code) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'test_coding_system', COUNT(*), SUM(CASE WHEN test_coding_system IS NOT NULL AND TRIM(test_coding_system) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN test_coding_system IS NOT NULL AND TRIM(test_coding_system) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'result_value', COUNT(*), SUM(CASE WHEN result_value IS NOT NULL AND TRIM(result_value) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN result_value IS NOT NULL AND TRIM(result_value) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'result_unit', COUNT(*), SUM(CASE WHEN result_unit IS NOT NULL AND TRIM(result_unit) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN result_unit IS NOT NULL AND TRIM(result_unit) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'result_range', COUNT(*), SUM(CASE WHEN result_range IS NOT NULL AND TRIM(result_range) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN result_range IS NOT NULL AND TRIM(result_range) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'normal_flag', COUNT(*), SUM(CASE WHEN normal_flag IS NOT NULL AND TRIM(normal_flag) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN normal_flag IS NOT NULL AND TRIM(normal_flag) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'result_status', COUNT(*), SUM(CASE WHEN result_status IS NOT NULL AND TRIM(result_status) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN result_status IS NOT NULL AND TRIM(result_status) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'specimen_source', COUNT(*), SUM(CASE WHEN specimen_source IS NOT NULL AND TRIM(specimen_source) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN specimen_source IS NOT NULL AND TRIM(specimen_source) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'result_name_full', COUNT(*), SUM(CASE WHEN result_name_full IS NOT NULL AND TRIM(result_name_full) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN result_name_full IS NOT NULL AND TRIM(result_name_full) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs
UNION ALL
SELECT 'udm_unq_id', COUNT(*), SUM(CASE WHEN udm_unq_id IS NOT NULL AND TRIM(udm_unq_id) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN udm_unq_id IS NOT NULL AND TRIM(udm_unq_id) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_labs;

===========COMP-001: ndid completeness (Critical, threshold 0% missing)=======
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN ndid IS NULL THEN 1 ELSE 0 END) AS n_missing_ndid,
       ROUND(SUM(CASE WHEN ndid IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_missing_ndid
FROM rgd_gold_ad.labs;

===========COMP-002: encounterid completeness (Critical, threshold 0% missing)=======
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS n_missing_encounterid,
       ROUND(SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_missing_encounterid
FROM rgd_gold_ad.labs;

===========COMP-002b: encounterid null by psid=======
SELECT psid,
       SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS n_missing,
       COUNT(*) AS total,
       ROUND(SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_missing
FROM rgd_gold_ad.labs
GROUP BY psid
ORDER BY n_missing DESC;

===========COMP-003: result_date completeness (Critical, threshold <2% missing)=======
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN result_date IS NULL THEN 1 ELSE 0 END) AS n_missing_result_date,
       ROUND(SUM(CASE WHEN result_date IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_missing_result_date
FROM rgd_gold_ad.labs;

===========COMP-017: fully-null columns (Major) - test_code, lab_order_date, test_panel_name all 100% NULL=======
-- VERIFIED: three columns are entirely unpopulated in this refresh.
SELECT 'test_code' AS column_name, COUNT(*) AS total_rows,
       SUM(CASE WHEN test_code IS NULL OR TRIM(test_code) = '' THEN 1 ELSE 0 END) AS n_missing,
       ROUND(SUM(CASE WHEN test_code IS NOT NULL AND TRIM(test_code) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_present
FROM rgd_gold_ad.labs
UNION ALL
SELECT 'lab_order_date', COUNT(*),
       SUM(CASE WHEN lab_order_date IS NULL THEN 1 ELSE 0 END),
       ROUND(SUM(CASE WHEN lab_order_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
FROM rgd_gold_ad.labs
UNION ALL
SELECT 'test_panel_name', COUNT(*),
       SUM(CASE WHEN test_panel_name IS NULL OR TRIM(test_panel_name) = '' THEN 1 ELSE 0 END),
       ROUND(SUM(CASE WHEN test_panel_name IS NOT NULL AND TRIM(test_panel_name) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
FROM rgd_gold_ad.labs;

===========COMP-005: test_parameter completeness (Major, threshold >=95%)=======
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN test_parameter IS NULL OR TRIM(test_parameter) = '' THEN 1 ELSE 0 END) AS n_missing,
       ROUND(SUM(CASE WHEN test_parameter IS NOT NULL AND TRIM(test_parameter) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_present
FROM rgd_gold_ad.labs;

===========COMP-008: result_value completeness (Major, threshold >=95%)=======
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN result_value IS NULL OR TRIM(result_value) = '' THEN 1 ELSE 0 END) AS n_missing,
       ROUND(SUM(CASE WHEN result_value IS NOT NULL AND TRIM(result_value) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_present
FROM rgd_gold_ad.labs;

===========COMP-020: udm_unq_id completeness (Critical, threshold 0% missing)=======
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN udm_unq_id IS NULL OR TRIM(udm_unq_id) = '' THEN 1 ELSE 0 END) AS n_missing_udm_unq_id
FROM rgd_gold_ad.labs;


-- #############################################################################
-- # 2. CORRECTNESS
-- #############################################################################

===========CORR-011a: result_date plausibility classification=======
WITH classified AS (
    SELECT ndid, encounterid, result_date,
        CASE
            WHEN result_date IS NULL THEN 'NULL'
            WHEN CAST(result_date AS CHAR) IN ('0000-00-00','0000-00-00 00:00:00') THEN 'SENTINEL_ZERO'
            WHEN YEAR(result_date) < 1900 THEN 'TOO_OLD (<1900)'
            WHEN result_date > CURDATE() THEN 'FUTURE_DATE'
            ELSE 'PLAUSIBLE'
        END AS result_date_category
    FROM rgd_gold_ad.labs
)
SELECT result_date_category, COUNT(*) AS n_rows,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM classified
GROUP BY result_date_category
ORDER BY n_rows DESC;

===========CORR-011b: implausible result_date detail (future + ancient)=======
SELECT ndid, psid, encounterid, result_date, test_parameter, result_value
FROM rgd_gold_ad.labs
WHERE result_date > CURDATE() OR result_date < '1900-01-01'
ORDER BY result_date DESC
LIMIT 100;

===========CORR-011c: valid date range=======
SELECT
    MIN(CASE WHEN result_date >= '1900-01-01' THEN result_date END) AS min_valid_result_date,
    MAX(CASE WHEN result_date <= CURDATE() THEN result_date END) AS max_valid_result_date
FROM rgd_gold_ad.labs;

===========CORR-014: cross-date logic (result_date before sample_collection / order)=======
-- VERIFIED: result_before_collection = 85,602 (2.1%) - chronologically impossible.
-- collection_before_order = 0 (lab_order_date is 100% null, so no comparison possible).
SELECT
    SUM(CASE WHEN result_date IS NOT NULL AND sample_collection_date IS NOT NULL
             AND result_date < sample_collection_date THEN 1 ELSE 0 END) AS result_before_collection,
    SUM(CASE WHEN sample_collection_date IS NOT NULL AND lab_order_date IS NOT NULL
             AND sample_collection_date < lab_order_date THEN 1 ELSE 0 END) AS collection_before_order
FROM rgd_gold_ad.labs;

===========CORR-012: primary key uniqueness (udm_unq_id)=======
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT udm_unq_id) AS distinct_udm_unq_id,
       COUNT(*) - COUNT(DISTINCT udm_unq_id) AS duplicate_pk
FROM rgd_gold_ad.labs;

===========CORR-013: duplicate record check (result_name_full in key; test_code EXCLUDED - 100% null)=======
-- NOTE: test_code is 100% null in this refresh, so it cannot serve as a key column.
-- result_name_full is the refresh-added distinguishing column and IS required in the key.
SELECT COUNT(*) AS duplicate_groups, SUM(cnt - 1) AS excess_rows
FROM (
    SELECT ndid, encounterid, result_date, test_parameter,
           result_value, result_unit, result_name_full, COUNT(*) AS cnt
    FROM rgd_gold_ad.labs
    WHERE udm_active_flag = 'Y'
      AND encounterid IS NOT NULL
      AND result_date IS NOT NULL
    GROUP BY ndid, encounterid, result_date, test_parameter,
             result_value, result_unit, result_name_full
    HAVING COUNT(*) > 1
) t;

===========CORR-013b: duplicate comparison WITHOUT result_name_full (shows false-positive inflation)=======
SELECT COUNT(*) AS dup_groups_without_name_full, SUM(cnt - 1) AS excess_without_name_full
FROM (
    SELECT ndid, encounterid, result_date, test_parameter, result_value, result_unit, COUNT(*) AS cnt
    FROM rgd_gold_ad.labs
    WHERE udm_active_flag = 'Y'
      AND encounterid IS NOT NULL
      AND result_date IS NOT NULL
    GROUP BY ndid, encounterid, result_date, test_parameter, result_value, result_unit
    HAVING COUNT(*) > 1
) t;


-- #############################################################################
-- # 3. CONCORDANCE
-- #############################################################################

===========CONC-001: referential integrity - orphan ndids (Critical, threshold 0%)=======
SELECT COUNT(DISTINCT l.ndid) AS orphan_ndids
FROM rgd_gold_ad.labs l
LEFT JOIN rgd_gold_ad.patients p ON l.ndid = p.ndid
WHERE p.ndid IS NULL;

===========CONC-005: test_coding_system standard-value distribution (LOINC coverage)=======
SELECT COALESCE(test_coding_system, 'NULL') AS test_coding_system, COUNT(*) AS cnt,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM rgd_gold_ad.labs
GROUP BY test_coding_system
ORDER BY cnt DESC;

===========CONC-005b: normal_flag standard-value distribution (uncontrolled vocabulary)=======
-- VERIFIED: ~20 distinct values, NOT a controlled vocabulary. Standard flags (N/H/L/A/S)
-- mixed with junk single-chars (+, *, #, -), doubled codes (HH, LL, AA), and 'Unknown'.
-- True missing = empty-string (47.40%) + NULL (6.31%) = 53.71%. Note: empty-string is
-- distinct from NULL here and must not be counted as populated.
SELECT
    CASE WHEN normal_flag IS NULL THEN 'NULL'
         WHEN TRIM(normal_flag) = '' THEN 'EMPTY_STRING'
         ELSE normal_flag END AS normal_flag_value,
    COUNT(*) AS cnt,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM rgd_gold_ad.labs
GROUP BY normal_flag_value
ORDER BY cnt DESC
LIMIT 25;

===========CONC-011: test_parameter to result_name_full consistency (top parameters)=======
SELECT test_parameter, COUNT(DISTINCT result_name_full) AS name_full_variants, COUNT(*) AS n_rows
FROM rgd_gold_ad.labs
WHERE test_parameter IS NOT NULL AND TRIM(test_parameter) != ''
GROUP BY test_parameter
ORDER BY n_rows DESC
LIMIT 25;


-- #############################################################################
-- # 4. CREDIBILITY
-- #############################################################################

===========PLAUS: result_value numeric plausibility scan=======
SELECT
    SUM(CASE WHEN result_value IS NULL OR TRIM(result_value) = '' THEN 1 ELSE 0 END) AS null_value,
    SUM(CASE WHEN result_value REGEXP '^[0-9]+(\\.[0-9]+)?$' THEN 1 ELSE 0 END) AS numeric_value,
    SUM(CASE WHEN result_value IS NOT NULL AND TRIM(result_value) != '' AND result_value NOT REGEXP '^[0-9]+(\\.[0-9]+)?$' THEN 1 ELSE 0 END) AS non_numeric_value
FROM rgd_gold_ad.labs;

===========PLAUS-FREQ: records per patient=======
SELECT
    MIN(lab_count) AS min_per_patient,
    MAX(lab_count) AS max_per_patient,
    ROUND(AVG(lab_count), 1) AS avg_per_patient,
    SUM(CASE WHEN lab_count = 1 THEN 1 ELSE 0 END) AS patients_with_1,
    SUM(CASE WHEN lab_count > 1000 THEN 1 ELSE 0 END) AS patients_over_1000
FROM (
    SELECT ndid, COUNT(*) AS lab_count
    FROM rgd_gold_ad.labs
    GROUP BY ndid
) t;

===========PLAUS-PANEL: top test_panel_name values=======
SELECT test_panel_name, COUNT(*) AS cnt
FROM rgd_gold_ad.labs
WHERE test_panel_name IS NOT NULL AND TRIM(test_panel_name) != ''
GROUP BY test_panel_name
ORDER BY cnt DESC
LIMIT 20;


-- #############################################################################
-- # 5. CURRENCY
-- #############################################################################

===========CURR-013: historical data stability (udm_active_flag)=======
SELECT COALESCE(udm_active_flag, 'NULL') AS udm_active_flag, COUNT(*) AS cnt,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM rgd_gold_ad.labs
GROUP BY udm_active_flag
ORDER BY cnt DESC;

===========CURR-014: future-dated events (Critical, threshold 0)=======
SELECT SUM(CASE WHEN result_date > CURDATE() THEN 1 ELSE 0 END) AS future_result_date,
       SUM(CASE WHEN enc_date > CURDATE() THEN 1 ELSE 0 END) AS future_enc_date
FROM rgd_gold_ad.labs;

===========CURRENCY: run summary and load lineage=======
SELECT run_id, cohort_run_id,
       COUNT(*) AS total_records,
       COUNT(DISTINCT ndid) AS unique_patients,
       COUNT(DISTINCT source_udm_inc_id) AS distinct_source_records,
       MIN(gold_created_datetime) AS gold_created_min,
       MAX(gold_created_datetime) AS gold_created_max,
       SUM(CASE WHEN gold_updated_datetime IS NULL THEN 1 ELSE 0 END) AS never_updated
FROM rgd_gold_ad.labs
GROUP BY run_id, cohort_run_id
ORDER BY cohort_run_id DESC;

-- =============================================================================
-- END OF FILE
-- =============================================================================
