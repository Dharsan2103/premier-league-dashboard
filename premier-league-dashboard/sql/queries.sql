-- =====================================================
-- PREMIER LEAGUE SQL PORTFOLIO QUERIES
-- Author: Dharsan G S
-- Database: PostgreSQL
-- =====================================================


-- ─────────────────────────────────────────────────────
-- QUERY 1: Full League Table for Any Season
-- Skills: JOIN, GROUP BY, CASE, ORDER BY
-- ─────────────────────────────────────────────────────
SELECT
    t.team_name,
    s.position,
    s.played,
    s.won,
    s.drawn,
    s.lost,
    s.goals_for,
    s.goals_against,
    s.goal_difference,
    s.points,
    s.notes
FROM standings s
JOIN teams t ON s.team_id = t.team_id
JOIN seasons se ON s.season_id = se.season_id
WHERE se.season_name = '2024'
ORDER BY s.position;


-- ─────────────────────────────────────────────────────
-- QUERY 2: All-Time Title Winners
-- Skills: JOIN, GROUP BY, ORDER BY
-- ─────────────────────────────────────────────────────
SELECT
    t.team_name,
    COUNT(*) AS titles_won,
    STRING_AGG(se.season_name::TEXT, ', ' ORDER BY se.season_name) AS winning_seasons
FROM standings s
JOIN teams t  ON s.team_id   = t.team_id
JOIN seasons se ON s.season_id = se.season_id
WHERE s.position = 1
GROUP BY t.team_name
ORDER BY titles_won DESC;


-- ─────────────────────────────────────────────────────
-- QUERY 3: Most Relegated Teams All Time
-- Skills: JOIN, GROUP BY, FILTER on notes
-- ─────────────────────────────────────────────────────
SELECT
    t.team_name,
    COUNT(*) AS times_relegated
FROM standings s
JOIN teams t ON s.team_id = t.team_id
WHERE LOWER(s.notes) LIKE '%relegate%'
GROUP BY t.team_name
ORDER BY times_relegated DESC
LIMIT 10;


-- ─────────────────────────────────────────────────────
-- QUERY 4: Home vs Away Win Comparison Per Team
-- Skills: JOIN, CASE, GROUP BY, ROUND
-- ─────────────────────────────────────────────────────
SELECT
    t.team_name,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN m.result = 'H' AND m.home_team_id = t.team_id THEN 1
             WHEN m.result = 'A' AND m.away_team_id = t.team_id THEN 1
             ELSE 0 END) AS total_wins,
    SUM(CASE WHEN m.result = 'H' AND m.home_team_id = t.team_id THEN 1
             ELSE 0 END) AS home_wins,
    SUM(CASE WHEN m.result = 'A' AND m.away_team_id = t.team_id THEN 1
             ELSE 0 END) AS away_wins,
    ROUND(SUM(CASE WHEN m.result = 'H' AND m.home_team_id = t.team_id THEN 1
                   WHEN m.result = 'A' AND m.away_team_id = t.team_id THEN 1
                   ELSE 0 END) * 100.0 / COUNT(*), 1) AS win_pct
FROM matches m
JOIN teams t ON t.team_id IN (m.home_team_id, m.away_team_id)
GROUP BY t.team_name
HAVING COUNT(*) > 100
ORDER BY win_pct DESC
LIMIT 15;


-- ─────────────────────────────────────────────────────
-- QUERY 5: Head to Head Record Between Two Teams
-- Skills: JOIN, CASE, SUM, WHERE with OR
-- ─────────────────────────────────────────────────────
SELECT
    ht.team_name                                          AS home_team,
    at.team_name                                          AS away_team,
    COUNT(*)                                              AS total_matches,
    SUM(CASE WHEN m.result = 'H' THEN 1 ELSE 0 END)      AS home_team_wins,
    SUM(CASE WHEN m.result = 'D' THEN 1 ELSE 0 END)      AS draws,
    SUM(CASE WHEN m.result = 'A' THEN 1 ELSE 0 END)      AS away_team_wins,
    SUM(m.home_goals)                                     AS home_goals_total,
    SUM(m.away_goals)                                     AS away_goals_total
FROM matches m
JOIN teams ht ON m.home_team_id = ht.team_id
JOIN teams at ON m.away_team_id = at.team_id
WHERE (ht.team_name = 'Manchester United' AND at.team_name = 'Arsenal')
   OR (ht.team_name = 'Arsenal' AND at.team_name = 'Manchester United')
