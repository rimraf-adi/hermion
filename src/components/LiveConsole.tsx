import { Component, createSignal, onMount, onCleanup, For, Show } from "solid-js";
import { listen } from "@tauri-apps/api/event";
import { getSidecarStatus, restartSidecar, type AppLogEntry, type SidecarStatusInfo } from "../lib/tauri-bridge";

const LiveConsole: Component = () => {
  const [logs, setLogs] = createSignal<AppLogEntry[]>([
    {
      timestamp: new Date().toLocaleTimeString(),
      category: "SYSTEM",
      message: "Live telemetry console initialized",
      level: "info",
    },
  ]);
  const [sidecarStatus, setSidecarStatus] = createSignal<SidecarStatusInfo | null>(null);
  const [isRestarting, setIsRestarting] = createSignal(false);
  let logContainerRef: HTMLDivElement | undefined;

  const refreshStatus = async () => {
    try {
      const status = await getSidecarStatus();
      setSidecarStatus(status);
    } catch {
      // ignore
    }
  };

  onMount(async () => {
    await refreshStatus();

    // Poll status periodically
    const interval = setInterval(refreshStatus, 2000);

    // Listen for live app logs emitted from Rust backend
    const unlistenLog = await listen("app-log", (event) => {
      const entry = event.payload as AppLogEntry;
      setLogs((prev) => [...prev.slice(-150), entry]);

      // Auto-scroll to bottom
      if (logContainerRef) {
        logContainerRef.scrollTop = logContainerRef.scrollHeight;
      }
    });

    onCleanup(() => {
      clearInterval(interval);
      unlistenLog();
    });
  });

  const handleRestartSidecar = async () => {
    setIsRestarting(true);
    try {
      await restartSidecar();
      await refreshStatus();
    } catch (err) {
      console.error("Restart error:", err);
    } finally {
      setIsRestarting(false);
    }
  };

  const handleClearLogs = () => {
    setLogs([]);
  };

  const getBadgeClass = (category: string) => {
    switch (category) {
      case "AUDIO":
        return "badge-audio";
      case "SIDECAR":
      case "STATUS":
        return "badge-sidecar";
      case "ASR_PARTIAL":
      case "ASR_FINAL":
        return "badge-asr";
      case "INJECT":
        return "badge-inject";
      default:
        return "badge-system";
    }
  };

  return (
    <div class="console-card">
      <div class="console-header">
        <div class="flex items-center gap-2">
          <div class={`status-dot ${sidecarStatus()?.is_ready ? "ready" : "initializing"}`} />
          <span class="text-xs font-semibold text-primary">Live Logs & Telemetry</span>
          <Show when={sidecarStatus()?.pid}>
            <span class="text-xs text-muted text-mono">PID: {sidecarStatus()?.pid}</span>
          </Show>
        </div>

        <div class="flex items-center gap-1">
          <button
            class="btn btn-ghost btn-sm text-xs"
            onClick={handleRestartSidecar}
            disabled={isRestarting()}
            title="Restart Sidecar Process"
          >
            {isRestarting() ? "Restarting..." : "Restart"}
          </button>
          <button
            class="btn btn-ghost btn-sm text-xs"
            onClick={handleClearLogs}
            title="Clear Log Screen"
          >
            Clear
          </button>
        </div>
      </div>

      <div class="console-logs" ref={logContainerRef}>
        <For each={logs()}>
          {(log) => (
            <div class={`log-line log-${log.level}`}>
              <span class="log-time">{log.timestamp}</span>
              <span class={`log-category ${getBadgeClass(log.category)}`}>
                {log.category}
              </span>
              <span class="log-msg">{log.message}</span>
            </div>
          )}
        </For>
      </div>

      <style>{`
        .console-card {
          display: flex;
          flex-direction: column;
          width: 100%;
          background: #09090d;
          border: 1px solid rgba(255, 255, 255, 0.1);
          border-radius: var(--radius-md);
          overflow: hidden;
          font-family: var(--font-mono);
          font-size: 11px;
          margin-top: 4px;
        }

        .console-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 6px 10px;
          background: #111118;
          border-bottom: 1px solid rgba(255, 255, 255, 0.08);
        }

        .console-logs {
          height: 120px;
          overflow-y: auto;
          padding: 6px 8px;
          display: flex;
          flex-direction: column;
          gap: 3px;
          line-height: 1.4;
          background: #060609;
        }

        .log-line {
          display: flex;
          align-items: flex-start;
          gap: 6px;
          word-break: break-all;
        }

        .log-time {
          color: #71717a;
          flex-shrink: 0;
          font-size: 10px;
        }

        .log-category {
          padding: 1px 4px;
          border-radius: 3px;
          font-size: 9px;
          font-weight: 600;
          flex-shrink: 0;
          letter-spacing: 0.03em;
        }

        .badge-audio { background: rgba(59, 130, 246, 0.2); color: #60a5fa; }
        .badge-sidecar { background: rgba(168, 85, 247, 0.2); color: #c084fc; }
        .badge-asr { background: rgba(34, 197, 94, 0.2); color: #4ade80; }
        .badge-inject { background: rgba(244, 63, 94, 0.2); color: #fb7185; }
        .badge-system { background: rgba(113, 113, 122, 0.2); color: #a1a1aa; }

        .log-msg {
          color: #e4e4e7;
          flex: 1;
        }

        .log-info .log-msg { color: #d4d4d8; }
        .log-success .log-msg { color: #4ade80; }
        .log-warn .log-msg { color: #facc15; }
        .log-error .log-msg { color: #f87171; }
        .log-debug .log-msg { color: #a1a1aa; }

        .status-dot.initializing {
          background: #eab308;
          box-shadow: 0 0 8px rgba(234, 179, 8, 0.5);
        }
      `}</style>
    </div>
  );
};

export default LiveConsole;
