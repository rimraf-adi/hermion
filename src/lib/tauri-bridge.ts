import { invoke } from "@tauri-apps/api/core";

// ── Audio ────────────────────────────────────────────────────

export interface AudioDeviceInfo {
  name: string;
  is_default: boolean;
  sample_rate: number;
  channels: number;
}

export async function listAudioDevices(): Promise<AudioDeviceInfo[]> {
  return invoke("list_audio_devices");
}

export async function getMicLevel(): Promise<number> {
  return invoke("get_mic_level");
}

// ── Transcription ────────────────────────────────────────────

export async function startListening(): Promise<void> {
  return invoke("start_listening");
}

export async function stopListening(): Promise<string> {
  return invoke("stop_listening");
}

export async function injectText(text: string, method: string): Promise<void> {
  return invoke("inject_text", { text, method });
}

// ── Settings ─────────────────────────────────────────────────

export interface AppSettings {
  hotkey: string;
  mode: "push_to_talk" | "toggle";
  model_id: string;
  language: string;
  audio_device: string;
  vad_enabled: boolean;
  vad_threshold: number;
  auto_punctuation: boolean;
  llm_enabled: boolean;
  llm_endpoint: string;
  llm_model: string;
  llm_prompt: string;
  theme: string;
  accent_color: string;
  inject_method: "keystroke" | "clipboard";
  overlay_position: string;
  launch_at_login: boolean;
  noise_suppression: boolean;
}

export async function getSettings(): Promise<AppSettings> {
  return invoke("get_settings");
}

export async function saveSettings(settings: AppSettings): Promise<void> {
  return invoke("save_settings", { settings });
}

export async function updateSetting(key: string, value: string): Promise<void> {
  return invoke("update_setting", { key, value });
}

// ── History ──────────────────────────────────────────────────

export interface HistoryEntry {
  id: number;
  text: string;
  raw_text: string;
  duration_ms: number;
  latency_ms: number;
  confidence: number;
  model_id: string;
  language: string;
  created_at: string;
  app_context: string;
}

export async function getHistory(limit: number = 50, offset: number = 0): Promise<HistoryEntry[]> {
  return invoke("get_history", { limit, offset });
}

export async function searchHistory(query: string, limit: number = 50): Promise<HistoryEntry[]> {
  return invoke("search_history", { query, limit });
}

export async function addHistoryEntry(entry: HistoryEntry): Promise<number> {
  return invoke("add_history_entry", { entry });
}

export async function deleteHistoryEntry(id: number): Promise<void> {
  return invoke("delete_history_entry", { id });
}

export async function clearHistory(): Promise<void> {
  return invoke("clear_history");
}

// ── App State ────────────────────────────────────────────────

export interface AppState {
  is_listening: boolean;
  is_sidecar_ready: boolean;
  current_model: string;
  mic_level: number;
}

export async function getAppState(): Promise<AppState> {
  return invoke("get_app_state");
}

export async function isFirstRun(): Promise<boolean> {
  return invoke("is_first_run");
}
