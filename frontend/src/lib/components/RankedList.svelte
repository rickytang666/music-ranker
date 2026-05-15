<script lang="ts">
	import { IconTrendingDown, IconTrendingUp, IconQuestionMark, IconX } from '@tabler/icons-svelte';
	import { matchupStore, type FlagType } from '$lib/stores/signals.svelte';
	import type { RankedSong } from '$lib/types';
	import AlbumArt from './AlbumArt.svelte';

	let {
		songs,
		onRemove,
		onFlag
	}: {
		songs: RankedSong[];
		onRemove?: (id: number) => void;
		onFlag?: (songId: number, type: FlagType) => void;
	} = $props();

	function handleFlag(songId: number, type: FlagType) {
		if (matchupStore.isFlagged(songId)) return;
		onFlag?.(songId, type);
	}
</script>

<div class="list">
	{#each songs as song, i (song.id)}
		<div class="row">
			<span class="rank">{i + 1}</span>

			<AlbumArt src={song.album_art_url} alt={song.album_name ?? song.title} size={36} />

			<div class="meta">
				<span class="title">{song.title}</span>
				<span class="artist">{song.artist_name}</span>
				{#if song.album_name}
					<span class="album">{song.album_name}</span>
				{/if}
			</div>

			<div class="elo-col">
				<span class="elo-score">{Math.round(song.elo_score)}</span>
				<span class="elo-label">elo</span>
				<span class="matchup-count">{song.matchup_count}×</span>
			</div>

			<div class="actions">
				<button
					class="action-btn"
					class:active={matchupStore.getFlagType(song.id) === 'underrated'}
					onclick={() => handleFlag(song.id, 'underrated')}
					title="Underrated"
				>
					<IconTrendingUp size={13} />
				</button>
				<button
					class="action-btn"
					class:active={matchupStore.getFlagType(song.id) === 'overrated'}
					onclick={() => handleFlag(song.id, 'overrated')}
					title="Overrated"
				>
					<IconTrendingDown size={13} />
				</button>
				<button
					class="action-btn"
					class:active={matchupStore.getFlagType(song.id) === 'unsure'}
					onclick={() => handleFlag(song.id, 'unsure')}
					title="Unsure"
				>
					<IconQuestionMark size={13} />
				</button>
				{#if onRemove}
					<button class="action-btn remove" onclick={() => onRemove!(song.id)} title="Remove">
						<IconX size={13} />
					</button>
				{/if}
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
		user-select: none;
	}
	.row:last-child { border-bottom: none; }

	.actions {
		display: flex;
		align-items: center;
		gap: 2px;
		flex-shrink: 0;
		opacity: 0;
		transition: opacity 0.15s;
	}
	.row:hover .actions { opacity: 1; }

	/* always visible on touch devices */
	@media (hover: none) {
		.actions { opacity: 1; }
	}

	.action-btn {
		background: none;
		border: none;
		border-radius: 4px;
		width: 22px;
		height: 22px;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		color: var(--muted);
		padding: 0;
		transition: color 0.1s, background 0.1s;
	}
	.action-btn:hover { color: var(--ink); background: rgba(26,26,26,0.06); }
	.action-btn.active { color: var(--ink); }
	.action-btn.remove:hover { color: #c0392b; background: rgba(192,57,43,0.07); }

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

	.album {
		font-family: var(--font-mono);
		font-size: 9px;
		color: var(--muted);
		letter-spacing: 0.3px;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		opacity: 0.6;
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

	.matchup-count {
		font-family: var(--font-mono);
		font-size: 8px;
		color: var(--muted);
		letter-spacing: 0.5px;
		line-height: 1;
		opacity: 0.6;
	}
</style>
