use anyhow::Result;
use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use cpal::{SampleFormat, StreamConfig};
use log::{error, info};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::thread;

use crate::models::AudioDeviceInfo;

/// Thread-safe audio capture manager.
/// The cpal `Stream` is not Send+Sync, so we manage it on a dedicated thread.
pub struct AudioCapture {
    is_capturing: Arc<AtomicBool>,
    buffer: Arc<Mutex<Vec<f32>>>,
    mic_level: Arc<Mutex<f32>>,
    capture_thread: Option<thread::JoinHandle<()>>,
    stop_signal: Arc<AtomicBool>,
}

// Safety: AudioCapture doesn't hold the Stream directly — it's on a separate thread.
// The fields we do hold (Arc<AtomicBool>, Arc<Mutex<...>>) are all Send+Sync.
unsafe impl Send for AudioCapture {}
unsafe impl Sync for AudioCapture {}

impl AudioCapture {
    pub fn new() -> Self {
        Self {
            is_capturing: Arc::new(AtomicBool::new(false)),
            buffer: Arc::new(Mutex::new(Vec::new())),
            mic_level: Arc::new(Mutex::new(0.0)),
            capture_thread: None,
            stop_signal: Arc::new(AtomicBool::new(false)),
        }
    }

    /// List available input devices
    pub fn list_devices() -> Result<Vec<AudioDeviceInfo>> {
        let host = cpal::default_host();
        let mut devices = Vec::new();

        let default_device = host.default_input_device();
        let default_name = default_device
            .as_ref()
            .map(|d| d.name().unwrap_or_default())
            .unwrap_or_default();

        if let Ok(input_devices) = host.input_devices() {
            for device in input_devices {
                let name = device.name().unwrap_or_else(|_| "Unknown".to_string());
                let config = device.default_input_config().ok();
                devices.push(AudioDeviceInfo {
                    is_default: name == default_name,
                    name,
                    sample_rate: config
                        .as_ref()
                        .map(|c| c.sample_rate().0)
                        .unwrap_or(16000),
                    channels: config.as_ref().map(|c| c.channels()).unwrap_or(1),
                });
            }
        }

        Ok(devices)
    }

    /// Start capturing audio from the specified device (or default).
    /// Spawns a dedicated thread to own the cpal::Stream.
    pub fn start(&mut self, device_name: &str) -> Result<()> {
        if self.is_capturing.load(Ordering::SeqCst) {
            return Ok(());
        }

        let device_name = device_name.to_string();
        let buffer = self.buffer.clone();
        let mic_level = self.mic_level.clone();
        let is_capturing = self.is_capturing.clone();
        let stop_signal = Arc::new(AtomicBool::new(false));
        self.stop_signal = stop_signal.clone();

        is_capturing.store(true, Ordering::SeqCst);

        let handle = thread::spawn(move || {
            if let Err(e) = run_capture_loop(&device_name, &buffer, &mic_level, &is_capturing, &stop_signal) {
                error!("Audio capture thread error: {}", e);
                is_capturing.store(false, Ordering::SeqCst);
            }
        });

        self.capture_thread = Some(handle);
        info!("Audio capture started (on dedicated thread)");

        Ok(())
    }

    /// Stop capturing audio
    pub fn stop(&mut self) {
        self.stop_signal.store(true, Ordering::SeqCst);
        self.is_capturing.store(false, Ordering::SeqCst);

        if let Some(handle) = self.capture_thread.take() {
            // Give the thread a moment to clean up
            let _ = handle.join();
        }

        info!("Audio capture stopped");
    }

    /// Drain the accumulated audio buffer
    pub fn drain_buffer(&self) -> Vec<f32> {
        let mut buffer = self.buffer.lock().unwrap();
        let data = buffer.clone();
        buffer.clear();
        data
    }

    /// Get current mic level (RMS)
    pub fn get_mic_level(&self) -> f32 {
        *self.mic_level.lock().unwrap()
    }

    pub fn is_active(&self) -> bool {
        self.is_capturing.load(Ordering::SeqCst)
    }
}

