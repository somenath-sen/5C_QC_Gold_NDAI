-- =============================================================================
-- NeuroDiscovery AI — Gold Layer QC Queries
-- Table: rgd_gold_ad.labs
-- Schema: rgd_gold_ad
-- Prepared By: Somenath Sen — RWD Team
-- Date: July 2026
-- Framework: 5C (Completeness, Correctness, Concordance, Credibility, Currency)
-- DE Key: psid + ndid + eid + enc_date + result_date + result_code
--         + result_name + result_parameter + result_value + report_id
-- Gold mapping: eid → encounterid, result_code → test_code,
--               result_name/result_parameter → test_parameter
-- Missing DE fields: report_id (not in Gold)
-- Exclusions: null/empty test_parameter, <<name>> placeholder
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- BASELINE
-- ─────────────────────────────────────────────────────────────────────────────

-- B1. Total records, patients, psids
SELECT COUNT(*) AS total_records,
    COUNT(DISTINCT ndid) AS unique_patients,
    COUNT(DISTINCT psid) AS unique_psids
FROM rgd_gold_ad.labs;

-- B2. Records and patients by psid
SELECT psid, COUNT(*) AS records,
    COUNT(DISTINCT ndid) AS unique_patients
FROM rgd_gold_ad.labs
GROUP BY psid ORDER BY records DESC;

-- B3. Cohort coverage
SELECT
    (SELECT COUNT(DISTINCT ndid) FROM rgd_gold_ad.patients) AS cohort_patients,
    COUNT(DISTINCT ndid) AS patients_with_labs,
    (SELECT COUNT(DISTINCT ndid) FROM rgd_gold_ad.patients)
        - COUNT(DISTINCT ndid) AS patients_without_labs
FROM rgd_gold_ad.labs;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. COMPLETENESS
-- ─────────────────────────────────────────────────────────────────────────────

-- C1.1 Null counts across all columns
SELECT
    SUM(CASE WHEN ndid IS NULL THEN 1 ELSE 0 END) AS null_ndid,
    SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS null_encounterid,
    SUM(CASE WHEN enc_date IS NULL THEN 1 ELSE 0 END) AS null_enc_date,
    SUM(CASE WHEN result_date IS NULL THEN 1 ELSE 0 END) AS null_result_date,
    SUM(CASE WHEN sample_collection_date IS NULL THEN 1 ELSE 0 END) AS null_sample_collection_date,
    SUM(CASE WHEN test_code IS NULL OR test_code = '' THEN 1 ELSE 0 END) AS null_test_code,
    SUM(CASE WHEN test_parameter IS NULL OR test_parameter = '' THEN 1 ELSE 0 END) AS null_test_parameter,
    SUM(CASE WHEN result_value IS NULL OR result_value = '' THEN 1 ELSE 0 END) AS null_result_value,
    SUM(CASE WHEN result_unit IS NULL OR result_unit = '' THEN 1 ELSE 0 END) AS null_result_unit,
    SUM(CASE WHEN result_range IS NULL OR result_range = '' THEN 1 ELSE 0 END) AS null_result_range,
    SUM(CASE WHEN result_status IS NULL OR result_status = '' THEN 1 ELSE 0 END) AS null_result_status,
    SUM(CASE WHEN normal_flag IS NULL OR normal_flag = '' THEN 1 ELSE 0 END) AS null_normal_flag,
    SUM(CASE WHEN test_coding_system IS NULL OR test_coding_system = '' THEN 1 ELSE 0 END) AS null_test_coding_system,
    SUM(CASE WHEN lab_order_date IS NULL THEN 1 ELSE 0 END) AS null_lab_order_date,
    SUM(CASE WHEN test_panel_name IS NULL OR test_panel_name = '' THEN 1 ELSE 0 END) AS null_test_panel_name,
    SUM(CASE WHEN resultid IS NULL THEN 1 ELSE 0 END) AS null_resultid,
    SUM(CASE WHEN specimen_source IS NULL OR specimen_source = '' THEN 1 ELSE 0 END) AS null_specimen_source
FROM rgd_gold_ad.labs;

-- C1.2 Fill rate from DE table (official source)
SELECT column_name, total_count, null_records, fill_rate_pct
FROM staging.fill_rate_report_gold
WHERE schema_name = 'rgd_gold_ad'
AND table_name = 'labs'
ORDER BY fill_rate_pct DESC;

