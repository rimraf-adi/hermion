import { Component, Show } from "solid-js";
import {
  isListening,
  setIsListening,
  partialText,
  finalText,
  setPartialText,
  setFinalText,
  isSidecarReady,
  micLevel,
  setMicLevel,
  settings,
} from "../stores/app-store";
import { startListening, stopListening, injectText, getMicLevel } from "../lib/tauri-bridge";
import Waveform from "./Waveform";

const MicIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z" />
    <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
    <line x1="12" x2="12" y1="19" y2="22" />
  </svg>
);

const StopIcon = () => (
  <svg viewBox="0 0 24 24" fill="currentColor">
    <rect x="6" y="6" width="12" height="12" rx="2" />
  </svg>
);

const HomeView: Component = () => {
  let micLevelInterval: number | undefined;

  const handleToggleListening = async () => {
    if (isListening()) {
      // Stop listening
      try {
        const audioData = await stopListening();
        if (micLevelInterval) {
          clearInterval(micLevelInterval);
          micLevelInterval = undefined;
        }
        setIsListening(false);
        setMicLevel(0);

        // The final text will come from the sidecar event
        // For now, set a placeholder
        const text = finalText() || partialText();
        if (text && text.length > 0 && !text.startsWith("[")) {
          await injectText(text, settings().inject_method);
        }
        setPartialText("");
      } catch (err) {
        console.error("Failed to stop listening:", err);
      }
    } else {
      // Start listening
      try {
        await startListening();
        setIsListening(true);
        setFinalText("");
        setPartialText("");

        // Poll mic level for visualization
        micLevelInterval = window.setInterval(async () => {
          try {
            const level = await getMicLevel();
            setMicLevel(level);
          } catch {
            // ignore
          }
        }, 50);
      } catch (err) {
        console.error("Failed to start listening:", err);
      }
    }
  };

  return (
    <div class="home-container">
      {/* Hero Section */}
      <div class="home-hero">
        <div class="home-brand">
          <h1 class="text-gradient" style={{ "font-size": "var(--text-2xl)", "font-weight": "var(--weight-extrabold)" }}>
            Hermion
          </h1>
          <p class="text-muted text-sm" style={{ "margin-top": "var(--space-1)" }}>
            Voice Keyboard — Powered by Moonshine
          </p>
        </div>
      </div>

      {/* Mic Button */}
      <div class="home-mic-section">
        <button
          class={`mic-button ${isListening() ? "active" : ""}`}
          onClick={handleToggleListening}
          id="mic-toggle-btn"
        >
          <Show when={isListening()}>
            <div class="pulse-ring" />
          </Show>
          <Show when={isListening()} fallback={<MicIcon />}>
            <StopIcon />
          </Show>
        </button>

        <div class="home-mic-label">
          <Show
            when={isListening()}
            fallback={
              <p class="text-muted text-sm">
                Press <kbd class="kbd">F5</kbd> or click to start
              </p>
            }
          >
            <p class="text-sm" style={{ color: "var(--color-accent)" }}>
              Listening...
            </p>
          </Show>
        </div>
      </div>

      {/* Waveform */}
      <div class="home-waveform">
        <Waveform />
      </div>

      {/* Transcript */}
      <div class="transcript-area">
        <Show
          when={partialText() || finalText()}
          fallback={
            <div class="transcript-placeholder">
              Your transcription will appear here
            </div>
          }
        >
          <Show when={finalText()}>
            <span>{finalText()}</span>
          </Show>
          <Show when={partialText()}>
            <span class="partial">{partialText()}</span>
          </Show>
          <Show when={isListening()}>
            <span class="cursor" />
          </Show>
        </Show>
      </div>

      {/* Status Bar */}
      <div class="home-status">
        <div class="flex items-center gap-2">
          <div class={`status-dot ${isSidecarReady() ? "ready" : ""} ${isListening() ? "listening" : ""}`} />
          <span class="text-xs text-muted">
            {isListening() ? "Recording" : isSidecarReady() ? "Ready" : "Initializing..."}
          </span>
        </div>
        <span class="text-xs text-muted text-mono">
          {settings().model_id}
        </span>
      </div>

      <style>{`
        .home-container {
          display: flex;
          flex-direction: column;
          align-items: center;
          padding: var(--space-6) var(--space-5);
          gap: var(--space-5);
          height: 100%;
        }

        .home-hero {
          text-align: center;
        }

        .home-mic-section {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: var(--space-4);
        }

        .home-mic-label {
          text-align: center;
        }

        .kbd {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          min-width: 28px;
          padding: 2px 8px;
          font-family: var(--font-mono);
          font-size: var(--text-xs);
          font-weight: var(--weight-medium);
          color: var(--color-text-secondary);
          background: var(--color-surface);
          border: 1px solid var(--color-border);
          border-radius: var(--radius-sm);
          box-shadow: 0 1px 0 var(--color-border);
        }

        .home-waveform {
          width: 100%;
          max-width: 320px;
        }

        .home-status {
          display: flex;
          align-items: center;
          justify-content: space-between;
          width: 100%;
          padding: var(--space-3) var(--space-4);
          background: var(--color-bg-secondary);
          border-radius: var(--radius-md);
          border: 1px solid var(--color-border-subtle);
          margin-top: auto;
        }
      `}</style>
    </div>
  );
};

export default HomeView;
