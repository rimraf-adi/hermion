use anyhow::Result;
use arboard::Clipboard;
use enigo::{Enigo, Keyboard, Settings};
use log::info;
use std::thread;
use std::time::Duration;

/// Inject text into the currently focused application
pub fn inject_text(text: &str, method: &str) -> Result<()> {
    match method {
        "clipboard" => inject_via_clipboard(text),
        "keystroke" => inject_via_keystrokes(text),
        _ => inject_via_clipboard(text), // default to clipboard
    }
}

/// Inject text by placing it on the clipboard and simulating Cmd+V / Ctrl+V
/// Preserves the original clipboard content
fn inject_via_clipboard(text: &str) -> Result<()> {
    let mut clipboard = Clipboard::new()
        .map_err(|e| anyhow::anyhow!("Failed to access clipboard: {}", e))?;

    // Save original clipboard content
    let original = clipboard.get_text().ok();

    // Set new text
    clipboard
        .set_text(text.to_string())
        .map_err(|e| anyhow::anyhow!("Failed to set clipboard: {}", e))?;

    // Small delay to ensure clipboard is ready
    thread::sleep(Duration::from_millis(50));

    // Simulate paste (Cmd+V on macOS, Ctrl+V on Windows/Linux)
    let mut enigo = Enigo::new(&Settings::default())
        .map_err(|e| anyhow::anyhow!("Failed to create enigo: {}", e))?;

    #[cfg(target_os = "macos")]
    {
        use enigo::Key;
        enigo.key(Key::Meta, enigo::Direction::Press).ok();
        enigo.key(Key::Unicode('v'), enigo::Direction::Click).ok();
        enigo.key(Key::Meta, enigo::Direction::Release).ok();
    }

    #[cfg(not(target_os = "macos"))]
    {
        use enigo::Key;
        enigo.key(Key::Control, enigo::Direction::Press).ok();
        enigo.key(Key::Unicode('v'), enigo::Direction::Click).ok();
        enigo.key(Key::Control, enigo::Direction::Release).ok();
    }

    // Wait for paste to complete, then restore original clipboard
    thread::sleep(Duration::from_millis(100));
    if let Some(original_text) = original {
        clipboard.set_text(original_text).ok();
    }

    info!("Injected {} characters via clipboard", text.len());
    Ok(())
}

/// Inject text character-by-character via simulated keystrokes
/// Slower but doesn't touch the clipboard
fn inject_via_keystrokes(text: &str) -> Result<()> {
    let mut enigo = Enigo::new(&Settings::default())
        .map_err(|e| anyhow::anyhow!("Failed to create enigo: {}", e))?;

    enigo
        .text(text)
        .map_err(|e| anyhow::anyhow!("Failed to type text: {}", e))?;

    info!("Injected {} characters via keystrokes", text.len());
    Ok(())
}

/// Process dictation commands embedded in text
/// Returns the processed text with commands executed
pub fn process_dictation_commands(text: &str) -> String {
    let mut result = text.to_string();

    // Common dictation command replacements
    let replacements = vec![
        ("new line", "\n"),
        ("new paragraph", "\n\n"),
        ("period", "."),
        ("comma", ","),
        ("exclamation mark", "!"),
        ("exclamation point", "!"),
        ("question mark", "?"),
        ("colon", ":"),
        ("semicolon", ";"),
        ("open quote", "\""),
        ("close quote", "\""),
        ("open paren", "("),
        ("close paren", ")"),
        ("open bracket", "["),
        ("close bracket", "]"),
        ("open brace", "{"),
        ("close brace", "}"),
        ("dash", "-"),
        ("hyphen", "-"),
        ("underscore", "_"),
        ("at sign", "@"),
        ("hash", "#"),
        ("dollar sign", "$"),
        ("percent", "%"),
        ("ampersand", "&"),
        ("asterisk", "*"),
        ("plus", "+"),
        ("equals", "="),
        ("pipe", "|"),
        ("backslash", "\\"),
        ("forward slash", "/"),
        ("tilde", "~"),
        ("tab", "\t"),
    ];

    for (command, replacement) in replacements {
        // Case-insensitive replacement
        let lower = result.to_lowercase();
        while let Some(pos) = lower.find(command) {
            let end = pos + command.len();
            result = format!("{}{}{}", &result[..pos], replacement, &result[end..]);
            break; // re-check from start due to changed string
        }
    }

    result
}
