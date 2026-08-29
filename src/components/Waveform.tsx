import { Component, For, createEffect, createSignal, onCleanup } from "solid-js";
import { micLevel, isListening } from "../stores/app-store";

const NUM_BARS = 32;

const Waveform: Component = () => {
  const [bars, setBars] = createSignal<number[]>(Array(NUM_BARS).fill(4));

  // Animate bars based on mic level
  createEffect(() => {
    if (!isListening()) {
      setBars(Array(NUM_BARS).fill(4));
      return;
    }

    const interval = setInterval(() => {
      const level = micLevel();
      const newBars = Array(NUM_BARS)
        .fill(0)
        .map((_, i) => {
          // Create a wave pattern with randomness scaled by mic level
          const centerDist = Math.abs(i - NUM_BARS / 2) / (NUM_BARS / 2);
          const wave = Math.sin(Date.now() / 200 + i * 0.3) * 0.5 + 0.5;
          const amplitude = Math.max(level * 300, 0.1);
          const height = 4 + (1 - centerDist * 0.6) * wave * amplitude * (0.7 + Math.random() * 0.3);
          return Math.min(Math.max(height, 4), 36);
        });
      setBars(newBars);
    }, 60);

    onCleanup(() => clearInterval(interval));
  });

  return (
    <div class="waveform-container">
      <For each={bars()}>
        {(height) => (
          <div
            class={`waveform-bar ${!isListening() ? "idle" : ""}`}
            style={{ height: `${height}px` }}
          />
        )}
      </For>
    </div>
  );
};

export default Waveform;