GROUP BY ht.team_name, at.team_name;


-- ─────────────────────────────────────────────────────
-- QUERY 6: Most Goals Scored in a Single Season (Team)
-- Skills: JOIN, GROUP BY, ORDER BY, LIMIT
-- ─────────────────────────────────────────────────────
SELECT
    t.team_name,
    se.season_name,
    s.goals_for,
    s.goals_against,
    s.goal_difference,
    s.points,
    s.position
FROM standings s
JOIN teams   t  ON s.team_id   = t.team_id
JOIN seasons se ON s.season_id = se.season_id
ORDER BY s.goals_for DESC
LIMIT 10;


-- ─────────────────────────────────────────────────────
-- QUERY 7: Top 10 Players by Goals (2024/25)
-- Skills: JOIN, GROUP BY, ORDER BY, LIMIT
-- ─────────────────────────────────────────────────────
SELECT
    p.player_name,
    t.team_name,
    p.position,
    ps.goals,
    ps.assists,
    ps.goals + ps.assists           AS goal_contributions,
    ps.minutes_played,
    ps.xg,
    ROUND(ps.goals - ps.xg, 2)     AS xg_overperformance
FROM player_stats ps
JOIN players p  ON ps.player_id  = p.player_id
JOIN teams   t  ON p.team_id     = t.team_id
JOIN seasons se ON ps.season_id  = se.season_id
WHERE se.season_name = '2024/2025'
  AND ps.minutes_played > 500
ORDER BY ps.goals DESC
LIMIT 10;


-- ─────────────────────────────────────────────────────
-- QUERY 8: Top Assist Providers (2024/25)
-- Skills: JOIN, WHERE, ORDER BY
-- ─────────────────────────────────────────────────────
SELECT
    p.player_name,
    t.team_name,
    p.position,
    ps.assists,
    ps.goals,
    ps.xa,
    ROUND(ps.assists - ps.xa, 2)   AS xa_overperformance,
    ps.minutes_played
FROM player_stats ps
JOIN players p  ON ps.player_id = p.player_id
JOIN teams   t  ON p.team_id    = t.team_id
JOIN seasons se ON ps.season_id = se.season_id
WHERE se.season_name = '2024/2025'
  AND ps.minutes_played > 500
ORDER BY ps.assists DESC
LIMIT 10;


-- ─────────────────────────────────────────────────────
-- QUERY 9: Most Disciplined vs Most Carded Players
-- Skills: JOIN, ORDER BY, LIMIT
-- ─────────────────────────────────────────────────────
SELECT
    p.player_name,
    t.team_name,
    p.position,
    ps.yellow_cards,
    ps.red_cards,
    ps.yellow_cards + (ps.red_cards * 3)   AS discipline_score,
    ps.fouls,
    ps.minutes_played
FROM player_stats ps
JOIN players p  ON ps.player_id = p.player_id
JOIN teams   t  ON p.team_id    = t.team_id
JOIN seasons se ON ps.season_id = se.season_id
WHERE se.season_name = '2024/2025'
  AND ps.minutes_played > 500
ORDER BY discipline_score DESC
LIMIT 10;


-- ─────────────────────────────────────────────────────
-- QUERY 10: xG Overperformers & Underperformers
-- Skills: ROUND, arithmetic, JOIN, ORDER BY
-- ─────────────────────────────────────────────────────
SELECT
    p.player_name,
    t.team_name,
    p.position,
    ps.goals,
    ROUND(ps.xg, 2)                AS expected_goals,
    ROUND(ps.goals - ps.xg, 2)    AS xg_difference,
    CASE
        WHEN ps.goals > ps.xg THEN 'Overperformer 🔥'
        WHEN ps.goals < ps.xg THEN 'Underperformer ❄️'
        ELSE 'On Target ✅'
    END AS xg_status
FROM player_stats ps
JOIN players p  ON ps.player_id = p.player_id
JOIN teams   t  ON p.team_id    = t.team_id
JOIN seasons se ON ps.season_id = se.season_id
WHERE se.season_name = '2024/2025'
  AND ps.minutes_played > 900
  AND ps.xg > 0
ORDER BY ABS(ps.goals - ps.xg) DESC
LIMIT 15;


