<script lang="ts">
  interface Props {
    confidence: number;
  }

  let { confidence }: Props = $props();

  const { left, right } = $derived.by(() => ({
    left: Math.round((1 - confidence) * 100),
    right: Math.round(confidence * 100),
  }));
</script>

<div class="confidence-container">
  <div class="ratio-display">
    <span class="ratio-left">{left}</span>
    <span class="ratio-dash">-</span>
    <span class="ratio-right">{right}</span>
  </div>

  <div class="slider-wrapper">
    <input
      type="range"
      min="0"
      max="1"
      step="0.01"
      value={confidence}
      class="confidence-slider"
      tabindex="-1"
    />
  </div>
</div>

<style>
  .confidence-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 20px;
    width: 100%;
    max-width: 500px;
  }

  .ratio-display {
    display: flex;
    align-items: baseline;
    gap: 12px;
    justify-content: center;
  }

  .ratio-left,
  .ratio-right {
    font-family: var(--font-mono);
    font-size: 48px;
    font-weight: 600;
    font-variant-numeric: tabular-nums;
    line-height: 1;
  }

  .ratio-left {
    color: #3a9e6e;
  }

  .ratio-right {
    color: var(--accent);
  }

  .ratio-dash {
    font-size: 32px;
    color: var(--muted);
  }

  .slider-wrapper {
    width: 100%;
  }

  .confidence-slider {
    width: 100%;
    height: 6px;
    border-radius: 3px;
    outline: none;
    appearance: none;
    pointer-events: none;
    cursor: default;
    display: block;
    background: rgba(26, 26, 26, 0.15);
  }

  .confidence-slider::-webkit-slider-thumb {
    appearance: none;
    width: 20px;
    height: 20px;
    border-radius: 50%;
    background: var(--paper);
    border: 2px solid var(--ink);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  }

  .confidence-slider::-moz-range-thumb {
    width: 20px;
    height: 20px;
    border-radius: 50%;
    background: var(--paper);
    border: 2px solid var(--ink);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  }

  @media (max-width: 640px) {
    .confidence-container { gap: 10px; }
    .ratio-left, .ratio-right { font-size: 28px; }
    .ratio-dash { font-size: 22px; }
  }
</style>
