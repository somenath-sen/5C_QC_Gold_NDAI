-- =============================================================================
-- NeuroDiscovery AI - Regulatory-Grade Data QC Queries (5C Model)
-- Table: rgd_gold_ad.procedures
-- Prepared By: Somenath Sen - RWD Team
-- Date: August 2026
-- Framework: 5C (Completeness, Correctness, Concordance, Credibility, Currency)
-- Critical Fields: ndid, encounterid, proc_code, proc_name
-- Duplicate key requires proc_name_full (added in Aug 2026 refresh)
-- =============================================================================


-- #############################################################################
-- # BASELINE
-- #############################################################################

===========BASELINE: total records, patients, psids=======
SELECT COUNT(*) AS total_records,
       COUNT(DISTINCT ndid) AS unique_patients,
       COUNT(DISTINCT psid) AS unique_psids
FROM rgd_gold_ad.procedures;

===========BASELINE: records and patients by psid=======
SELECT psid,
       COUNT(*) AS records,
       COUNT(DISTINCT ndid) AS unique_patients
FROM rgd_gold_ad.procedures
GROUP BY psid
ORDER BY records DESC;

===========BASELINE: cohort coverage=======
SELECT
    (SELECT COUNT(DISTINCT ndid) FROM rgd_gold_ad.patients WHERE udm_active_flag = 'Y') AS cohort_patients,
    COUNT(DISTINCT ndid) AS patients_with_procedures,
    (SELECT COUNT(DISTINCT ndid) FROM rgd_gold_ad.patients WHERE udm_active_flag = 'Y') - COUNT(DISTINCT ndid) AS patients_without_procedures
FROM rgd_gold_ad.procedures;


-- #############################################################################
-- # 1. COMPLETENESS
-- #############################################################################

