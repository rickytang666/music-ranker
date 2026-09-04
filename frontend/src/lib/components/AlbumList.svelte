<script lang="ts">
  import type { RankedSong } from "$lib/types";
  import AlbumArt from "./AlbumArt.svelte";
  import { IconChevronRight } from "@tabler/icons-svelte";
  import { albumKey, albumLabel } from "$lib/albums";

  let {
    songs,
    onSelect,
  }: { songs: RankedSong[]; onSelect?: (key: string) => void } = $props();

  interface AlbumRow {
    key: string;
    album_name: string;
    artist_name: string;
    album_art_url: string | null;
    song_count: number;
    avg_rank: number;
    mean_elo: number;
  }

  let albums = $derived.by(() => {
    // eslint-disable-next-line svelte/prefer-svelte-reactivity
    const map = new Map<string, Array<{ song: RankedSong; rank: number }>>();

    songs.forEach((song, i) => {
      const key = albumKey(song);
      if (!map.has(key)) map.set(key, []);
      map.get(key)!.push({ song, rank: i + 1 });
    });

    const rows: AlbumRow[] = [];
    for (const [key, entries] of map) {
      const ranks = entries.map((e) => e.rank);
      const elos = entries.map((e) => e.song.elo_score);
      const mean_elo = elos.reduce((a, b) => a + b, 0) / elos.length;
      rows.push({
        key,
        album_name: albumLabel(entries[0].song),
        artist_name: entries[0].song.artist_name,
        album_art_url: entries[0].song.album_art_url,
        song_count: entries.length,
        avg_rank: ranks.reduce((a, b) => a + b, 0) / ranks.length,
        mean_elo: mean_elo,
      });
    }

    return rows.sort((a, b) => b.mean_elo - a.mean_elo);
  });
</script>

{#snippet rowBody(album: AlbumRow, i: number)}
  <span class="rank">{i + 1}</span>

  <AlbumArt src={album.album_art_url} alt={album.album_name} size={36} />

  <div class="meta">
    <span class="album-name">{album.album_name}</span>
    <span class="artist">{album.artist_name}</span>
  </div>

  <div class="stats">
    <span class="avg-rank">#{album.avg_rank.toFixed(1)}</span>
    <span class="stat-label">avg rank</span>
    <span class="song-count">{Math.round(album.mean_elo)} elo · {album.song_count} songs</span>
  </div>

  {#if onSelect}
    <!-- always visible, not hover only: touch devices have no hover to reveal it -->
    <span class="chevron" aria-hidden="true"><IconChevronRight size={16} /></span>
  {/if}
{/snippet}

<div class="list">
  {#each albums as album, i (album.key)}
    {#if onSelect}
      <button
        class="row selectable"
        onclick={() => onSelect(album.key)}
        title="Show only {album.album_name}"
      >
        {@render rowBody(album, i)}
      </button>
    {:else}
      <div class="row">{@render rowBody(album, i)}</div>
    {/if}
  {/each}
</div>

<style>
  .list {
    display: flex;
    flex-direction: column;
    overflow-y: auto;
    flex: 1;
  }

  .chevron {
    display: flex;
    align-items: center;
    flex-shrink: 0;
    margin-left: 4px;
    color: var(--text-muted);
  }
  .row.selectable:hover .chevron {
    color: var(--ink);
  }

  .row.selectable {
    width: 100%;
    text-align: left;
    background: none;
    font: inherit;
    color: inherit;
    cursor: pointer;
    /* a button carries a default 2px outset bevel on every side; only the
       dashed bottom from .row should survive */
    border: none;
    border-bottom: 1px dashed var(--text-muted);
  }
  .row.selectable:hover {
    background: var(--surface-hover);
  }

  .row {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 9px 18px;
    border-bottom: 1px dashed var(--text-muted);
    flex-shrink: 0;
  }
  .row:last-child {
    border-bottom: none;
  }

  .rank {
    font-family: var(--font-serif);
    font-size: 15px;
    width: 22px;
    text-align: right;
    flex-shrink: 0;
    color: var(--text-muted);
  }

  .meta {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 3px;
    min-width: 0;
  }

  .album-name {
    font-family: var(--font-serif);
    font-size: 14px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    line-height: 1.2;
  }

  .artist {
    font-family: var(--font-ui);
    font-size: 9.5px;
    color: var(--text-muted);
    letter-spacing: 0.4px;
    text-transform: uppercase;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .stats {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    flex-shrink: 0;
    gap: 2px;
  }

  .avg-rank {
    font-family: var(--font-mono);
    font-size: 13px;
    font-weight: 500;
    font-variant-numeric: tabular-nums;
    line-height: 1;
  }

  .stat-label {
    font-family: var(--font-ui);
    font-size: 8px;
    color: var(--text-muted);
    letter-spacing: 1px;
    text-transform: uppercase;
    line-height: 1;
  }

  .song-count {
    font-family: var(--font-ui);
    font-size: 8px;
    color: var(--text-muted);
    letter-spacing: 0.5px;
    line-height: 1;
    opacity: 0.6;
  }
</style>
