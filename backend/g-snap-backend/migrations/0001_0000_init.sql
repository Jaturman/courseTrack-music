-- Migration number: 0001

-- Mejor marca histórica por usuario (1 registro por name).
CREATE TABLE IF NOT EXISTS users (
  name TEXT PRIMARY KEY,
  best_value INTEGER NOT NULL,
  best_ts INTEGER NOT NULL
);

-- Ganadores de mejor valor por periodo (UTC).
CREATE TABLE IF NOT EXISTS winners_day (
  day_key TEXT PRIMARY KEY, -- YYYY-MM-DD
  name TEXT NOT NULL,
  value INTEGER NOT NULL,
  ts INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS winners_month (
  month_key TEXT PRIMARY KEY, -- YYYY-MM
  name TEXT NOT NULL,
  value INTEGER NOT NULL,
  ts INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS winners_year (
  year_key TEXT PRIMARY KEY, -- YYYY
  name TEXT NOT NULL,
  value INTEGER NOT NULL,
  ts INTEGER NOT NULL
);
