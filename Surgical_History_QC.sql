-- =============================================================================
-- NeuroDiscovery AI — Gold Layer QC Queries
-- Table: rgd_gold_ad.surgical_history
-- Schema: rgd_gold_ad
-- Prepared By: Somenath Sen — RWD Team
-- Date: July 2026
-- Framework: 5C (Completeness, Correctness, Concordance, Credibility, Currency)
-- DE Key: surgicalhistoryid + ndid + psid + eid + enc_date + surgery_date
--         + surgery_name + surgery_code + surgery_reason
-- Gold mapping: surgicalhistoryid → history_id, eid → encounterid,
--               surgery_date → history_date, surgery_name → hist_name
-- Missing DE fields: surgery_code, surgery_reason (not in Gold)
-- Exclusions: null/empty hist_name; non-surgical entries; null history_id;
--             normalize hist_notes (empty string treated as null)
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- BASELINE
-- ─────────────────────────────────────────────────────────────────────────────

-- B1. Total records, patients, psids
SELECT COUNT(*) AS total_records,
    COUNT(DISTINCT ndid) AS unique_patients,
    COUNT(DISTINCT psid) AS unique_psids
FROM rgd_gold_ad.surgical_history;

-- B2. Records and patients by psid
SELECT psid, COUNT(*) AS records,
    COUNT(DISTINCT ndid) AS unique_patients
FROM rgd_gold_ad.surgical_history
GROUP BY psid ORDER BY records DESC;

-- B3. Cohort coverage
SELECT
    (SELECT COUNT(DISTINCT ndid) FROM rgd_gold_ad.patients) AS cohort_patients,
    COUNT(DISTINCT ndid) AS patients_with_surgical_history,
    (SELECT COUNT(DISTINCT ndid) FROM rgd_gold_ad.patients)
        - COUNT(DISTINCT ndid) AS patients_without_surgical_history
FROM rgd_gold_ad.surgical_history;

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
FROM rgd_gold_ad.surgical_history;

-- C1.2 Fill rate from DE table (official source)
SELECT column_name, total_count, null_records, fill_rate_pct
FROM staging.fill_rate_report_gold
WHERE schema_name = 'rgd_gold_ad'
AND table_name = 'surgical_history'
ORDER BY fill_rate_pct DESC;

-- C1.3 hist_category distribution
SELECT hist_category, COUNT(*) AS cnt
FROM rgd_gold_ad.surgical_history
GROUP BY hist_category ORDER BY cnt DESC;

-- C1.4 Encounterid null by psid
SELECT psid,
    SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS null_encounterid,
    COUNT(*) AS total_records,
    ROUND(SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS pct_null
FROM rgd_gold_ad.surgical_history
GROUP BY psid ORDER BY null_encounterid DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. CORRECTNESS
-- ─────────────────────────────────────────────────────────────────────────────

-- C2.1 Non-surgical hist_name entries
SELECT hist_name, COUNT(*) AS cnt
FROM rgd_gold_ad.surgical_history
WHERE LOWER(hist_name) IN (
    'follow up visit','follow-up visit','office visit','visit',
    'no surgical history','no surgery','unknown','n/a','na'
)
GROUP BY hist_name ORDER BY cnt DESC;

-- C2.2 FREETEXT shell records by psid
SELECT psid, COUNT(*) AS cnt
FROM rgd_gold_ad.surgical_history
WHERE hist_category = 'SURGICALHISTORYLIST_FREETEXT'
GROUP BY psid ORDER BY cnt DESC;

-- C2.3 Date plausibility
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
FROM rgd_gold_ad.surgical_history;

-- C2.4 Far-future date sample rows
SELECT gold_row_id, ndid, psid, encounterid, history_id,
    enc_date, history_date, hist_category, hist_name, hist_notes, udm_active_flag
FROM rgd_gold_ad.surgical_history
WHERE history_date > '2900-01-01'
ORDER BY psid LIMIT 10;

-- C2.5 Date plausibility by psid
SELECT psid,
    SUM(CASE WHEN history_date > '2900-01-01' THEN 1 ELSE 0 END) AS far_future,
    SUM(CASE WHEN history_date > CURDATE()
             AND history_date <= '2900-01-01' THEN 1 ELSE 0 END) AS near_future,
    SUM(CASE WHEN history_date < '1900-01-01' THEN 1 ELSE 0 END) AS before_1900,
    SUM(CASE WHEN enc_date > CURDATE() THEN 1 ELSE 0 END) AS future_enc_date
FROM rgd_gold_ad.surgical_history
GROUP BY psid
HAVING far_future > 0 OR near_future > 0 OR before_1900 > 0 OR future_enc_date > 0
ORDER BY far_future DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. CONCORDANCE
-- ─────────────────────────────────────────────────────────────────────────────

-- C3.1 Top hist_name values (excluding non-surgical entries)
SELECT hist_name, COUNT(*) AS cnt
FROM rgd_gold_ad.surgical_history
WHERE hist_name IS NOT NULL AND hist_name != ''
AND LOWER(hist_name) NOT IN (
    'follow up visit','follow-up visit','office visit','visit',
    'no surgical history','no surgery','unknown','n/a','na'
)
GROUP BY hist_name ORDER BY cnt DESC LIMIT 20;

-- C3.2 hist_notes vs hist_name mirror check (sample)
SELECT hist_name, hist_notes, COUNT(*) AS cnt
FROM rgd_gold_ad.surgical_history
WHERE hist_name IS NOT NULL AND hist_notes IS NOT NULL
AND hist_name = hist_notes
GROUP BY hist_name, hist_notes
ORDER BY cnt DESC LIMIT 10;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. CREDIBILITY
-- ─────────────────────────────────────────────────────────────────────────────

-- C4.1 Duplicate count on clean DE key (history_id IS NOT NULL required)
SELECT COUNT(*) AS duplicate_groups, SUM(grp_size-1) AS excess_rows
FROM (
    SELECT history_id, ndid, psid, encounterid,
           enc_date, history_date, hist_name,
           NULLIF(TRIM(hist_notes), '') AS hist_notes_clean,
           COUNT(*) AS grp_size
    FROM rgd_gold_ad.surgical_history
    WHERE udm_active_flag = 'Y'
    AND hist_name IS NOT NULL AND hist_name != ''
    AND history_id IS NOT NULL
    AND LOWER(hist_name) NOT IN (
        'follow up visit','follow-up visit','office visit','visit'
    )
    GROUP BY history_id, ndid, psid, encounterid,
             enc_date, history_date, hist_name,
             NULLIF(TRIM(hist_notes), '')
    HAVING COUNT(*) > 1
) t;

-- C4.2 Orphan ndids
SELECT COUNT(DISTINCT s.ndid) AS orphan_ndids
FROM rgd_gold_ad.surgical_history s
LEFT JOIN rgd_gold_ad.patients p ON s.ndid = p.ndid
WHERE p.ndid IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. CURRENCY
-- ─────────────────────────────────────────────────────────────────────────────

-- C5.1 udm_active_flag distribution
SELECT udm_active_flag, COUNT(*) AS cnt
FROM rgd_gold_ad.surgical_history
GROUP BY udm_active_flag;

-- C5.2 Date range confirmation
SELECT
    MIN(history_date) AS min_history_date,
    MAX(history_date) AS max_history_date,
    MIN(enc_date) AS min_enc_date,
    MAX(enc_date) AS max_enc_date
FROM rgd_gold_ad.surgical_history
WHERE history_date BETWEEN '1900-01-01' AND '2900-01-01';
