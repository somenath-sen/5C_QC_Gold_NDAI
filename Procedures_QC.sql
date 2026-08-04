-- =============================================================================
-- NeuroDiscovery AI — Gold Layer QC Queries
-- Table: rgd_gold_ad.procedures
-- Schema: rgd_gold_ad
-- Prepared By: Somenath Sen — RWD Team
-- Date: July 2026
-- Framework: 5C (Completeness, Correctness, Concordance, Credibility, Currency)
-- DE Key: psid + ndid + eid + encounter_date + proc_start_date + proc_last_date
--         + proc_code + proc_name
-- Gold mapping: eid → encounterid, proc_last_date → proc_end_date
-- Missing DE fields: encounter_date (not in Gold)
-- Exclusions: NS records (proc_code = 'NS'), null proc_start_date
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- BASELINE
-- ─────────────────────────────────────────────────────────────────────────────

-- B1. Total records, patients, psids
SELECT COUNT(*) AS total_records,
    COUNT(DISTINCT ndid) AS unique_patients,
    COUNT(DISTINCT psid) AS unique_psids
FROM rgd_gold_ad.procedures;

-- B2. Records and patients by psid
SELECT psid, COUNT(*) AS records,
    COUNT(DISTINCT ndid) AS unique_patients
FROM rgd_gold_ad.procedures
GROUP BY psid ORDER BY records DESC;

-- B3. Cohort coverage
SELECT
    (SELECT COUNT(DISTINCT ndid) FROM rgd_gold_ad.patients) AS cohort_patients,
    COUNT(DISTINCT ndid) AS patients_with_procedures,
    (SELECT COUNT(DISTINCT ndid) FROM rgd_gold_ad.patients)
        - COUNT(DISTINCT ndid) AS patients_without_procedures
FROM rgd_gold_ad.procedures;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. COMPLETENESS
-- ─────────────────────────────────────────────────────────────────────────────

-- C1.1 Null counts across all columns
SELECT
    SUM(CASE WHEN ndid IS NULL THEN 1 ELSE 0 END) AS null_ndid,
    SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS null_encounterid,
    SUM(CASE WHEN proc_start_date IS NULL THEN 1 ELSE 0 END) AS null_proc_start_date,
    SUM(CASE WHEN proc_end_date IS NULL THEN 1 ELSE 0 END) AS null_proc_end_date,
    SUM(CASE WHEN proc_code IS NULL OR proc_code = '' THEN 1 ELSE 0 END) AS null_proc_code,
    SUM(CASE WHEN proc_name IS NULL OR proc_name = '' THEN 1 ELSE 0 END) AS null_proc_name,
    SUM(CASE WHEN proc_coding_system IS NULL OR proc_coding_system = '' THEN 1 ELSE 0 END) AS null_proc_coding_system,
    SUM(CASE WHEN proc_description IS NULL OR proc_description = '' THEN 1 ELSE 0 END) AS null_proc_description,
    SUM(CASE WHEN proc_category IS NULL OR proc_category = '' THEN 1 ELSE 0 END) AS null_proc_category,
    SUM(CASE WHEN proc_units IS NULL THEN 1 ELSE 0 END) AS null_proc_units,
    SUM(CASE WHEN proc_notes IS NULL OR proc_notes = '' THEN 1 ELSE 0 END) AS null_proc_notes,
    SUM(CASE WHEN procedureid IS NULL THEN 1 ELSE 0 END) AS null_procedureid
FROM rgd_gold_ad.procedures;

-- C1.2 Fill rate from DE table (official source)
SELECT column_name, total_count, null_records, fill_rate_pct
FROM staging.fill_rate_report_gold
WHERE schema_name = 'rgd_gold_ad'
AND table_name = 'procedures'
ORDER BY fill_rate_pct DESC;

-- C1.3 proc_coding_system distribution
SELECT proc_coding_system, COUNT(*) AS cnt
FROM rgd_gold_ad.procedures
GROUP BY proc_coding_system ORDER BY cnt DESC;

