use crate::models::{AppSettings, AudioDeviceInfo, HistoryEntry};
use crate::AppStateManager;
use base64::Engine;
use tauri::{Emitter, Manager, State};

// ── Audio Commands ────────────────────────────────────────────

#[tauri::command]
pub fn list_audio_devices() -> Result<Vec<AudioDeviceInfo>, String> {
    crate::audio::AudioCapture::list_devices().map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_mic_level(state: State<'_, AppStateManager>) -> f32 {
    state.audio.lock().unwrap().get_mic_level()
}

// ── Transcription Commands ────────────────────────────────────

#[tauri::command]
pub fn start_listening(
    state: State<'_, AppStateManager>,
    app_handle: tauri::AppHandle,
) -> Result<(), String> {
    let settings = state.db.load_settings().map_err(|e| e.to_string())?;

    // Start audio capture
    state
        .audio
        .lock()
        .unwrap()
        .start(&settings.audio_device)
        .map_err(|e| e.to_string())?;

    // Update state
    {
        let mut app_state = state.app_state.lock().unwrap();
        app_state.is_listening = true;
    }

    // Emit state change event to frontend
    app_handle.emit("listening-state-changed", true).ok();

    // Show overlay window
    if let Some(window) = app_handle.get_webview_window("overlay") {
        window.show().ok();
    }

    log::info!("Started listening");
    Ok(())
}

#[tauri::command]
pub fn stop_listening(
    state: State<'_, AppStateManager>,
    app_handle: tauri::AppHandle,
) -> Result<String, String> {
    // Stop audio capture
    let audio_data = {
        let mut audio = state.audio.lock().unwrap();
        let data = audio.drain_buffer();
        audio.stop();
        data
    };

    // Update state
    {
        let mut app_state = state.app_state.lock().unwrap();
        app_state.is_listening = false;
    }

    // Emit state change
    app_handle.emit("listening-state-changed", false).ok();

    // If we have audio data, encode it
    if !audio_data.is_empty() {
        let bytes: Vec<u8> = audio_data
            .iter()
            .flat_map(|f| f.to_le_bytes())
            .collect();
        let encoded = base64::engine::general_purpose::STANDARD.encode(&bytes);
        log::info!(
            "Captured {} samples ({} bytes)",
            audio_data.len(),
            bytes.len()
        );
        return Ok(encoded);
    }

    Ok(String::new())
}

#[tauri::command]
pub fn inject_text(text: String, method: String) -> Result<(), String> {
    // Process dictation commands first
    let processed = crate::injection::process_dictation_commands(&text);
    crate::injection::inject_text(&processed, &method).map_err(|e| e.to_string())
}

// ── Settings Commands ─────────────────────────────────────────

#[tauri::command]
pub fn get_settings(state: State<'_, AppStateManager>) -> Result<AppSettings, String> {
    state.db.load_settings().map_err(|e| e.to_string())
}

#[tauri::command]
pub fn save_settings(
    state: State<'_, AppStateManager>,
    settings: AppSettings,
) -> Result<(), String> {
    state
        .db
        .save_settings(&settings)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn update_setting(
    state: State<'_, AppStateManager>,
    key: String,
    value: String,
) -> Result<(), String> {
    state
        .db
        .save_setting(&key, &value)
        .map_err(|e| e.to_string())
}

// ── History Commands ──────────────────────────────────────────

#[tauri::command]
pub fn get_history(
    state: State<'_, AppStateManager>,
    limit: i64,
    offset: i64,
) -> Result<Vec<HistoryEntry>, String> {
    state
        .db
        .get_history(limit, offset)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn search_history(
    state: State<'_, AppStateManager>,
    query: String,
    limit: i64,
) -> Result<Vec<HistoryEntry>, String> {
    state
        .db
        .search_history(&query, limit)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn add_history_entry(
    state: State<'_, AppStateManager>,
    entry: HistoryEntry,
) -> Result<i64, String> {
    state.db.add_history(&entry).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn delete_history_entry(state: State<'_, AppStateManager>, id: i64) -> Result<(), String> {
    state
        .db
        .delete_history_entry(id)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn clear_history(state: State<'_, AppStateManager>) -> Result<(), String> {
    state.db.clear_history().map_err(|e| e.to_string())
}

// ── App State Commands ────────────────────────────────────────

#[tauri::command]
pub fn get_app_state(state: State<'_, AppStateManager>) -> crate::models::AppState {
    state.app_state.lock().unwrap().clone()
}

#[tauri::command]
pub fn is_first_run(state: State<'_, AppStateManager>) -> bool {
    // Check if settings have been saved before
    state
        .db
        .load_settings()
        .map(|s| s.hotkey == "CapsLock" && s.model_id == "moonshine-base-en")
        .unwrap_or(true)
}
