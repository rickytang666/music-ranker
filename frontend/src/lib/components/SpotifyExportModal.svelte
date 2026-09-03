<script lang="ts">
  import { IconMinus, IconPlus, IconExternalLink } from "@tabler/icons-svelte";
  import { PUBLIC_API_BASE_URL } from "$env/static/public";
  import { api, ApiError, describeError } from "$lib/api";
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
  // snapshot at submit time: editing the form afterwards must not rewrite history
  let exportedName = $state("");
  let exportedCount = $state(0);
  let exportedPublic = $state(false);

  let autoSync = $state(syncCount !== null);
  let syncCountValue = $state(
    Math.min(syncCount ?? lastExportCount ?? DEFAULT_COUNT, rankedSongs.length),
  );
  let syncSaving = $state(false);
  // the sync setting used to need a separate save press, and skipping it
  // discarded the change silently; it now persists on its own
  let syncStatus = $state<"idle" | "saving" | "saved" | "failed">("idle");
  let syncSaveError = $state("");
  let syncTimer: ReturnType<typeof setTimeout> | null = null;

  function queueSyncSave() {
    if (!autoSync) return;
    if (syncTimer) clearTimeout(syncTimer);
    syncStatus = "saving";
    syncTimer = setTimeout(() => {
      syncTimer = null;
      persistSync(syncCountValue);
    }, 600);
  }

  // used before exporting and before closing so a pending change cannot be lost
  function flushSyncSave() {
    if (!syncTimer) return;
    clearTimeout(syncTimer);
    syncTimer = null;
    return persistSync(syncCountValue);
  }

  async function persistSync(newCount: number | null) {
    syncSaving = true;
    syncStatus = "saving";
    syncSaveError = "";
    try {
      await api.patch(`/api/v1/rankings/${rankingId}`, {
        ranking: { spotify_sync_count: newCount },
      });
      onSyncUpdated(newCount);
      syncStatus = "saved";
    } catch (e) {
      console.error("[export] saving auto-sync failed", e);
      syncSaveError = describeError(e).message;
      syncStatus = "failed";
    } finally {
      syncSaving = false;
    }
  }

  function closeAfterFlush() {
    flushSyncSave();
    onClose();
  }

  let preview = $derived(rankedSongs.slice(0, count));
  let hasExisting = $derived(!!spotifyPlaylistId);

  function decrementSync() {
    if (syncCountValue > 1) {
      syncCountValue--;
      queueSyncSave();
    }
  }
  function incrementSync() {
    if (syncCountValue < rankedSongs.length) {
      syncCountValue++;
      queueSyncSave();
    }
  }
  function parseCount(e: Event, max: number): number {
    const val = parseInt((e.target as HTMLInputElement).value);
    return isNaN(val) ? max : Math.max(1, Math.min(max, val));
  }

  function onSyncCountInput(e: Event) {
    syncCountValue = parseCount(e, rankedSongs.length);
    queueSyncSave();
  }

  async function toggleSync() {
    if (syncTimer) {
      clearTimeout(syncTimer);
      syncTimer = null;
    }
    autoSync = !autoSync;
    await persistSync(autoSync ? syncCountValue : null);
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
    await flushSyncSave();
    phase = "loading";
    try {
      const exportResult = await api.post<{ status: string; playlist_url: string }>(
        `/api/v1/rankings/${rankingId}/export/spotify`,
        { name: name.trim() || rankingName, count, public: isPublic },
      );
      playlistUrl = exportResult.playlist_url;
      exportedName = name.trim() || rankingName;
      exportedCount = count;
      exportedPublic = isPublic;
      resultMsg =
        exportResult.status === "created" ? "playlist created" : "playlist updated";
      phase = "success";
      const id = exportResult.playlist_url.split("/").pop() ?? "";
      onExported(id, count);
    } catch (err: unknown) {
      console.error("[export] export failed", err);
      // read the status rather than substring-matching the message
      if (err instanceof ApiError && err.status === 403) {
        phase = "reauth";
        return;
      }
      resultMsg = describeError(err, { subject: "spotify" }).message;
      phase = "error";
    }
  }
</script>

