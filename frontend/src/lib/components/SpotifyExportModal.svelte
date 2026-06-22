<script lang="ts">
  import { IconMinus, IconPlus, IconExternalLink } from "@tabler/icons-svelte";
  import { PUBLIC_API_BASE_URL } from "$env/static/public";
  import { api } from "$lib/api";
  import type { RankedSong } from "$lib/types";
  import Modal from "./Modal.svelte";

  let {
    rankingId,
    rankingName,
    spotifyPlaylistId,
    lastExportCount,
    syncCount,
    syncError,
    rankedSongs,
    onClose,
    onExported,
    onSyncUpdated,
  }: {
    rankingId: number;
    rankingName: string;
    spotifyPlaylistId: string | null;
    lastExportCount: number | null;
    syncCount: number | null;
    syncError: boolean;
    rankedSongs: RankedSong[];
    onClose: () => void;
    onExported: (playlistId: string, exportedCount: number) => void;
    onSyncUpdated: (syncCount: number | null) => void;
  } = $props();

  type Phase = "idle" | "loading" | "success" | "error" | "reauth";

  const DEFAULT_COUNT = 20;

  let name = $state(rankingName);
  let count = $state(Math.min(lastExportCount ?? DEFAULT_COUNT, rankedSongs.length));
  let isPublic = $state(false);
  let phase = $state<Phase>("idle");
  let resultMsg = $state("");
  let playlistUrl = $state("");

  let autoSync = $state(syncCount !== null);
  let syncCountValue = $state(
    Math.min(syncCount ?? lastExportCount ?? DEFAULT_COUNT, rankedSongs.length),
  );
  let syncSaving = $state(false);

  let preview = $derived(rankedSongs.slice(0, count));
  let hasExisting = $derived(!!spotifyPlaylistId);

  function decrementSync() {
    if (syncCountValue > 1) syncCountValue--;
  }
  function incrementSync() {
    if (syncCountValue < rankedSongs.length) syncCountValue++;
  }
  function parseCount(e: Event, max: number): number {
    const val = parseInt((e.target as HTMLInputElement).value);
    return isNaN(val) ? max : Math.max(1, Math.min(max, val));
  }

  function onSyncCountInput(e: Event) {
    syncCountValue = parseCount(e, rankedSongs.length);
  }

  async function patchSync(newCount: number | null) {
    syncSaving = true;
    try {
      await api.patch(`/api/v1/rankings/${rankingId}`, {
        ranking: { spotify_sync_count: newCount },
      });
      onSyncUpdated(newCount);
    } finally {
      syncSaving = false;
    }
  }

  async function toggleSync() {
    autoSync = !autoSync;
    await patchSync(autoSync ? syncCountValue : null);
  }

  function decrement() {
    if (count > 1) count--;
  }
  function increment() {
    if (count < rankedSongs.length) count++;
  }

  function onCountInput(e: Event) {
    count = parseCount(e, rankedSongs.length);
  }

  async function submit() {
    if (phase === "loading") return;
    phase = "loading";
    try {
      const result = await api.post<{ status: string; playlist_url: string }>(
        `/api/v1/rankings/${rankingId}/export/spotify`,
        { name: name.trim() || rankingName, count, public: isPublic },
      );
      playlistUrl = result.playlist_url;
      resultMsg =
        result.status === "created" ? "playlist created" : "playlist updated";
      phase = "success";
      const id = result.playlist_url.split("/").pop() ?? "";
      onExported(id, count);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      if (msg.includes("spotify_scope_required") || msg.includes("403")) {
        phase = "reauth";
      } else {
        resultMsg = msg || "export failed. try again.";
        phase = "error";
      }
    }
  }
</script>