/// Runs on a dedicated thread, owning the cpal::Stream (which is !Send)
fn run_capture_loop(
    device_name: &str,
    buffer: &Arc<Mutex<Vec<f32>>>,
    mic_level: &Arc<Mutex<f32>>,
    is_capturing: &Arc<AtomicBool>,
    stop_signal: &Arc<AtomicBool>,
) -> Result<()> {
    let host = cpal::default_host();

    let device = if device_name == "default" {
        host.default_input_device()
            .ok_or_else(|| anyhow::anyhow!("No default input device found"))?
    } else {
        let mut found = None;
        if let Ok(devices) = host.input_devices() {
            for d in devices {
                if d.name().unwrap_or_default() == device_name {
                    found = Some(d);
                    break;
                }
            }
        }
        found.ok_or_else(|| anyhow::anyhow!("Device '{}' not found", device_name))?
    };

    info!("Using audio device: {}", device.name()?);

    let supported_config = device.default_input_config()?;
    let sample_format = supported_config.sample_format();

    // Try 16kHz mono first, fall back to device default
    let supports_16k = device
        .supported_input_configs()
        .map(|mut configs| {
            configs.any(|c| {
                c.channels() >= 1
                    && c.min_sample_rate().0 <= 16000
                    && c.max_sample_rate().0 >= 16000
            })
        })
        .unwrap_or(false);

    let actual_config = if supports_16k {
        StreamConfig {
            channels: 1,
            sample_rate: cpal::SampleRate(16000),
            buffer_size: cpal::BufferSize::Default,
        }
    } else {
        supported_config.config()
    };

    let source_rate = actual_config.sample_rate.0;
    let source_channels = actual_config.channels;

    let buffer_clone = buffer.clone();
    let mic_level_clone = mic_level.clone();
    let is_capturing_clone = is_capturing.clone();

    let stream = match sample_format {
        SampleFormat::F32 => device.build_input_stream(
            &actual_config,
            move |data: &[f32], _: &cpal::InputCallbackInfo| {
                if !is_capturing_clone.load(Ordering::SeqCst) {
                    return;
                }
                let mono = to_mono_16khz(data, source_channels, source_rate);
                let level = calculate_rms(&mono);
                *mic_level_clone.lock().unwrap() = level;
                buffer_clone.lock().unwrap().extend_from_slice(&mono);
            },
            move |err| error!("Audio stream error: {}", err),
            None,
        )?,
        SampleFormat::I16 => {
            let buffer_i16 = buffer.clone();
            let mic_level_i16 = mic_level.clone();
            let is_cap_i16 = is_capturing.clone();

            device.build_input_stream(
                &actual_config,
                move |data: &[i16], _: &cpal::InputCallbackInfo| {
                    if !is_cap_i16.load(Ordering::SeqCst) {
                        return;
                    }
                    let f32_data: Vec<f32> = data.iter().map(|&s| s as f32 / 32768.0).collect();
                    let mono = to_mono_16khz(&f32_data, source_channels, source_rate);
                    let level = calculate_rms(&mono);
                    *mic_level_i16.lock().unwrap() = level;
                    buffer_i16.lock().unwrap().extend_from_slice(&mono);
                },
                move |err| error!("Audio stream error: {}", err),
                None,
            )?
        }
        _ => {
            return Err(anyhow::anyhow!("Unsupported sample format: {:?}", sample_format));
        }
    };

    stream.play()?;
    info!("Audio stream playing");

    // Block this thread until stop signal
    while !stop_signal.load(Ordering::SeqCst) {
        thread::sleep(std::time::Duration::from_millis(50));
    }

    // Stream is dropped here, stopping the capture
    drop(stream);
    info!("Audio stream dropped");

    Ok(())
}

/// Convert multi-channel audio to mono 16kHz
fn to_mono_16khz(data: &[f32], channels: u16, sample_rate: u32) -> Vec<f32> {
    let ch = channels as usize;

    let mono: Vec<f32> = if ch > 1 {
        data.chunks(ch)
            .map(|frame| frame.iter().sum::<f32>() / ch as f32)
            .collect()
    } else {
        data.to_vec()
    };

    if sample_rate == 16000 {
        mono
    } else {
        let ratio = 16000.0 / sample_rate as f64;
        let output_len = (mono.len() as f64 * ratio) as usize;
        let mut output = Vec::with_capacity(output_len);
        for i in 0..output_len {
            let src_idx = i as f64 / ratio;
            let idx = src_idx as usize;
            let frac = src_idx - idx as f64;
            if idx + 1 < mono.len() {
                let sample = mono[idx] as f64 * (1.0 - frac) + mono[idx + 1] as f64 * frac;
                output.push(sample as f32);
            } else if idx < mono.len() {
                output.push(mono[idx]);
            }
        }
        output
    }
}

/// Calculate RMS level for visualization
fn calculate_rms(samples: &[f32]) -> f32 {
    if samples.is_empty() {
        return 0.0;
    }
    let sum: f32 = samples.iter().map(|s| s * s).sum();
    (sum / samples.len() as f32).sqrt()
}
