<script lang="ts">
  import { page } from "$app/stores";
  import { onMount, untrack } from "svelte";
  import {
    IconPlus,
    IconLoader2,
    IconArrowsShuffle,
    IconShare,
    IconCheck,
    IconRotate,
  } from "@tabler/icons-svelte";
  import { PUBLIC_API_BASE_URL } from "$env/static/public";
  import { api, ApiError } from "$lib/api";
  import { auth } from "$lib/stores/auth.svelte";
  import { rankings } from "$lib/stores/rankings.svelte";
  import { flagStore } from "$lib/stores/signals.svelte";
  import type { BaseSong, RankedSong } from "$lib/types";
  import SongCard from "$lib/components/SongCard.svelte";
  import SongImportModal from "$lib/components/SongImportModal.svelte";
  import RankedList from "$lib/components/RankedList.svelte";

  interface Matchup {
    song_a: BaseSong;
    song_b: BaseSong;
  }

  let rankingId = $derived(parseInt($page.params.id ?? "0"));
  let ranking = $derived(rankings.list.find((r) => r.id === rankingId));

  let matchup = $state<Matchup | null>(null);
  let matchupPhase = $state<
    "loading" | "ready" | "picking" | "empty" | "error"
  >("loading");
  let rankedSongs = $state<RankedSong[]>([]);
  let shownPairs = $state<string[]>([]);
  let importOpen = $state(false);
  let exportOpen = $state(false);
  let copyFeedback = $state(false);
  let mobileTab = $state<"match" | "ranking">("match");

  async function fetchExportText(): Promise<string> {
    const res = await fetch(
      `${PUBLIC_API_BASE_URL}/api/v1/rankings/${rankingId}/export`,
      {
        headers: {
          Authorization: `Bearer ${auth.token}`,
          Accept: "text/plain",
        },
      },
    );
    if (!res.ok) throw new Error("export failed");
    return res.text();
  }

  async function copyToClipboard() {
    const text = await fetchExportText();
    await navigator.clipboard.writeText(text);
    exportOpen = false;
    copyFeedback = true;
    setTimeout(() => (copyFeedback = false), 2000);
  }

  async function downloadTxt() {
    const text = await fetchExportText();
    const name = ranking?.name ?? "ranking";
    const blob = new Blob([text], { type: "text/plain" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `${name}.txt`;
    a.click();
    URL.revokeObjectURL(url);
    exportOpen = false;
  }

  $effect(() => {
    if (rankingId) {
      untrack(() => {
        loadNext();
        loadSongs();
      });
    }
  });

  function nextUrl() {
    const parts: string[] = [];
    const flagQs = flagStore.toQueryString();
    if (flagQs) parts.push(flagQs.slice(1));
    if (shownPairs.length > 0) parts.push(`skip_pairs=${shownPairs.join(";")}`);
    return `/api/v1/rankings/${rankingId}/matchups/next${parts.length ? `?${parts.join("&")}` : ""}`;
  }

  async function loadNext() {
    if (matchup) {
      const pair = [matchup.song_a.id, matchup.song_b.id]
        .sort((a, b) => a - b)
        .join(",");
      shownPairs = [...shownPairs.slice(-9), pair];
    }
    matchupPhase = "loading";
    try {
      const result = await api.get<Matchup>(nextUrl());
      matchup = result;
      matchupPhase = "ready";
    } catch (err: unknown) {
      matchupPhase =
        err instanceof ApiError && err.status === 422 ? "empty" : "error";
    }
  }

  async function loadSongs() {
    try {
      rankedSongs = await api.get<RankedSong[]>(
        `/api/v1/rankings/${rankingId}/songs`,
      );
    } catch {
      // non-critical — list just stays stale
    }
  }

  async function pick(winnerId: number) {
    if (!matchup || matchupPhase !== "ready") return;
    matchupPhase = "picking";
    try {
      await api.post(`/api/v1/rankings/${rankingId}/matchups`, {
        matchup: {
          winner_id: winnerId,
          song_a_id: matchup.song_a.id,
          song_b_id: matchup.song_b.id,
        },
      });
      flagStore.tick();
      await Promise.all([loadNext(), loadSongs()]);
    } catch {
      matchupPhase = "error";
    }
  }

  function skip() {
    loadNext();
  }

  async function onSongsAdded() {
    shownPairs = [];
    await Promise.all([loadNext(), loadSongs()]);
  }

  async function resetRanking() {
    if (
      !confirm("Reset all ELO scores and match history? This cannot be undone.")
    )
      return;
    shownPairs = [];
    await api.post(`/api/v1/rankings/${rankingId}/reset`, {});
    await Promise.all([loadNext(), loadSongs()]);
  }

  async function removeSong(songId: number) {
    try {
      await api.delete(`/api/v1/rankings/${rankingId}/songs/${songId}`);
      rankedSongs = rankedSongs.filter((s) => s.id !== songId);
      loadNext();
    } catch {
      // non-critical
    }
  }

  function onKeydown(e: KeyboardEvent) {
    if ((e.metaKey || e.ctrlKey) && e.key === "k") {
      e.preventDefault();
      importOpen = true;
      return;
    }
    if (!matchup || matchupPhase !== "ready") return;
    if (e.key === "ArrowLeft") pick(matchup.song_a.id);
    if (e.key === "ArrowRight") pick(matchup.song_b.id);
    if (e.key === "s" || e.key === "S") skip();
  }

  onMount(() => {
    return () => {
      matchup = null;
    };
  });
</script>

<svelte:window onkeydown={onKeydown} />

<div class="mobile-tabs">
  <button
    class="mobile-tab"
    class:active={mobileTab === "match"}
    onclick={() => (mobileTab = "match")}>Match</button
  >
  <button
    class="mobile-tab"
    class:active={mobileTab === "ranking"}
    onclick={() => {
      mobileTab = "ranking";
      exportOpen = false;
    }}>Ranking</button
  >
</div>

<!-- center: matchup -->
<div class="center" class:mobile-hidden={mobileTab !== "match"}>
  {#if ranking}
    <div class="matchup-header">
      <p class="label">which do you prefer?</p>
      <p class="ranking-name">{ranking.name}</p>
    </div>
  {/if}

  <div class="cards-area">
    {#if matchupPhase === "loading" || matchupPhase === "picking"}
      <div class="state-msg">
        <IconLoader2 size={24} class="spin" />
      </div>
    {:else if matchupPhase === "empty"}
      <div class="state-msg">
        <p class="state-title">not enough songs</p>
        <p class="state-sub">add at least 2 songs using the + button</p>
      </div>
    {:else if matchupPhase === "error"}
      <div class="state-msg">
        <p class="state-title">something went wrong</p>
        <button class="retry-btn" onclick={loadNext}>retry</button>
      </div>
    {:else if matchup}
      <SongCard
        song={matchup.song_a}
        tilt={-1.2}
        disabled={matchupPhase !== "ready"}
        flag={flagStore.get(matchup.song_a.id)?.type}
        onPick={() => pick(matchup!.song_a.id)}
        onClearFlag={() => flagStore.clear(matchup!.song_a.id)}
      />
      <SongCard
        song={matchup.song_b}
        tilt={1.2}
        disabled={matchupPhase !== "ready"}
        flag={flagStore.get(matchup.song_b.id)?.type}
        onPick={() => pick(matchup!.song_b.id)}
        onClearFlag={() => flagStore.clear(matchup!.song_b.id)}
      />
    {/if}
  </div>

  {#if matchupPhase === "ready"}
    <div class="controls">
      <button class="control-btn" onclick={skip}>
        <IconArrowsShuffle size={14} />
        Skip
      </button>
      <p class="key-hint">← → to pick · S to skip · ⌘K to add</p>
    </div>
  {/if}
</div>

<!-- right: ranked list -->
<aside class="right-panel" class:mobile-hidden={mobileTab !== "ranking"}>
  <div class="panel-header">
    <div class="panel-title">
      <span class="title-text">Your ranking</span>
      {#if rankedSongs.length > 0}
        <span class="song-count">{rankedSongs.length} songs · sorted</span>
      {/if}
    </div>
    <div class="panel-actions">
      {#if rankedSongs.length > 0}
        <div class="export-wrap">
          <button
            class="icon-btn"
            class:active={copyFeedback}
            onclick={() => (exportOpen = !exportOpen)}
            title="Export"
          >
            {#if copyFeedback}
              <IconCheck size={14} />
            {:else}
              <IconShare size={14} />
            {/if}
          </button>
          {#if exportOpen}
            <!-- svelte-ignore a11y_click_events_have_key_events -->
            <!-- svelte-ignore a11y_no_static_element_interactions -->
            <div
              class="export-overlay"
              onclick={() => (exportOpen = false)}
            ></div>
            <div class="export-menu">
              <button class="export-item" onclick={copyToClipboard}
                >Copy to clipboard</button
              >
              <button class="export-item" onclick={downloadTxt}
                >Download .txt</button
              >
            </div>
          {/if}
        </div>
      {/if}
      {#if rankedSongs.length > 0}
        <button class="icon-btn" onclick={resetRanking} title="Reset ranking">
          <IconRotate size={14} />
        </button>
      {/if}
      <button
        class="icon-btn"
        onclick={() => (importOpen = true)}
        title="Add songs"
      >
        <IconPlus size={14} />
      </button>
    </div>
  </div>

  {#if rankedSongs.length === 0}
    <div class="empty-list">
      <p>add songs to start ranking</p>
    </div>
  {:else}
    <RankedList songs={rankedSongs} onRemove={removeSong} />
  {/if}
</aside>

{#if importOpen && ranking}
  <SongImportModal
    {rankingId}
    rankingName={ranking.name}
    onClose={() => (importOpen = false)}
    onAdded={onSongsAdded}
  />
{/if}

<style>
  :global(.spin) {
    animation: spin 1s linear infinite;
  }
  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }

  .center {
    flex: 1;
    border-right: var(--border);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 40px 56px;
    gap: 32px;
    overflow: hidden;
  }

  .matchup-header {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 6px;
    flex-shrink: 0;
  }

  .label {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 1px;
    text-transform: uppercase;
    color: var(--muted);
  }

  .ranking-name {
    font-family: var(--font-serif);
    font-size: 28px;
  }

  .cards-area {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 72px;
    flex: 1;
    min-height: 0;
  }

  .state-msg {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 12px;
    color: var(--muted);
  }

  .state-title {
    font-family: var(--font-serif);
    font-size: 20px;
    color: var(--ink);
  }

  .state-sub {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--muted);
    letter-spacing: 0.3px;
  }

  .retry-btn {
    background: none;
    border: var(--border);
    border-radius: 6px;
    padding: 8px 18px;
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.3px;
    cursor: pointer;
    color: var(--ink);
  }

  .controls {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 8px;
    flex-shrink: 0;
  }

  .control-btn {
    display: flex;
    align-items: center;
    gap: 6px;
    background: none;
    border: var(--border);
    border-radius: 20px;
    padding: 8px 16px;
    font-family: var(--font-serif);
    font-size: 14px;
    cursor: pointer;
    color: var(--ink);
  }
  .control-btn:hover {
    background: rgba(26, 26, 26, 0.04);
  }

  .key-hint {
    font-family: var(--font-mono);
    font-size: 10px;
    color: var(--muted);
    letter-spacing: 0.5px;
  }

  .right-panel {
    width: 400px;
    flex-shrink: 0;
    display: flex;
    flex-direction: column;
    background: var(--paper);
    overflow: hidden;
  }

  .panel-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 18px 18px 14px;
    border-bottom: var(--border);
    flex-shrink: 0;
  }

  .panel-title {
    display: flex;
    align-items: baseline;
    gap: 8px;
  }

  .title-text {
    font-family: var(--font-serif);
    font-size: 20px;
  }

  .song-count {
    font-family: var(--font-mono);
    font-size: 10px;
    color: var(--muted);
    letter-spacing: 0.5px;
    text-transform: uppercase;
  }

  .panel-actions {
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .icon-btn {
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
  .icon-btn.active {
    background: var(--ink);
    color: var(--paper);
  }

  .export-wrap {
    position: relative;
  }

  .export-overlay {
    position: fixed;
    inset: 0;
    z-index: 9;
  }

  .export-menu {
    position: absolute;
    right: 0;
    top: calc(100% + 6px);
    background: var(--paper);
    border: var(--border);
    border-radius: 6px;
    padding: 4px;
    min-width: 160px;
    box-shadow: 3px 3px 0 0 rgba(0, 0, 0, 0.06);
    z-index: 10;
  }

  .export-item {
    display: block;
    width: 100%;
    text-align: left;
    background: none;
    border: none;
    border-radius: 4px;
    padding: 8px 12px;
    font-family: var(--font-serif);
    font-size: 14px;
    color: var(--ink);
    cursor: pointer;
  }
  .export-item:hover {
    background: rgba(26, 26, 26, 0.06);
  }

  .empty-list {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 1.5px dashed var(--muted);
    border-radius: 6px;
    margin: 16px;
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--muted);
    letter-spacing: 0.3px;
    text-align: center;
    padding: 24px;
  }

  .mobile-tabs {
    display: none;
  }

  @media (max-width: 640px) {
    .mobile-hidden {
      display: none !important;
    }

    .mobile-tabs {
      display: flex;
      border-bottom: var(--border);
      flex-shrink: 0;
    }
    .mobile-tab {
      flex: 1;
      padding: 10px;
      font-family: var(--font-mono);
      font-size: 11px;
      letter-spacing: 0.8px;
      text-transform: uppercase;
      border: none;
      border-bottom: 2px solid transparent;
      background: none;
      cursor: pointer;
      color: var(--muted);
      margin-bottom: -1px;
    }
    .mobile-tab.active {
      color: var(--ink);
      border-bottom-color: var(--ink);
    }

    .center {
      padding: 20px 16px;
      border-right: none;
      gap: 20px;
    }
    .ranking-name {
      font-size: 22px;
    }
    .cards-area {
      gap: 16px;
    }
    .key-hint {
      display: none;
    }

    .right-panel {
      width: 100%;
      flex: 1;
    }
  }
</style>