===========COMPLETENESS: rgd_gold_ad.procedures - full column fill rate=======
WITH cohort_proc AS (
    SELECT *
    FROM rgd_gold_ad.procedures
)
SELECT 'gold_row_id' AS column_name, COUNT(*) AS denominator, SUM(CASE WHEN gold_row_id IS NOT NULL THEN 1 ELSE 0 END) AS present_count, ROUND(SUM(CASE WHEN gold_row_id IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_present FROM cohort_proc
UNION ALL
SELECT 'ndid', COUNT(*), SUM(CASE WHEN ndid IS NOT NULL AND TRIM(ndid) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN ndid IS NOT NULL AND TRIM(ndid) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'psid', COUNT(*), SUM(CASE WHEN psid IS NOT NULL AND TRIM(psid) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN psid IS NOT NULL AND TRIM(psid) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'udm_unq_id', COUNT(*), SUM(CASE WHEN udm_unq_id IS NOT NULL AND TRIM(udm_unq_id) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN udm_unq_id IS NOT NULL AND TRIM(udm_unq_id) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'encounterid', COUNT(*), SUM(CASE WHEN encounterid IS NOT NULL AND TRIM(encounterid) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN encounterid IS NOT NULL AND TRIM(encounterid) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'procedureid', COUNT(*), SUM(CASE WHEN procedureid IS NOT NULL AND TRIM(procedureid) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN procedureid IS NOT NULL AND TRIM(procedureid) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'proc_start_date', COUNT(*), SUM(CASE WHEN proc_start_date IS NOT NULL THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN proc_start_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'proc_end_date', COUNT(*), SUM(CASE WHEN proc_end_date IS NOT NULL THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN proc_end_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'proc_code', COUNT(*), SUM(CASE WHEN proc_code IS NOT NULL AND TRIM(proc_code) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN proc_code IS NOT NULL AND TRIM(proc_code) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'proc_name', COUNT(*), SUM(CASE WHEN proc_name IS NOT NULL AND TRIM(proc_name) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN proc_name IS NOT NULL AND TRIM(proc_name) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'proc_category', COUNT(*), SUM(CASE WHEN proc_category IS NOT NULL AND TRIM(proc_category) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN proc_category IS NOT NULL AND TRIM(proc_category) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'proc_coding_system', COUNT(*), SUM(CASE WHEN proc_coding_system IS NOT NULL AND TRIM(proc_coding_system) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN proc_coding_system IS NOT NULL AND TRIM(proc_coding_system) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'proc_units', COUNT(*), SUM(CASE WHEN proc_units IS NOT NULL AND TRIM(proc_units) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN proc_units IS NOT NULL AND TRIM(proc_units) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'proc_description', COUNT(*), SUM(CASE WHEN proc_description IS NOT NULL AND TRIM(proc_description) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN proc_description IS NOT NULL AND TRIM(proc_description) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'proc_notes', COUNT(*), SUM(CASE WHEN proc_notes IS NOT NULL AND TRIM(proc_notes) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN proc_notes IS NOT NULL AND TRIM(proc_notes) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'proc_name_full', COUNT(*), SUM(CASE WHEN proc_name_full IS NOT NULL AND TRIM(proc_name_full) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN proc_name_full IS NOT NULL AND TRIM(proc_name_full) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'udm_active_flag', COUNT(*), SUM(CASE WHEN udm_active_flag IS NOT NULL AND TRIM(udm_active_flag) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN udm_active_flag IS NOT NULL AND TRIM(udm_active_flag) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'source_udm_inc_id', COUNT(*), SUM(CASE WHEN source_udm_inc_id IS NOT NULL AND TRIM(source_udm_inc_id) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN source_udm_inc_id IS NOT NULL AND TRIM(source_udm_inc_id) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'cohort_run_id', COUNT(*), SUM(CASE WHEN cohort_run_id IS NOT NULL AND TRIM(cohort_run_id) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN cohort_run_id IS NOT NULL AND TRIM(cohort_run_id) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'run_id', COUNT(*), SUM(CASE WHEN run_id IS NOT NULL AND TRIM(run_id) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN run_id IS NOT NULL AND TRIM(run_id) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'gold_created_datetime', COUNT(*), SUM(CASE WHEN gold_created_datetime IS NOT NULL THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN gold_created_datetime IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc
UNION ALL
SELECT 'gold_updated_datetime', COUNT(*), SUM(CASE WHEN gold_updated_datetime IS NOT NULL THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN gold_updated_datetime IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM cohort_proc;

===========COMP-001: ndid completeness (Critical, threshold 0% missing)=======
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN ndid IS NULL THEN 1 ELSE 0 END) AS n_missing_ndid,
       ROUND(SUM(CASE WHEN ndid IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_missing_ndid
FROM rgd_gold_ad.procedures;

===========COMP-002a: encounterid completeness (Critical, threshold 0% missing)=======
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS n_missing_encounterid,
       ROUND(SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_missing_encounterid
FROM rgd_gold_ad.procedures;

===========COMP-002b: encounterid null by psid=======
SELECT psid,
       SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS n_missing_encounterid,
       COUNT(*) AS total_rows,
       ROUND(SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_missing
FROM rgd_gold_ad.procedures
GROUP BY psid
HAVING n_missing_encounterid > 0
ORDER BY n_missing_encounterid DESC;

===========COMP-003a / COMP-017: proc_start_date & proc_end_date fill rate (Critical <2% / Major >=95%)=======
SELECT 'proc_start_date' AS column_name, COUNT(*) AS denominator, SUM(CASE WHEN proc_start_date IS NOT NULL THEN 1 ELSE 0 END) AS present_count, ROUND(SUM(CASE WHEN proc_start_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_present
FROM rgd_gold_ad.procedures
UNION ALL
SELECT 'proc_end_date', COUNT(*), SUM(CASE WHEN proc_end_date IS NOT NULL THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN proc_end_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
FROM rgd_gold_ad.procedures;

===========COMP-003b: proc_start_date null by psid=======
SELECT psid,
       SUM(CASE WHEN proc_start_date IS NULL THEN 1 ELSE 0 END) AS n_missing_start_date,
       COUNT(*) AS total_rows,
       ROUND(SUM(CASE WHEN proc_start_date IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_missing
FROM rgd_gold_ad.procedures
GROUP BY psid
HAVING n_missing_start_date > 0
ORDER BY n_missing_start_date DESC;

===========PROC-003 / PROC-005: proc_code & proc_name completeness (Major, threshold >=95%)=======
SELECT 'proc_code' AS column_name, COUNT(*) AS denominator, SUM(CASE WHEN proc_code IS NOT NULL AND TRIM(proc_code) != '' THEN 1 ELSE 0 END) AS present_count, ROUND(SUM(CASE WHEN proc_code IS NOT NULL AND TRIM(proc_code) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_present
FROM rgd_gold_ad.procedures
UNION ALL
SELECT 'proc_name', COUNT(*), SUM(CASE WHEN proc_name IS NOT NULL AND TRIM(proc_name) != '' THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN proc_name IS NOT NULL AND TRIM(proc_name) != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
FROM rgd_gold_ad.procedures;

===========COMP-020: incremental id (udm_unq_id) present (Critical, threshold 0% missing)=======
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN udm_unq_id IS NULL OR TRIM(udm_unq_id) = '' THEN 1 ELSE 0 END) AS n_missing_unq_id,
       ROUND(SUM(CASE WHEN udm_unq_id IS NULL OR TRIM(udm_unq_id) = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_missing
FROM rgd_gold_ad.procedures;


-- #############################################################################
-- # 2. CORRECTNESS
-- #############################################################################

===========CORR-011a: Date format / implausibility check - proc_start_date=======
WITH classified AS (
    SELECT
        ndid, encounterid, proc_start_date,
        CASE
            WHEN proc_start_date IS NULL THEN 'NULL'
            WHEN CAST(proc_start_date AS CHAR) IN ('0000-00-00 00:00:00','0000-00-00') THEN 'SENTINEL_ZERO'
            WHEN YEAR(proc_start_date) < 100 THEN 'IMPLAUSIBLE_LOW_YEAR (century-truncated)'
            WHEN YEAR(proc_start_date) >= 100 AND YEAR(proc_start_date) < 1900 THEN 'TOO_OLD (100-1899)'
            WHEN YEAR(proc_start_date) >= 4700 THEN 'FAR_FUTURE_SENTINEL (~4701-style)'
            WHEN proc_start_date > NOW() THEN 'FUTURE_DATE (ordinary)'
            ELSE 'PLAUSIBLE'
        END AS proc_start_date_category
    FROM rgd_gold_ad.procedures
)
SELECT proc_start_date_category, COUNT(*) AS n_rows,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM classified
GROUP BY proc_start_date_category
ORDER BY n_rows DESC;

===========CORR-011b: proc_start_date example rows for each category (5 examples each)=======
WITH classified AS (
    SELECT
        ndid, encounterid, proc_start_date,
        CASE
            WHEN proc_start_date IS NULL THEN 'NULL'
            WHEN CAST(proc_start_date AS CHAR) IN ('0000-00-00 00:00:00','0000-00-00') THEN 'SENTINEL_ZERO'
            WHEN YEAR(proc_start_date) < 100 THEN 'IMPLAUSIBLE_LOW_YEAR (century-truncated)'
            WHEN YEAR(proc_start_date) >= 100 AND YEAR(proc_start_date) < 1900 THEN 'TOO_OLD (100-1899)'
            WHEN YEAR(proc_start_date) >= 4700 THEN 'FAR_FUTURE_SENTINEL (~4701-style)'
            WHEN proc_start_date > NOW() THEN 'FUTURE_DATE (ordinary)'
            ELSE 'PLAUSIBLE'
        END AS proc_start_date_category
    FROM rgd_gold_ad.procedures
),
ranked AS (
    SELECT ndid, encounterid, proc_start_date, proc_start_date_category,
           ROW_NUMBER() OVER (PARTITION BY proc_start_date_category ORDER BY ndid) AS rn
    FROM classified
    WHERE proc_start_date_category != 'NULL'
)
SELECT proc_start_date_category, ndid, encounterid, proc_start_date
FROM ranked
WHERE rn <= 5
ORDER BY proc_start_date_category, ndid;

===========CORR-011c: Date format / implausibility check - proc_end_date=======
WITH classified AS (
    SELECT
        ndid, encounterid, proc_end_date,
        CASE
            WHEN proc_end_date IS NULL THEN 'NULL'
            WHEN CAST(proc_end_date AS CHAR) IN ('0000-00-00 00:00:00','0000-00-00') THEN 'SENTINEL_ZERO'
            WHEN YEAR(proc_end_date) < 100 THEN 'IMPLAUSIBLE_LOW_YEAR (century-truncated)'
            WHEN YEAR(proc_end_date) >= 100 AND YEAR(proc_end_date) < 1900 THEN 'TOO_OLD (100-1899)'
            WHEN YEAR(proc_end_date) >= 4700 THEN 'FAR_FUTURE_SENTINEL (~4701-style)'
            WHEN proc_end_date > NOW() THEN 'FUTURE_DATE (ordinary)'
            ELSE 'PLAUSIBLE'
        END AS proc_end_date_category
    FROM rgd_gold_ad.procedures
)
SELECT proc_end_date_category, COUNT(*) AS n_rows,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM classified
GROUP BY proc_end_date_category
ORDER BY n_rows DESC;

===========CORR-011d: Future-dated proc_start_date detail (Critical, threshold 0)=======
SELECT ndid, psid, encounterid, proc_start_date, proc_end_date, proc_code, proc_name
FROM rgd_gold_ad.procedures
WHERE proc_start_date > CURDATE()
ORDER BY proc_start_date DESC;

===========CORR-011e: proc_end_date before proc_start_date (Critical, threshold 0)=======
SELECT ndid, psid, encounterid, proc_start_date, proc_end_date, proc_code, proc_name
FROM rgd_gold_ad.procedures
WHERE proc_end_date IS NOT NULL
  AND proc_start_date IS NOT NULL
  AND proc_end_date < proc_start_date
ORDER BY proc_start_date;

===========CORR-011f: valid date range (excluding sentinels)=======
SELECT
    MIN(CASE WHEN proc_start_date BETWEEN '1900-01-01' AND CURDATE() THEN proc_start_date END) AS min_valid_start,
    MAX(CASE WHEN proc_start_date BETWEEN '1900-01-01' AND CURDATE() THEN proc_start_date END) AS max_valid_start
FROM rgd_gold_ad.procedures;

===========CORR-007a: proc_start_date before year_of_birth (Critical, threshold 0)=======
WITH proc_check AS (
    SELECT
        p.ndid, p.encounterid, p.proc_start_date, pt.year_of_birth,
        CASE
            WHEN pt.year_of_birth IS NULL OR pt.year_of_birth = 0 THEN 'UNKNOWN_BIRTH_YEAR'
            WHEN pt.year_of_birth >= 2000 AND YEAR(p.proc_start_date) < pt.year_of_birth THEN 'BEFORE_BIRTH_KNOWN_SOURCE_DOB_ISSUE'
            WHEN YEAR(p.proc_start_date) < pt.year_of_birth THEN 'BEFORE_BIRTH_NEW_CASE'
            ELSE 'VALID'
        END AS flag
    FROM rgd_gold_ad.procedures p
    INNER JOIN rgd_gold_ad.patients pt ON p.ndid = pt.ndid
    WHERE p.proc_start_date IS NOT NULL
      AND CAST(p.proc_start_date AS CHAR) NOT IN ('0000-00-00 00:00:00','0000-00-00')
      AND YEAR(p.proc_start_date) >= 1900
)
SELECT flag, COUNT(*) AS n_rows, COUNT(DISTINCT ndid) AS n_distinct_ndids,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM proc_check
GROUP BY flag
ORDER BY n_rows DESC;

===========CORR-007b: violating rows detail (before birth)=======
SELECT p.ndid, p.psid, p.encounterid, p.proc_start_date, pt.year_of_birth, p.proc_code, p.proc_name
FROM rgd_gold_ad.procedures p
INNER JOIN rgd_gold_ad.patients pt ON p.ndid = pt.ndid
WHERE p.proc_start_date IS NOT NULL
  AND CAST(p.proc_start_date AS CHAR) NOT IN ('0000-00-00 00:00:00','0000-00-00')
  AND YEAR(p.proc_start_date) >= 1900
  AND pt.year_of_birth IS NOT NULL AND pt.year_of_birth != 0
  AND YEAR(p.proc_start_date) < pt.year_of_birth
ORDER BY p.ndid, p.proc_start_date;

===========CORR-010a: procedures after death (Critical, threshold 0) - excludes sentinel death dates=======
WITH proc_death AS (
    SELECT
        p.ndid, p.encounterid, p.proc_start_date, pt.death_date,
        CASE
            WHEN pt.death_date IS NULL THEN 'NO_DEATH_DATE'
            WHEN CAST(pt.death_date AS CHAR) IN ('0000-00-00 00:00:00','0000-00-00') THEN 'SENTINEL_DEATH_DATE'
            WHEN YEAR(pt.death_date) < 1900 THEN 'IMPLAUSIBLE_DEATH_DATE'
            WHEN p.proc_start_date > pt.death_date THEN 'AFTER_DEATH'
            ELSE 'VALID'
        END AS flag
    FROM rgd_gold_ad.procedures p
    INNER JOIN rgd_gold_ad.patients pt ON p.ndid = pt.ndid
    WHERE p.proc_start_date IS NOT NULL
      AND CAST(p.proc_start_date AS CHAR) NOT IN ('0000-00-00 00:00:00','0000-00-00')
      AND YEAR(p.proc_start_date) >= 1900
)
SELECT flag, COUNT(*) AS n_rows, COUNT(DISTINCT ndid) AS n_distinct_ndids
FROM proc_death
GROUP BY flag
ORDER BY n_rows DESC;

===========CORR-010b: procedure records after a valid death date (detail)=======
SELECT p.ndid, p.psid, p.encounterid, pt.death_date, p.proc_start_date, p.proc_code, p.proc_name
FROM rgd_gold_ad.procedures p
INNER JOIN rgd_gold_ad.patients pt ON p.ndid = pt.ndid
WHERE pt.death_date IS NOT NULL
  AND CAST(pt.death_date AS CHAR) NOT IN ('0000-00-00 00:00:00','0000-00-00')
  AND YEAR(pt.death_date) >= 1900
  AND p.proc_start_date IS NOT NULL
  AND p.proc_start_date > pt.death_date
ORDER BY p.ndid, p.proc_start_date;

===========CORR-010c: death_date data quality in patients (sentinel isolation)=======
SELECT
    SUM(CASE WHEN death_date IS NULL THEN 1 ELSE 0 END) AS null_death,
    SUM(CASE WHEN CAST(death_date AS CHAR) IN ('0000-00-00 00:00:00','0000-00-00') OR death_date < '1900-01-01' THEN 1 ELSE 0 END) AS placeholder_death,
    SUM(CASE WHEN death_date >= '1900-01-01' THEN 1 ELSE 0 END) AS valid_death
FROM rgd_gold_ad.patients
WHERE deceased_status = 'Y';

===========CORR-012 / PROC-009: primary key uniqueness (Critical, threshold 100%)=======
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT udm_unq_id) AS distinct_udm_unq_id,
       COUNT(DISTINCT gold_row_id) AS distinct_gold_row_id,
       COUNT(*) - COUNT(DISTINCT udm_unq_id) AS duplicate_udm_unq_id,
       COUNT(*) - COUNT(DISTINCT gold_row_id) AS duplicate_gold_row_id
FROM rgd_gold_ad.procedures;

===========CORR-013a: Business-key duplicates (includes proc_name_full per DE guidance, null-safe)=======
SELECT COUNT(*) AS duplicate_groups, SUM(cnt - 1) AS excess_rows
FROM (
    SELECT psid, ndid, encounterid, proc_start_date, proc_end_date,
           proc_code, proc_name, proc_name_full, COUNT(*) AS cnt
    FROM rgd_gold_ad.procedures
    WHERE udm_active_flag = 'Y'
      AND proc_code != 'NS'
      AND proc_start_date IS NOT NULL
    GROUP BY psid, ndid, encounterid, proc_start_date, proc_end_date,
             proc_code, proc_name, proc_name_full
    HAVING COUNT(*) > 1
) t;

===========CORR-013b: duplicate groups by psid=======
SELECT psid, COUNT(*) AS duplicate_groups, SUM(cnt - 1) AS excess_rows
FROM (
    SELECT psid, ndid, encounterid, proc_start_date, proc_end_date,
           proc_code, proc_name, proc_name_full, COUNT(*) AS cnt
    FROM rgd_gold_ad.procedures
    WHERE udm_active_flag = 'Y'
      AND proc_code != 'NS'
      AND proc_start_date IS NOT NULL
    GROUP BY psid, ndid, encounterid, proc_start_date, proc_end_date,
             proc_code, proc_name, proc_name_full
    HAVING COUNT(*) > 1
) t
GROUP BY psid
ORDER BY duplicate_groups DESC;

===========CORR-004a / PROC-004: CPT Category II/III mislabelled as HCPCS by psid (Major, threshold <1% invalid)=======
SELECT psid, COUNT(*) AS mislabelled_records, COUNT(DISTINCT ndid) AS unique_patients
FROM rgd_gold_ad.procedures
WHERE proc_coding_system = 'HCPCS'
  AND (proc_code LIKE '%F' OR proc_code LIKE '%T')
GROUP BY psid
ORDER BY mislabelled_records DESC;

===========CORR-004b / PROC-004: CPT mislabel total and % of table=======
SELECT COUNT(*) AS mislabelled_total,
       (SELECT COUNT(*) FROM rgd_gold_ad.procedures) AS table_total,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM rgd_gold_ad.procedures), 2) AS pct_of_table
FROM rgd_gold_ad.procedures
WHERE proc_coding_system = 'HCPCS'
  AND (proc_code LIKE '%F' OR proc_code LIKE '%T');

===========PROC-007: procedure_date <= encounter_date + 30 days (Major, threshold >=90%)=======
SELECT COUNT(*) AS total_checked,
       SUM(CASE WHEN p.proc_start_date <= DATE_ADD(e.enc_date, INTERVAL 30 DAY) THEN 1 ELSE 0 END) AS within_30d,
       SUM(CASE WHEN p.proc_start_date > DATE_ADD(e.enc_date, INTERVAL 30 DAY) THEN 1 ELSE 0 END) AS beyond_30d,
       ROUND(SUM(CASE WHEN p.proc_start_date <= DATE_ADD(e.enc_date, INTERVAL 30 DAY) THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_within_30d
FROM rgd_gold_ad.procedures p
INNER JOIN rgd_gold_ad.encounters e ON p.encounterid = e.encounterid
WHERE p.proc_start_date IS NOT NULL AND e.enc_date IS NOT NULL;


-- #############################################################################
-- # 3. CONCORDANCE
-- #############################################################################

===========CONC-001 / PROC-001 link: referential integrity to patients (Critical, threshold 0% orphan)=======
SELECT COUNT(DISTINCT p.ndid) AS orphan_ndids
FROM rgd_gold_ad.procedures p
LEFT JOIN rgd_gold_ad.patients pt ON p.ndid = pt.ndid
WHERE pt.ndid IS NULL;

===========CONC-002a / PROC-002 link: referential integrity to encounters (Critical, threshold 0% orphan)=======
SELECT COUNT(*) AS orphan_records,
       COUNT(DISTINCT p.encounterid) AS orphan_encounterids
FROM rgd_gold_ad.procedures p
LEFT JOIN rgd_gold_ad.encounters e ON p.encounterid = e.encounterid
WHERE p.encounterid IS NOT NULL AND e.encounterid IS NULL;

===========CONC-002b: orphan encounterids by psid=======
SELECT p.psid, COUNT(*) AS orphan_records, COUNT(DISTINCT p.encounterid) AS orphan_encounterids
FROM rgd_gold_ad.procedures p
LEFT JOIN rgd_gold_ad.encounters e ON p.encounterid = e.encounterid
WHERE p.encounterid IS NOT NULL AND e.encounterid IS NULL
GROUP BY p.psid
ORDER BY orphan_records DESC;

===========CONC-005: proc_coding_system standardized-value distribution=======
SELECT
    COALESCE(proc_coding_system, 'NULL/Missing') AS proc_coding_system,
    COUNT(*) AS n_rows,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total,
    CASE
        WHEN proc_coding_system IN ('CPT','HCPCS') THEN 'STANDARDIZED'
        WHEN proc_coding_system IS NULL OR TRIM(proc_coding_system) = '' THEN 'MISSING'
        WHEN proc_coding_system = 'NS' THEN 'NS_PLACEHOLDER'
        ELSE 'NON_STANDARD'
    END AS standardization_flag
FROM rgd_gold_ad.procedures
GROUP BY proc_coding_system
ORDER BY standardization_flag, n_rows DESC;

===========CONC-011a: proc_code maps to a single consistent proc_name=======
SELECT COUNT(*) AS codes_with_multiple_names
FROM (
    SELECT proc_code, COUNT(DISTINCT proc_name) AS name_variants
    FROM rgd_gold_ad.procedures
    WHERE proc_code IS NOT NULL AND proc_code != '' AND proc_code != 'NS'
    GROUP BY proc_code
    HAVING COUNT(DISTINCT proc_name) > 1
) t;

===========CONC-011b: proc_codes with multiple distinct proc_names (detail)=======
SELECT proc_code, COUNT(DISTINCT proc_name) AS name_variants, COUNT(*) AS n_rows
FROM rgd_gold_ad.procedures
WHERE proc_code IS NOT NULL AND proc_code != '' AND proc_code != 'NS'
GROUP BY proc_code
HAVING COUNT(DISTINCT proc_name) > 1
ORDER BY name_variants DESC, n_rows DESC;


-- #############################################################################
-- # 4. CREDIBILITY
-- #############################################################################

===========PROC-008a: Gender-procedure credibility (Critical, threshold 0 violations)=======
SELECT COUNT(*) AS gender_mismatch, COUNT(DISTINCT p.ndid) AS patients
FROM rgd_gold_ad.procedures p
INNER JOIN rgd_gold_ad.patients pt ON p.ndid = pt.ndid
WHERE pt.udm_active_flag = 'Y'
  AND (
        (pt.gender IN ('F','Female') AND (UPPER(p.proc_name) LIKE '%PROSTAT%' OR UPPER(p.proc_name) LIKE '%VASECTOMY%' OR UPPER(p.proc_name) LIKE '%ORCHIECTOMY%' OR UPPER(p.proc_name) LIKE '%TESTIC%'))
        OR
        (pt.gender IN ('M','Male') AND (UPPER(p.proc_name) LIKE '%HYSTERECTOM%' OR UPPER(p.proc_name) LIKE '%OOPHOR%' OR UPPER(p.proc_name) LIKE '%CESAREAN%' OR UPPER(p.proc_name) LIKE '%CERVICAL SMEAR%' OR UPPER(p.proc_name) LIKE '%MAMMOGRAM%'))
      );

===========PROC-008b: gender-procedure violating rows (if any)=======
SELECT p.ndid, p.psid, pt.gender, p.proc_code, p.proc_name, p.proc_start_date
FROM rgd_gold_ad.procedures p
INNER JOIN rgd_gold_ad.patients pt ON p.ndid = pt.ndid
WHERE pt.udm_active_flag = 'Y'
  AND (
        (pt.gender IN ('F','Female') AND (UPPER(p.proc_name) LIKE '%PROSTAT%' OR UPPER(p.proc_name) LIKE '%VASECTOMY%' OR UPPER(p.proc_name) LIKE '%ORCHIECTOMY%' OR UPPER(p.proc_name) LIKE '%TESTIC%'))
        OR
        (pt.gender IN ('M','Male') AND (UPPER(p.proc_name) LIKE '%HYSTERECTOM%' OR UPPER(p.proc_name) LIKE '%OOPHOR%' OR UPPER(p.proc_name) LIKE '%CESAREAN%' OR UPPER(p.proc_name) LIKE '%CERVICAL SMEAR%' OR UPPER(p.proc_name) LIKE '%MAMMOGRAM%'))
      )
ORDER BY p.ndid;

===========CREDIBILITY: NS placeholder records (proc_code = NS AND proc_coding_system = NS) by psid=======
SELECT psid, COUNT(*) AS ns_records
FROM rgd_gold_ad.procedures
WHERE proc_code = 'NS' AND proc_coding_system = 'NS'
GROUP BY psid
ORDER BY ns_records DESC;

===========CREDIBILITY: NS placeholder total and % of table=======
SELECT COUNT(*) AS ns_total,
       (SELECT COUNT(*) FROM rgd_gold_ad.procedures) AS table_total,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM rgd_gold_ad.procedures), 2) AS pct_of_table
FROM rgd_gold_ad.procedures
WHERE proc_code = 'NS' AND proc_coding_system = 'NS';

===========PLAUS-011a: procedures per patient per month - outlier check (Major, threshold <1%)=======
WITH monthly_counts AS (
    SELECT ndid, DATE_FORMAT(proc_start_date, '%Y-%m') AS proc_month, COUNT(*) AS n_procedures
    FROM rgd_gold_ad.procedures
    WHERE proc_start_date IS NOT NULL
      AND CAST(proc_start_date AS CHAR) NOT IN ('0000-00-00 00:00:00','0000-00-00')
      AND YEAR(proc_start_date) >= 1900 AND YEAR(proc_start_date) < 4700
    GROUP BY ndid, DATE_FORMAT(proc_start_date, '%Y-%m')
),
stats AS (
    SELECT AVG(n_procedures) AS mean_val, STDDEV(n_procedures) AS stddev_val
    FROM monthly_counts
)
SELECT
    COUNT(*) AS total_patient_months,
    SUM(CASE WHEN mc.n_procedures > 30 THEN 1 ELSE 0 END) AS n_over_30_per_month,
    ROUND(SUM(CASE WHEN mc.n_procedures > 30 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_over_30_per_month,
    SUM(CASE WHEN mc.n_procedures > s.mean_val + 3 * s.stddev_val THEN 1 ELSE 0 END) AS n_over_3sd,
    ROUND(SUM(CASE WHEN mc.n_procedures > s.mean_val + 3 * s.stddev_val THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_over_3sd,
    '<1%' AS threshold
FROM monthly_counts mc, stats s;

===========PLAUS-011b: patient-months with unrealistic procedure frequency (detail)=======
WITH monthly_counts AS (
    SELECT ndid, DATE_FORMAT(proc_start_date, '%Y-%m') AS proc_month, COUNT(*) AS n_procedures
    FROM rgd_gold_ad.procedures
    WHERE proc_start_date IS NOT NULL
      AND CAST(proc_start_date AS CHAR) NOT IN ('0000-00-00 00:00:00','0000-00-00')
      AND YEAR(proc_start_date) >= 1900 AND YEAR(proc_start_date) < 4700
    GROUP BY ndid, DATE_FORMAT(proc_start_date, '%Y-%m')
)
SELECT ndid, proc_month, n_procedures
FROM monthly_counts
WHERE n_procedures > 30
ORDER BY n_procedures DESC
LIMIT 100;


-- #############################################################################
-- # 5. CURRENCY
-- #############################################################################

===========CURRENCY: rgd_gold_ad.procedures=======
WITH per_patient AS (
    SELECT ndid, COUNT(*) AS proc_count
    FROM rgd_gold_ad.procedures
    WHERE ndid IS NOT NULL
    GROUP BY ndid
)
SELECT 'udm_active_flag_distribution' AS check_name, CAST(udm_active_flag AS CHAR) AS attribute, CAST(COUNT(*) AS CHAR) AS value
FROM rgd_gold_ad.procedures
GROUP BY udm_active_flag
UNION ALL
SELECT 'cohort_run_id_distribution', CAST(cohort_run_id AS CHAR), CAST(COUNT(*) AS CHAR)
FROM rgd_gold_ad.procedures
GROUP BY cohort_run_id
UNION ALL
SELECT 'gold_created_date_distribution', CAST(DATE(gold_created_datetime) AS CHAR), CAST(COUNT(*) AS CHAR)
FROM rgd_gold_ad.procedures
GROUP BY DATE(gold_created_datetime)
UNION ALL
SELECT 'source_id_duplication', 'total_records', CAST(COUNT(*) AS CHAR)
FROM rgd_gold_ad.procedures
UNION ALL
SELECT 'source_id_duplication', 'distinct_source_ids', CAST(COUNT(DISTINCT source_udm_inc_id) AS CHAR)
FROM rgd_gold_ad.procedures
UNION ALL
SELECT 'source_id_duplication', 'duplicate_source_count', CAST(COUNT(*) - COUNT(DISTINCT source_udm_inc_id) AS CHAR)
FROM rgd_gold_ad.procedures
UNION ALL
SELECT 'update_status', 'total_records', CAST(COUNT(*) AS CHAR)
FROM rgd_gold_ad.procedures
UNION ALL
SELECT 'update_status', 'never_updated_count', CAST(SUM(CASE WHEN gold_updated_datetime IS NULL THEN 1 ELSE 0 END) AS CHAR)
FROM rgd_gold_ad.procedures
UNION ALL
SELECT 'update_status', 'updated_count', CAST(SUM(CASE WHEN gold_updated_datetime IS NOT NULL THEN 1 ELSE 0 END) AS CHAR)
FROM rgd_gold_ad.procedures
UNION ALL
SELECT 'per_patient_proc_summary', 'total_patients', CAST(COUNT(*) AS CHAR) FROM per_patient
UNION ALL
SELECT 'per_patient_proc_summary', 'avg_proc_per_patient', CAST(ROUND(AVG(proc_count), 1) AS CHAR) FROM per_patient
UNION ALL
SELECT 'per_patient_proc_summary', 'max_proc_per_patient', CAST(MAX(proc_count) AS CHAR) FROM per_patient
UNION ALL
SELECT 'per_patient_proc_summary', 'patients_with_1_proc', CAST(SUM(CASE WHEN proc_count = 1 THEN 1 ELSE 0 END) AS CHAR) FROM per_patient
UNION ALL
SELECT 'per_patient_proc_summary', 'patients_with_over_100_proc', CAST(SUM(CASE WHEN proc_count > 100 THEN 1 ELSE 0 END) AS CHAR) FROM per_patient
UNION ALL
SELECT 'run_type_distribution', CASE WHEN run_id LIKE 'manual%' THEN 'Manual' ELSE 'Scheduled/Other' END, CAST(COUNT(*) AS CHAR)
FROM rgd_gold_ad.procedures
GROUP BY CASE WHEN run_id LIKE 'manual%' THEN 'Manual' ELSE 'Scheduled/Other' END
UNION ALL
SELECT 'future_date_check', 'future_proc_start_dates', CAST(SUM(CASE WHEN proc_start_date > CURRENT_DATE() THEN 1 ELSE 0 END) AS CHAR)
FROM rgd_gold_ad.procedures
UNION ALL
SELECT 'future_date_check', 'future_proc_end_dates', CAST(SUM(CASE WHEN proc_end_date > CURRENT_DATE() THEN 1 ELSE 0 END) AS CHAR)
FROM rgd_gold_ad.procedures
ORDER BY check_name;

===========CURR-013: udm_active_flag distribution (Gold expects all Y)=======
SELECT udm_active_flag, COUNT(*) AS cnt,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM rgd_gold_ad.procedures
GROUP BY udm_active_flag;

===========CURR-014: future-dated events (Critical, threshold 0)=======
SELECT SUM(CASE WHEN proc_start_date > CURDATE() THEN 1 ELSE 0 END) AS future_proc_start_dates,
       SUM(CASE WHEN proc_end_date > CURDATE() THEN 1 ELSE 0 END) AS future_proc_end_dates
FROM rgd_gold_ad.procedures;

===========CURRENCY: snapshot recency (load / date range)=======
SELECT
    MIN(proc_start_date) AS earliest_start,
    MAX(CASE WHEN proc_start_date <= CURDATE() THEN proc_start_date END) AS latest_valid_start,
    MAX(gold_created_datetime) AS latest_load,
    MAX(gold_updated_datetime) AS latest_update
FROM rgd_gold_ad.procedures;

-- =============================================================================
-- END OF FILE
-- =============================================================================