{#snippet stepper(value: number, onDecrement: () => void, onIncrement: () => void, oninput: (e: Event) => void, label: string)}
  <div class="stepper">
    <button class="step-btn" onclick={onDecrement} disabled={value <= 1}>
      <IconMinus size={12} />
    </button>
    <input
      class="count-input"
      type="number"
      min={1}
      max={rankedSongs.length}
      {value}
      {oninput}
    />
    <button
      class="step-btn"
      onclick={onIncrement}
      disabled={value >= rankedSongs.length}
    >
      <IconPlus size={12} />
    </button>
    <span class="count-of">{label}</span>
  </div>
{/snippet}

<Modal title="export to spotify" {onClose}>
  {#if phase === "success"}
    <div class="result-area">
      <p class="result-msg">{resultMsg}</p>
      <a
        class="open-link"
        href={playlistUrl}
        target="_blank"
        rel="noopener noreferrer"
      >
        open in spotify <IconExternalLink size={13} />
      </a>
    </div>
    <footer>
      <span></span>
      <button class="submit-btn" onclick={onClose}>done</button>
    </footer>
  {:else if phase === "reauth"}
    <div class="result-area">
      <p class="result-msg error">spotify permissions required</p>
      <p class="reauth-hint">
        reconnect your spotify account to grant playlist access, then close that
        tab and try again.
      </p>
      <a
        class="reauth-link"
        href="{PUBLIC_API_BASE_URL}/auth/spotify"
        target="_blank"
        rel="noopener noreferrer">reconnect spotify</a
      >
    </div>
    <footer>
      <span></span>
      <button class="submit-btn secondary" onclick={onClose}>cancel</button>
    </footer>
  {:else}
    {#if syncError}
      <div class="sync-error-banner">
        auto-sync paused: spotify access was revoked. export manually to
        reconnect.
      </div>
    {/if}

    <div class="form">
      <label class="field">
        <span class="label">playlist name</span>
        <input
          type="text"
          bind:value={name}
          placeholder={rankingName}
          maxlength={100}
        />
      </label>

      <div class="field">
        <span class="label">songs to export</span>
        {@render stepper(count, decrement, increment, onCountInput, `of ${rankedSongs.length}`)}
      </div>

      <div class="field visibility-field">
        <span class="label">visibility</span>
        <div class="toggle-row">
          <button
            class="toggle-opt"
            class:active={!isPublic}
            onclick={() => (isPublic = false)}>private</button
          >
          <button
            class="toggle-opt"
            class:active={isPublic}
            onclick={() => (isPublic = true)}>public</button
          >
        </div>
      </div>

      <div class="field sync-field">
        <div class="sync-header">
          <span class="label">daily auto-sync</span>
          <button
            class="switch"
            class:on={autoSync}
            onclick={toggleSync}
            disabled={syncSaving}
            role="switch"
            aria-checked={autoSync}
          >
            <span class="switch-thumb"></span>
          </button>
        </div>
        {#if autoSync}
          <div class="sync-row">
            {@render stepper(syncCountValue, decrementSync, incrementSync, onSyncCountInput, "top songs synced daily")}
            <button
              class="save-sync-btn"
              onclick={() => patchSync(syncCountValue)}
              disabled={syncSaving}
            >
              {syncSaving ? "saving…" : "save"}
            </button>
          </div>
        {/if}
      </div>
    </div>

    <div class="preview-header">
      <span class="label">preview ({count} songs)</span>
    </div>
    <ul class="preview-list">
      {#each preview as song, i (song.id)}
        <li class="preview-row">
          <span class="preview-rank">{i + 1}</span>
          {#if song.album_art_url}
            <img
              class="preview-art"
              src={song.album_art_url}
              alt=""
              width="24"
              height="24"
            />
          {/if}
          <span class="preview-title">{song.title}</span>
          <span class="preview-artist">{song.artist_name}</span>
        </li>
      {/each}
    </ul>

    <footer>
      {#if phase === "error"}
        <span class="error-msg">{resultMsg}</span>
      {:else}
        <span></span>
      {/if}
      <button
        class="submit-btn"
        onclick={submit}
        disabled={phase === "loading"}
      >
        {#if phase === "loading"}
          exporting…
        {:else if hasExisting}
          update spotify playlist
        {:else}
          export to spotify
        {/if}
      </button>
    </footer>
  {/if}
</Modal>

<style>
  .form {
    padding: 16px 20px;
    display: flex;
    flex-direction: column;
    gap: 14px;
    flex-shrink: 0;
    border-bottom: var(--border);
  }

  .field {
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .label {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.8px;
    text-transform: uppercase;
    color: var(--muted);
  }

  .field input[type="text"] {
    font-family: var(--font-serif);
    font-size: 15px;
    color: var(--ink);
    background: none;
    border: var(--border);
    border-radius: 4px;
    padding: 7px 10px;
    outline: none;
    width: 100%;
    box-sizing: border-box;
  }
  .field input[type="text"]:focus {
    border-color: var(--ink);
  }

  .stepper {
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .step-btn {
    background: none;
    border: var(--border);
    border-radius: 4px;
    width: 26px;
    height: 26px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    color: var(--ink);
    flex-shrink: 0;
  }
  .step-btn:disabled {
    opacity: 0.3;
    cursor: not-allowed;
  }

  .count-input {
    font-family: var(--font-mono);
    font-size: 14px;
    color: var(--ink);
    background: none;
    border: var(--border);
    border-radius: 4px;
    padding: 4px 8px;
    width: 54px;
    text-align: center;
    outline: none;
    -moz-appearance: textfield;
  }
  .count-input::-webkit-inner-spin-button,
  .count-input::-webkit-outer-spin-button {
    -webkit-appearance: none;
  }

  .count-of {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--muted);
  }

  .toggle-row {
    display: flex;
    gap: 0;
    border: var(--border);
    border-radius: 4px;
    overflow: hidden;
    width: fit-content;
  }

  .toggle-opt {
    background: none;
    border: none;
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.4px;
    padding: 6px 14px;
    cursor: pointer;
    color: var(--muted);
  }
  .toggle-opt.active {
    background: var(--ink);
    color: var(--paper);
  }
  .toggle-opt:first-child {
    border-right: var(--border);
  }

  .preview-header {
    padding: 10px 20px 6px;
    flex-shrink: 0;
  }

  .preview-list {
    list-style: none;
    overflow-y: auto;
    flex: 1;
    padding: 0 0 4px;
  }

  .preview-row {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 5px 20px;
  }
  .preview-row:hover {
    background: rgba(0, 0, 0, 0.03);
  }

  .preview-rank {
    font-family: var(--font-mono);
    font-size: 10px;
    color: var(--muted);
    width: 18px;
    text-align: right;
    flex-shrink: 0;
  }

  .preview-art {
    border-radius: 2px;
    flex-shrink: 0;
    object-fit: cover;
  }

  .preview-title {
    font-family: var(--font-serif);
    font-size: 13px;
    color: var(--ink);
    flex: 1;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    min-width: 0;
  }

  .preview-artist {
    font-family: var(--font-mono);
    font-size: 10px;
    color: var(--muted);
    flex-shrink: 0;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    max-width: 120px;
  }

  footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 14px 20px;
    border-top: var(--border);
    flex-shrink: 0;
  }

  .submit-btn {
    background: #1db954;
    color: #fff;
    border: none;
    border-radius: 6px;
    padding: 9px 20px;
    font-family: var(--font-serif);
    font-size: 15px;
    cursor: pointer;
  }
  .submit-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
  .submit-btn.secondary {
    background: none;
    border: var(--border);
    color: var(--ink);
  }

  .error-msg {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--accent);
  }

  .result-area {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 12px;
    padding: 40px 20px;
  }

  .result-msg {
    font-family: var(--font-serif);
    font-size: 18px;
    color: var(--ink);
  }
  .result-msg.error {
    color: var(--accent);
  }

  .open-link {
    display: flex;
    align-items: center;
    gap: 5px;
    font-family: var(--font-mono);
    font-size: 11px;
    color: #1db954;
    text-decoration: none;
    letter-spacing: 0.3px;
  }
  .open-link:hover {
    text-decoration: underline;
  }

  .reauth-hint {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--muted);
    text-align: center;
  }

  .reauth-link {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--ink);
    text-decoration: underline;
    letter-spacing: 0.3px;
  }

  .switch {
    position: relative;
    width: 36px;
    height: 20px;
    border-radius: 10px;
    background: var(--muted);
    border: none;
    cursor: pointer;
    padding: 0;
    flex-shrink: 0;
    transition: background 0.2s;
    opacity: 0.5;
  }
  .switch.on {
    background: #1db954;
    opacity: 1;
  }
  .switch-thumb {
    position: absolute;
    top: 3px;
    left: 3px;
    width: 14px;
    height: 14px;
    border-radius: 50%;
    background: white;
    transition: transform 0.2s;
  }
  .switch.on .switch-thumb {
    transform: translateX(16px);
  }

  .sync-error-banner {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--accent);
    background: rgba(192, 57, 43, 0.06);
    border-bottom: 1px solid rgba(192, 57, 43, 0.2);
    padding: 10px 20px;
    letter-spacing: 0.2px;
  }

  .sync-field {
    border-top: var(--border);
    padding-top: 14px;
  }

  .sync-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .sync-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    margin-top: 8px;
  }

  .save-sync-btn {
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.4px;
    background: none;
    border: var(--border);
    border-radius: 4px;
    padding: 5px 12px;
    cursor: pointer;
    color: var(--ink);
    flex-shrink: 0;
  }
  .save-sync-btn:disabled {
    opacity: 0.4;
    cursor: not-allowed;
  }
</style>