-- ─────────────────────────────────────────────────────
-- QUERY 11: Goals Per Season Trend (All Time)
-- Skills: JOIN, GROUP BY, ORDER BY — trend analysis
-- ─────────────────────────────────────────────────────
SELECT
    se.season_name,
    SUM(m.home_goals + m.away_goals)               AS total_goals,
    COUNT(m.match_id)                              AS total_matches,
    ROUND(AVG(m.home_goals + m.away_goals), 2)     AS avg_goals_per_game,
    SUM(CASE WHEN m.result = 'H' THEN 1 ELSE 0 END) AS home_wins,
    SUM(CASE WHEN m.result = 'A' THEN 1 ELSE 0 END) AS away_wins,
    SUM(CASE WHEN m.result = 'D' THEN 1 ELSE 0 END) AS draws
FROM matches m
JOIN seasons se ON m.season_id = se.season_id
GROUP BY se.season_name
ORDER BY se.season_name;


-- ─────────────────────────────────────────────────────
-- QUERY 12: Best Attack vs Best Defense Each Season
-- Skills: CTE, RANK(), Window Function, JOIN
-- ─────────────────────────────────────────────────────
WITH ranked AS (
    SELECT
        t.team_name,
        se.season_name,
        s.goals_for,
        s.goals_against,
        RANK() OVER (PARTITION BY s.season_id ORDER BY s.goals_for DESC)    AS attack_rank,
        RANK() OVER (PARTITION BY s.season_id ORDER BY s.goals_against ASC) AS defense_rank
    FROM standings s
    JOIN teams   t  ON s.team_id   = t.team_id
    JOIN seasons se ON s.season_id = se.season_id
)
SELECT
    season_name,
    MAX(CASE WHEN attack_rank  = 1 THEN team_name END) AS best_attack,
    MAX(CASE WHEN attack_rank  = 1 THEN goals_for END)     AS goals_scored,
    MAX(CASE WHEN defense_rank = 1 THEN team_name END) AS best_defense,
    MIN(CASE WHEN defense_rank = 1 THEN goals_against END) AS goals_conceded
FROM ranked
GROUP BY season_name
ORDER BY season_name;


-- ─────────────────────────────────────────────────────
-- QUERY 13: Points Needed to Win the Title Each Season
-- Skills: JOIN, WHERE, subquery
-- ─────────────────────────────────────────────────────
SELECT
    se.season_name,
    t.team_name          AS champion,
    s.points             AS title_winning_points,
    s.goals_for,
    s.goals_against,
    s.won,
    s.drawn,
    s.lost
FROM standings s
JOIN teams   t  ON s.team_id   = t.team_id
JOIN seasons se ON s.season_id = se.season_id
WHERE s.position = 1
ORDER BY se.season_name;


-- ─────────────────────────────────────────────────────
-- QUERY 14: Nationality Distribution of Players
-- Skills: GROUP BY, COUNT, ORDER BY
-- ─────────────────────────────────────────────────────
SELECT
    p.nationality,
    COUNT(*)                                        AS total_players,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM players p
WHERE p.nationality IS NOT NULL
  AND p.nationality != 'nan'
GROUP BY p.nationality
ORDER BY total_players DESC
LIMIT 15;


-- ─────────────────────────────────────────────────────
-- QUERY 15: Complete Player Performance Summary
-- Skills: Multiple JOINs, calculated columns, CASE
-- ─────────────────────────────────────────────────────
SELECT
    p.player_name,
    t.team_name,
    p.nationality,
    p.position,
    ps.appearances,
    ps.minutes_played,
    ps.goals,
    ps.assists,
    ps.goals + ps.assists                               AS goal_contributions,
    ROUND(ps.xg, 2)                                     AS xg,
    ROUND(ps.xa, 2)                                     AS xa,
    ps.yellow_cards,
    ps.red_cards,
    ps.clean_sheets,
    CASE
        WHEN p.position = 'Forward'    AND ps.goals   >= 15 THEN '⭐ Elite'
        WHEN p.position = 'Midfielder' AND ps.assists >= 8  THEN '⭐ Elite'
        WHEN p.position = 'Defender'   AND ps.clean_sheets >= 10 THEN '⭐ Elite'
        WHEN p.position = 'Goalkeeper' AND ps.clean_sheets >= 10 THEN '⭐ Elite'
        ELSE 'Regular'
    END AS performance_tier
FROM player_stats ps
JOIN players p  ON ps.player_id = p.player_id
JOIN teams   t  ON p.team_id    = t.team_id
JOIN seasons se ON ps.season_id = se.season_id
WHERE se.season_name = '2024/2025'
ORDER BY goal_contributions DESC;