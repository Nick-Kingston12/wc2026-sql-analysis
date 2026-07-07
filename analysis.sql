-- ============================================================
-- FIFA WORLD CUP 2026 — SQL ANALYSIS
-- Built live during the tournament | Data: 52 completed matches
-- Nick van Rensburg | SQLite
-- ============================================================

-- ============================================================
-- QUERY 1: GOLDEN BOOT RACE — Top scorers so far
-- ============================================================
SELECT
    sp.player_name,
    t.team_name,
    sp.position,
    sp.club_team,
    COUNT(me.event_id)        AS goals_scored,
    ROUND(CAST(sp.market_value_eur AS REAL) / 1000000, 1) AS market_value_millions_eur
FROM match_events me
JOIN squads_and_players sp ON me.player_id = sp.player_id
JOIN teams t ON sp.team_id = t.team_id
WHERE me.event_type = 'Goal'
GROUP BY sp.player_id, sp.player_name, t.team_name, sp.position, sp.club_team
ORDER BY goals_scored DESC
LIMIT 10;

-- ============================================================
-- QUERY 2: GROUP STANDINGS — Points, GF, GA, GD
-- ============================================================
WITH all_results AS (
    SELECT
        home_team_id AS team_id,
        CAST(home_score AS INT) AS gf,
        CAST(away_score AS INT) AS ga,
        CASE
            WHEN CAST(home_score AS INT) > CAST(away_score AS INT) THEN 3
            WHEN CAST(home_score AS INT) = CAST(away_score AS INT) THEN 1
            ELSE 0
        END AS pts,
        CASE WHEN CAST(home_score AS INT) > CAST(away_score AS INT) THEN 1 ELSE 0 END AS wins,
        CASE WHEN CAST(home_score AS INT) = CAST(away_score AS INT) THEN 1 ELSE 0 END AS draws,
        CASE WHEN CAST(home_score AS INT) < CAST(away_score AS INT) THEN 1 ELSE 0 END AS losses
    FROM matches WHERE status = 'Completed'
    UNION ALL
    SELECT
        away_team_id AS team_id,
        CAST(away_score AS INT) AS gf,
        CAST(home_score AS INT) AS ga,
        CASE
            WHEN CAST(away_score AS INT) > CAST(home_score AS INT) THEN 3
            WHEN CAST(away_score AS INT) = CAST(home_score AS INT) THEN 1
            ELSE 0
        END AS pts,
        CASE WHEN CAST(away_score AS INT) > CAST(home_score AS INT) THEN 1 ELSE 0 END AS wins,
        CASE WHEN CAST(away_score AS INT) = CAST(home_score AS INT) THEN 1 ELSE 0 END AS draws,
        CASE WHEN CAST(away_score AS INT) < CAST(home_score AS INT) THEN 1 ELSE 0 END AS losses
    FROM matches WHERE status = 'Completed'
)
SELECT
    t.group_letter    AS grp,
    t.team_name,
    COUNT(*)          AS played,
    SUM(wins)         AS w,
    SUM(draws)        AS d,
    SUM(losses)       AS l,
    SUM(gf)           AS gf,
    SUM(ga)           AS ga,
    SUM(gf) - SUM(ga) AS gd,
    SUM(pts)          AS pts
FROM all_results ar
JOIN teams t ON ar.team_id = t.team_id
GROUP BY t.group_letter, t.team_name
ORDER BY t.group_letter, pts DESC, gd DESC, gf DESC;

-- ============================================================
-- QUERY 3: MOST CLINICAL TEAMS — Shot conversion rate
-- ============================================================
SELECT
    t.team_name,
    t.group_letter,
    SUM(CAST(mts.total_shots AS INT))           AS total_shots,
    SUM(CAST(mts.shots_on_target AS INT))       AS shots_on_target,
    COUNT(me.event_id)                           AS goals_scored,
    ROUND(
        CAST(COUNT(me.event_id) AS REAL) /
        NULLIF(SUM(CAST(mts.total_shots AS INT)), 0) * 100, 1
    )                                            AS conversion_rate_pct,
    ROUND(
        CAST(SUM(CAST(mts.total_shots AS INT)) AS REAL) /
        NULLIF(COUNT(me.event_id), 0), 1
    )                                            AS shots_per_goal
FROM match_team_stats mts
JOIN teams t ON mts.team_id = t.team_id
LEFT JOIN match_events me
    ON me.match_id = mts.match_id
    AND me.team_id = mts.team_id
    AND me.event_type = 'Goal'
GROUP BY t.team_id, t.team_name, t.group_letter
HAVING SUM(CAST(mts.total_shots AS INT)) > 0
ORDER BY conversion_rate_pct DESC
LIMIT 12;

