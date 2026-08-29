import { Component, Match, onMount, Switch } from "solid-js";
import { listen } from "@tauri-apps/api/event";
import {
  currentView,
  setCurrentView,
  setIsListening,
  setPartialText,
  setFinalText,
  setIsSidecarReady,
  setIsVadSpeech,
} from "./stores/app-store";
import HomeView from "./components/HomeView";
import SettingsView from "./components/SettingsView";
import HistoryView from "./components/HistoryView";
import Onboarding from "./components/Onboarding";
import OverlayView from "./components/OverlayView";
import { isFirstRun, getSettings, injectText, addHistoryEntry, startListening, stopListening } from "./lib/tauri-bridge";
import "./styles/index.css";

const MicNavIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z" />
    <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
    <line x1="12" x2="12" y1="19" y2="22" />
  </svg>
);

const HistoryNavIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="12" cy="12" r="10" />
    <polyline points="12 6 12 12 16 14" />
  </svg>
);

const SettingsNavIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z" />
    <circle cx="12" cy="12" r="3" />
  </svg>
);

const App: Component = () => {
  const isOverlay = window.location.hash.includes("overlay");

  onMount(async () => {
    if (isOverlay) return;

    // Check if first run
    try {
      const firstRun = await isFirstRun();
      if (firstRun) {
        setCurrentView("onboarding");
      }
    } catch {
      // Fallback — show home
    }

    // Listen for Tauri events
    listen("listening-state-changed", (event) => {
      setIsListening(event.payload as boolean);
    });

    listen("transcription-partial", (event) => {
      setPartialText(event.payload as string);
    });

    listen("transcription-final", async (event) => {
      const text = event.payload as string;
      setFinalText(text);
      setPartialText("");

      if (text && text.trim() && !text.startsWith("[")) {
        try {
          const appSettings = await getSettings();
          await injectText(text, appSettings.inject_method);
          await addHistoryEntry({
            id: 0,
            text,
            raw_text: text,
            duration_ms: 0,
            latency_ms: 0,
            confidence: 0.95,
            model_id: appSettings.model_id,
            language: appSettings.language,
            created_at: new Date().toISOString(),
            app_context: "active-window",
          });
        } catch (err) {
          console.error("Auto-inject or history save failed:", err);
        }
      }
    });

    listen("sidecar-ready", (event) => {
      setIsSidecarReady(event.payload as boolean);
    });

    listen("vad-speech", (event) => {
      setIsVadSpeech(event.payload as boolean);
    });

    listen("hotkey-pressed", async (event) => {
      const pressed = event.payload as boolean;
      const appSettings = await getSettings();
      if (appSettings.mode === "push_to_talk") {
        if (pressed && !isListening()) {
          await startListening();
        } else if (!pressed && isListening()) {
          await stopListening();
        }
      } else {
        // Toggle mode: toggle on key press
        if (pressed) {
          if (isListening()) {
            await stopListening();
          } else {
            await startListening();
          }
        }
      }
    });

    listen("toggle-listening", async () => {
      if (isListening()) {
        await stopListening();
      } else {
        await startListening();
      }
    });

    listen("navigate", (event) => {
      const view = event.payload as string;
      if (view === "settings") setCurrentView("settings");
      else if (view === "history") setCurrentView("history");
      else setCurrentView("home");
    });
  });

  if (isOverlay) {
    return <OverlayView />;
  }

  return (
    <div class="app-container">
      <Switch>
        <Match when={currentView() === "onboarding"}>
          <Onboarding />
        </Match>

        <Match when={currentView() !== "onboarding"}>
          {/* Main App Layout */}
          <div class="app-header">
            <div class="flex items-center gap-2">
              <span
                class="text-gradient"
                style={{
                  "font-weight": "var(--weight-bold)",
                  "font-size": "var(--text-base)",
                  "letter-spacing": "-0.02em",
                }}
              >
                hermion
              </span>
            </div>
            <div class="flex items-center gap-1">
              <span class="badge badge-success">
                <span class="status-dot ready" style={{ width: "6px", height: "6px" }} />
                Offline
              </span>
            </div>
          </div>

          <div class="app-content">
            <Switch>
              <Match when={currentView() === "home"}>
                <HomeView />
              </Match>
              <Match when={currentView() === "settings"}>
                <SettingsView />
              </Match>
              <Match when={currentView() === "history"}>
                <HistoryView />
              </Match>
            </Switch>
          </div>

          {/* Bottom Navigation */}
          <div class="app-footer">
            <div class="nav-tabs">
              <button
                class={`nav-tab ${currentView() === "home" ? "active" : ""}`}
                onClick={() => setCurrentView("home")}
                id="nav-home"
              >
                <div class="flex flex-col items-center gap-1">
                  <MicNavIcon />
                  <span class="text-xs">Voice</span>
                </div>
              </button>
              <button
                class={`nav-tab ${currentView() === "history" ? "active" : ""}`}
                onClick={() => setCurrentView("history")}
                id="nav-history"
              >
                <div class="flex flex-col items-center gap-1">
                  <HistoryNavIcon />
                  <span class="text-xs">History</span>
                </div>
              </button>
              <button
                class={`nav-tab ${currentView() === "settings" ? "active" : ""}`}
                onClick={() => setCurrentView("settings")}
                id="nav-settings"
              >
                <div class="flex flex-col items-center gap-1">
                  <SettingsNavIcon />
                  <span class="text-xs">Settings</span>
                </div>
              </button>
            </div>
          </div>
        </Match>
      </Switch>
    </div>
  );
};

export default App;
