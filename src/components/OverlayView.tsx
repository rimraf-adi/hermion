import { Component, createSignal, onMount, onCleanup, For } from "solid-js";
import { listen } from "@tauri-apps/api/event";
import { getCurrentWebviewWindow } from "@tauri-apps/api/webviewWindow";
import { getMicLevel, stopListening, injectText, getSettings } from "../lib/tauri-bridge";

const NUM_DOTS = 10;

const OverlayView: Component = () => {
  const [micLevel, setMicLevel] = createSignal(0);
  const [dotHeights, setDotHeights] = createSignal<number[]>(Array(NUM_DOTS).fill(4));
  const [isProcessing, setIsProcessing] = createSignal(false);
  let transcript = "";
  let pollInterval: number | undefined;

  onMount(async () => {
    // Poll audio level for live equalizer animation
    pollInterval = window.setInterval(async () => {
      try {
        const lvl = await getMicLevel();
        setMicLevel(lvl);

        // Generate dynamic heights for the center equalizer dots
        const now = Date.now();
        const heights = Array(NUM_DOTS).fill(0).map((_, i) => {
          const wave = Math.sin(now / 150 + i * 0.6) * 0.5 + 0.5;
          const amp = Math.max(lvl * 80, 0);
          const h = 4 + wave * amp * (0.8 + Math.random() * 0.4);
          return Math.min(Math.max(Math.round(h), 4), 20);
        });
        setDotHeights(heights);
      } catch {
        // ignore
      }
    }, 40);

    // Listen for transcription updates
    await listen("transcription-partial", (event) => {
      transcript = event.payload as string;
    });

    await listen("transcription-final", (event) => {
      transcript = event.payload as string;
    });

    await listen("listening-state-changed", (event) => {
      const active = event.payload as boolean;
      if (!active && !isProcessing()) {
        getCurrentWebviewWindow().hide();
      }
    });

    onCleanup(() => {
      if (pollInterval) clearInterval(pollInterval);
    });
  });

  // Handle Cancel (Grey '✕' button)
  const handleCancel = async (e: MouseEvent) => {
    e.stopPropagation();
    try {
      if (pollInterval) clearInterval(pollInterval);
      transcript = "";
      await stopListening();
      const win = getCurrentWebviewWindow();
      await win.hide();
    } catch (err) {
      console.error("Cancel failed:", err);
    }
  };

  // Handle Stop & Inject (Red '■' button)
  const handleStopAndInject = async (e: MouseEvent) => {
    e.stopPropagation();
    try {
      setIsProcessing(true);
      if (pollInterval) clearInterval(pollInterval);
      await stopListening();

      // Brief delay to allow final transcription to settle
      setTimeout(async () => {
        try {
          const settings = await getSettings();
          if (transcript && transcript.trim() && !transcript.startsWith("[")) {
            await injectText(transcript, settings.inject_method);
          }
        } finally {
          setIsProcessing(false);
          const win = getCurrentWebviewWindow();
          await win.hide();
        }
      }, 200);
    } catch (err) {
      console.error("Stop & inject error:", err);
      setIsProcessing(false);
      getCurrentWebviewWindow().hide();
    }
  };

  return (
    <div class="wispr-container">
      <div class="wispr-pill" data-tauri-drag-region>
        {/* Left: Cancel Button (Grey Circle with X) */}
        <button
          class="wispr-btn wispr-cancel-btn"
          onClick={handleCancel}
          title="Cancel dictation"
          aria-label="Cancel"
        >
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round">
            <line x1="18" y1="6" x2="6" y2="18" />
            <line x1="6" y1="6" x2="18" y2="18" />
          </svg>
        </button>

        {/* Center: Live Waveform Dots */}
        <div class="wispr-equalizer" data-tauri-drag-region>
          <For each={dotHeights()}>
            {(height) => (
              <div
                class="wispr-dot"
                style={{ height: `${height}px` }}
              />
            )}
          </For>
        </div>

        {/* Right: Record/Stop Button (Coral Circle with White Square) */}
        <button
          class="wispr-btn wispr-stop-btn"
          onClick={handleStopAndInject}
          title="Finish and paste text"
          aria-label="Stop and Insert"
        >
          <div class="wispr-stop-icon" />
        </button>
      </div>

      <style>{`
        * {
          box-sizing: border-box;
          margin: 0;
          padding: 0;
          user-select: none;
          -webkit-user-select: none;
        }

        html, body {
          background: transparent !important;
          width: 100vw;
          height: 100vh;
          overflow: hidden;
          display: flex;
          align-items: center;
          justify-content: center;
          margin: 0;
          padding: 0;
        }

        .wispr-container {
          display: flex;
          align-items: center;
          justify-content: center;
          width: 100%;
          height: 100%;
        }

        .wispr-pill {
          display: flex;
          align-items: center;
          justify-content: space-between;
          width: 172px;
          height: 40px;
          padding: 4px 6px;
          background: #0d0d11;
          border-radius: 9999px;
          border: 1px solid rgba(255, 255, 255, 0.14);
          box-shadow: 0 10px 30px rgba(0, 0, 0, 0.75), 0 0 1px rgba(255, 255, 255, 0.2);
          cursor: grab;
          -webkit-app-region: drag;
          transition: transform 0.12s ease;
        }

        .wispr-pill:active {
          cursor: grabbing;
        }

        .wispr-btn {
          display: flex;
          align-items: center;
          justify-content: center;
          width: 30px;
          height: 30px;
          border-radius: 50%;
          border: none;
          cursor: pointer;
          -webkit-app-region: no-drag;
          transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
          flex-shrink: 0;
        }

        /* Cancel Button: Matte grey circle with white X */
        .wispr-cancel-btn {
          background: #3f3f46;
          color: #f4f4f5;
        }

        .wispr-cancel-btn:hover {
          background: #52525b;
          transform: scale(1.08);
        }

        .wispr-cancel-btn:active {
          transform: scale(0.94);
        }

        /* Stop Button: Coral red circle with centered white square */
        .wispr-stop-btn {
          background: #ef4444;
          box-shadow: 0 0 12px rgba(239, 68, 68, 0.45);
        }

        .wispr-stop-btn:hover {
          background: #f87171;
          box-shadow: 0 0 16px rgba(239, 68, 68, 0.65);
          transform: scale(1.08);
        }

        .wispr-stop-btn:active {
          transform: scale(0.94);
        }

        .wispr-stop-icon {
          width: 9px;
          height: 9px;
          background: #ffffff;
          border-radius: 2px;
        }

        /* Center Equalizer: Clean white audio dots/bars */
        .wispr-equalizer {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 3.5px;
          height: 22px;
          padding: 0 4px;
          -webkit-app-region: drag;
        }

        .wispr-dot {
          width: 3.5px;
          background: #ffffff;
          border-radius: 99px;
          transition: height 0.05s ease-out;
          min-height: 3.5px;
        }
      `}</style>
    </div>
  );
};

export default OverlayView;
