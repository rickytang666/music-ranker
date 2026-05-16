<script lang="ts">
  import type { RankedSong } from "$lib/types";
  import AlbumArt from "./AlbumArt.svelte";

  let { songs }: { songs: RankedSong[] } = $props();

  interface AlbumRow {
    key: string;
    album_name: string;
    artist_name: string;
    album_art_url: string | null;
    song_count: number;
    avg_rank: number;
    avg_elo: number;
    best_rank: number;
    worst_rank: number;
  }

  let albums = $derived.by(() => {
    const map = new Map<string, Array<{ song: RankedSong; rank: number }>>();

    songs.forEach((song, i) => {
      const key = song.album_name ?? `__singles__${song.artist_name}`;
      if (!map.has(key)) map.set(key, []);
      map.get(key)!.push({ song, rank: i + 1 });
    });

    const rows: AlbumRow[] = [];
    for (const [key, entries] of map) {
      const ranks = entries.map((e) => e.rank);
      const elos = entries.map((e) => e.song.elo_score);
      rows.push({
        key,
        album_name: entries[0].song.album_name ?? "Singles",
        artist_name: entries[0].song.artist_name,
        album_art_url: entries[0].song.album_art_url,
        song_count: entries.length,
        avg_rank: ranks.reduce((a, b) => a + b, 0) / ranks.length,
        avg_elo: elos.reduce((a, b) => a + b, 0) / elos.length,
        best_rank: Math.min(...ranks),
        worst_rank: Math.max(...ranks),
      });
    }

    return rows.sort((a, b) => b.avg_elo - a.avg_elo);
  });
</script>

<div class="list">
  {#each albums as album, i (album.key)}
    <div class="row">
      <span class="rank">{i + 1}</span>

      <AlbumArt src={album.album_art_url} alt={album.album_name} size={36} />

      <div class="meta">
        <span class="album-name">{album.album_name}</span>
        <span class="artist">{album.artist_name}</span>
      </div>

      <div class="stats">
        <span class="avg-rank">#{album.avg_rank.toFixed(1)}</span>
        <span class="stat-label">avg rank</span>
        <span class="song-count">{album.song_count} songs</span>
      </div>
    </div>
  {/each}
</div>

<style>
  .list {
    display: flex;
    flex-direction: column;
    overflow-y: auto;
    flex: 1;
  }

  .row {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 9px 18px;
    border-bottom: 1px dashed var(--muted);
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
    color: var(--muted);
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
    font-family: var(--font-mono);
    font-size: 9.5px;
    color: var(--muted);
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
    font-family: var(--font-mono);
    font-size: 8px;
    color: var(--muted);
    letter-spacing: 1px;
    text-transform: uppercase;
    line-height: 1;
  }

  .song-count {
    font-family: var(--font-mono);
    font-size: 8px;
    color: var(--muted);
    letter-spacing: 0.5px;
    line-height: 1;
    opacity: 0.6;
  }
</style>
