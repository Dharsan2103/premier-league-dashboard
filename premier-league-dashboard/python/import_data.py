import pandas as pd
import psycopg2
import os
import glob

# ============================================
# DATABASE CONNECTION
# ============================================
conn = psycopg2.connect(
    host="localhost",
    database="premier_league",
    user="postgres",
    password="Tharu21@@"   # <-- change this to your pgAdmin password
)
cursor = conn.cursor()
print("✅ Connected to database!")

# ============================================
# HELPER FUNCTIONS
# ============================================
def safe_int(val):
    try:
        if pd.isna(val): return 0
        return int(float(val))
    except: return 0

def safe_float(val):
    try:
        if pd.isna(val): return 0.0
        return float(val)
    except: return 0.0

def safe_str(val):
    try:
        if pd.isna(val): return None
        return str(val).strip()
    except: return None

def get_or_create_season(season_name):
    cursor.execute("SELECT season_id FROM seasons WHERE season_name = %s", (str(season_name),))
    row = cursor.fetchone()
    if row: return row[0]
    cursor.execute("INSERT INTO seasons (season_name) VALUES (%s) RETURNING season_id", (str(season_name),))
    return cursor.fetchone()[0]

def get_or_create_team(team_name):
    cursor.execute("SELECT team_id FROM teams WHERE team_name = %s", (str(team_name).strip(),))
    row = cursor.fetchone()
    if row: return row[0]
    cursor.execute("INSERT INTO teams (team_name) VALUES (%s) RETURNING team_id", (str(team_name).strip(),))
    return cursor.fetchone()[0]

# ============================================
# 1. IMPORT STANDINGS
# ============================================
print("\n📥 Importing Standings...")

standings_file = r"C:\Users\Dharsan G S\PL Analysis\pl19-24\pl-tables-1993-2024.csv"
df = pd.read_csv(standings_file)
print(f"   Found {len(df)} rows")
print(f"   Columns: {list(df.columns)}")

for _, row in df.iterrows():
    season_id = get_or_create_season(safe_int(row['season_end_year']))
    team_id   = get_or_create_team(str(row['team']))
    cursor.execute("""
        INSERT INTO standings 
            (season_id, team_id, position, played, won, drawn, lost,
             goals_for, goals_against, goal_difference, points, notes)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
    """, (
        season_id, team_id,
        safe_int(row['position']),
        safe_int(row['played']),
        safe_int(row['won']),
        safe_int(row['drawn']),
        safe_int(row['lost']),
        safe_int(row['gf']),
        safe_int(row['ga']),
        safe_int(row['gd']),
        safe_int(row['points']),
        safe_str(row.get('notes', None))
    ))

conn.commit()
print("✅ Standings imported!")

# ============================================
# 2. IMPORT MATCHES
# ============================================
print("\n📥 Importing Matches...")

matches_file = r"C:\Users\Dharsan G S\PL Analysis\pl19-23\premier-league-matches.csv"
df = pd.read_csv(matches_file)
print(f"   Found {len(df)} rows")
print(f"   Columns: {list(df.columns)}")

for _, row in df.iterrows():
    season_id    = get_or_create_season(safe_int(row['Season_End_Year']))
    home_team_id = get_or_create_team(str(row['Home']))
    away_team_id = get_or_create_team(str(row['Away']))

    try:
        match_date = pd.to_datetime(row['Date']).date()
    except:
        match_date = None

    cursor.execute("""
        INSERT INTO matches 
            (season_id, gameweek, match_date, home_team_id, away_team_id,
             home_goals, away_goals, result)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
    """, (
        season_id,
        safe_int(row.get('Wk', 0)),
        match_date,
        home_team_id,
        away_team_id,
        safe_int(row['HomeGoals']),
        safe_int(row['AwayGoals']),
        safe_str(row.get('FTR', None))
    ))

conn.commit()
print("✅ Matches imported!")

# ============================================
# 3. IMPORT CLUB STATS (multiple CSV files)
# ============================================
print("\n📥 Importing Club Stats...")

club_stats_folder = r"C:\Users\Dharsan G S\PL Analysis\pl16-25\datasets\club_stats"
csv_files = glob.glob(os.path.join(club_stats_folder, "*.csv"))
print(f"   Found {len(csv_files)} club stat files")