-- C1.4 Encounterid null by psid
SELECT psid,
    SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS null_encounterid,
    COUNT(*) AS total_records,
    ROUND(SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS pct_null
FROM rgd_gold_ad.procedures
GROUP BY psid ORDER BY null_encounterid DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. CORRECTNESS
-- ─────────────────────────────────────────────────────────────────────────────

-- C2.1 NS records (proc_code = NS + proc_coding_system = NS)
SELECT psid,
    SUM(CASE WHEN proc_code = 'NS' THEN 1 ELSE 0 END) AS ns_proc_code,
    SUM(CASE WHEN proc_coding_system = 'NS' THEN 1 ELSE 0 END) AS ns_coding_system,
    COUNT(*) AS total_ns_records
FROM rgd_gold_ad.procedures
WHERE proc_code = 'NS' OR proc_coding_system = 'NS'
GROUP BY psid ORDER BY ns_proc_code DESC;

-- C2.2 Date plausibility
SELECT
    SUM(CASE WHEN proc_start_date > '2900-01-01' THEN 1 ELSE 0 END) AS far_future,
    SUM(CASE WHEN proc_start_date > CURDATE()
             AND proc_start_date <= '2900-01-01' THEN 1 ELSE 0 END) AS near_future,
    SUM(CASE WHEN proc_start_date < '1900-01-01' THEN 1 ELSE 0 END) AS before_1900,
    SUM(CASE WHEN proc_end_date < proc_start_date THEN 1 ELSE 0 END) AS end_before_start,
    MIN(CASE WHEN proc_start_date BETWEEN '1900-01-01' AND CURDATE()
             THEN proc_start_date END) AS min_proc_start_date,
    MAX(CASE WHEN proc_start_date BETWEEN '1900-01-01' AND CURDATE()
             THEN proc_start_date END) AS max_proc_start_date
FROM rgd_gold_ad.procedures;

-- C2.3 Far-future date sample rows
SELECT gold_row_id, ndid, psid, encounterid, procedureid,
    proc_start_date, proc_end_date, proc_code,
    proc_coding_system, proc_name
FROM rgd_gold_ad.procedures
WHERE proc_start_date > '2900-01-01'
ORDER BY proc_start_date DESC;

-- C2.4 Date plausibility by psid (far-future, near-future breakdown)
SELECT psid,
    SUM(CASE WHEN proc_start_date > '2900-01-01' THEN 1 ELSE 0 END) AS far_future,
    SUM(CASE WHEN proc_start_date > CURDATE()
             AND proc_start_date <= '2900-01-01' THEN 1 ELSE 0 END) AS near_future
FROM rgd_gold_ad.procedures
GROUP BY psid
HAVING far_future > 0 OR near_future > 0
ORDER BY far_future DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. CONCORDANCE
-- ─────────────────────────────────────────────────────────────────────────────

-- C3.1 HCPCS/CPT Category II/III mislabel
-- CPT Cat II codes end in F; Cat III codes end in T
-- These are labelled as HCPCS but are CPT codes
SELECT psid, COUNT(*) AS mislabelled_records,
    COUNT(DISTINCT ndid) AS unique_patients
FROM rgd_gold_ad.procedures
WHERE proc_coding_system = 'HCPCS'
AND (proc_code LIKE '%F' OR proc_code LIKE '%T')
GROUP BY psid ORDER BY mislabelled_records DESC;

-- C3.2 Top proc codes with coding system
SELECT proc_code, proc_coding_system, COUNT(*) AS cnt
FROM rgd_gold_ad.procedures
WHERE proc_code IS NOT NULL
AND proc_code NOT IN ('NS', '')
GROUP BY proc_code, proc_coding_system
ORDER BY cnt DESC LIMIT 20;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. CREDIBILITY
-- ─────────────────────────────────────────────────────────────────────────────

-- C4.1 Duplicate count on clean DE key
SELECT COUNT(*) AS duplicate_groups, SUM(grp_size-1) AS excess_rows
FROM (
    SELECT psid, ndid, encounterid, proc_start_date,
           proc_end_date, proc_code, proc_name,
           COUNT(*) AS grp_size
    FROM rgd_gold_ad.procedures
    WHERE udm_active_flag = 'Y'
    AND proc_code != 'NS'
    AND proc_start_date IS NOT NULL
    GROUP BY psid, ndid, encounterid, proc_start_date,
             proc_end_date, proc_code, proc_name
    HAVING COUNT(*) > 1
) t;

-- C4.2 Duplicate psid breakdown
SELECT psid, COUNT(*) AS duplicate_groups, SUM(grp_size-1) AS excess_rows
FROM (
    SELECT psid, ndid, encounterid, proc_start_date,
           proc_end_date, proc_code, proc_name,
           COUNT(*) AS grp_size
    FROM rgd_gold_ad.procedures
    WHERE udm_active_flag = 'Y'
    AND proc_code != 'NS'
    AND proc_start_date IS NOT NULL
    GROUP BY psid, ndid, encounterid, proc_start_date,
             proc_end_date, proc_code, proc_name
    HAVING COUNT(*) > 1
) t
GROUP BY psid ORDER BY duplicate_groups DESC;

-- C4.3 Duplicate sample rows
SELECT a.psid, a.ndid, a.encounterid, a.proc_start_date,
    a.proc_end_date, a.proc_code, a.proc_coding_system, a.proc_name
FROM rgd_gold_ad.procedures a
JOIN (
    SELECT psid, ndid, encounterid, proc_start_date,
           proc_end_date, proc_code, proc_name
    FROM rgd_gold_ad.procedures
    WHERE udm_active_flag = 'Y'
    AND proc_code != 'NS'
    AND proc_start_date IS NOT NULL
    GROUP BY psid, ndid, encounterid, proc_start_date,
             proc_end_date, proc_code, proc_name
    HAVING COUNT(*) > 1
    LIMIT 3
) b ON a.psid <=> b.psid AND a.ndid <=> b.ndid
    AND a.encounterid <=> b.encounterid
    AND a.proc_start_date <=> b.proc_start_date
    AND a.proc_end_date <=> b.proc_end_date
    AND a.proc_code <=> b.proc_code
    AND a.proc_name <=> b.proc_name
WHERE a.udm_active_flag = 'Y'
ORDER BY a.psid, a.ndid, a.proc_code;

-- C4.4 Orphan ndids
SELECT COUNT(DISTINCT p.ndid) AS orphan_ndids
FROM rgd_gold_ad.procedures p
LEFT JOIN rgd_gold_ad.patients pt ON p.ndid = pt.ndid
WHERE pt.ndid IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. CURRENCY
-- ─────────────────────────────────────────────────────────────────────────────

-- C5.1 udm_active_flag distribution
SELECT udm_active_flag, COUNT(*) AS cnt
FROM rgd_gold_ad.procedures
GROUP BY udm_active_flag;

-- C5.2 Date range confirmation
SELECT
    MIN(proc_start_date) AS min_proc_start_date,
    MAX(proc_start_date) AS max_proc_start_date,
    MIN(enc_date) AS min_enc_date,
    MAX(enc_date) AS max_enc_date
FROM rgd_gold_ad.procedures
WHERE proc_start_date BETWEEN '1900-01-01' AND '2900-01-01';
