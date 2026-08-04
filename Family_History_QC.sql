-- =============================================================================
-- NeuroDiscovery AI — Gold Layer QC Queries
-- Table: rgd_gold_ad.family_history
-- Schema: rgd_gold_ad
-- Prepared By: Somenath Sen — RWD Team
-- Date: July 2026
-- Framework: 5C (Completeness, Correctness, Concordance, Credibility, Currency)
-- DE Key: family_hist_id + ndid + psid + eid + enc_date + onset_date
--         + family_hist_date + family_relationship_code + family_hist_details
--         + family_hist_code + family_hist_value + itemname
-- Gold mapping: family_hist_id → history_id, eid → encounterid,
--               family_hist_date → history_date,
--               family_hist_details → hist_notes,
--               family_hist_value → hist_value, itemname → hist_name
-- Missing DE fields: onset_date, family_relationship_code, family_hist_code
-- Two-field structure: hist_name = family member; hist_value = condition (ICD-9)
-- Exclusions: records where hist_name + hist_value + hist_notes all null
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- BASELINE
-- ─────────────────────────────────────────────────────────────────────────────

-- B1. Total records, patients, psids
SELECT COUNT(*) AS total_records,
    COUNT(DISTINCT ndid) AS unique_patients,
    COUNT(DISTINCT psid) AS unique_psids
FROM rgd_gold_ad.family_history;

-- B2. Records and patients by psid
SELECT psid, COUNT(*) AS records,
    COUNT(DISTINCT ndid) AS unique_patients
FROM rgd_gold_ad.family_history
GROUP BY psid ORDER BY records DESC;

-- B3. Cohort coverage
SELECT
    (SELECT COUNT(DISTINCT ndid) FROM rgd_gold_ad.patients) AS cohort_patients,
    COUNT(DISTINCT ndid) AS patients_with_family_history,
    (SELECT COUNT(DISTINCT ndid) FROM rgd_gold_ad.patients)
        - COUNT(DISTINCT ndid) AS patients_without_family_history
FROM rgd_gold_ad.family_history;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. COMPLETENESS
-- ─────────────────────────────────────────────────────────────────────────────

-- C1.1 Null counts across all columns
SELECT
    SUM(CASE WHEN ndid IS NULL THEN 1 ELSE 0 END) AS null_ndid,
    SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS null_encounterid,
    SUM(CASE WHEN enc_date IS NULL THEN 1 ELSE 0 END) AS null_enc_date,
    SUM(CASE WHEN history_id IS NULL THEN 1 ELSE 0 END) AS null_history_id,
    SUM(CASE WHEN history_date IS NULL THEN 1 ELSE 0 END) AS null_history_date,
    SUM(CASE WHEN history_episode_date IS NULL THEN 1 ELSE 0 END) AS null_history_episode_date,
    SUM(CASE WHEN hist_category IS NULL OR hist_category = '' THEN 1 ELSE 0 END) AS null_hist_category,
    SUM(CASE WHEN hist_name IS NULL OR hist_name = '' THEN 1 ELSE 0 END) AS null_hist_name,
    SUM(CASE WHEN hist_question IS NULL OR hist_question = '' THEN 1 ELSE 0 END) AS null_hist_question,
    SUM(CASE WHEN hist_value IS NULL OR hist_value = '' THEN 1 ELSE 0 END) AS null_hist_value,
    SUM(CASE WHEN hist_notes IS NULL OR hist_notes = '' THEN 1 ELSE 0 END) AS null_hist_notes
FROM rgd_gold_ad.family_history;

-- C1.2 Fill rate from DE table (official source)
SELECT column_name, total_count, null_records, fill_rate_pct
FROM staging.fill_rate_report_gold
WHERE schema_name = 'rgd_gold_ad'
AND table_name = 'family_history'
ORDER BY fill_rate_pct DESC;

