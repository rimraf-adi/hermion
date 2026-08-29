use anyhow::Result;
use rusqlite::{params, Connection};
use std::path::PathBuf;
use std::sync::Mutex;

use crate::models::{AppSettings, HistoryEntry, InjectMethod, InputMode};

pub struct Database {
    conn: Mutex<Connection>,
}

impl Database {
    pub fn new(app_dir: PathBuf) -> Result<Self> {
        std::fs::create_dir_all(&app_dir)?;
        let db_path = app_dir.join("hermion.db");
        let conn = Connection::open(db_path)?;

        // Create tables
        conn.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                text TEXT NOT NULL,
                raw_text TEXT NOT NULL DEFAULT '',
                duration_ms INTEGER NOT NULL DEFAULT 0,
                latency_ms INTEGER NOT NULL DEFAULT 0,
                confidence REAL NOT NULL DEFAULT 0.0,
                model_id TEXT NOT NULL DEFAULT '',
                language TEXT NOT NULL DEFAULT 'en',
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                app_context TEXT NOT NULL DEFAULT ''
            );

            CREATE TABLE IF NOT EXISTS vocabulary (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                term TEXT NOT NULL UNIQUE,
                boost REAL NOT NULL DEFAULT 1.0,
                category TEXT NOT NULL DEFAULT 'general'
            );

