<script lang="ts">
	export interface RankedSong {
		id: number;
		title: string;
		artist_name: string;
		album_name: string | null;
		album_art_url: string | null;
		elo_score: number;
		matchup_count: number;
	}

	let { songs }: { songs: RankedSong[] } = $props();
</script>

<div class="list">
	{#each songs as song, i (song.id)}
		<div class="row">
			<span class="rank">{i + 1}</span>

			{#if song.album_art_url}
				<img src={song.album_art_url} alt={song.album_name ?? song.title} class="art" />
			{:else}
				<div class="art placeholder"></div>
			{/if}

			<div class="meta">
				<span class="title">{song.title}</span>
				<span class="artist">{song.artist_name}</span>
			</div>

			<div class="elo-col">
				<span class="elo-score">{song.elo_score}</span>
				<span class="elo-label">elo</span>
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
	.row:last-child { border-bottom: none; }

	.rank {
		font-family: var(--font-serif);
		font-size: 15px;
		width: 22px;
		text-align: right;
		flex-shrink: 0;
		color: var(--muted);
	}

	.art {
		width: 36px;
		height: 36px;
		border-radius: 3px;
		object-fit: cover;
		flex-shrink: 0;
		border: 1px solid rgba(26, 26, 26, 0.12);
	}
	.art.placeholder {
		background: repeating-linear-gradient(135deg, transparent 0 5px, rgba(0,0,0,0.06) 5px 6px);
		border: var(--border);
	}

	.meta {
		flex: 1;
		display: flex;
		flex-direction: column;
		gap: 3px;
		min-width: 0;
	}

	.title {
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

	.elo-col {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		flex-shrink: 0;
		gap: 2px;
	}

	.elo-score {
		font-family: var(--font-mono);
		font-size: 13px;
		font-weight: 500;
		font-variant-numeric: tabular-nums;
		line-height: 1;
	}

	.elo-label {
		font-family: var(--font-mono);
		font-size: 8px;
		color: var(--muted);
		letter-spacing: 1px;
		text-transform: uppercase;
		line-height: 1;
	}
</style>
