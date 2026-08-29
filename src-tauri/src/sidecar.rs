use anyhow::Result;
use log::{error, info};
use std::io::{BufRead, BufReader, Write};
use std::process::{Child, Command, Stdio};
use std::sync::{Arc, Mutex};
use std::thread;
use tauri::{AppHandle, Emitter};

use crate::models::{SidecarCommand, SidecarEvent};

pub struct SidecarManager {
    child: Option<Child>,
    stdin_tx: Option<std::sync::mpsc::Sender<String>>,
    is_ready: Arc<Mutex<bool>>,
}

// Safety: Child is managed internally with synchronization
unsafe impl Send for SidecarManager {}
unsafe impl Sync for SidecarManager {}

impl SidecarManager {
    pub fn new() -> Self {
        Self {
            child: None,
            stdin_tx: None,
            is_ready: Arc::new(Mutex::new(false)),
        }
    }

    /// Spawn the Moonshine inference sidecar process and begin event reading loop
    pub fn spawn(&mut self, app_handle: AppHandle) -> Result<()> {
        info!("Spawning hermion-sidecar process...");

        // Look for sidecar binary in standard Tauri externalBin paths or development builds
        let sidecar_exe = find_sidecar_executable()?;
        info!("Found sidecar at: {:?}", sidecar_exe);

        let mut child = Command::new(sidecar_exe)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::inherit())
            .spawn()
            .map_err(|e| anyhow::anyhow!("Failed to spawn sidecar: {}", e))?;

        let stdout = child
            .stdout
            .take()
            .ok_or_else(|| anyhow::anyhow!("Failed to open sidecar stdout"))?;

        let mut stdin = child
            .stdin
            .take()
            .ok_or_else(|| anyhow::anyhow!("Failed to open sidecar stdin"))?;

        let (tx, rx) = std::sync::mpsc::channel::<String>();
        self.stdin_tx = Some(tx);

        // Stdin writing thread
        thread::spawn(move || {
            while let Ok(line) = rx.recv() {
                if let Err(e) = writeln!(stdin, "{}", line) {
                    error!("Error writing to sidecar stdin: {}", e);
                    break;
                }
                if let Err(e) = stdin.flush() {
                    error!("Error flushing sidecar stdin: {}", e);
                    break;
                }
            }
        });

        let is_ready = self.is_ready.clone();
        let app_handle_clone = app_handle.clone();

        // Stdout reading thread
        thread::spawn(move || {
            let reader = BufReader::new(stdout);
            for line in reader.lines() {
                match line {
                    Ok(raw_line) => {
                        let trimmed = raw_line.trim();
                        if trimmed.is_empty() {
                            continue;
                        }
                        match serde_json::from_str::<SidecarEvent>(trimmed) {
                            Ok(event) => match event {
                                SidecarEvent::Ready => {
                                    info!("Sidecar is ready");
                                    *is_ready.lock().unwrap() = true;
                                    app_handle_clone.emit("sidecar-ready", true).ok();
                                }
                                SidecarEvent::Partial { text, is_final, latency_ms } => {
                                    app_handle_clone.emit("transcription-partial", &text).ok();
                                    log::debug!("Partial ({}ms, final={}): {}", latency_ms, is_final, text);
                                }
                                SidecarEvent::Final { text, confidence, latency_ms } => {
                                    app_handle_clone.emit("transcription-final", &text).ok();
                                    info!("Final ({}ms, conf={:.2}): {}", latency_ms, confidence, text);
                                }
                                SidecarEvent::Vad { is_speech } => {
                                    app_handle_clone.emit("vad-speech", is_speech).ok();
                                }
                                SidecarEvent::Status { model_loaded, gpu_available, memory_mb } => {
                                    app_handle_clone
                                        .emit(
                                            "sidecar-status",
                                            serde_json::json!({
                                                "model_loaded": model_loaded,
                                                "gpu_available": gpu_available,
                                                "memory_mb": memory_mb
                                            }),
                                        )
                                        .ok();
                                }
                                SidecarEvent::Error { message } => {
                                    error!("Sidecar error: {}", message);
                                    app_handle_clone.emit("sidecar-error", &message).ok();
                                }
                            },
                            Err(e) => {
                                error!("Failed to parse sidecar event JSON '{}': {}", trimmed, e);
                            }
                        }
                    }
                    Err(e) => {
                        error!("Error reading from sidecar stdout: {}", e);
                        break;
                    }
                }
            }
            *is_ready.lock().unwrap() = false;
            app_handle_clone.emit("sidecar-ready", false).ok();
            info!("Sidecar stdout reader thread terminated");
        });

        self.child = Some(child);
        Ok(())
    }

    /// Send a command to the sidecar via stdin
    pub fn send_command(&self, cmd: &SidecarCommand) -> Result<()> {
        if let Some(tx) = &self.stdin_tx {
            let json = serde_json::to_string(cmd)?;
            tx.send(json)
                .map_err(|e| anyhow::anyhow!("Failed to send to sidecar channel: {}", e))?;
        }
        Ok(())
    }

    pub fn is_ready(&self) -> bool {
        *self.is_ready.lock().unwrap()
    }

    pub fn shutdown(&mut self) {
        if let Some(tx) = self.stdin_tx.take() {
            let _ = tx.send(serde_json::to_string(&SidecarCommand::Shutdown).unwrap_or_default());
        }
        if let Some(mut child) = self.child.take() {
            let _ = child.kill();
            let _ = child.wait();
        }
    }
}

/// Helper to locate the sidecar executable across dev and bundled modes
fn find_sidecar_executable() -> Result<std::path::PathBuf> {
    // 1. Check next to current executable
    if let Ok(current_exe) = std::env::current_exe() {
        if let Some(parent) = current_exe.parent() {
            let candidate = parent.join("hermion-sidecar");
            if candidate.exists() {
                return Ok(candidate);
            }
        }
    }

    // 2. Check target/debug, target/release, and bin directories with and without target triple
    let manifest_dir = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    let target_triple = env!("TAURI_ENV_TARGET_TRIPLE");
    let candidates = [
        manifest_dir.join(format!("bin/hermion-sidecar-{}", target_triple)),
        manifest_dir.join("bin/hermion-sidecar"),
        manifest_dir.join("../src-sidecar/target/debug/hermion-sidecar"),
        manifest_dir.join("../src-sidecar/target/release/hermion-sidecar"),
        manifest_dir.join("../target/debug/hermion-sidecar"),
        manifest_dir.join("../target/release/hermion-sidecar"),
    ];

    for candidate in &candidates {
        if candidate.exists() {
            return Ok(candidate.clone());
        }
    }

    // Default fallback
    Ok(manifest_dir.join(format!("bin/hermion-sidecar-{}", target_triple)))
}
