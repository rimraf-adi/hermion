import { Component, createSignal, onMount, Show } from "solid-js";
import { listen } from "@tauri-apps/api/event";
import { getCurrentWebviewWindow } from "@tauri-apps/api/webviewWindow";
import { getMicLevel, stopListening, injectText, getSettings } from "../lib/tauri-bridge";

const OverlayView: Component = () => {
  const [isListening, setIsListening] = createSignal(true);
  const [transcript, setTranscript] = createSignal("");
  const [micLevel, setMicLevel] = createSignal(0);

  let pollInterval: number | undefined;

  onMount(async () => {
    // Start polling audio level while overlay is open
    pollInterval = window.setInterval(async () => {
      try {
        const lvl = await getMicLevel();
        setMicLevel(lvl);
      } catch {
        // ignore
      }
    }, 50);

    // Listen for transcription events
    await listen("transcription-partial", (event) => {
      setTranscript(event.payload as string);
    });

    await listen("transcription-final", (event) => {
      setTranscript(event.payload as string);
    });

    await listen("listening-state-changed", (event) => {
      const active = event.payload as boolean;
      setIsListening(active);
      if (!active) {
        // Auto-hide after brief delay
        setTimeout(() => {
          getCurrentWebviewWindow().hide();
        }, 1200);
      }
    });
  });

  const handleStopAndInject = async () => {
    try {
      if (pollInterval) clearInterval(pollInterval);
      await stopListening();
      const settings = await getSettings();
      const current = transcript();
      if (current && !current.startsWith("[")) {
        await injectText(current, settings.inject_method);
      }
      const window = getCurrentWebviewWindow();
      await window.hide();
    } catch (err) {
      console.error("Overlay stop error:", err);
    }
  };

  return (
    <div class="overlay-pill animate-fade-in">
      <div class="overlay-left">
        <div class={`overlay-indicator ${isListening() ? "recording" : "done"}`} />
        <div class="overlay-bars">
          <div
            class="mini-bar"
            style={{ height: `${Math.min(24, Math.max(4, micLevel() * 150))}px` }}
          />
          <div
            class="mini-bar"
            style={{ height: `${Math.min(24, Math.max(4, micLevel() * 220))}px` }}
          />
          <div
            class="mini-bar"
            style={{ height: `${Math.min(24, Math.max(4, micLevel() * 180))}px` }}
          />
        </div>
      </div>

      <div class="overlay-text">
        <Show
          when={transcript()}
          fallback={<span class="placeholder">Listening... speak now</span>}
        >
          <span>{transcript()}</span>
          <Show when={isListening()}>
            <span class="cursor" />
          </Show>
        </Show>
      </div>

      <button
        class="overlay-btn"
        onClick={handleStopAndInject}
        title="Stop and insert"
      >
        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
          <polyline points="20 6 9 17 4 12" />
        </svg>
      </button>

      <style>{`
        body {
          background: transparent !important;
          margin: 0;
          padding: 6px;
          overflow: hidden;
        }

        .overlay-pill {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 8px 16px;
          background: rgba(18, 18, 26, 0.92);
          backdrop-filter: blur(24px);
          -webkit-backdrop-filter: blur(24px);
          border: 1px solid rgba(124, 58, 237, 0.35);
          border-radius: 9999px;
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6), 0 0 24px rgba(124, 58, 237, 0.2);
          color: #f0f0f5;
          font-family: 'Inter', system-ui, sans-serif;
          height: 56px;
          box-sizing: border-box;
          user-select: none;
          -webkit-app-region: drag;
        }

        .overlay-left {
          display: flex;
          align-items: center;
          gap: 8px;
          -webkit-app-region: no-drag;
        }

        .overlay-indicator {
          width: 10px;
          height: 10px;
          border-radius: 50%;
          transition: all 0.2s ease;
        }

        .overlay-indicator.recording {
          background: #7c3aed;
          box-shadow: 0 0 10px #7c3aed, 0 0 20px rgba(124, 58, 237, 0.6);
          animation: pulse 1.5s infinite;
        }

        .overlay-indicator.done {
          background: #22c55e;
          box-shadow: 0 0 10px #22c55e;
        }

        @keyframes pulse {
          0%, 100% { transform: scale(1); opacity: 1; }
          50% { transform: scale(1.25); opacity: 0.8; }
        }

        .overlay-bars {
          display: flex;
          align-items: center;
          gap: 2px;
          height: 24px;
        }

        .mini-bar {
          width: 3px;
          background: #7c3aed;
          border-radius: 99px;
          transition: height 0.06s ease;
        }

        .overlay-text {
          flex: 1;
          font-size: 14px;
          font-weight: 500;
          color: #f0f0f5;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
          min-width: 0;
          -webkit-app-region: no-drag;
        }

        .overlay-text .placeholder {
          color: #8a8aa3;
          font-style: italic;
        }

        .overlay-btn {
          display: flex;
          align-items: center;
          justify-content: center;
          width: 28px;
          height: 28px;
          border-radius: 50%;
          background: #7c3aed;
          color: #ffffff;
          border: none;
          cursor: pointer;
          transition: all 0.15s ease;
          -webkit-app-region: no-drag;
          flex-shrink: 0;
        }

        .overlay-btn:hover {
          background: #8b5cf6;
          transform: scale(1.08);
        }

        .cursor {
          display: inline-block;
          width: 2px;
          height: 14px;
          background: #7c3aed;
          margin-left: 3px;
          vertical-align: middle;
          animation: blink 0.9s infinite;
        }

        @keyframes blink {
          0%, 100% { opacity: 1; }
          50% { opacity: 0; }
        }
      `}</style>
    </div>
  );
};

export default OverlayView;
