-- =============================================================================
-- NeuroDiscovery AI — Gold Layer QC Queries
-- Table: rgd_gold_ad.radiology
-- Schema: rgd_gold_ad
-- Prepared By: Somenath Sen — RWD Team
-- Date: July 2026
-- Framework: 5C (Completeness, Correctness, Concordance, Credibility, Currency)
-- DE Key: psid + ndid + eid + result_id + img_finding + report_id
--         + report_date + img_date + study_name
-- Gold mapping: eid → encounterid, result_id → resultid, report_date → result_date
-- Missing DE fields: report_id (not in Gold)
-- Note: img_date and result_date are VARCHAR(100) — use LEFT(col,10) or STR_TO_DATE()
-- Exclusions: records where resultid + study_name both null (shell records)
--             case-insensitive LOWER(study_name)
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- BASELINE
-- ─────────────────────────────────────────────────────────────────────────────

-- B1. Total records, patients, psids
SELECT COUNT(*) AS total_records,
    COUNT(DISTINCT ndid) AS unique_patients,
    COUNT(DISTINCT psid) AS unique_psids
FROM rgd_gold_ad.radiology;

-- B2. Records and patients by psid
SELECT psid, COUNT(*) AS records,
    COUNT(DISTINCT ndid) AS unique_patients
FROM rgd_gold_ad.radiology
GROUP BY psid ORDER BY records DESC;

-- B3. Cohort coverage
SELECT
    (SELECT COUNT(DISTINCT ndid) FROM rgd_gold_ad.patients) AS cohort_patients,
    COUNT(DISTINCT ndid) AS patients_with_radiology,
    (SELECT COUNT(DISTINCT ndid) FROM rgd_gold_ad.patients)
        - COUNT(DISTINCT ndid) AS patients_without_radiology
FROM rgd_gold_ad.radiology;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. COMPLETENESS
-- ─────────────────────────────────────────────────────────────────────────────

-- C1.1 Null counts across all columns
SELECT
    SUM(CASE WHEN ndid IS NULL THEN 1 ELSE 0 END) AS null_ndid,
    SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS null_encounterid,
    SUM(CASE WHEN enc_date IS NULL THEN 1 ELSE 0 END) AS null_enc_date,
    SUM(CASE WHEN resultid IS NULL THEN 1 ELSE 0 END) AS null_resultid,
    SUM(CASE WHEN img_date IS NULL OR img_date = '' THEN 1 ELSE 0 END) AS null_img_date,
    SUM(CASE WHEN result_date IS NULL OR result_date = '' THEN 1 ELSE 0 END) AS null_result_date,
    SUM(CASE WHEN study_name IS NULL OR study_name = '' THEN 1 ELSE 0 END) AS null_study_name,
    SUM(CASE WHEN img_modality IS NULL OR img_modality = '' THEN 1 ELSE 0 END) AS null_img_modality,
    SUM(CASE WHEN img_report_status IS NULL OR img_report_status = '' THEN 1 ELSE 0 END) AS null_img_report_status,
    SUM(CASE WHEN img_report_text IS NULL OR img_report_text = '' THEN 1 ELSE 0 END) AS null_img_report_text,
    SUM(CASE WHEN img_finding IS NULL OR img_finding = '' THEN 1 ELSE 0 END) AS null_img_finding,
    SUM(CASE WHEN img_order_date IS NULL OR img_order_date = '' THEN 1 ELSE 0 END) AS null_img_order_date
FROM rgd_gold_ad.radiology;

-- C1.2 Fill rate from DE table (official source)
SELECT column_name, total_count, null_records, fill_rate_pct
FROM staging.fill_rate_report_gold
WHERE schema_name = 'rgd_gold_ad'
AND table_name = 'radiology'
ORDER BY fill_rate_pct DESC;

