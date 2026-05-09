<script lang="ts">
	import { flagStore, type FlagType } from '$lib/stores/signals.svelte';

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

	interface MenuState {
		songId: number;
		x: number;
		y: number;
	}

	let menu = $state<MenuState | null>(null);

	function onContextMenu(e: MouseEvent, songId: number) {
		e.preventDefault();
		// keep menu inside viewport
		const menuW = 160;
		const menuH = 120;
		const x = e.clientX + menuW > window.innerWidth ? e.clientX - menuW : e.clientX;
		const y = e.clientY + menuH > window.innerHeight ? e.clientY - menuH : e.clientY;
		menu = { songId, x, y };
	}

	function pickFlag(type: FlagType) {
		if (!menu) return;
		flagStore.set(menu.songId, type);
		menu = null;
	}

	function clearFlag() {
		if (!menu) return;
		flagStore.clear(menu.songId);
		menu = null;
	}

	function dismiss() {
		menu = null;
	}

	function onKeydown(e: KeyboardEvent) {
		if (e.key === 'Escape') menu = null;
	}
</script>

<svelte:window onkeydown={onKeydown} />

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
{#if menu}
	<div class="overlay" onclick={dismiss}></div>
	<div class="context-menu" style="left: {menu.x}px; top: {menu.y}px">
		<button class="menu-item" class:active={flagStore.get(menu.songId)?.type === 'overrated'} onclick={() => pickFlag('overrated')}>
			Overrated
		</button>
		<button class="menu-item" class:active={flagStore.get(menu.songId)?.type === 'underrated'} onclick={() => pickFlag('underrated')}>
			Underrated
		</button>
		<button class="menu-item" class:active={flagStore.get(menu.songId)?.type === 'unsure'} onclick={() => pickFlag('unsure')}>
			Unsure
		</button>
		{#if flagStore.get(menu.songId)}
			<div class="menu-divider"></div>
			<button class="menu-item muted" onclick={clearFlag}>Clear flag</button>
		{/if}
	</div>
{/if}

<div class="list">
	{#each songs as song, i (song.id)}
		<!-- svelte-ignore a11y_no_static_element_interactions -->
		<div class="row" oncontextmenu={(e) => onContextMenu(e, song.id)}>
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
				<span class="elo-score">{Math.round(song.elo_score)}</span>
				<span class="elo-label">elo</span>
			</div>
		</div>
	{/each}
</div>

<style>
	.overlay {
		position: fixed;
		inset: 0;
		z-index: 49;
	}

	.context-menu {
		position: fixed;
		z-index: 50;
		background: var(--paper);
		border: var(--border);
		border-radius: 6px;
		padding: 4px;
		min-width: 148px;
		box-shadow: 3px 3px 0 0 rgba(0, 0, 0, 0.06);
	}

	.menu-item {
		display: block;
		width: 100%;
		text-align: left;
		background: none;
		border: none;
		border-radius: 4px;
		padding: 8px 12px;
		font-family: var(--font-serif);
		font-size: 15px;
		color: var(--ink);
		cursor: pointer;
	}
	.menu-item:hover { background: rgba(26, 26, 26, 0.06); }
	.menu-item.active { font-weight: 600; }
	.menu-item.muted { color: var(--muted); font-size: 13px; }

	.menu-divider {
		height: 1px;
		background: rgba(26, 26, 26, 0.1);
		margin: 4px 8px;
	}

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
	.row:hover { background: rgba(26, 26, 26, 0.02); }

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