for file in csv_files:
    df = pd.read_csv(file)
    for _, row in df.iterrows():
        team_id   = get_or_create_team(str(row['club_name']))
        season_id = get_or_create_season(str(row['season']))

        cursor.execute("""
            INSERT INTO club_stats
                (team_id, season_id, games_played, goals_scored, goals_conceded,
                 xg, shots, shots_on_target, yellow_cards, red_cards,
                 corners, fouls, passes, touches, tackles,
                 interceptions, blocks, clearances, aerial_duels_won,
                 crosses, dribbles_attempted, dribbles_completed,
                 penalties, offsides)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """, (
            team_id, season_id,
            safe_int(row.get('Games Played',    row.get('games_played', 0))),
            safe_int(row.get('Goals',           0)),
            safe_int(row.get('Goals Conceded',  row.get('Conceded', 0))),
            safe_float(row.get('XG',            row.get('xg', 0))),
            safe_int(row.get('Shots',           0)),
            safe_int(row.get('Shots On Target', row.get('shots_on_target', 0))),
            safe_int(row.get('Yellow Cards',    row.get('yellow_cards', 0))),
            safe_int(row.get('Red Cards',       row.get('red_cards', 0))),
            safe_int(row.get('Corners',         row.get('corners', 0))),
            safe_int(row.get('Fouls',           row.get('fouls', 0))),
            safe_int(row.get('Passes',          row.get('passes', 0))),
            safe_int(row.get('Touches in penalty area', row.get('touches', 0))),
            safe_int(row.get('Total Tackles',   row.get('tackles', 0))),
            safe_int(row.get('Interceptions',   row.get('interceptions', 0))),
            safe_int(row.get('Blocks',          row.get('blocks', 0))),
            safe_int(row.get('Clearances',      row.get('clearances', 0))),
            safe_int(row.get('Aerial Duels Won',row.get('aerial_duels_won', 0))),
            safe_int(row.get('crosses',         row.get('cross_accuracy', 0))),
            safe_int(row.get('dribble_attempts',row.get('dribbles_attempted', 0))),
            safe_int(row.get('dribble_accuracy',row.get('dribbles_completed', 0))),
            safe_int(row.get('Penalties',       row.get('penalties', 0))),
            safe_int(row.get('Offsides',        row.get('offsides', 0))),
        ))

conn.commit()
print("✅ Club Stats imported!")

# ============================================
# 4. IMPORT PLAYER INFO
# ============================================
print("\n📥 Importing Player Info...")

player_info_file = r"C:\Users\Dharsan G S\PL Analysis\pl16-25\datasets\premier_player_info.csv"
df = pd.read_csv(player_info_file)
print(f"   Found {len(df)} players")
print(f"   Columns: {list(df.columns)}")

for _, row in df.iterrows():
    team_id = get_or_create_team(str(row['player_club']))
    cursor.execute("""
        INSERT INTO players (player_name, nationality, position, team_id)
        VALUES (%s, %s, %s, %s)
    """, (
        safe_str(row['player_name']),
        safe_str(row['player_country']),
        safe_str(row['player_position']),
        team_id
    ))

conn.commit()
print("✅ Player Info imported!")

# ============================================
# 5. IMPORT PLAYER STATS
# ============================================
print("\n📥 Importing Player Stats...")

player_stats_file = r"C:\Users\Dharsan G S\PL Analysis\pl16-25\datasets\player_stats_2024_2025_season.csv"
df = pd.read_csv(player_stats_file)
print(f"   Found {len(df)} rows")
print(f"   Columns: {list(df.columns)}")

season_id = get_or_create_season("2024/2025")

for _, row in df.iterrows():
    cursor.execute("SELECT player_id FROM players WHERE player_name = %s", (safe_str(row['player_name']),))
    result    = cursor.fetchone()
    player_id = result[0] if result else None

    cursor.execute("""
        INSERT INTO player_stats
            (player_id, season_id, appearances, minutes_played, goals, assists,
             xg, xa, shots, shots_on_target, pass_accuracy,
             yellow_cards, red_cards, fouls, tackles, interceptions,
             blocks, clearances, aerial_duels_won,
             dribbles_attempted, dribbles_completed,
             preferred_foot, long_passes, crosses, offsides,
             penalties_scored, clean_sheets)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
    """, (
        player_id, season_id,
        safe_int(row.get('appearances',         row.get('sub_appearances', 0))),
        safe_int(row.get('Minutes Played',       0)),
        safe_int(row.get('Goals',                0)),
        safe_int(row.get('Assists',              0)),
        safe_float(row.get('XG',                 0)),
        safe_float(row.get('XA',                 0)),
        safe_int(row.get('Shots On Target',      0)),
        safe_int(row.get('Shots On Target',      0)),
        safe_float(row.get('pass_accuracy',      0)),
        safe_int(row.get('Yellow Cards',         0)),
        safe_int(row.get('Red Cards',            0)),
        safe_int(row.get('Fouls',                0)),
        safe_int(row.get('Total Tackles',        0)),
        safe_int(row.get('Interceptions',        0)),
        safe_int(row.get('Blocks',               0)),
        safe_int(row.get('Clearances',           0)),
        safe_int(row.get('Aerial Duels Won',     0)),
        safe_int(row.get('dribble_attempts',     0)),
        safe_int(row.get('dribble_accuracy',     0)),
        safe_str(row.get('Preferred Foot',       None)),
        safe_int(row.get('long_pass_accuracy',   0)),
        safe_int(row.get('Corners Taken',        0)),
        safe_int(row.get('Offsides',             0)),
        safe_int(row.get('Penalties Taken',      0)),
        safe_int(row.get('Clean Sheets',         0)),
    ))

conn.commit()
print("✅ Player Stats imported!")

# ============================================
# DONE
# ============================================
cursor.close()
conn.close()
print("\n🎉 ALL DATA IMPORTED SUCCESSFULLY!")
print("Go back to pgAdmin and check your tables!")