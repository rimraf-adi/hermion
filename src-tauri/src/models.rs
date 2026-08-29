use serde::{Deserialize, Serialize};

/// Settings stored in SQLite
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppSettings {
    pub hotkey: String,
    pub mode: InputMode,
    pub model_id: String,
    pub language: String,
    pub audio_device: String,
    pub vad_enabled: bool,
    pub vad_threshold: f64,
    pub auto_punctuation: bool,
    pub llm_enabled: bool,
    pub llm_endpoint: String,
    pub llm_model: String,
    pub llm_prompt: String,
    pub theme: String,
    pub accent_color: String,
    pub inject_method: InjectMethod,
    pub overlay_position: String,
    pub launch_at_login: bool,
    pub noise_suppression: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum InputMode {
    PushToTalk,
    Toggle,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum InjectMethod {
    Keystroke,
    Clipboard,
}

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            hotkey: "CapsLock".to_string(),
            mode: InputMode::PushToTalk,
            model_id: "moonshine-base-en".to_string(),
            language: "en".to_string(),
            audio_device: "default".to_string(),
            vad_enabled: true,
            vad_threshold: 0.5,
            auto_punctuation: true,
            llm_enabled: false,
            llm_endpoint: "http://localhost:11434".to_string(),
            llm_model: "llama3".to_string(),
            llm_prompt: "Fix grammar and punctuation. Remove filler words. Output only the corrected text.".to_string(),
            theme: "dark".to_string(),
            accent_color: "#7c3aed".to_string(),
            inject_method: InjectMethod::Clipboard,
            overlay_position: "top-center".to_string(),
            launch_at_login: false,
            noise_suppression: true,
        }
    }
}

/// A transcription history entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HistoryEntry {
    pub id: i64,
    pub text: String,
    pub raw_text: String,
    pub duration_ms: i64,
    pub latency_ms: i64,
    pub confidence: f64,
    pub model_id: String,
    pub language: String,
    pub created_at: String,
    pub app_context: String,
}

/// Messages sent from Tauri → Sidecar
#[allow(dead_code)]
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum SidecarCommand {
    Start {
        config: SidecarConfig,
    },
    Audio {
        data: String, // base64-encoded PCM f32 16kHz mono
        timestamp_ms: u64,
    },
    Stop,
    Shutdown,
}

#[allow(dead_code)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SidecarConfig {
    pub model: String,
    pub language: String,
    pub vad_threshold: f64,
}

/// Messages sent from Sidecar → Tauri
#[allow(dead_code)]
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum SidecarEvent {
    Partial {
        text: String,
        is_final: bool,
        latency_ms: u64,
    },
    Final {
        text: String,
        confidence: f64,
        latency_ms: u64,
    },
    Vad {
        is_speech: bool,
    },
    Status {
        model_loaded: bool,
        gpu_available: bool,
        memory_mb: u64,
    },
    Error {
        message: String,
    },
    Ready,
}

/// Audio device info for the frontend
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AudioDeviceInfo {
    pub name: String,
    pub is_default: bool,
    pub sample_rate: u32,
    pub channels: u16,
}

/// Current app state sent to frontend
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppState {
    pub is_listening: bool,
    pub is_sidecar_ready: bool,
    pub current_model: String,
    pub mic_level: f32,
}
