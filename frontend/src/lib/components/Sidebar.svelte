<script lang="ts">
  import { goto } from "$app/navigation";
  import {
    IconChevronLeft,
    IconChevronRight,
    IconPlus,
    IconCheck,
    IconX,
  } from "@tabler/icons-svelte";
  import { api } from "$lib/api";
  import { rankings, type Ranking } from "$lib/stores/rankings.svelte";

  let { activeId }: { activeId?: number } = $props();

  let collapsed = $state(false);
  let creating = $state(false);
  let newName = $state("");
  let saving = $state(false);

  function firstGlyph(name: string) {
    const first = Array.from(name.trim())[0] ?? "";
    return /[a-z]/i.test(first) ? first.toUpperCase() : first;
  }

  async function createRanking() {
    if (!newName.trim()) return;
    saving = true;
    try {
      const ranking = await api.post<Ranking>("/api/v1/rankings", {
        ranking: { name: newName.trim() },
      });
      rankings.add(ranking);
      newName = "";
      creating = false;
      goto(`/rankings/${ranking.id}`);
    } finally {
      saving = false;
    }
  }

  function cancelCreate() {
    newName = "";
    creating = false;
  }
</script>

<aside class="sidebar" class:collapsed>
  <div class="header">
    {#if !collapsed}
      <span class="label">Rankings</span>
    {/if}
    <button
      class="icon-btn"
      onclick={() => (collapsed = !collapsed)}
      title={collapsed ? "Expand" : "Collapse"}
    >
      {#if collapsed}
        <IconChevronRight size={16} />
      {:else}
        <IconChevronLeft size={16} />
      {/if}
    </button>
  </div>

  <nav class="tabs">
    {#each rankings.list as ranking (ranking.id)}
      {#if collapsed}
        <a
          class="glyph-tab"
          class:active={ranking.id === activeId}
          href="/rankings/{ranking.id}"
          title={ranking.name}
        >
          {firstGlyph(ranking.name)}
        </a>
      {:else}
        <a
          class="tab"
          class:active={ranking.id === activeId}
          href="/rankings/{ranking.id}"
        >
          {ranking.name}
        </a>
      {/if}
    {/each}
  </nav>

  <div class="footer">
    {#if collapsed}
      <button
        class="glyph-add"
        onclick={() => {
          collapsed = false;
          creating = true;
        }}
        title="New ranking"
      >
        <IconPlus size={16} />
      </button>
    {:else if creating}
      <div class="new-ranking-form">
        <!-- svelte-ignore a11y_autofocus -->
        <input
          autofocus
          bind:value={newName}
          placeholder="Ranking name"
          onkeydown={(e) => {
            if (e.key === "Enter") createRanking();
            if (e.key === "Escape") cancelCreate();
          }}
          disabled={saving}
        />
        <div class="form-actions">
          <button
            class="icon-btn"
            onclick={createRanking}
            disabled={saving || !newName.trim()}
          >
            <IconCheck size={14} />
          </button>
          <button class="icon-btn" onclick={cancelCreate} disabled={saving}>
            <IconX size={14} />
          </button>
        </div>
      </div>
    {:else}
      <button class="new-ranking-btn" onclick={() => (creating = true)}>
        <IconPlus size={14} />
        New Ranking
      </button>
    {/if}
  </div>
</aside>

<style>
  .sidebar {
    width: 220px;
    flex-shrink: 0;
    border-right: var(--border);
    background: var(--paper);
    display: flex;
    flex-direction: column;
    padding: 20px 16px;
    gap: 16px;
    transition: width 0.2s ease;
  }
  .sidebar.collapsed {
    width: 56px;
    padding: 20px 10px;
    align-items: center;
  }

  .header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-shrink: 0;
  }
  .collapsed .header {
    justify-content: center;
  }

  .label {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 1px;
    text-transform: uppercase;
    color: var(--muted);
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
  .icon-btn:disabled {
    opacity: 0.4;
    cursor: not-allowed;
  }

  .tabs {
    display: flex;
    flex-direction: column;
    gap: 8px;
    flex: 1;
    overflow-y: auto;
  }

  .tab {
    display: block;
    border: var(--border);
    border-radius: 6px;
    padding: 9px 11px;
    font-family: var(--font-serif);
    font-size: 16px;
    line-height: 1.2;
    color: var(--ink);
    text-decoration: none;
    word-break: break-word;
  }
  .tab.active {
    background: var(--ink);
    color: var(--paper);
  }

  .glyph-tab {
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    border: var(--border);
    border-radius: 6px;
    width: 36px;
    height: 36px;
    font-family: var(--font-serif);
    font-size: 16px;
    color: var(--ink);
    text-decoration: none;
  }
  .glyph-tab.active {
    background: var(--ink);
    color: var(--paper);
  }
  /* active accent bar */
  .glyph-tab.active::before {
    content: "";
    position: absolute;
    left: -4px;
    top: 6px;
    bottom: 6px;
    width: 2px;
    background: var(--accent);
    border-radius: 1px;
  }

  .footer {
    flex-shrink: 0;
  }

  .new-ranking-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    width: 100%;
    border: 1.5px dashed var(--ink);
    border-radius: 6px;
    padding: 10px;
    font-family: var(--font-serif);
    font-size: 15px;
    background: none;
    color: var(--ink);
    cursor: pointer;
  }

  .glyph-add {
    display: flex;
    align-items: center;
    justify-content: center;
    border: 1.5px dashed var(--ink);
    border-radius: 6px;
    width: 36px;
    height: 36px;
    background: none;
    color: var(--ink);
    cursor: pointer;
  }

  .new-ranking-form {
    display: flex;
    flex-direction: column;
    gap: 6px;
    border: var(--border);
    border-radius: 6px;
    padding: 8px;
  }
  .new-ranking-form input {
    border: none;
    border-bottom: 1px solid var(--muted);
    background: none;
    font-family: var(--font-serif);
    font-size: 15px;
    color: var(--ink);
    outline: none;
    padding: 2px 0;
    width: 100%;
  }
  .form-actions {
    display: flex;
    gap: 6px;
    justify-content: flex-end;
  }
</style>