-- ============================================================
-- QUERY 4: POSSESSION VS RESULTS — Do dominant teams win?
-- ============================================================
WITH match_possession AS (
    SELECT
        mts.match_id,
        mts.team_id,
        CAST(mts.possession_pct AS REAL) AS possession,
        CASE
            WHEN mts.team_id = m.home_team_id THEN
                CASE
                    WHEN CAST(m.home_score AS INT) > CAST(m.away_score AS INT) THEN 'Win'
                    WHEN CAST(m.home_score AS INT) = CAST(m.away_score AS INT) THEN 'Draw'
                    ELSE 'Loss'
                END
            ELSE
                CASE
                    WHEN CAST(m.away_score AS INT) > CAST(m.home_score AS INT) THEN 'Win'
                    WHEN CAST(m.away_score AS INT) = CAST(m.home_score AS INT) THEN 'Draw'
                    ELSE 'Loss'
                END
        END AS result
    FROM match_team_stats mts
    JOIN matches m ON mts.match_id = m.match_id
    WHERE m.status = 'Completed'
)
SELECT
    result,
    COUNT(*)                              AS occurrences,
    ROUND(AVG(possession), 1)             AS avg_possession_pct,
    ROUND(MIN(possession), 1)             AS min_possession_pct,
    ROUND(MAX(possession), 1)             AS max_possession_pct
FROM match_possession
GROUP BY result
ORDER BY avg_possession_pct DESC;

-- ============================================================
-- QUERY 5: CONFEDERATION POWER — Avg goals & xG by region
-- ============================================================
WITH team_goals AS (
    SELECT
        t.confederation,
        t.team_id,
        t.team_name,
        SUM(CASE WHEN m.home_team_id = t.team_id THEN CAST(m.home_score AS INT)
                 WHEN m.away_team_id = t.team_id THEN CAST(m.away_score AS INT)
                 ELSE 0 END)  AS goals_for,
        SUM(CASE WHEN m.home_team_id = t.team_id THEN CAST(m.away_score AS INT)
                 WHEN m.away_team_id = t.team_id THEN CAST(m.home_score AS INT)
                 ELSE 0 END)  AS goals_against,
        SUM(CASE WHEN m.home_team_id = t.team_id THEN CAST(m.home_xg AS REAL)
                 WHEN m.away_team_id = t.team_id THEN CAST(m.away_xg AS REAL)
                 ELSE 0 END)  AS total_xg,
        COUNT(m.match_id)     AS matches_played
    FROM teams t
    JOIN matches m
        ON (m.home_team_id = t.team_id OR m.away_team_id = t.team_id)
        AND m.status = 'Completed'
    GROUP BY t.confederation, t.team_id
)
SELECT
    confederation,
    COUNT(DISTINCT team_id)               AS teams,
    SUM(matches_played)                   AS total_matches,
    SUM(goals_for)                        AS total_goals,
    ROUND(AVG(goals_for), 2)              AS avg_goals_per_team,
    ROUND(SUM(goals_for) * 1.0 /
          NULLIF(SUM(matches_played),0), 2) AS goals_per_match,
    ROUND(AVG(total_xg), 2)              AS avg_xg_per_team,
    SUM(goals_for) - SUM(goals_against)  AS total_gd
FROM team_goals
GROUP BY confederation
ORDER BY goals_per_match DESC;

-- ============================================================
-- QUERY 6: SQUAD WEALTH vs PERFORMANCE
-- Most expensive squads — are they winning?
-- ============================================================
WITH squad_value AS (
    SELECT
        t.team_id,
        t.team_name,
        t.group_letter,
        t.fifa_ranking_pre_tournament,
        SUM(CAST(sp.market_value_eur AS REAL)) AS squad_value_eur,
        COUNT(sp.player_id)                     AS squad_size
    FROM teams t
    JOIN squads_and_players sp ON sp.team_id = t.team_id
    GROUP BY t.team_id
),
team_pts AS (
    SELECT team_id, SUM(pts) AS points, SUM(gf) AS goals FROM (
        SELECT home_team_id AS team_id,
            CASE WHEN CAST(home_score AS INT) > CAST(away_score AS INT) THEN 3
                 WHEN CAST(home_score AS INT) = CAST(away_score AS INT) THEN 1
                 ELSE 0 END AS pts,
            CAST(home_score AS INT) AS gf
        FROM matches WHERE status = 'Completed'
        UNION ALL
        SELECT away_team_id,
            CASE WHEN CAST(away_score AS INT) > CAST(home_score AS INT) THEN 3
                 WHEN CAST(away_score AS INT) = CAST(home_score AS INT) THEN 1
                 ELSE 0 END,
            CAST(away_score AS INT)
        FROM matches WHERE status = 'Completed'
    ) GROUP BY team_id
)
SELECT
    sv.team_name,
    sv.group_letter,
    sv.fifa_ranking_pre_tournament  AS fifa_rank,
    ROUND(sv.squad_value_eur / 1000000, 0) AS squad_value_M_eur,
    COALESCE(tp.points, 0)          AS points,
    COALESCE(tp.goals, 0)           AS goals_scored
FROM squad_value sv
LEFT JOIN team_pts tp ON sv.team_id = tp.team_id
ORDER BY sv.squad_value_eur DESC
LIMIT 15;

