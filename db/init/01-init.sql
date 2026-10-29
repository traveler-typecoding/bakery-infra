-- Runs once on first container start (empty data directory only).
-- Put schema bootstrapping here. Example:

-- CREATE TABLE IF NOT EXISTS users (
--     id SERIAL PRIMARY KEY,
--     email TEXT UNIQUE NOT NULL,
--     created_at TIMESTAMPTZ NOT NULL DEFAULT now()
-- );

SELECT 'database initialized' AS status;
