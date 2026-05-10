<script lang="ts">
  import { goto } from "$app/navigation";
  import {
    IconChevronLeft,
    IconChevronRight,
    IconPlus,
    IconCheck,
    IconX,
    IconPencil,
    IconTrash,
  } from "@tabler/icons-svelte";
  import { onMount } from "svelte";
  import { api } from "$lib/api";
  import { rankings, type Ranking } from "$lib/stores/rankings.svelte";

  let {
    activeId,
    drawerOpen = false,
    onClose = () => {}
  }: { activeId?: number; drawerOpen?: boolean; onClose?: () => void } = $props();

  let collapsed = $state(false);
  let isMobile = $state(false);
  let effectiveCollapsed = $derived(collapsed && !isMobile);

  onMount(() => {
    const mq = window.matchMedia('(max-width: 640px)');
    isMobile = mq.matches;
    const handler = (e: MediaQueryListEvent) => { isMobile = e.matches; };
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  });
  let creating = $state(false);
  let newName = $state("");
  let saving = $state(false);
  let renamingId = $state<number | null>(null);
  let renameValue = $state("");

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

  function startRename(ranking: Ranking) {
    renamingId = ranking.id;
    renameValue = ranking.name;
  }

  function cancelRename() {
    renamingId = null;
    renameValue = "";
  }

  async function submitRename() {
    if (!renameValue.trim() || !renamingId) return;
    try {
      const updated = await api.patch<Ranking>(`/api/v1/rankings/${renamingId}`, {
        ranking: { name: renameValue.trim() },
      });
      rankings.update(updated);
      renamingId = null;
    } catch {
      // keep editing on error
    }
  }

  async function deleteRanking(ranking: Ranking) {
    if (!confirm(`Delete "${ranking.name}"? This cannot be undone.`)) return;
    try {
      await api.delete(`/api/v1/rankings/${ranking.id}`);
      rankings.remove(ranking.id);
      if (activeId === ranking.id) goto("/");
    } catch {
      // silently ignore
    }
  }
</script>

<aside class="sidebar" class:collapsed={effectiveCollapsed} class:drawer-open={drawerOpen}>
  <div class="header">
    {#if !collapsed}
      <span class="label">Rankings</span>
    {/if}
    <button
      class="icon-btn"
      onclick={() => (collapsed = !collapsed)}
      title={collapsed ? "Expand" : "Collapse"}
    >
      {#if effectiveCollapsed}
        <IconChevronRight size={16} />
      {:else}
        <IconChevronLeft size={16} />
      {/if}
    </button>
  </div>

  <nav class="tabs">
    {#each rankings.list as ranking (ranking.id)}
      {#if effectiveCollapsed}
        <a
          class="glyph-tab"
          class:active={ranking.id === activeId}
          href="/rankings/{ranking.id}"
          title={ranking.name}
        >
          {firstGlyph(ranking.name)}
        </a>
      {:else if renamingId === ranking.id}
        <div class="tab-row rename-row">
          <!-- svelte-ignore a11y_autofocus -->
          <input
            autofocus
            class="rename-input"
            bind:value={renameValue}
            onkeydown={(e) => {
              if (e.key === "Enter") submitRename();
              if (e.key === "Escape") cancelRename();
            }}
          />
          <button class="icon-btn" onclick={submitRename} disabled={!renameValue.trim()}>
            <IconCheck size={13} />
          </button>
          <button class="icon-btn" onclick={cancelRename}>
            <IconX size={13} />
          </button>
        </div>
      {:else}
        <div class="tab-row" class:active={ranking.id === activeId}>
          <a class="tab-link" href="/rankings/{ranking.id}">{ranking.name}</a>
          <div class="tab-actions">
            <button class="tab-icon-btn" onclick={() => startRename(ranking)} title="Rename">
              <IconPencil size={12} />
            </button>
            <button class="tab-icon-btn danger" onclick={() => deleteRanking(ranking)} title="Delete">
              <IconTrash size={12} />
            </button>
          </div>
        </div>
      {/if}
    {/each}
  </nav>

  <div class="footer">
    {#if effectiveCollapsed}
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

  @media (max-width: 640px) {
    .sidebar {
      position: fixed;
      left: 0;
      top: 0;
      height: 100%;
      z-index: 200;
      width: 280px;
      padding: 24px 16px;
      transform: translateX(-100%);
      transition: transform 0.2s ease;
    }
    .sidebar.drawer-open {
      transform: translateX(0);
    }
    .header .icon-btn { display: none; }
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

  .tab-row {
    display: flex;
    align-items: center;
    border: var(--border);
    border-radius: 6px;
    padding: 0 6px 0 11px;
    min-height: 40px;
    gap: 4px;
  }
  .tab-row.active {
    background: var(--ink);
    color: var(--paper);
  }
  .tab-row.active .tab-link {
    color: var(--paper);
  }
  .tab-row.active .tab-icon-btn {
    color: rgba(255, 255, 255, 0.45);
  }
  .tab-row.active .tab-icon-btn:hover {
    color: rgba(255, 255, 255, 0.9);
    background: none;
  }

  .tab-link {
    flex: 1;
    font-family: var(--font-serif);
    font-size: 16px;
    line-height: 1.2;
    color: var(--ink);
    text-decoration: none;
    word-break: break-word;
    padding: 9px 0;
  }

  .tab-actions {
    display: flex;
    gap: 0;
    flex-shrink: 0;
    opacity: 0;
    transition: opacity 0.15s;
  }
  .tab-row:hover .tab-actions {
    opacity: 1;
  }

  .tab-icon-btn {
    background: none;
    border: none;
    border-radius: 3px;
    width: 22px;
    height: 22px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    color: rgba(26, 26, 26, 0.3);
    flex-shrink: 0;
    padding: 0;
    transition: color 0.1s;
  }
  .tab-icon-btn:hover { color: var(--ink); background: none; }
  .tab-icon-btn.danger:hover { color: #c0392b; background: none; }

  .rename-row {
    padding: 6px 6px 6px 8px;
  }

  .rename-input {
    flex: 1;
    border: none;
    border-bottom: 1px solid var(--muted);
    background: none;
    font-family: var(--font-serif);
    font-size: 15px;
    color: var(--ink);
    outline: none;
    padding: 2px 4px;
    min-width: 0;
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
