import { Component, createSignal, For, onMount, Show } from "solid-js";
import { settings, setSettings } from "../stores/app-store";
import {
  getSettings,
  saveSettings,
  listAudioDevices,
  type AppSettings,
  type AudioDeviceInfo,
} from "../lib/tauri-bridge";

const SettingsView: Component = () => {
  const [devices, setDevices] = createSignal<AudioDeviceInfo[]>([]);
  const [isSaving, setIsSaving] = createSignal(false);
  const [saveMessage, setSaveMessage] = createSignal("");

  onMount(async () => {
    try {
      const [loadedSettings, loadedDevices] = await Promise.all([
        getSettings(),
        listAudioDevices(),
      ]);
      setSettings(loadedSettings);
      setDevices(loadedDevices);
    } catch (err) {
      console.error("Failed to load settings:", err);
    }
  });

  const updateField = <K extends keyof AppSettings>(key: K, value: AppSettings[K]) => {
    setSettings((prev) => ({ ...prev, [key]: value }));
  };

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await saveSettings(settings());
      setSaveMessage("Settings saved!");
      setTimeout(() => setSaveMessage(""), 2000);
    } catch (err) {
      setSaveMessage("Failed to save");
      console.error(err);
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div class="settings-container">
      <div class="settings-header">
        <h2 style={{ "font-size": "var(--text-lg)" }}>Settings</h2>
        <Show when={saveMessage()}>
          <span class="badge badge-success">{saveMessage()}</span>
        </Show>
      </div>

      {/* ── Input Section ───────────────────────── */}
      <div class="settings-section">
        <div class="section-title">Input</div>
        <div class="card">
          <div class="form-row">
            <div>
              <div class="form-label">Hotkey</div>
              <div class="form-hint">Global shortcut to activate</div>
            </div>
            <div class="kbd" style={{ "font-size": "var(--text-sm)", padding: "6px 14px" }}>
              {settings().hotkey}
            </div>
          </div>

          <div class="form-row">
            <div>
              <div class="form-label">Input Mode</div>
              <div class="form-hint">How the hotkey activates listening</div>
            </div>
            <select
              class="select"
              style={{ width: "160px" }}
              value={settings().mode}
              onChange={(e) => updateField("mode", e.currentTarget.value as "push_to_talk" | "toggle")}
            >
              <option value="push_to_talk">Push to Talk</option>
              <option value="toggle">Toggle</option>
            </select>
          </div>

          <div class="form-row">
            <div>
              <div class="form-label">Microphone</div>
              <div class="form-hint">Audio input device</div>
            </div>
            <select
              class="select"
              style={{ width: "200px" }}
              value={settings().audio_device}
              onChange={(e) => updateField("audio_device", e.currentTarget.value)}
            >
              <option value="default">System Default</option>
              <For each={devices()}>
                {(device) => (
                  <option value={device.name}>
                    {device.name} {device.is_default ? "(Default)" : ""}
                  </option>
                )}
              </For>
            </select>
          </div>

          <div class="form-row">
            <div>
              <div class="form-label">Text Injection</div>
              <div class="form-hint">How text is typed into apps</div>
            </div>
            <select
              class="select"
              style={{ width: "160px" }}
              value={settings().inject_method}
              onChange={(e) => updateField("inject_method", e.currentTarget.value as "keystroke" | "clipboard")}
            >
              <option value="clipboard">Clipboard Paste</option>
              <option value="keystroke">Keystrokes</option>
            </select>
          </div>
        </div>
      </div>

      {/* ── Model Section ───────────────────────── */}
      <div class="settings-section">
        <div class="section-title">Model</div>
        <div class="card">
          <div class="form-row">
            <div>
              <div class="form-label">ASR Model</div>
              <div class="form-hint">Speech recognition model</div>
            </div>
            <select
              class="select"
              style={{ width: "200px" }}
              value={settings().model_id}
              onChange={(e) => updateField("model_id", e.currentTarget.value)}
            >
              <option value="moonshine-tiny-en">Moonshine Tiny (fastest)</option>
              <option value="moonshine-base-en">Moonshine Base (balanced)</option>
            </select>
          </div>

          <div class="form-row">
            <div>
              <div class="form-label">Language</div>
              <div class="form-hint">Speech recognition language</div>
            </div>
            <select
              class="select"
              style={{ width: "160px" }}
              value={settings().language}
              onChange={(e) => updateField("language", e.currentTarget.value)}
            >
              <option value="en">English</option>
              <option value="zh">Chinese</option>
              <option value="ja">Japanese</option>
              <option value="ko">Korean</option>
              <option value="ar">Arabic</option>
              <option value="vi">Vietnamese</option>
              <option value="uk">Ukrainian</option>
            </select>
          </div>

          <div class="form-row">
            <div>
              <div class="form-label">Voice Activity Detection</div>
              <div class="form-hint">Auto-detect speech vs silence</div>
            </div>
            <div
              class={`toggle ${settings().vad_enabled ? "active" : ""}`}
              onClick={() => updateField("vad_enabled", !settings().vad_enabled)}
            />
          </div>

          <div class="form-row">
            <div>
              <div class="form-label">Auto-Punctuation</div>
              <div class="form-hint">Add periods, commas automatically</div>
            </div>
            <div
              class={`toggle ${settings().auto_punctuation ? "active" : ""}`}
              onClick={() => updateField("auto_punctuation", !settings().auto_punctuation)}
            />
          </div>

          <div class="form-row">
            <div>
              <div class="form-label">Noise Suppression</div>
              <div class="form-hint">Filter background noise</div>
            </div>
            <div
              class={`toggle ${settings().noise_suppression ? "active" : ""}`}
              onClick={() => updateField("noise_suppression", !settings().noise_suppression)}
            />
          </div>
        </div>
      </div>

      {/* ── LLM Section ─────────────────────────── */}
      <div class="settings-section">
        <div class="section-title">AI Post-Processing</div>
        <div class="card">
          <div class="form-row">
            <div>
              <div class="form-label">Enable LLM Cleanup</div>
              <div class="form-hint">Fix grammar via local LLM</div>
            </div>
            <div
              class={`toggle ${settings().llm_enabled ? "active" : ""}`}
              onClick={() => updateField("llm_enabled", !settings().llm_enabled)}
            />
          </div>

          <Show when={settings().llm_enabled}>
            <div class="form-group mt-4">
              <label class="form-label">Ollama Endpoint</label>
              <input
                class="input"
                type="text"
                value={settings().llm_endpoint}
                onInput={(e) => updateField("llm_endpoint", e.currentTarget.value)}
              />
            </div>

            <div class="form-group mt-4">
              <label class="form-label">Model</label>
              <input
                class="input"
                type="text"
                value={settings().llm_model}
                onInput={(e) => updateField("llm_model", e.currentTarget.value)}
                placeholder="e.g., llama3, mistral"
              />
            </div>

            <div class="form-group mt-4">
              <label class="form-label">Prompt</label>
              <textarea
                class="input"
                rows={3}
                value={settings().llm_prompt}
                onInput={(e) => updateField("llm_prompt", e.currentTarget.value)}
                style={{ resize: "vertical", "min-height": "80px" }}
              />
            </div>
          </Show>
        </div>
      </div>

      {/* ── Appearance Section ──────────────────── */}
      <div class="settings-section">
        <div class="section-title">Appearance</div>
        <div class="card">
          <div class="form-row">
            <div>
              <div class="form-label">Theme</div>
            </div>
            <select
              class="select"
              style={{ width: "140px" }}
              value={settings().theme}
              onChange={(e) => updateField("theme", e.currentTarget.value)}
            >
              <option value="dark">Dark</option>
              <option value="light">Light</option>
              <option value="system">System</option>
            </select>
          </div>

          <div class="form-row">
            <div>
              <div class="form-label">Launch at Login</div>
              <div class="form-hint">Start Hermion when you log in</div>
            </div>
            <div
              class={`toggle ${settings().launch_at_login ? "active" : ""}`}
              onClick={() => updateField("launch_at_login", !settings().launch_at_login)}
            />
          </div>
        </div>
      </div>

      {/* ── Save Button ─────────────────────────── */}
      <button
        class="btn btn-primary btn-lg w-full"
        onClick={handleSave}
        disabled={isSaving()}
        id="save-settings-btn"
      >
        {isSaving() ? "Saving..." : "Save Settings"}
      </button>

      <style>{`
        .settings-container {
          display: flex;
          flex-direction: column;
          gap: var(--space-5);
          padding-bottom: var(--space-6);
        }

        .settings-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
        }

        .settings-section {
          display: flex;
          flex-direction: column;
          gap: var(--space-3);
        }

        .settings-section .card {
          padding: var(--space-1) var(--space-4);
        }
      `}</style>
    </div>
  );
};

export default SettingsView;