-- ============================================================
-- QUERY 7: DIRTIEST vs CLEANEST TEAMS — Discipline table
-- ============================================================
SELECT
    t.team_name,
    t.confederation,
    COUNT(CASE WHEN me.event_type = 'Yellow Card' THEN 1 END) AS yellow_cards,
    COUNT(CASE WHEN me.event_type = 'Red Card'    THEN 1 END) AS red_cards,
    COUNT(CASE WHEN me.event_type IN ('Yellow Card','Red Card') THEN 1 END) AS total_cards,
    COUNT(DISTINCT me.match_id)                                AS matches_played,
    ROUND(
        COUNT(CASE WHEN me.event_type IN ('Yellow Card','Red Card') THEN 1 END) * 1.0 /
        NULLIF(COUNT(DISTINCT me.match_id), 0), 2
    )                                                          AS cards_per_game
FROM match_events me
JOIN teams t ON me.team_id = t.team_id
WHERE me.event_type IN ('Yellow Card', 'Red Card')
GROUP BY t.team_id, t.team_name, t.confederation
ORDER BY cards_per_game DESC;

-- ============================================================
-- QUERY 8: STADIUM GOALS — Which venues produce the most drama?
-- ============================================================
SELECT
    v.stadium_name,
    v.city,
    v.country,
    v.capacity,
    COUNT(DISTINCT m.match_id)                     AS matches_played,
    SUM(CAST(m.home_score AS INT) +
        CAST(m.away_score AS INT))                 AS total_goals,
    ROUND(
        SUM(CAST(m.home_score AS INT) +
            CAST(m.away_score AS INT)) * 1.0 /
        NULLIF(COUNT(DISTINCT m.match_id), 0), 2
    )                                              AS goals_per_game,
    MAX(CAST(m.home_score AS INT) +
        CAST(m.away_score AS INT))                 AS highest_scoring_game
FROM venues v
JOIN matches m ON m.venue_id = v.venue_id
WHERE m.status = 'Completed'
GROUP BY v.venue_id, v.stadium_name, v.city, v.country, v.capacity
ORDER BY goals_per_game DESC;

-- ============================================================
-- QUERY 9: OVERPERFORMERS & UNDERPERFORMERS
-- Teams beating or losing to their xG
-- ============================================================
SELECT
    t.team_name,
    t.group_letter,
    SUM(CASE WHEN m.home_team_id = t.team_id THEN CAST(m.home_score AS INT)
             ELSE CAST(m.away_score AS INT) END)         AS actual_goals,
    ROUND(SUM(CASE WHEN m.home_team_id = t.team_id THEN CAST(m.home_xg AS REAL)
                   ELSE CAST(m.away_xg AS REAL) END), 2) AS expected_goals_xg,
    ROUND(
        SUM(CASE WHEN m.home_team_id = t.team_id THEN CAST(m.home_score AS INT)
                 ELSE CAST(m.away_score AS INT) END) -
        SUM(CASE WHEN m.home_team_id = t.team_id THEN CAST(m.home_xg AS REAL)
                 ELSE CAST(m.away_xg AS REAL) END), 2
    )                                                    AS goals_minus_xg,
    CASE
        WHEN SUM(CASE WHEN m.home_team_id = t.team_id THEN CAST(m.home_score AS INT)
                      ELSE CAST(m.away_score AS INT) END) >
             SUM(CASE WHEN m.home_team_id = t.team_id THEN CAST(m.home_xg AS REAL)
                      ELSE CAST(m.away_xg AS REAL) END)
        THEN '🔥 Overperforming'
        ELSE '📉 Underperforming'
    END                                                  AS xg_status
FROM teams t
JOIN matches m
    ON (m.home_team_id = t.team_id OR m.away_team_id = t.team_id)
    AND m.status = 'Completed'
GROUP BY t.team_id, t.team_name, t.group_letter
HAVING COUNT(m.match_id) >= 2
ORDER BY goals_minus_xg DESC;

-- ============================================================
-- QUERY 10: AGE vs GOALS — Do veteran players deliver at WCs?
-- ============================================================
SELECT
    CASE
        WHEN age < 22 THEN 'Under 22'
        WHEN age BETWEEN 22 AND 25 THEN '22-25'
        WHEN age BETWEEN 26 AND 29 THEN '26-29 (Prime)'
        WHEN age BETWEEN 30 AND 33 THEN '30-33 (Veteran)'
        ELSE '34+'
    END                          AS age_group,
    COUNT(DISTINCT sp.player_id) AS players,
    SUM(goals)                   AS total_goals,
    ROUND(AVG(goals), 3)         AS avg_goals_per_player,
    ROUND(AVG(CAST(sp.market_value_eur AS REAL))/1000000, 1) AS avg_value_M_eur
FROM (
    SELECT
        sp.*,
        CAST((julianday('2026-06-11') - julianday(sp.date_of_birth)) / 365.25 AS INT) AS age,
        COUNT(me.event_id) AS goals
    FROM squads_and_players sp
    LEFT JOIN match_events me
        ON me.player_id = sp.player_id AND me.event_type = 'Goal'
    GROUP BY sp.player_id
) sp
GROUP BY age_group
ORDER BY MIN(age);