-- C1.3 Shell records (null resultid + null img_date + null result_date) by psid
SELECT psid,
    SUM(CASE WHEN resultid IS NULL AND img_date IS NULL
             AND result_date IS NULL THEN 1 ELSE 0 END) AS shell_records,
    COUNT(*) AS total_records,
    ROUND(SUM(CASE WHEN resultid IS NULL AND img_date IS NULL
             AND result_date IS NULL THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS pct_shell
FROM rgd_gold_ad.radiology
GROUP BY psid ORDER BY shell_records DESC;

-- C1.4 Encounterid null by psid
SELECT psid,
    SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS null_encounterid,
    COUNT(*) AS total_records,
    ROUND(SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS pct_null
FROM rgd_gold_ad.radiology
GROUP BY psid ORDER BY null_encounterid DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. CORRECTNESS
-- ─────────────────────────────────────────────────────────────────────────────

-- C2.1 Date plausibility (img_date is VARCHAR — requires casting)
SELECT
    SUM(CASE WHEN STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') > '2900-01-01'
             THEN 1 ELSE 0 END) AS far_future,
    SUM(CASE WHEN STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') > CURDATE()
             AND STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') <= '2900-01-01'
             THEN 1 ELSE 0 END) AS near_future,
    SUM(CASE WHEN STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') < '1900-01-01'
             THEN 1 ELSE 0 END) AS before_1900,
    SUM(CASE WHEN LEFT(img_date,4) = '0000' THEN 1 ELSE 0 END) AS zero_year
FROM rgd_gold_ad.radiology
WHERE img_date IS NOT NULL AND img_date != '';

-- C2.2 Date plausibility by psid
SELECT psid,
    SUM(CASE WHEN STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') > CURDATE()
             THEN 1 ELSE 0 END) AS future_img_date,
    SUM(CASE WHEN STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') < '1900-01-01'
             THEN 1 ELSE 0 END) AS before_1900
FROM rgd_gold_ad.radiology
WHERE img_date IS NOT NULL AND img_date != ''
GROUP BY psid
HAVING future_img_date > 0 OR before_1900 > 0
ORDER BY future_img_date DESC;

-- C2.3 Non-radiology study_name content
SELECT study_name, COUNT(*) AS cnt
FROM rgd_gold_ad.radiology
WHERE LOWER(study_name) IN (
    'vitamin b12','tsh','thyroid stimulating hormone',
    'comprehensive metabolic panel','comp. metabolic panel',
    'electroencephalogram','electrolyte panel',
    'valproic acid level','phenobarbital'
)
GROUP BY study_name ORDER BY cnt DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. CONCORDANCE
-- ─────────────────────────────────────────────────────────────────────────────

-- C3.1 img_report_status distribution
SELECT img_report_status, COUNT(*) AS cnt
FROM rgd_gold_ad.radiology
GROUP BY img_report_status ORDER BY cnt DESC;

-- C3.2 img_modality distribution
SELECT img_modality, COUNT(*) AS cnt
FROM rgd_gold_ad.radiology
WHERE img_modality IS NOT NULL AND img_modality != ''
GROUP BY img_modality ORDER BY cnt DESC LIMIT 20;

-- C3.3 Top study names
SELECT study_name, COUNT(*) AS cnt
FROM rgd_gold_ad.radiology
WHERE study_name IS NOT NULL AND study_name != ''
GROUP BY study_name ORDER BY cnt DESC LIMIT 20;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. CREDIBILITY
-- ─────────────────────────────────────────────────────────────────────────────

-- C4.1 Duplicate count on clean DE key
SELECT COUNT(*) AS duplicate_groups, SUM(grp_size-1) AS excess_rows
FROM (
    SELECT psid, ndid, encounterid, resultid,
           img_finding, result_date, img_date,
           LOWER(study_name) AS study_name,
           COUNT(*) AS grp_size
    FROM rgd_gold_ad.radiology
    WHERE udm_active_flag = 'Y'
    AND NOT (resultid IS NULL AND study_name IS NULL)
    GROUP BY psid, ndid, encounterid, resultid,
             img_finding, result_date, img_date,
             LOWER(study_name)
    HAVING COUNT(*) > 1
) t;

-- C4.2 Duplicate psid breakdown
SELECT psid, COUNT(*) AS duplicate_groups, SUM(grp_size-1) AS excess_rows
FROM (
    SELECT psid, ndid, encounterid, resultid,
           img_finding, result_date, img_date,
           LOWER(study_name) AS study_name,
           COUNT(*) AS grp_size
    FROM rgd_gold_ad.radiology
    WHERE udm_active_flag = 'Y'
    AND NOT (resultid IS NULL AND study_name IS NULL)
    GROUP BY psid, ndid, encounterid, resultid,
             img_finding, result_date, img_date,
             LOWER(study_name)
    HAVING COUNT(*) > 1
) t
GROUP BY psid ORDER BY duplicate_groups DESC;

-- C4.3 Duplicate sample rows
SELECT a.psid, a.ndid, a.encounterid, a.resultid,
    a.img_finding, a.result_date, a.img_date, a.study_name
FROM rgd_gold_ad.radiology a
JOIN (
    SELECT psid, ndid, encounterid, resultid,
           img_finding, result_date, img_date,
           LOWER(study_name) AS study_name_lower
    FROM rgd_gold_ad.radiology
    WHERE udm_active_flag = 'Y'
    AND NOT (resultid IS NULL AND study_name IS NULL)
    GROUP BY psid, ndid, encounterid, resultid,
             img_finding, result_date, img_date,
             LOWER(study_name)
    HAVING COUNT(*) > 1
    LIMIT 3
) b ON a.psid <=> b.psid AND a.ndid <=> b.ndid
    AND a.encounterid <=> b.encounterid
    AND a.resultid <=> b.resultid
    AND a.img_finding <=> b.img_finding
    AND a.result_date <=> b.result_date
    AND a.img_date <=> b.img_date
    AND LOWER(a.study_name) <=> b.study_name_lower
WHERE a.udm_active_flag = 'Y'
ORDER BY a.psid, a.ndid, a.study_name;

-- C4.4 Orphan ndids
SELECT COUNT(DISTINCT r.ndid) AS orphan_ndids
FROM rgd_gold_ad.radiology r
LEFT JOIN rgd_gold_ad.patients p ON r.ndid = p.ndid
WHERE p.ndid IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. CURRENCY
-- ─────────────────────────────────────────────────────────────────────────────

-- C5.1 udm_active_flag distribution
SELECT udm_active_flag, COUNT(*) AS cnt
FROM rgd_gold_ad.radiology
GROUP BY udm_active_flag;

-- C5.2 Date range confirmation (VARCHAR cast required)
SELECT
    MIN(STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d')) AS min_img_date,
    MAX(STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d')) AS max_img_date,
    MIN(enc_date) AS min_enc_date,
    MAX(enc_date) AS max_enc_date
FROM rgd_gold_ad.radiology
WHERE img_date IS NOT NULL AND img_date != ''
AND STR_TO_DATE(LEFT(img_date,10),'%Y-%m-%d') BETWEEN '1900-01-01' AND '2900-01-01';
