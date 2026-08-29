use serde::{Deserialize, Serialize};

/// Messages received from Tauri (stdin)
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum IncomingMessage {
    Start { config: SidecarConfig },
    Audio { data: String, timestamp_ms: u64 },
    Stop,
    Shutdown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SidecarConfig {
    pub model: String,
    pub language: String,
    pub vad_threshold: f64,
}

/// Messages sent to Tauri (stdout)
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum OutgoingMessage {
    Ready,
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
}
