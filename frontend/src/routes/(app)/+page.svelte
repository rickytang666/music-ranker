<script lang="ts">
  import { goto } from "$app/navigation";
  import { api, describeError } from "$lib/api";
  import { rankings, type Ranking } from "$lib/stores/rankings.svelte";
  import { IconPlus, IconMusic } from "@tabler/icons-svelte";

  let creating = $state(false);
  let newName = $state("");
  let saving = $state(false);
  let createError = $state("");
  let nameInput = $state<HTMLInputElement | null>(null);

  $effect(() => {
    if (creating) nameInput?.focus();
  });

  // EloService leaves a song provisional under 10 matchups, and each matchup covers two songs
  const MATCHUPS_PER_SONG_TO_SETTLE = 5;

  function percentRanked(ranking: Ranking): number {
    const target = ranking.song_count * MATCHUPS_PER_SONG_TO_SETTLE;
    if (target === 0) return 0;
    return Math.min(100, Math.round((ranking.matchup_count / target) * 100));
  }

  async function createRanking() {
    const name = newName.trim();
    if (!name || saving) return;
    saving = true;
    createError = "";
    try {
      const ranking = await api.post<Ranking>("/api/v1/rankings", {
        ranking: { name },
      });
      rankings.add(ranking);
      goto(`/rankings/${ranking.id}`);
    } catch (e) {
      console.error("[home] create ranking failed", e);
      createError = describeError(e).message;
      saving = false;
    }
  }

  function cancel() {
    creating = false;
    newName = "";
    createError = "";
  }
</script>

<div class="page">
  <div class="inner">
    {#if rankings.list.length === 0}
      <div class="blank">
        <IconMusic size={28} stroke={1.5} />
        <h1 class="blank-title">Start your first ranking</h1>
        <p class="blank-sub">
          Pick an artist or album, then decide song by song which one you like more.
        </p>
      </div>
    {:else}
      <header class="head">
        <h1 class="title">Your rankings</h1>
        <p class="sub">{rankings.list.length} in progress</p>
      </header>

      <div class="grid">
        {#each rankings.list as ranking (ranking.id)}
          <a class="card" href="/rankings/{ranking.id}">
            <span class="card-name">{ranking.name}</span>
            <span class="card-meta">
              {ranking.song_count}
              {ranking.song_count === 1 ? "song" : "songs"}
              &middot;
              {ranking.matchup_count}
              {ranking.matchup_count === 1 ? "matchup" : "matchups"}
            </span>
            <span class="bar" aria-hidden="true">
              <span class="fill" style="width: {percentRanked(ranking)}%"></span>
            </span>
            <span class="card-progress">{percentRanked(ranking)}% ranked</span>
          </a>
        {/each}
      </div>
    {/if}

    {#if creating}
      <div class="create-form">
        <input
          bind:this={nameInput}
          bind:value={newName}
          placeholder="Ranking name"
          disabled={saving}
          onkeydown={(e) => {
            if (e.key === "Enter") createRanking();
            if (e.key === "Escape") cancel();
          }}
        />
        <button class="primary" onclick={createRanking} disabled={saving || !newName.trim()}>
          {saving ? "creating…" : "create"}
        </button>
        <button class="ghost" onclick={cancel} disabled={saving}>cancel</button>
      </div>
      {#if createError}
        <p class="create-error" role="alert">{createError}</p>
      {/if}
    {:else}
      <button class="new-btn" onclick={() => (creating = true)}>
        <IconPlus size={16} />
        New ranking
      </button>
    {/if}
  </div>
</div>

<style>
  /* padding scales so small screens are not left with a sliver of content */
  .page {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: clamp(16px, 5vw, 48px);
    overflow-y: auto;
  }
  .inner {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 24px;
    width: 100%;
    max-width: 720px;
  }

  .head {
    text-align: center;
  }
  .title {
    font-family: var(--font-serif);
    font-size: clamp(24px, 7vw, 32px);
    line-height: 1.2;
  }
  .sub {
    margin-top: 4px;
    font-family: var(--font-ui);
    font-size: 12px;
    color: var(--text-muted);
  }

  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
    gap: 12px;
    width: 100%;
  }
  .card {
    display: flex;
    flex-direction: column;
    gap: 6px;
    padding: 16px;
    border: var(--border);
    border-radius: 8px;
    text-decoration: none;
    color: var(--ink);
    background: var(--paper);
    transition: background 0.1s;
  }
  .card:hover {
    background: var(--surface-hover);
  }
  .card-name {
    font-family: var(--font-serif);
    font-size: 18px;
    line-height: 1.25;
    word-break: break-word;
  }
  .card-meta,
  .card-progress {
    font-family: var(--font-ui);
    font-size: 11px;
    color: var(--text-muted);
  }
  .bar {
    display: block;
    height: 4px;
    margin-top: 4px;
    border-radius: 2px;
    background: var(--surface-active);
    overflow: hidden;
  }
  .fill {
    display: block;
    height: 100%;
    background: var(--ink);
  }

  .blank {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 10px;
    text-align: center;
    color: var(--ink);
    padding: clamp(24px, 6vw, 40px) clamp(16px, 5vw, 40px);
  }
  .blank-title {
    font-family: var(--font-serif);
    font-size: clamp(24px, 7vw, 32px);
    line-height: 1.2;
  }
  .blank-sub {
    max-width: 34ch;
    font-family: var(--font-serif);
    font-size: 15px;
    line-height: 1.5;
    color: var(--text-muted);
  }

  .new-btn,
  .primary,
  .ghost {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    font-family: var(--font-ui);
    font-size: 13px;
    padding: 9px 16px;
    border-radius: 6px;
    cursor: pointer;
  }
  .new-btn,
  .ghost {
    background: none;
    border: 1.5px solid var(--ink);
    color: var(--ink);
  }
  .new-btn:hover,
  .ghost:hover:not(:disabled) {
    background: var(--surface-hover);
  }
  .primary {
    background: var(--ink);
    border: 1.5px solid var(--ink);
    color: var(--paper);
  }
  .primary:disabled {
    background: none;
    border-color: var(--line-soft);
    color: var(--text-muted);
    cursor: not-allowed;
  }

  .create-form {
    display: flex;
    gap: 8px;
    width: 100%;
    max-width: 420px;
  }
  .create-form input {
    flex: 1;
    min-width: 0;
    padding: 9px 12px;
    font-family: var(--font-serif);
    font-size: 15px;
    color: var(--ink);
    background: var(--paper);
    border: 1.5px solid var(--line-soft);
    border-radius: 6px;
  }
  .create-form input:focus {
    outline: none;
    border-color: var(--ink);
  }
  .create-error {
    font-family: var(--font-ui);
    font-size: 12px;
    color: var(--danger);
  }
</style>