            CREATE INDEX IF NOT EXISTS idx_history_created_at ON history(created_at);
            ",
        )?;

        Ok(Self {
            conn: Mutex::new(conn),
        })
    }

    // ── Settings ──────────────────────────────────────────────

    pub fn load_settings(&self) -> Result<AppSettings> {
        let conn = self.conn.lock().unwrap();
        let mut settings = AppSettings::default();

        let mut stmt = conn.prepare("SELECT key, value FROM settings")?;
        let rows = stmt.query_map([], |row| {
            Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?))
        })?;

        for row in rows {
            let (key, value) = row?;
            match key.as_str() {
                "hotkey" => settings.hotkey = value,
                "mode" => {
                    settings.mode = if value == "toggle" {
                        InputMode::Toggle
                    } else {
                        InputMode::PushToTalk
                    }
                }
                "model_id" => settings.model_id = value,
                "language" => settings.language = value,
                "audio_device" => settings.audio_device = value,
                "vad_enabled" => settings.vad_enabled = value == "true",
                "vad_threshold" => {
                    settings.vad_threshold = value.parse().unwrap_or(0.5)
                }
                "auto_punctuation" => settings.auto_punctuation = value == "true",
                "llm_enabled" => settings.llm_enabled = value == "true",
                "llm_endpoint" => settings.llm_endpoint = value,
                "llm_model" => settings.llm_model = value,
                "llm_prompt" => settings.llm_prompt = value,
                "theme" => settings.theme = value,
                "accent_color" => settings.accent_color = value,
                "inject_method" => {
                    settings.inject_method = if value == "keystroke" {
                        InjectMethod::Keystroke
                    } else {
                        InjectMethod::Clipboard
                    }
                }
                "overlay_position" => settings.overlay_position = value,
                "launch_at_login" => settings.launch_at_login = value == "true",
                "noise_suppression" => settings.noise_suppression = value == "true",
                _ => {}
            }
        }

        Ok(settings)
    }

    pub fn save_setting(&self, key: &str, value: &str) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute(
            "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
            params![key, value],
        )?;
        Ok(())
    }

    pub fn save_settings(&self, settings: &AppSettings) -> Result<()> {
        let mode = match settings.mode {
            InputMode::PushToTalk => "push_to_talk",
            InputMode::Toggle => "toggle",
        };
        let inject = match settings.inject_method {
            InjectMethod::Keystroke => "keystroke",
            InjectMethod::Clipboard => "clipboard",
        };

        let pairs: Vec<(&str, String)> = vec![
            ("hotkey", settings.hotkey.clone()),
            ("mode", mode.to_string()),
            ("model_id", settings.model_id.clone()),
            ("language", settings.language.clone()),
            ("audio_device", settings.audio_device.clone()),
            ("vad_enabled", settings.vad_enabled.to_string()),
            ("vad_threshold", settings.vad_threshold.to_string()),
            ("auto_punctuation", settings.auto_punctuation.to_string()),
            ("llm_enabled", settings.llm_enabled.to_string()),
            ("llm_endpoint", settings.llm_endpoint.clone()),
            ("llm_model", settings.llm_model.clone()),
            ("llm_prompt", settings.llm_prompt.clone()),
            ("theme", settings.theme.clone()),
            ("accent_color", settings.accent_color.clone()),
            ("inject_method", inject.to_string()),
            ("overlay_position", settings.overlay_position.clone()),
            ("launch_at_login", settings.launch_at_login.to_string()),
            ("noise_suppression", settings.noise_suppression.to_string()),
        ];

        let conn = self.conn.lock().unwrap();
        for (k, v) in pairs {
            conn.execute(
                "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
                params![k, v],
            )?;
        }
        Ok(())
    }

    // ── History ───────────────────────────────────────────────

    pub fn add_history(&self, entry: &HistoryEntry) -> Result<i64> {
        let conn = self.conn.lock().unwrap();
        conn.execute(
            "INSERT INTO history (text, raw_text, duration_ms, latency_ms, confidence, model_id, language, app_context)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
            params![
                entry.text,
                entry.raw_text,
                entry.duration_ms,
                entry.latency_ms,
                entry.confidence,
                entry.model_id,
                entry.language,
                entry.app_context,
            ],
        )?;
        Ok(conn.last_insert_rowid())
    }

    pub fn get_history(&self, limit: i64, offset: i64) -> Result<Vec<HistoryEntry>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, text, raw_text, duration_ms, latency_ms, confidence, model_id, language, created_at, app_context
             FROM history ORDER BY created_at DESC LIMIT ?1 OFFSET ?2",
        )?;

        let entries = stmt
            .query_map(params![limit, offset], |row| {
                Ok(HistoryEntry {
                    id: row.get(0)?,
                    text: row.get(1)?,
                    raw_text: row.get(2)?,
                    duration_ms: row.get(3)?,
                    latency_ms: row.get(4)?,
                    confidence: row.get(5)?,
                    model_id: row.get(6)?,
                    language: row.get(7)?,
                    created_at: row.get(8)?,
                    app_context: row.get(9)?,
                })
            })?
            .collect::<std::result::Result<Vec<_>, _>>()?;

        Ok(entries)
    }

    pub fn search_history(&self, query: &str, limit: i64) -> Result<Vec<HistoryEntry>> {
        let conn = self.conn.lock().unwrap();
        let pattern = format!("%{}%", query);
        let mut stmt = conn.prepare(
            "SELECT id, text, raw_text, duration_ms, latency_ms, confidence, model_id, language, created_at, app_context
             FROM history WHERE text LIKE ?1 ORDER BY created_at DESC LIMIT ?2",
        )?;

        let entries = stmt
            .query_map(params![pattern, limit], |row| {
                Ok(HistoryEntry {
                    id: row.get(0)?,
                    text: row.get(1)?,
                    raw_text: row.get(2)?,
                    duration_ms: row.get(3)?,
                    latency_ms: row.get(4)?,
                    confidence: row.get(5)?,
                    model_id: row.get(6)?,
                    language: row.get(7)?,
                    created_at: row.get(8)?,
                    app_context: row.get(9)?,
                })
            })?
            .collect::<std::result::Result<Vec<_>, _>>()?;

        Ok(entries)
    }

    pub fn delete_history_entry(&self, id: i64) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute("DELETE FROM history WHERE id = ?1", params![id])?;
        Ok(())
    }

    pub fn clear_history(&self) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute("DELETE FROM history", [])?;
        Ok(())
    }
}