-- C1.3 Encounterid null by psid
SELECT psid,
    SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS null_encounterid,
    COUNT(*) AS total_records,
    ROUND(SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS pct_null
FROM rgd_gold_ad.family_history
GROUP BY psid ORDER BY null_encounterid DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. CORRECTNESS
-- ─────────────────────────────────────────────────────────────────────────────

-- C2.1 Junk hist_name (colon suffix) by psid
SELECT psid, COUNT(*) AS cnt
FROM rgd_gold_ad.family_history
WHERE hist_name = 'Family History:'
GROUP BY psid ORDER BY cnt DESC;

-- C2.2 Date plausibility
SELECT
    SUM(CASE WHEN history_date > '2900-01-01' THEN 1 ELSE 0 END) AS far_future,
    SUM(CASE WHEN history_date > CURDATE()
             AND history_date <= '2900-01-01' THEN 1 ELSE 0 END) AS near_future,
    SUM(CASE WHEN history_date < '1900-01-01' THEN 1 ELSE 0 END) AS before_1900,
    SUM(CASE WHEN enc_date > CURDATE() THEN 1 ELSE 0 END) AS future_enc_date,
    MIN(CASE WHEN history_date BETWEEN '1900-01-01' AND CURDATE()
             THEN history_date END) AS min_history_date,
    MAX(CASE WHEN history_date BETWEEN '1900-01-01' AND CURDATE()
             THEN history_date END) AS max_history_date
FROM rgd_gold_ad.family_history;

-- C2.3 Far-future date sample rows
SELECT gold_row_id, ndid, psid, encounterid, history_id,
    enc_date, history_date, hist_category,
    hist_name, hist_question, hist_value, hist_notes, udm_active_flag
FROM rgd_gold_ad.family_history
WHERE history_date > '2900-01-01'
ORDER BY psid LIMIT 10;

-- C2.4 Date plausibility by psid
SELECT psid,
    SUM(CASE WHEN history_date > '2900-01-01' THEN 1 ELSE 0 END) AS far_future,
    SUM(CASE WHEN enc_date > CURDATE() THEN 1 ELSE 0 END) AS future_enc_date
FROM rgd_gold_ad.family_history
GROUP BY psid
HAVING far_future > 0 OR future_enc_date > 0
ORDER BY far_future DESC;

-- C2.5 hist_notes empty string pattern (not null but empty)
SELECT psid, COUNT(*) AS empty_string_hist_notes
FROM rgd_gold_ad.family_history
WHERE hist_notes = ''
GROUP BY psid ORDER BY empty_string_hist_notes DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. CONCORDANCE
-- ─────────────────────────────────────────────────────────────────────────────

-- C3.1 hist_category variants by psid
SELECT psid, hist_category, COUNT(*) AS cnt
FROM rgd_gold_ad.family_history
GROUP BY psid, hist_category ORDER BY psid;

-- C3.2 Top hist_name values (family member relationships)
SELECT hist_name, COUNT(*) AS cnt
FROM rgd_gold_ad.family_history
WHERE hist_name IS NOT NULL AND hist_name != ''
AND hist_name != 'Family History:'
GROUP BY hist_name ORDER BY cnt DESC LIMIT 20;

-- C3.3 Top hist_value values (conditions — ICD-9 descriptions)
SELECT hist_value, COUNT(*) AS cnt
FROM rgd_gold_ad.family_history
WHERE hist_value IS NOT NULL AND hist_value != ''
GROUP BY hist_value ORDER BY cnt DESC LIMIT 20;

-- C3.4 AD-relevant hist_value counts
SELECT hist_value, COUNT(*) AS cnt
FROM rgd_gold_ad.family_history
WHERE hist_value IN (
    'Alzheimer\'s disease', 'Dementia', 'Parkinson\'s Disease',
    'Cerebral Infarction',
    'Cerebral Artery Occlusion with Cerebral Infarction'
)
GROUP BY hist_value ORDER BY cnt DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. CREDIBILITY
-- ─────────────────────────────────────────────────────────────────────────────

-- C4.1 Duplicate count on clean DE key
SELECT COUNT(*) AS duplicate_groups, SUM(grp_size-1) AS excess_rows
FROM (
    SELECT history_id, ndid, psid, encounterid,
           enc_date, history_date, hist_notes,
           hist_value, hist_name,
           COUNT(*) AS grp_size
    FROM rgd_gold_ad.family_history
    WHERE udm_active_flag = 'Y'
    AND NOT (hist_name IS NULL AND hist_value IS NULL AND hist_notes IS NULL)
    GROUP BY history_id, ndid, psid, encounterid,
             enc_date, history_date, hist_notes,
             hist_value, hist_name
    HAVING COUNT(*) > 1
) t;

-- C4.2 Duplicate psid breakdown
SELECT psid, COUNT(*) AS duplicate_groups, SUM(grp_size-1) AS excess_rows
FROM (
    SELECT history_id, ndid, psid, encounterid,
           enc_date, history_date, hist_notes,
           hist_value, hist_name,
           COUNT(*) AS grp_size
    FROM rgd_gold_ad.family_history
    WHERE udm_active_flag = 'Y'
    AND NOT (hist_name IS NULL AND hist_value IS NULL AND hist_notes IS NULL)
    GROUP BY history_id, ndid, psid, encounterid,
             enc_date, history_date, hist_notes,
             hist_value, hist_name
    HAVING COUNT(*) > 1
) t
GROUP BY psid ORDER BY duplicate_groups DESC;

-- C4.3 Duplicate sample rows
SELECT a.psid, a.ndid, a.encounterid, a.enc_date,
    a.history_date, a.hist_notes, a.hist_value, a.hist_name, a.history_id
FROM rgd_gold_ad.family_history a
JOIN (
    SELECT history_id, ndid, psid, encounterid,
           enc_date, history_date, hist_notes, hist_value, hist_name
    FROM rgd_gold_ad.family_history
    WHERE udm_active_flag = 'Y'
    AND NOT (hist_name IS NULL AND hist_value IS NULL AND hist_notes IS NULL)
    GROUP BY history_id, ndid, psid, encounterid,
             enc_date, history_date, hist_notes, hist_value, hist_name
    HAVING COUNT(*) > 1
    LIMIT 3
) b ON a.history_id <=> b.history_id AND a.ndid <=> b.ndid
    AND a.psid <=> b.psid AND a.encounterid <=> b.encounterid
    AND a.enc_date <=> b.enc_date
    AND a.history_date <=> b.history_date
    AND a.hist_notes <=> b.hist_notes
    AND a.hist_value <=> b.hist_value
    AND a.hist_name <=> b.hist_name
WHERE a.udm_active_flag = 'Y'
ORDER BY a.psid, a.ndid, a.hist_name;

-- C4.4 Orphan ndids
SELECT COUNT(DISTINCT f.ndid) AS orphan_ndids
FROM rgd_gold_ad.family_history f
LEFT JOIN rgd_gold_ad.patients p ON f.ndid = p.ndid
WHERE p.ndid IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. CURRENCY
-- ─────────────────────────────────────────────────────────────────────────────

-- C5.1 udm_active_flag distribution
SELECT udm_active_flag, COUNT(*) AS cnt
FROM rgd_gold_ad.family_history
GROUP BY udm_active_flag;

-- C5.2 Date range confirmation
SELECT
    MIN(history_date) AS min_history_date,
    MAX(history_date) AS max_history_date,
    MIN(enc_date) AS min_enc_date,
    MAX(enc_date) AS max_enc_date
FROM rgd_gold_ad.family_history
WHERE history_date BETWEEN '1900-01-01' AND '2900-01-01';
