import { Component, createSignal, For, onMount, Show } from "solid-js";
import {
  getHistory,
  searchHistory,
  deleteHistoryEntry,
  clearHistory,
  injectText,
  type HistoryEntry,
} from "../lib/tauri-bridge";
import { settings } from "../stores/app-store";

const ClockIcon = () => (
  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="12" cy="12" r="10" />
    <polyline points="12 6 12 12 16 14" />
  </svg>
);

const CopyIcon = () => (
  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <rect width="14" height="14" x="8" y="8" rx="2" />
    <path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2" />
  </svg>
);

const TrashIcon = () => (
  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M3 6h18" />
    <path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6" />
    <path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2" />
  </svg>
);

const InjectIcon = () => (
  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M5 12h14" />
    <path d="m12 5 7 7-7 7" />
  </svg>
);

const HistoryView: Component = () => {
  const [entries, setEntries] = createSignal<HistoryEntry[]>([]);
  const [searchQuery, setSearchQuery] = createSignal("");
  const [isLoading, setIsLoading] = createSignal(true);

  onMount(() => loadHistory());

  const loadHistory = async () => {
    setIsLoading(true);
    try {
      const data = await getHistory(100, 0);
      setEntries(data);
    } catch (err) {
      console.error("Failed to load history:", err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSearch = async (query: string) => {
    setSearchQuery(query);
    try {
      if (query.trim()) {
        const results = await searchHistory(query, 50);
        setEntries(results);
      } else {
        await loadHistory();
      }
    } catch (err) {
      console.error("Search failed:", err);
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await deleteHistoryEntry(id);
      setEntries((prev) => prev.filter((e) => e.id !== id));
    } catch (err) {
      console.error("Delete failed:", err);
    }
  };

  const handleClearAll = async () => {
    try {
      await clearHistory();
      setEntries([]);
    } catch (err) {
      console.error("Clear failed:", err);
    }
  };

  const handleReInject = async (text: string) => {
    try {
      await injectText(text, settings().inject_method);
    } catch (err) {
      console.error("Re-inject failed:", err);
    }
  };

  const formatTime = (dateStr: string): string => {
    try {
      const date = new Date(dateStr);
      const now = new Date();
      const diffMs = now.getTime() - date.getTime();
      const diffMins = Math.floor(diffMs / 60000);

      if (diffMins < 1) return "Just now";
      if (diffMins < 60) return `${diffMins}m ago`;
      if (diffMins < 1440) return `${Math.floor(diffMins / 60)}h ago`;
      return date.toLocaleDateString();
    } catch {
      return dateStr;
    }
  };

  return (
    <div class="history-container">
      <div class="settings-header">
        <h2 style={{ "font-size": "var(--text-lg)" }}>History</h2>
        <Show when={entries().length > 0}>
          <button class="btn btn-ghost btn-sm" onClick={handleClearAll}>
            <TrashIcon /> Clear All
          </button>
        </Show>
      </div>

      {/* Search */}
      <input
        class="input"
        type="text"
        placeholder="Search transcriptions..."
        value={searchQuery()}
        onInput={(e) => handleSearch(e.currentTarget.value)}
        id="history-search"
      />

      {/* List */}
      <div class="history-list">
        <Show when={!isLoading()} fallback={<div class="transcript-placeholder">Loading...</div>}>
          <Show
            when={entries().length > 0}
            fallback={
              <div class="transcript-placeholder">
                {searchQuery() ? "No results found" : "No transcriptions yet"}
              </div>
            }
          >
            <For each={entries()}>
              {(entry) => (
                <div class="history-item animate-slide-up">
                  <div class="flex-col gap-1" style={{ flex: "1", "min-width": "0" }}>
                    <div class="text">{entry.text}</div>
                    <div class="flex items-center gap-2">
                      <span class="meta">
                        <ClockIcon /> {formatTime(entry.created_at)}
                      </span>
                      <Show when={entry.confidence > 0}>
                        <span class="badge">{Math.round(entry.confidence * 100)}%</span>
                      </Show>
                      <Show when={entry.latency_ms > 0}>
                        <span class="meta">{entry.latency_ms}ms</span>
                      </Show>
                    </div>
                  </div>
                  <div class="flex gap-1">
                    <button
                      class="btn btn-ghost btn-icon btn-sm"
                      onClick={() => handleReInject(entry.text)}
                      title="Re-inject text"
                    >
                      <InjectIcon />
                    </button>
                    <button
                      class="btn btn-ghost btn-icon btn-sm"
                      onClick={() => navigator.clipboard.writeText(entry.text)}
                      title="Copy to clipboard"
                    >
                      <CopyIcon />
                    </button>
                    <button
                      class="btn btn-ghost btn-icon btn-sm"
                      onClick={() => handleDelete(entry.id)}
                      title="Delete"
                    >
                      <TrashIcon />
                    </button>
                  </div>
                </div>
              )}
            </For>
          </Show>
        </Show>
      </div>

      <style>{`
        .history-container {
          display: flex;
          flex-direction: column;
          gap: var(--space-4);
        }

        .history-list {
          display: flex;
          flex-direction: column;
          gap: var(--space-1);
        }

        .history-item .meta {
          display: inline-flex;
          align-items: center;
          gap: 4px;
        }
      `}</style>
    </div>
  );
};

export default HistoryView;
