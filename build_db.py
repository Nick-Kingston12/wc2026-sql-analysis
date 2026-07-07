"""
FIFA World Cup 2026 — Database Builder
Loads 9 CSV files into a normalised SQLite database.
"""
import sqlite3, csv, os

DB_PATH = "wc2026.db"
DATA_DIR = "data"

if os.path.exists(DB_PATH):
    os.remove(DB_PATH)

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

def load_csv(table_name, file_name):
    path = f"{DATA_DIR}/{file_name}.csv"
    with open(path, encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        if not rows:
            return
        cols = rows[0].keys()
        placeholders = ",".join("?" for _ in cols)
        col_defs = ",".join(f'"{c}" TEXT' for c in cols)
        cur.execute(f'CREATE TABLE IF NOT EXISTS "{table_name}" ({col_defs})')
        for row in rows:
            cur.execute(f'INSERT INTO "{table_name}" VALUES ({placeholders})', list(row.values()))
    print(f"  ✓ {table_name}: {len(rows)} rows loaded")

tables = [
    ("teams",              "teams"),
    ("venues",             "venues"),
    ("tournament_stages",  "tournament_stages"),
    ("referees",           "referees"),
    ("squads_and_players", "squads_and_players"),
    ("matches",            "matches"),
    ("match_events",       "match_events"),
    ("match_team_stats",   "match_team_stats"),
    ("match_lineups",      "match_lineups"),
]

print("Building wc2026.db ...\n")
for table, file in tables:
    load_csv(table, file)

conn.commit()
conn.close()
print(f"\n✅ Done! wc2026.db is ready.")
print("   Open in DB Browser for SQLite, or run analysis.sql")