-- C1.3 LOINC coverage by psid
SELECT psid,
    SUM(CASE WHEN test_coding_system = 'LOINC' THEN 1 ELSE 0 END) AS loinc_records,
    COUNT(*) AS total_records,
    ROUND(SUM(CASE WHEN test_coding_system = 'LOINC' THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS loinc_pct
FROM rgd_gold_ad.labs
GROUP BY psid ORDER BY total_records DESC;

-- C1.4 Encounterid null by psid
SELECT psid,
    SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS null_encounterid,
    COUNT(*) AS total_records,
    ROUND(SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS pct_null
FROM rgd_gold_ad.labs
GROUP BY psid ORDER BY null_encounterid DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. CORRECTNESS
-- ─────────────────────────────────────────────────────────────────────────────

-- C2.1 result_date before sample_collection_date by psid
SELECT psid,
    COUNT(*) AS records,
    MIN(DATEDIFF(result_date, sample_collection_date)) AS min_offset_days,
    MAX(DATEDIFF(result_date, sample_collection_date)) AS max_offset_days
FROM rgd_gold_ad.labs
WHERE result_date < sample_collection_date
GROUP BY psid ORDER BY records DESC;

-- C2.2 <<name>> placeholder in test_parameter
SELECT psid, COUNT(*) AS cnt
FROM rgd_gold_ad.labs
WHERE test_parameter = '<<name>>'
GROUP BY psid ORDER BY cnt DESC;

-- C2.3 Date plausibility
SELECT
    SUM(CASE WHEN result_date > '2900-01-01' THEN 1 ELSE 0 END) AS far_future,
    SUM(CASE WHEN result_date > CURDATE()
             AND result_date <= '2900-01-01' THEN 1 ELSE 0 END) AS near_future,
    SUM(CASE WHEN result_date < '1900-01-01' THEN 1 ELSE 0 END) AS before_1900,
    MIN(CASE WHEN result_date BETWEEN '1900-01-01' AND CURDATE()
             THEN result_date END) AS min_result_date,
    MAX(CASE WHEN result_date BETWEEN '1900-01-01' AND CURDATE()
             THEN result_date END) AS max_result_date
FROM rgd_gold_ad.labs;

-- C2.4 psid 8 outlier sample (-569 day offset)
SELECT gold_row_id, ndid, psid, encounterid, resultid,
    enc_date, result_date, sample_collection_date,
    test_parameter, result_value, result_unit,
    DATEDIFF(result_date, sample_collection_date) AS offset_days
FROM rgd_gold_ad.labs
WHERE psid = 8
AND result_date < sample_collection_date
AND DATEDIFF(result_date, sample_collection_date) <= -500
LIMIT 10;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. CONCORDANCE
-- ─────────────────────────────────────────────────────────────────────────────

-- C3.1 test_coding_system distribution
SELECT test_coding_system, COUNT(*) AS cnt
FROM rgd_gold_ad.labs
GROUP BY test_coding_system ORDER BY cnt DESC;

-- C3.2 Top test parameters
SELECT test_parameter, COUNT(*) AS cnt
FROM rgd_gold_ad.labs
WHERE test_parameter IS NOT NULL
AND test_parameter != ''
AND test_parameter != '<<name>>'
GROUP BY test_parameter ORDER BY cnt DESC LIMIT 20;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. CREDIBILITY
-- ─────────────────────────────────────────────────────────────────────────────

-- C4.1 Duplicate count on clean DE key
SELECT COUNT(*) AS duplicate_groups, SUM(grp_size-1) AS excess_rows
FROM (
    SELECT psid, ndid, encounterid, enc_date,
           result_date, test_code, test_parameter, result_value,
           COUNT(*) AS grp_size
    FROM rgd_gold_ad.labs
    WHERE udm_active_flag = 'Y'
    AND test_parameter IS NOT NULL AND test_parameter != ''
    AND test_parameter != '<<name>>'
    GROUP BY psid, ndid, encounterid, enc_date,
             result_date, test_code, test_parameter, result_value
    HAVING COUNT(*) > 1
) t;

-- C4.2 Duplicate psid breakdown
SELECT psid, COUNT(*) AS duplicate_groups, SUM(grp_size-1) AS excess_rows
FROM (
    SELECT psid, ndid, encounterid, enc_date,
           result_date, test_code, test_parameter, result_value,
           COUNT(*) AS grp_size
    FROM rgd_gold_ad.labs
    WHERE udm_active_flag = 'Y'
    AND test_parameter IS NOT NULL AND test_parameter != ''
    AND test_parameter != '<<name>>'
    GROUP BY psid, ndid, encounterid, enc_date,
             result_date, test_code, test_parameter, result_value
    HAVING COUNT(*) > 1
) t
GROUP BY psid ORDER BY duplicate_groups DESC;

-- C4.3 Duplicate sample rows
SELECT a.psid, a.ndid, a.encounterid, a.enc_date,
    a.result_date, a.test_code, a.test_parameter,
    a.result_value, a.result_unit
FROM rgd_gold_ad.labs a
JOIN (
    SELECT psid, ndid, encounterid, enc_date,
           result_date, test_code, test_parameter, result_value
    FROM rgd_gold_ad.labs
    WHERE udm_active_flag = 'Y'
    AND test_parameter IS NOT NULL AND test_parameter != ''
    AND test_parameter != '<<name>>'
    GROUP BY psid, ndid, encounterid, enc_date,
             result_date, test_code, test_parameter, result_value
    HAVING COUNT(*) > 1
    LIMIT 3
) b ON a.psid <=> b.psid AND a.ndid <=> b.ndid
    AND a.encounterid <=> b.encounterid
    AND a.enc_date <=> b.enc_date
    AND a.result_date <=> b.result_date
    AND a.test_code <=> b.test_code
    AND a.test_parameter <=> b.test_parameter
    AND a.result_value <=> b.result_value
WHERE a.udm_active_flag = 'Y'
ORDER BY a.psid, a.ndid, a.test_parameter;

-- C4.4 Orphan ndids
SELECT COUNT(DISTINCT l.ndid) AS orphan_ndids
FROM rgd_gold_ad.labs l
LEFT JOIN rgd_gold_ad.patients p ON l.ndid = p.ndid
WHERE p.ndid IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. CURRENCY
-- ─────────────────────────────────────────────────────────────────────────────

-- C5.1 udm_active_flag distribution
SELECT udm_active_flag, COUNT(*) AS cnt
FROM rgd_gold_ad.labs
GROUP BY udm_active_flag;

-- C5.2 Date range confirmation
SELECT
    MIN(result_date) AS min_result_date,
    MAX(result_date) AS max_result_date,
    MIN(enc_date) AS min_enc_date,
    MAX(enc_date) AS max_enc_date
FROM rgd_gold_ad.labs
WHERE result_date BETWEEN '1900-01-01' AND '2900-01-01';
