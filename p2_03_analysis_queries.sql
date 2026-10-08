USE customer_ops_registry;

-- =====================================================================
-- QUERY 1: Agent Performance Scorecard
-- Combines interaction outcomes with audit CSAT scores per agent —
-- the core "who needs coaching" view a quality lead would build first.
-- =====================================================================
WITH agent_interactions AS (
    SELECT
        agent_id,
        COUNT(*) AS total_interactions,
        SUM(CASE WHEN first_contact_resolution = 'Yes' THEN 1 ELSE 0 END) AS fcr_count,
        SUM(CASE WHEN escalated = 'Yes' THEN 1 ELSE 0 END) AS escalation_count
    FROM interactions
    GROUP BY agent_id
),
agent_audits AS (
    SELECT
        i.agent_id,
        ROUND(AVG(qa.csat_score), 2) AS avg_csat,
        COUNT(qa.audit_id) AS audits_received
    FROM quality_audits qa
    JOIN interactions i ON i.interaction_id = qa.interaction_id
    GROUP BY i.agent_id
)
SELECT
    a.agent_id,
    a.agent_name,
    a.team,
    ai.total_interactions,
    ROUND(ai.fcr_count * 1.0 / ai.total_interactions * 100, 1) AS fcr_rate_pct,
    ROUND(ai.escalation_count * 1.0 / ai.total_interactions * 100, 1) AS escalation_rate_pct,
    aa.avg_csat,
    aa.audits_received
FROM agents a
JOIN agent_interactions ai ON ai.agent_id = a.agent_id
LEFT JOIN agent_audits aa ON aa.agent_id = a.agent_id
ORDER BY fcr_rate_pct ASC;


-- =====================================================================
-- QUERY 2: Coaching Priority List
-- Flags agents performing below team-average FCR and above
-- team-average escalation rate — the actual "who to coach first" list.
-- =====================================================================
WITH agent_stats AS (
    SELECT
        agent_id,
        COUNT(*) AS total_interactions,
        SUM(CASE WHEN first_contact_resolution = 'Yes' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) * 100 AS fcr_rate_pct,
        SUM(CASE WHEN escalated = 'Yes' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) * 100 AS escalation_rate_pct
    FROM interactions
    GROUP BY agent_id
),
team_avg AS (
    SELECT AVG(fcr_rate_pct) AS avg_fcr, AVG(escalation_rate_pct) AS avg_escalation
    FROM agent_stats
)
SELECT
    a.agent_id,
    ag.agent_name,
    ag.team,
    ROUND(a.fcr_rate_pct, 1) AS fcr_rate_pct,
    ROUND(a.escalation_rate_pct, 1) AS escalation_rate_pct
FROM agent_stats a
JOIN agents ag ON ag.agent_id = a.agent_id
CROSS JOIN team_avg t
WHERE a.fcr_rate_pct < t.avg_fcr
  AND a.escalation_rate_pct > t.avg_escalation
ORDER BY a.escalation_rate_pct DESC;


-- =====================================================================
-- QUERY 3: Does Escalation Hurt CSAT? (proves the business impact)
-- =====================================================================
SELECT
    i.escalated,
    ROUND(AVG(qa.csat_score), 2) AS avg_csat,
    COUNT(*) AS audited_interactions
FROM interactions i
JOIN quality_audits qa ON qa.interaction_id = i.interaction_id
GROUP BY i.escalated;


-- =====================================================================
-- QUERY 4: Appointment Failure Rate by Type and Region
-- =====================================================================
SELECT
    ap.appointment_type,
    c.region,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN ap.status = 'Failed' THEN 1 ELSE 0 END) AS failed_count,
    ROUND(SUM(CASE WHEN ap.status = 'Failed' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) * 100, 1) AS failure_rate_pct
FROM appointments ap
JOIN customers c ON c.customer_id = ap.customer_id
GROUP BY ap.appointment_type, c.region
ORDER BY failure_rate_pct DESC;


-- =====================================================================
-- QUERY 5: Top Appointment Failure Reasons (ranked)
-- =====================================================================
SELECT
    failure_reason,
    COUNT(*) AS occurrence_count,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS reason_rank
FROM appointments
WHERE failure_reason IS NOT NULL
GROUP BY failure_reason;


-- =====================================================================
-- QUERY 6: Monthly Escalation Trend with Running Total (window function)
-- =====================================================================
SELECT
    DATE_FORMAT(interaction_date, '%Y-%m') AS interaction_month,
    SUM(CASE WHEN escalated = 'Yes' THEN 1 ELSE 0 END) AS escalations_this_month,
    SUM(SUM(CASE WHEN escalated = 'Yes' THEN 1 ELSE 0 END)) OVER (ORDER BY DATE_FORMAT(interaction_date, '%Y-%m')) AS running_total_escalations
FROM interactions
GROUP BY DATE_FORMAT(interaction_date, '%Y-%m')
ORDER BY interaction_month;


-- =====================================================================
-- QUERY 7: Channel Performance Comparison (Email vs Call vs Chat)
-- =====================================================================
SELECT
    channel,
    COUNT(*) AS total_interactions,
    ROUND(SUM(CASE WHEN first_contact_resolution = 'Yes' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) * 100, 1) AS fcr_rate_pct,
    ROUND(SUM(CASE WHEN escalated = 'Yes' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) * 100, 1) AS escalation_rate_pct
FROM interactions
GROUP BY channel
ORDER BY escalation_rate_pct DESC;


-- =====================================================================
-- QUERY 8: Most Common Quality Issues Found (audit-level root causes)
-- =====================================================================
SELECT
    issue_found,
    COUNT(*) AS occurrence_count,
    ROUND(AVG(csat_score), 2) AS avg_csat_when_this_issue_found
FROM quality_audits
GROUP BY issue_found
ORDER BY occurrence_count DESC;
