-- =============================================================================
-- NeuroDiscovery AI — Gold Layer QC Queries
-- Table: rgd_gold_ad.past_medical_history
-- Schema: rgd_gold_ad
-- Prepared By: Somenath Sen — RWD Team
-- Date: July 2026
-- Framework: 5C (Completeness, Correctness, Concordance, Credibility, Currency)
-- DE Key: med_hist_id + ndid + psid + eid + encounter_date + med_hist_date
--         + med_hist_question + med_hist_value + med_hist_code
-- Gold mapping: med_hist_id → history_id, eid → encounterid,
--               encounter_date → enc_date, med_hist_date → history_date,
--               med_hist_question → hist_question, med_hist_value → hist_value
-- Missing DE fields: med_hist_code (not in Gold)
-- THREE RECORD TYPES:
--   Type 1 — Free-text (psid 1,3,4,8,13,14): hist_name = hist_value blobs,
--             hist_category NULL, hist_question NULL, history_id NULL
--   Type 2 — Structured (psid 2,5,6,10): hist_question + Y/N hist_value,
--             hist_category = MedicalHistory, hist_name NULL
--   Type 3 — Empty shells (psid 9,11,12): hist_category = MedicalHistory,
--             hist_name + hist_question + hist_value all NULL
-- Exclusions: null history_id for duplicate check
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- BASELINE
-- ─────────────────────────────────────────────────────────────────────────────

-- B1. Total records, patients, psids
SELECT COUNT(*) AS total_records,
    COUNT(DISTINCT ndid) AS unique_patients,
    COUNT(DISTINCT psid) AS unique_psids
FROM rgd_gold_ad.past_medical_history;

-- B2. Records and patients by psid
SELECT psid, COUNT(*) AS records,
    COUNT(DISTINCT ndid) AS unique_patients
FROM rgd_gold_ad.past_medical_history
GROUP BY psid ORDER BY records DESC;

-- B3. Cohort coverage
SELECT
    (SELECT COUNT(DISTINCT ndid) FROM rgd_gold_ad.patients) AS cohort_patients,
    COUNT(DISTINCT ndid) AS patients_with_pmh,
    (SELECT COUNT(DISTINCT ndid) FROM rgd_gold_ad.patients)
        - COUNT(DISTINCT ndid) AS patients_without_pmh
FROM rgd_gold_ad.past_medical_history;

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
FROM rgd_gold_ad.past_medical_history;

-- C1.2 Fill rate from DE table (official source)
SELECT column_name, total_count, null_records, fill_rate_pct
FROM staging.fill_rate_report_gold
WHERE schema_name = 'rgd_gold_ad'
AND table_name = 'past_medical_history'
ORDER BY fill_rate_pct DESC;

-- C1.3 Record structure by psid (verify three-type structure)
SELECT psid, hist_category,
    COUNT(*) AS records,
    SUM(CASE WHEN hist_name IS NULL OR hist_name = '' THEN 1 ELSE 0 END) AS null_hist_name,
    SUM(CASE WHEN hist_question IS NULL OR hist_question = '' THEN 1 ELSE 0 END) AS null_hist_question,
    SUM(CASE WHEN hist_value IS NULL OR hist_value = '' THEN 1 ELSE 0 END) AS null_hist_value
FROM rgd_gold_ad.past_medical_history
GROUP BY psid, hist_category
ORDER BY psid, hist_category;

-- C1.4 Empty shell verification (psid 9, 11, 12)
SELECT psid,
    SUM(CASE WHEN hist_name IS NULL AND hist_question IS NULL
             AND hist_value IS NULL THEN 1 ELSE 0 END) AS fully_empty_records,
    COUNT(*) AS total_records
FROM rgd_gold_ad.past_medical_history
WHERE hist_category = 'MedicalHistory'
AND psid IN (9, 11, 12)
GROUP BY psid;