{#snippet stepper(value: number, onDecrement: () => void, onIncrement: () => void, oninput: (e: Event) => void, label: string, what: string)}
  <div class="stepper">
    <button
      class="step-btn"
      onclick={onDecrement}
      disabled={value <= 1}
      aria-label="Decrease {what}"
    >
      <IconMinus size={12} />
    </button>
    <input
      class="count-input"
      type="number"
      min={1}
      max={rankedSongs.length}
      aria-label={what}
      {value}
      {oninput}
    />
    <button
      class="step-btn"
      onclick={onIncrement}
      disabled={value >= rankedSongs.length}
      aria-label="Increase {what}"
    >
      <IconPlus size={12} />
    </button>
    <span class="count-of">{label}</span>
  </div>
{/snippet}

<Modal title="export to spotify" onClose={closeAfterFlush}>
  {#if phase === "success"}
    <div class="result-area">
      <p class="result-msg">{resultMsg}</p>
      <!-- the user just made four choices; echo them back rather than only "done" -->
      <p class="result-detail">
        {exportedName} &middot; {exportedCount}
        {exportedCount === 1 ? "song" : "songs"} &middot;
        {exportedPublic ? "public" : "private"}
      </p>
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
      <button class="submit-btn secondary" onclick={() => (phase = "idle")}
        >back to settings</button
      >
      <button class="submit-btn" onclick={closeAfterFlush}>done</button>
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
        {@render stepper(count, decrement, increment, onCountInput, `of ${rankedSongs.length}`, "songs to export")}
        <span class="field-hint">this export only</span>
      </div>

      <div class="field visibility-field">
        <span class="label" id="visibility-label">visibility</span>
        <div class="toggle-row" role="group" aria-labelledby="visibility-label">
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
            aria-label="Daily auto-sync"
          >
            <span class="switch-thumb"></span>
          </button>
        </div>
        {#if autoSync}
          <div class="sync-row">
            {@render stepper(syncCountValue, decrementSync, incrementSync, onSyncCountInput, "top songs synced daily", "songs synced daily")}
            <span class="sync-status" role="status" aria-live="polite">
              {#if syncStatus === "saving"}saving…
              {:else if syncStatus === "saved"}saved
              {:else if syncStatus === "failed"}not saved
              {/if}
            </span>
          </div>
          {#if syncSaveError}
            <p class="sync-save-error" role="alert">{syncSaveError}</p>
          {/if}
        {/if}
      </div>
    </div>

    <div class="preview-header">
      <span class="label">preview ({count} {count === 1 ? "song" : "songs"})</span>
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
    font-family: var(--font-ui);
    font-size: 10px;
    letter-spacing: 0.8px;
    text-transform: uppercase;
    color: var(--text-muted);
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
    font-family: var(--font-ui);
    font-size: 11px;
    color: var(--text-muted);
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
    font-family: var(--font-ui);
    font-size: 11px;
    letter-spacing: 0.4px;
    padding: 6px 14px;
    cursor: pointer;
    color: var(--text-muted);
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
    /* was ~105px, about three rows out of a hundred */
    min-height: 170px;
    padding: 0 0 4px;
  }

  .preview-row {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 5px 20px;
  }
  .preview-row:hover {
    background: var(--wash);
  }

  .preview-rank {
    font-family: var(--font-mono);
    font-size: 10px;
    color: var(--text-muted);
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
    font-family: var(--font-ui);
    font-size: 10px;
    color: var(--text-muted);
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
    background: var(--spotify);
    color: var(--paper);
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
    font-family: var(--font-ui);
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

  .result-detail {
    font-family: var(--font-ui);
    font-size: 12px;
    color: var(--text-muted);
    text-align: center;
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
    font-family: var(--font-ui);
    font-size: 11px;
    color: var(--spotify);
    text-decoration: none;
    letter-spacing: 0.3px;
  }
  .open-link:hover {
    text-decoration: underline;
  }

  .reauth-hint {
    font-family: var(--font-ui);
    font-size: 11px;
    color: var(--text-muted);
    text-align: center;
  }

  .reauth-link {
    font-family: var(--font-ui);
    font-size: 11px;
    color: var(--ink);
    text-decoration: underline;
    letter-spacing: 0.3px;
  }

  /* 36x20 failed the 24px minimum tap target */
  .switch {
    position: relative;
    width: 44px;
    height: 24px;
    border-radius: 12px;
    background: var(--text-muted);
    border: none;
    cursor: pointer;
    padding: 0;
    flex-shrink: 0;
    transition: background 0.2s;
    opacity: 0.5;
  }
  .switch.on {
    background: var(--spotify);
    opacity: 1;
  }
  .switch-thumb {
    position: absolute;
    top: 3px;
    left: 3px;
    width: 18px;
    height: 18px;
    border-radius: 50%;
    background: white;
    transition: transform 0.2s;
  }
  .switch.on .switch-thumb {
    transform: translateX(20px);
  }

  .sync-error-banner {
    font-family: var(--font-ui);
    font-size: 11px;
    color: var(--accent);
    background: var(--danger-softer);
    border-bottom: 1px solid var(--danger-edge);
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

  .field-hint {
    margin-top: 6px;
    font-family: var(--font-ui);
    font-size: 11px;
    color: var(--text-muted);
  }

  .sync-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    margin-top: 8px;
  }

  .sync-status {
    font-family: var(--font-ui);
    font-size: 11px;
    color: var(--text-muted);
    white-space: nowrap;
    min-width: 52px;
  }
  .sync-save-error {
    margin-top: 6px;
    font-family: var(--font-ui);
    font-size: 11px;
    color: var(--danger);
  }
</style>
