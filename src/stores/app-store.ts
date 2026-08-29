import { createSignal } from "solid-js";
import type { AppSettings } from "../lib/tauri-bridge";

// ── Transcription State ──────────────────────────────────────

const [isListening, setIsListening] = createSignal(false);
const [partialText, setPartialText] = createSignal("");
const [finalText, setFinalText] = createSignal("");
const [isSidecarReady, setIsSidecarReady] = createSignal(false);

export {
  isListening,
  setIsListening,
  partialText,
  setPartialText,
  finalText,
  setFinalText,
  isSidecarReady,
  setIsSidecarReady,
};

// ── Audio State ──────────────────────────────────────────────

const [micLevel, setMicLevel] = createSignal(0);
const [isVadSpeech, setIsVadSpeech] = createSignal(false);
const [audioDevices, setAudioDevices] = createSignal<string[]>([]);

export {
  micLevel,
  setMicLevel,
  isVadSpeech,
  setIsVadSpeech,
  audioDevices,
  setAudioDevices,
};

// ── Settings State ───────────────────────────────────────────

const defaultSettings: AppSettings = {
  hotkey: "CapsLock",
  mode: "push_to_talk",
  model_id: "moonshine-base-en",
  language: "en",
  audio_device: "default",
  vad_enabled: true,
  vad_threshold: 0.5,
  auto_punctuation: true,
  llm_enabled: false,
  llm_endpoint: "http://localhost:11434",
  llm_model: "llama3",
  llm_prompt: "Fix grammar and punctuation. Remove filler words. Output only the corrected text.",
  theme: "dark",
  accent_color: "#7c3aed",
  inject_method: "clipboard",
  overlay_position: "top-center",
  launch_at_login: false,
  noise_suppression: true,
};

const [settings, setSettings] = createSignal<AppSettings>(defaultSettings);

export { settings, setSettings };

// ── Navigation State ─────────────────────────────────────────

export type View = "home" | "settings" | "history" | "onboarding";
const [currentView, setCurrentView] = createSignal<View>("home");

export { currentView, setCurrentView };