-- C1.5 Encounterid null by psid
SELECT psid,
    SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END) AS null_encounterid,
    COUNT(*) AS total_records,
    ROUND(SUM(CASE WHEN encounterid IS NULL THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS pct_null
FROM rgd_gold_ad.past_medical_history
GROUP BY psid ORDER BY null_encounterid DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. CORRECTNESS
-- ─────────────────────────────────────────────────────────────────────────────

-- C2.1 ((TESTPATIENTYN)) placeholder by psid and record type
SELECT psid, hist_category, COUNT(*) AS testpatient_records
FROM rgd_gold_ad.past_medical_history
WHERE hist_value = '((TESTPATIENTYN))'
OR hist_name = '((TESTPATIENTYN))'
GROUP BY psid, hist_category
ORDER BY testpatient_records DESC;

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
FROM rgd_gold_ad.past_medical_history;

-- C2.3 Far-future date sample rows
SELECT gold_row_id, ndid, psid, encounterid, history_id,
    enc_date, history_date, hist_category,
    hist_name, hist_question, hist_value, hist_notes, udm_active_flag
FROM rgd_gold_ad.past_medical_history
WHERE history_date > CURDATE()
OR enc_date > CURDATE()
ORDER BY history_date DESC LIMIT 10;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. CONCORDANCE
-- ─────────────────────────────────────────────────────────────────────────────

-- C3.1 hist_category distribution
SELECT hist_category, COUNT(*) AS cnt
FROM rgd_gold_ad.past_medical_history
GROUP BY hist_category ORDER BY cnt DESC;

-- C3.2 Top hist_name values (free-text records — exclude test patient and Y/N)
SELECT hist_name, COUNT(*) AS cnt
FROM rgd_gold_ad.past_medical_history
WHERE hist_name IS NOT NULL AND hist_name != ''
AND hist_name NOT IN ('((TESTPATIENTYN))','Y','N')
GROUP BY hist_name ORDER BY cnt DESC LIMIT 20;

-- C3.3 Top hist_question values (structured records)
SELECT hist_question, COUNT(*) AS cnt
FROM rgd_gold_ad.past_medical_history
WHERE hist_question IS NOT NULL AND hist_question != ''
GROUP BY hist_question ORDER BY cnt DESC LIMIT 20;

-- C3.4 Structured records — hist_question + hist_value breakdown
-- (excludes ((TESTPATIENTYN)))
SELECT hist_question, hist_value, COUNT(*) AS cnt
FROM rgd_gold_ad.past_medical_history
WHERE hist_category = 'MedicalHistory'
AND hist_question IS NOT NULL
AND hist_value != '((TESTPATIENTYN))'
GROUP BY hist_question, hist_value
ORDER BY cnt DESC LIMIT 20;

-- C3.5 hist_name = hist_value mirror check (free-text records)
SELECT
    SUM(CASE WHEN hist_name = hist_value THEN 1 ELSE 0 END) AS mirrored_records,
    COUNT(*) AS total_free_text_records
FROM rgd_gold_ad.past_medical_history
WHERE hist_category IS NULL
AND hist_name IS NOT NULL AND hist_value IS NOT NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. CREDIBILITY
-- ─────────────────────────────────────────────────────────────────────────────

-- C4.1 Duplicate count on clean DE key (history_id IS NOT NULL required)
SELECT COUNT(*) AS duplicate_groups, SUM(grp_size-1) AS excess_rows
FROM (
    SELECT history_id, ndid, psid, encounterid,
           enc_date, history_date, hist_question, hist_value,
           COUNT(*) AS grp_size
    FROM rgd_gold_ad.past_medical_history
    WHERE udm_active_flag = 'Y'
    AND history_id IS NOT NULL
    GROUP BY history_id, ndid, psid, encounterid,
             enc_date, history_date, hist_question, hist_value
    HAVING COUNT(*) > 1
) t;

-- C4.2 Orphan ndids
SELECT COUNT(DISTINCT p.ndid) AS orphan_ndids
FROM rgd_gold_ad.past_medical_history p
LEFT JOIN rgd_gold_ad.patients pt ON p.ndid = pt.ndid
WHERE pt.ndid IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. CURRENCY
-- ─────────────────────────────────────────────────────────────────────────────

-- C5.1 udm_active_flag distribution
SELECT udm_active_flag, COUNT(*) AS cnt
FROM rgd_gold_ad.past_medical_history
GROUP BY udm_active_flag;

-- C5.2 Date range confirmation
SELECT
    MIN(history_date) AS min_history_date,
    MAX(history_date) AS max_history_date,
    MIN(enc_date) AS min_enc_date,
    MAX(enc_date) AS max_enc_date
FROM rgd_gold_ad.past_medical_history
WHERE history_date BETWEEN '1900-01-01' AND '2900-01-01';
