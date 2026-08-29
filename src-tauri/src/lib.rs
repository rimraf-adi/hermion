mod audio;
mod commands;
mod db;
mod injection;
mod models;
mod sidecar;

use audio::AudioCapture;
use db::Database;
use models::AppState;
use sidecar::SidecarManager;
use std::sync::Mutex;
use tauri::{
    menu::{Menu, MenuItem},
    tray::TrayIconBuilder,
    Emitter, Manager,
};

/// Shared application state managed by Tauri
pub struct AppStateManager {
    pub db: Database,
    pub audio: Mutex<AudioCapture>,
    pub sidecar: Mutex<SidecarManager>,
    pub app_state: Mutex<AppState>,
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    env_logger::init();

    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_global_shortcut::Builder::new().build())
        .plugin(tauri_plugin_shell::init())
        .setup(|app| {
            // Initialize database
            let app_dir = app
                .path()
                .app_data_dir()
                .expect("Failed to get app data directory");

            let db = Database::new(app_dir).expect("Failed to initialize database");

            // Load settings
            let settings = db.load_settings().unwrap_or_default();

            // Initialize sidecar manager
            let mut sidecar_mgr = SidecarManager::new();
            if let Err(e) = sidecar_mgr.spawn(app.handle().clone()) {
                log::warn!("Sidecar not spawned immediately (will attempt on demand): {}", e);
            }

            // Create shared state
            let state = AppStateManager {
                db,
                audio: Mutex::new(AudioCapture::new()),
                sidecar: Mutex::new(sidecar_mgr),
                app_state: Mutex::new(AppState {
                    is_listening: false,
                    is_sidecar_ready: false,
                    current_model: settings.model_id.clone(),
                    mic_level: 0.0,
                }),
            };

            app.manage(state);

            // ── System Tray ──────────────────────────────────
            let show_item = MenuItem::with_id(app, "show", "Show Hermion", true, None::<&str>)?;
            let toggle_item =
                MenuItem::with_id(app, "toggle", "Start Listening", true, None::<&str>)?;
            let settings_item =
                MenuItem::with_id(app, "settings", "Settings", true, None::<&str>)?;
            let quit_item = MenuItem::with_id(app, "quit", "Quit Hermion", true, None::<&str>)?;

            let menu = Menu::with_items(
                app,
                &[&show_item, &toggle_item, &settings_item, &quit_item],
            )?;

            let _tray = TrayIconBuilder::with_id("hermion-tray")
                .menu(&menu)
                .tooltip("Hermion — Voice Keyboard")
                .on_menu_event(move |app, event| match event.id.as_ref() {
                    "show" => {
                        if let Some(window) = app.get_webview_window("main") {
                            window.show().ok();
                            window.set_focus().ok();
                        }
                    }
                    "toggle" => {
                        app.emit("toggle-listening", ()).ok();
                    }
                    "settings" => {
                        if let Some(window) = app.get_webview_window("main") {
                            window.show().ok();
                            window.set_focus().ok();
                            app.emit("navigate", "settings").ok();
                        }
                    }
                    "quit" => {
                        app.exit(0);
                    }
                    _ => {}
                })
                .build(app)?;

            // ── Register Global Shortcut ─────────────────────
            // Default: F5 as push-to-talk (CapsLock requires special handling per-platform)
            // We use F5 as a reliable cross-platform default that won't conflict
            use tauri_plugin_global_shortcut::GlobalShortcutExt;

            let app_handle = app.handle().clone();
            app.global_shortcut().on_shortcut("F5", move |_app, _shortcut, event| {
                if event.state == tauri_plugin_global_shortcut::ShortcutState::Pressed {
                    app_handle.emit("hotkey-pressed", true).ok();
                } else {
                    app_handle.emit("hotkey-pressed", false).ok();
                }
            }).ok();

            // ── Window Visibility ────────────────────────────
            // Show main window on first run, otherwise just tray
            if let Some(main_window) = app.get_webview_window("main") {
                main_window.show().ok();
            }

            log::info!("Hermion initialized successfully");
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::list_audio_devices,
            commands::get_mic_level,
            commands::start_listening,
            commands::stop_listening,
            commands::inject_text,
            commands::get_settings,
            commands::save_settings,
            commands::update_setting,
            commands::get_history,
            commands::search_history,
            commands::add_history_entry,
            commands::delete_history_entry,
            commands::clear_history,
            commands::get_app_state,
            commands::is_first_run,
        ])
        .run(tauri::generate_context!())
        .expect("error while running Hermion");
}
