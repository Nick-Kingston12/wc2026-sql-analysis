# ⚽ FIFA World Cup 2026 — SQL Analysis Project

> **Built live during the 2026 World Cup** | 52 completed matches analysed | Updated as the tournament progresses

[![SQLite](https://img.shields.io/badge/SQLite-003B57?style=flat&logo=sqlite&logoColor=white)](https://sqlite.org)
[![SQL](https://img.shields.io/badge/Pure%20SQL-Analysis-blue?style=flat)](./analysis.sql)
[![WC2026](https://img.shields.io/badge/FIFA%20World%20Cup-2026-green?style=flat)](https://www.fifa.com)

---

## 📌 Project Overview

The FIFA World Cup 2026 is the **largest in history** — 48 nations, 1,248 players, 104 matches across 16 venues in the USA, Canada, and Mexico. I built this analysis live as the tournament unfolded, treating it as a real-world SQL data engineering challenge.

Starting from 9 raw CSV files, I built a normalised relational SQLite database and wrote 10 analytical SQL queries to answer questions that matter: who's clinical in front of goal, which confederation is dominating, and are expensive squads actually worth it?

---

## 🗄️ Database Schema

**9 tables · 1,248 players · 48 nations · 16 venues · Full match event log**

| Table | Rows | Key Columns |
|---|---|---|
| `teams` | 48 | `team_id`, `team_name`, `confederation`, `group_letter`, `fifa_ranking_pre_tournament` |
| `squads_and_players` | 1,248 | `player_id`, `team_id`, `player_name`, `position`, `club_team`, `market_value_eur`, `date_of_birth` |
| `matches` | 72 | `match_id`, `home_team_id`, `away_team_id`, `home_score`, `away_score`, `home_xg`, `away_xg`, `status` |
| `match_events` | 303 | `event_id`, `match_id`, `minute`, `event_type`, `player_id`, `team_id` |
| `match_team_stats` | 104 | `match_id`, `team_id`, `possession_pct`, `total_shots`, `shots_on_target`, `corners`, `fouls` |
| `match_lineups` | 2,704 | `match_id`, `player_id`, `team_id`, `is_starting_xi`, `minutes_played` |
| `venues` | 16 | `venue_id`, `stadium_name`, `city`, `country`, `capacity`, `latitude`, `longitude` |
| `tournament_stages` | 7 | `stage_id`, `stage_name`, `is_knockout` |
| `referees` | 16 | `referee_id`, `name`, `country`, `avg_cards_per_game` |

---

## 🔍 10 Key Questions Answered

| # | Question | Technique |
|---|---|---|
| 1 | Who is leading the Golden Boot race? | JOIN + GROUP BY + COUNT |
| 2 | What do the full group standings look like? | CTE + UNION ALL + conditional aggregation |
| 3 | Which teams are most clinical in front of goal? | Multi-table JOIN + ROUND + NULLIF |
| 4 | Does possession actually win matches? | CTE + CASE WHEN + AVG |
| 5 | Which confederation is dominating? | Multi-level aggregation + subquery |
| 6 | Are the most expensive squads winning? | CTE + LEFT JOIN + SUM across tables |
| 7 | Who are the dirtiest and cleanest teams? | Conditional COUNT + cards per game |
| 8 | Which stadiums produce the most goals? | JOIN + SUM + goals per game ratio |
| 9 | Who is beating (or falling short of) their xG? | CASE WHEN overperformer detection |
| 10 | Do veteran players deliver at World Cups? | Date arithmetic + age bucketing + LEFT JOIN |

---

## 💡 Key Findings (Group Stage)

- 🥇 **Messi leads the Golden Boot with 5 goals** — at 38, he is defying age entirely
- 🏟️ **Vancouver (4.33 GPG) and Santa Clara (4.00 GPG)** are the most entertaining venues
- 🎯 **Possession wins** — teams with the ball average 52.7% possession in victories vs 42.9% in defeats
- 💶 **Squad value ≠ points** — Belgium (€603M squad, ranked 9th) have only 2 points after 2 matches
- 🌍 **UEFA leads all confederations** at 2.03 goals per match; CAF and AFC trail at 0.95
- 🔥 **Germany (+2.33 goals vs xG)** are the biggest overperformers of the tournament so far
- 👴 **Players aged 34+ average 11.9 tournament goals per player** — experience matters at World Cups
- 🟥 **Qatar (2 reds in 1 game)** and **Australia (4 yellows)** are the most disciplined concerns

---

## 🛠️ How to Run

### Prerequisites
- Python 3.8+
- SQLite (built into Python — no install needed)
- DB Browser for SQLite *(optional, for visual exploration)*

### Setup

```bash
git clone https://github.com/YOUR_USERNAME/wc2026-sql-analysis
cd wc2026-sql-analysis

# Build the database from CSV files
python build_db.py

# Run all analyses
python run_analysis.py

# Or open the .db file directly in DB Browser for SQLite
# and run analysis.sql manually
```

### Files

```
wc2026-sql-analysis/
├── data/                      # 9 raw CSV files (source data)
│   ├── matches.csv
│   ├── teams.csv
│   ├── squads_and_players.csv
│   ├── match_events.csv
│   ├── match_team_stats.csv
│   ├── match_lineups.csv
│   ├── venues.csv
│   ├── tournament_stages.csv
│   └── referees.csv
├── build_db.py                # Loads CSVs → SQLite database
├── analysis.sql               # All 10 analytical SQL queries
├── wc2026.db                  # Generated SQLite database
└── README.md
```

---

## 📊 SQL Techniques Used

- **CTEs** (`WITH`) for readable multi-step logic
- **UNION ALL** to combine home/away perspectives into single result sets
- **Window functions** and conditional aggregation with `CASE WHEN`
- **Multi-table JOINs** across 4–5 tables in a single query
- **Date arithmetic** using `julianday()` for age calculations
- **NULLIF** for safe division (avoiding divide-by-zero errors)
- **Subqueries** for pre-aggregation before final JOIN

---

## 📁 Data Source

Dataset: [FIFA World Cup 2026 Dataset — Kaggle](https://www.kaggle.com/datasets/mominullptr/fifa-world-cup-2026-dataset)  
Ingested via: `IBRAHIMKHALIL-AI/FIFA-WORLD-CUP-2026-Intelligence-Platform` (GitHub)

---

## 👤 Author

**Nick van Rensburg**  
BCom Information Systems & Business Management | Nelson Mandela University  
📍 Nijmegen, Netherlands  
[LinkedIn](https://linkedin.com/in/YOUR_PROFILE) · [GitHub](https://github.com/YOUR_USERNAME)

---

*Built live during the FIFA World Cup 2026 group stage. Analysis will be updated as knockout rounds progress.*

#SQL #DataAnalytics #FIFA #WorldCup2026 #DataAnalyst #PortfolioProject #SQLite
