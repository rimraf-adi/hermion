mod inference;
mod protocol;

use anyhow::Result;
use base64::Engine;
use inference::{MoonshineEngine, SimpleVAD};
use log::{error, info};
use protocol::{IncomingMessage, OutgoingMessage};
use std::io::{self, BufRead, Write};

fn send_message(msg: &OutgoingMessage) {
    let json = serde_json::to_string(msg).expect("Failed to serialize message");
    let stdout = io::stdout();
    let mut handle = stdout.lock();
    writeln!(handle, "{}", json).expect("Failed to write to stdout");
    handle.flush().expect("Failed to flush stdout");
}

fn main() -> Result<()> {
    env_logger::init();
    info!("Hermion sidecar starting...");

    let mut engine = MoonshineEngine::new();
    let mut vad = SimpleVAD::new(0.01); // Default threshold
    let mut is_listening = false;

    // Signal readiness
    send_message(&OutgoingMessage::Ready);

    // Read JSON messages from stdin
    let stdin = io::stdin();
    let reader = stdin.lock();

    for line in reader.lines() {
        let line = match line {
            Ok(l) => l.trim().to_string(),
            Err(e) => {
                error!("Failed to read stdin: {}", e);
                continue;
            }
        };

        if line.is_empty() {
            continue;
        }

        let msg: IncomingMessage = match serde_json::from_str(&line) {
            Ok(m) => m,
            Err(e) => {
                error!("Failed to parse message: {} — line: {}", e, &line[..line.len().min(100)]);
                send_message(&OutgoingMessage::Error {
                    message: format!("Parse error: {}", e),
                });
                continue;
            }
        };

        match msg {
            IncomingMessage::Start { config } => {
                info!("Starting with config: {:?}", config);

                // Load model if not already loaded
                if !engine.is_loaded() {
                    // Model directory would be passed or discovered
                    let model_dir = format!("models/{}", config.model);
                    match engine.load_model(&config.model, &model_dir) {
                        Ok(_) => {
                            send_message(&OutgoingMessage::Status {
                                model_loaded: true,
                                gpu_available: false,
                                memory_mb: 0,
                            });
                        }
                        Err(e) => {
                            send_message(&OutgoingMessage::Error {
                                message: format!("Failed to load model: {}", e),
                            });
                            continue;
                        }
                    }
                }

                vad = SimpleVAD::new(config.vad_threshold);
                engine.reset();
                is_listening = true;
                info!("Listening started");
            }

            IncomingMessage::Audio { data, timestamp_ms: _ } => {
                if !is_listening {
                    continue;
                }

                // Decode base64 PCM f32 audio
                let bytes = match base64::engine::general_purpose::STANDARD.decode(&data) {
                    Ok(b) => b,
                    Err(e) => {
                        error!("Failed to decode audio: {}", e);
                        continue;
                    }
                };

                // Convert bytes to f32 samples
                let samples: Vec<f32> = bytes
                    .chunks_exact(4)
                    .map(|chunk| f32::from_le_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]))
                    .collect();

                // Run VAD
                let vad_result = vad.process(&samples);
                if vad_result.changed {
                    send_message(&OutgoingMessage::Vad {
                        is_speech: vad_result.is_speech,
                    });
                }

                // Only process if speech detected
                if vad_result.is_speech {
                    match engine.process_audio_chunk(&samples) {
                        Ok(Some(partial)) => {
                            send_message(&OutgoingMessage::Partial {
                                text: partial.text,
                                is_final: partial.is_final,
                                latency_ms: partial.latency_ms,
                            });
                        }
                        Ok(None) => {} // Not enough audio yet
                        Err(e) => {
                            error!("Inference error: {}", e);
                            send_message(&OutgoingMessage::Error {
                                message: format!("Inference error: {}", e),
                            });
                        }
                    }
                }
            }

            IncomingMessage::Stop => {
                info!("Stop received");
                is_listening = false;

                // Finalize transcription
                match engine.finalize() {
                    Ok(result) => {
                        if !result.text.is_empty() {
                            send_message(&OutgoingMessage::Final {
                                text: result.text,
                                confidence: result.confidence,
                                latency_ms: result.latency_ms,
                            });
                        }
                    }
                    Err(e) => {
                        error!("Finalization error: {}", e);
                        send_message(&OutgoingMessage::Error {
                            message: format!("Finalization error: {}", e),
                        });
                    }
                }

                vad.reset();
                engine.reset();
            }

            IncomingMessage::Shutdown => {
                info!("Shutdown received, exiting");
                break;
            }
        }
    }

    info!("Hermion sidecar exiting");
    Ok(())
}
