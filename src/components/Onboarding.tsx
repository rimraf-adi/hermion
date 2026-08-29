import { Component, createSignal, Show } from "solid-js";
import { setCurrentView } from "../stores/app-store";

const STEPS = [
  {
    title: "Welcome to Hermion",
    description: "Your privacy-first voice keyboard. All speech processing happens entirely on your device — nothing is ever sent to the cloud.",
    icon: "mic",
  },
  {
    title: "Microphone Access",
    description: "Hermion needs microphone access to hear your voice. Click the button below to grant permission.",
    icon: "shield",
    action: "Grant Microphone Access",
  },
  {
    title: "Accessibility Permission",
    description: "On macOS, Hermion needs Accessibility access to type into other apps. You'll be prompted to allow this in System Settings.",
    icon: "keyboard",
    action: "Open System Settings",
    platform: "macos",
  },
  {
    title: "Choose Your Hotkey",
    description: "Press F5 to start and stop listening. You can change this later in Settings.",
    icon: "zap",
  },
  {
    title: "You're All Set!",
    description: "Press F5 anywhere to start dictating. Hermion will type your words into any app. Enjoy!",
    icon: "check",
    action: "Start Using Hermion",
  },
];

const Onboarding: Component = () => {
  const [step, setStep] = createSignal(0);

  const currentStep = () => STEPS[step()];

  const handleNext = () => {
    if (step() < STEPS.length - 1) {
      setStep((s) => s + 1);
    } else {
      setCurrentView("home");
    }
  };

  const handleAction = async () => {
    const s = currentStep();
    if (s.icon === "shield") {
      // Request microphone permission
      try {
        await navigator.mediaDevices.getUserMedia({ audio: true });
      } catch {
        // User denied — still proceed
      }
    }
    handleNext();
  };

  const renderIcon = (icon: string) => {
    switch (icon) {
      case "mic":
        return (
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z" />
            <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
            <line x1="12" x2="12" y1="19" y2="22" />
          </svg>
        );
      case "shield":
        return (
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z" />
            <path d="m9 12 2 2 4-4" />
          </svg>
        );
      case "keyboard":
        return (
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect width="20" height="16" x="2" y="4" rx="2" />
            <path d="M6 8h.001" />
            <path d="M10 8h.001" />
            <path d="M14 8h.001" />
            <path d="M18 8h.001" />
            <path d="M8 12h.001" />
            <path d="M12 12h.001" />
            <path d="M16 12h.001" />
            <path d="M7 16h10" />
          </svg>
        );
      case "zap":
        return (
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M4 14a1 1 0 0 1-.78-1.63l9.9-10.2a.5.5 0 0 1 .86.46l-1.92 6.02A1 1 0 0 0 13 10h7a1 1 0 0 1 .78 1.63l-9.9 10.2a.5.5 0 0 1-.86-.46l1.92-6.02A1 1 0 0 0 11 14z" />
          </svg>
        );
      case "check":
        return (
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
            <path d="m9 11 3 3L22 4" />
          </svg>
        );
      default:
        return null;
    }
  };

  return (
    <div class="onboarding-container">
      <div class="onboarding-step animate-slide-up" style={{ "--slide-key": step() } as any}>
        <div class="onboarding-icon">{renderIcon(currentStep().icon)}</div>

        <h2
          class="text-gradient"
          style={{
            "font-size": "var(--text-xl)",
            "font-weight": "var(--weight-bold)",
          }}
        >
          {currentStep().title}
        </h2>

        <p class="text-muted" style={{ "line-height": "var(--leading-relaxed)" }}>
          {currentStep().description}
        </p>

        <Show when={currentStep().action}>
          <button class="btn btn-primary btn-lg w-full" onClick={handleAction}>
            {currentStep().action}
          </button>
        </Show>

        <Show when={!currentStep().action}>
          <button class="btn btn-primary btn-lg w-full" onClick={handleNext}>
            Continue
          </button>
        </Show>

        <Show when={step() > 0}>
          <button
            class="btn btn-ghost"
            onClick={() => setStep((s) => s - 1)}
            style={{ "margin-top": "calc(-1 * var(--space-2))" }}
          >
            Back
          </button>
        </Show>

        {/* Progress Dots */}
        <div class="onboarding-dots">
          {STEPS.map((_, i) => (
            <div class={`onboarding-dot ${i === step() ? "active" : ""}`} />
          ))}
        </div>
      </div>
    </div>
  );
};

export default Onboarding;
