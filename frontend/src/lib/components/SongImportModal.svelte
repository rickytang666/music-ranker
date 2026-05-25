<script lang="ts">
	import { IconSearch, IconX, IconLoader2 } from '@tabler/icons-svelte';
	import { api } from '$lib/api';
	import type { BaseSong } from '$lib/types';
	import ImportItem from './ImportItem.svelte';

	interface AlbumResult {
		id: string;
		name: string;
		artist_name: string;
		image_url: string | null;
		release_date?: string;
	}

	interface ArtistResult {
		id: string;
		name: string;
		image_url: string | null;
	}

	let {
		rankingId,
		rankingName,
		onClose,
		onAdded
	}: {
		rankingId: number;
		rankingName: string;
		onClose: () => void;
		onAdded: () => void;
	} = $props();

	type Mode = 'song' | 'album' | 'artist';
	type Phase = 'idle' | 'searching' | 'results' | 'loading' | 'discography' | 'tracks' | 'no-results' | 'error';

	let mode = $state<Mode>('song');
	let phase = $state<Phase>('idle');
	let query = $state('');
	let errorMsg = $state('');
	let loadingMsg = $state('loading…');
	let saving = $state(false);

	let songResults = $state<BaseSong[]>([]);
	let albumResults = $state<AlbumResult[]>([]);
	let artistResults = $state<ArtistResult[]>([]);
	let selectedItems = $state(new Set<string>());

	let tracks = $state<BaseSong[]>([]);
	let selectedTracks = $state(new Set<number>());

	let searchTimer: ReturnType<typeof setTimeout>;

	const placeholders: Record<Mode, string> = {
		song: 'Search for a song…',
		album: 'Search for an album…',
		artist: 'Search for an artist…'
	};

	function switchMode(m: Mode) {
		if (mode === m) return;
		mode = m;
		query = '';
		phase = 'idle';
		songResults = [];
		albumResults = [];
		artistResults = [];
		selectedItems = new Set();
		tracks = [];
		selectedTracks = new Set();
		clearTimeout(searchTimer);
	}

	function onInput() {
		clearTimeout(searchTimer);
		const q = query.trim();
		if (!q) { phase = 'idle'; return; }
		phase = 'searching';
		searchTimer = setTimeout(() => doSearch(q), 400);
	}

	async function doSearch(q: string) {
		selectedItems = new Set();
		selectedTracks = new Set();
		try {
			if (mode === 'song') {
				const r = await api.get<BaseSong[]>(`/api/v1/spotify/search/tracks?q=${encodeURIComponent(q)}`);
				songResults = r;
				phase = r.length ? 'results' : 'no-results';
			} else if (mode === 'album') {
				const r = await api.get<AlbumResult[]>(`/api/v1/spotify/search/albums?q=${encodeURIComponent(q)}`);
				albumResults = r;
				phase = r.length ? 'results' : 'no-results';
			} else {
				const r = await api.get<ArtistResult[]>(`/api/v1/spotify/search/artists?q=${encodeURIComponent(q)}`);
				artistResults = r;
				phase = r.length ? 'results' : 'no-results';
			}
		} catch {
			errorMsg = 'search failed. check your connection.';
			phase = 'error';
		}
	}

	function toggleItem(id: string) {
		// eslint-disable-next-line svelte/prefer-svelte-reactivity
		const next = new Set(selectedItems);
		if (next.has(id)) { next.delete(id); } else { next.add(id); }
		selectedItems = next;
	}

	function toggleAllItems() {
		selectedItems =
			selectedItems.size === albumResults.length
				? new Set()
				: new Set(albumResults.map((a) => a.id));
	}

	function toggleTrack(id: number) {
		// eslint-disable-next-line svelte/prefer-svelte-reactivity
		const next = new Set(selectedTracks);
		if (next.has(id)) { next.delete(id); } else { next.add(id); }
		selectedTracks = next;
	}

	function toggleAllTracks() {
		selectedTracks =
			selectedTracks.size === tracks.length ? new Set() : new Set(tracks.map((t) => t.id));
	}

	async function loadDiscography(artistId: string) {
		selectedItems = new Set();
		loadingMsg = 'loading discography…';
		phase = 'loading';
		try {
			albumResults = await api.get<AlbumResult[]>(`/api/v1/spotify/artists/${artistId}/albums`);
			selectedItems = new Set(albumResults.map((a) => a.id));
			phase = albumResults.length ? 'discography' : 'no-results';
		} catch {
			errorMsg = 'failed to load discography. try again.';
			phase = 'error';
		}
	}

	async function loadTracks() {
		if (!selectedItems.size) return;
		loadingMsg = `loading ${selectedItems.size} album${selectedItems.size > 1 ? 's' : ''}…`;
		phase = 'loading';
		try {
			const batches = await Promise.all(
				albumResults
					.filter((a) => selectedItems.has(a.id))
					.map((album) => {
						const p = new URLSearchParams({ name: album.name, art: album.image_url ?? '', release_date: album.release_date ?? '' });
						return api.get<BaseSong[]>(`/api/v1/spotify/albums/${album.id}/tracks?${p}`);
					})
			);
			// eslint-disable-next-line svelte/prefer-svelte-reactivity
		const seen = new Set<number>();
			tracks = batches.flat().filter((t) => {
				if (seen.has(t.id)) return false;
				seen.add(t.id);
				return true;
			});
			selectedTracks = new Set(tracks.map((t) => t.id));
			phase = 'tracks';
		} catch {
			errorMsg = 'failed to load tracks. try again.';
			phase = 'error';
		}
	}

	function backToResults() {
		phase = mode === 'artist' ? 'discography' : 'results';
		tracks = [];
		selectedTracks = new Set();
	}

	function backToArtistResults() {
		phase = 'results';
		albumResults = [];
		selectedItems = new Set();
	}

	async function addSongs() {
		const ids = [...selectedTracks];
		if (!ids.length || saving) return;
		saving = true;
		try {
			await api.post(`/api/v1/rankings/${rankingId}/songs`, { song_ids: ids });
			onAdded();
			onClose();
		} catch {
			errorMsg = 'failed to add songs. try again.';
			saving = false;
		}
	}

	function onOverlayClick(e: MouseEvent) {
		if (e.target === e.currentTarget) onClose();
	}

	function onKeydown(e: KeyboardEvent) {
		if (e.key === 'Escape') onClose();
	}

	let canAdd = $derived(
		(mode === 'song' && phase === 'results' && selectedTracks.size > 0) ||
		(phase === 'tracks' && selectedTracks.size > 0)
	);
	let canLoad = $derived(
		(phase === 'results' && mode === 'album' && selectedItems.size > 0) ||
		(phase === 'discography' && selectedItems.size > 0)
	);
</script>

<svelte:window onkeydown={onKeydown} />

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div class="overlay" onclick={onOverlayClick}>
	<div class="modal" role="dialog" aria-modal="true">
		<header>
			<div class="header-text">
				<span class="modal-title">Add songs</span>
				<span class="ranking-name">— {rankingName}</span>
			</div>
			<button class="close-btn" onclick={onClose} aria-label="Close">
				<IconX size={16} />
			</button>
		</header>

		<div class="mode-tabs">
			{#each (['song', 'album', 'artist'] as Mode[]) as m (m)}
				<button class="mode-tab" class:active={mode === m} onclick={() => switchMode(m)}>
					{m}
				</button>
			{/each}
		</div>

		<div class="search-row">
			<IconSearch size={16} class="search-icon" />
			<!-- svelte-ignore a11y_autofocus -->
			<input
				type="search"
				placeholder={placeholders[mode]}
				bind:value={query}
				oninput={onInput}
				autofocus
			/>
		</div>

		<div class="content">
			{#if phase === 'idle'}
				<p class="hint">search for a {mode} to import</p>

			{:else if phase === 'searching' || phase === 'loading'}
				<div class="spinner-row">
					<IconLoader2 size={18} class="spin" />
					<span>{phase === 'searching' ? 'searching…' : loadingMsg}</span>
				</div>

			{:else if phase === 'results' && mode === 'song'}
				<ul class="item-list">
					{#each songResults as track (track.id)}
						<li>
							<ImportItem
								imageUrl={track.album_art_url}
								name={track.title}
								sub={track.artist_name + (track.album_name ? ` · ${track.album_name}` : '')}
								selected={selectedTracks.has(track.id)}
								onSelect={() => toggleTrack(track.id)}
							/>
						</li>
					{/each}
				</ul>

			{:else if phase === 'results' && mode === 'album'}
				<ul class="item-list">
					{#each albumResults as album (album.id)}
						<li>
							<ImportItem
								imageUrl={album.image_url}
								name={album.name}
								sub={album.artist_name}
								selected={selectedItems.has(album.id)}
								onSelect={() => toggleItem(album.id)}
							/>
						</li>
					{/each}
				</ul>

			{:else if phase === 'results' && mode === 'artist'}
				<ul class="item-list">
					{#each artistResults as artist (artist.id)}
						<li>
							<ImportItem
								imageUrl={artist.image_url}
								imageShape="round"
								name={artist.name}
								variant="navigate"
								onSelect={() => loadDiscography(artist.id)}
							/>
						</li>
					{/each}
				</ul>

			{:else if phase === 'discography'}
				<div class="list-header">
					<button class="text-btn" onclick={backToArtistResults}>← back</button>
					<button class="text-btn" onclick={toggleAllItems}>
						{selectedItems.size === albumResults.length ? 'deselect all' : 'select all'}
					</button>
				</div>
				<ul class="item-list">
					{#each albumResults as album (album.id)}
						<li>
							<ImportItem
								imageUrl={album.image_url}
								name={album.name}
								sub={album.artist_name}
								selected={selectedItems.has(album.id)}
								onSelect={() => toggleItem(album.id)}
							/>
						</li>
					{/each}
				</ul>

			{:else if phase === 'tracks'}
				<div class="list-header">
					<button class="text-btn" onclick={backToResults}>← back</button>
					<button class="text-btn" onclick={toggleAllTracks}>
						{selectedTracks.size === tracks.length ? 'deselect all' : 'select all'}
					</button>
				</div>
				<ul class="item-list">
					{#each tracks as track (track.id)}
						<li>
							<ImportItem
								imageUrl={track.album_art_url}
								name={track.title}
								sub={track.artist_name + (track.album_name ? ` · ${track.album_name}` : '')}
								selected={selectedTracks.has(track.id)}
								onSelect={() => toggleTrack(track.id)}
							/>
						</li>
					{/each}
				</ul>

			{:else if phase === 'no-results'}
				<p class="hint">no results for "{query}"</p>

			{:else if phase === 'error'}
				<p class="hint error">{errorMsg}</p>
			{/if}
		</div>

		<footer>
			<span class="count">
				{#if phase === 'tracks'}
					{selectedTracks.size} / {tracks.length} selected
				{:else if mode === 'song' && phase === 'results'}
					{selectedTracks.size > 0 ? `${selectedTracks.size} selected` : ''}
				{:else if (phase === 'results' || phase === 'discography') && selectedItems.size > 0}
					{selectedItems.size} selected
				{/if}
			</span>
			{#if canLoad}
				<button class="add-btn" onclick={loadTracks}>Load tracks →</button>
			{:else}
				<button class="add-btn" onclick={addSongs} disabled={!canAdd || saving}>
					{saving ? 'adding…' : selectedTracks.size > 0 ? `Add ${selectedTracks.size} songs` : 'Add songs'}
				</button>
			{/if}
		</footer>
	</div>
</div>

<style>
	.overlay {
		position: fixed;
		inset: 0;
		background: rgba(26, 26, 26, 0.4);
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 100;
	}

	.modal {
		background: var(--paper);
		border: var(--border);
		border-radius: 8px;
		width: 680px;
		max-width: 95vw;
		max-height: 80vh;
		display: flex;
		flex-direction: column;
		overflow: hidden;
	}

	header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 18px 20px 14px;
		border-bottom: var(--border);
		flex-shrink: 0;
	}

	.header-text {
		display: flex;
		align-items: baseline;
		gap: 8px;
	}

	.modal-title { font-family: var(--font-serif); font-size: 20px; }

	.ranking-name {
		font-family: var(--font-mono);
		font-size: 11px;
		color: var(--muted);
		letter-spacing: 0.3px;
	}

	.close-btn {
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
	}

	.mode-tabs {
		display: flex;
		border-bottom: var(--border);
		flex-shrink: 0;
	}

	.mode-tab {
		padding: 9px 20px;
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
	.mode-tab.active { color: var(--ink); border-bottom-color: var(--ink); }

	.search-row {
		display: flex;
		align-items: center;
		gap: 10px;
		padding: 12px 20px;
		border-bottom: var(--border);
		flex-shrink: 0;
		color: var(--muted);
	}

	.search-row input {
		flex: 1;
		border: none;
		background: none;
		font-family: var(--font-serif);
		font-size: 16px;
		color: var(--ink);
		outline: none;
	}

	.content { flex: 1; overflow-y: auto; padding: 12px 0; }

	.hint {
		font-family: var(--font-mono);
		font-size: 11px;
		color: var(--muted);
		text-align: center;
		padding: 40px 20px;
		letter-spacing: 0.3px;
	}
	.hint.error { color: var(--accent); }

	.spinner-row {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 10px;
		padding: 40px 20px;
		font-family: var(--font-mono);
		font-size: 11px;
		color: var(--muted);
	}

	:global(.spin) { animation: spin 1s linear infinite; }
	@keyframes spin { to { transform: rotate(360deg); } }

	ul { list-style: none; }
	.item-list { padding: 0 8px; }

	.list-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 4px 20px 10px;
	}

	.text-btn {
		background: none;
		border: none;
		font-family: var(--font-mono);
		font-size: 11px;
		color: var(--muted);
		cursor: pointer;
		letter-spacing: 0.3px;
		padding: 0;
	}
	.text-btn:hover { color: var(--ink); }

	footer {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 14px 20px;
		border-top: var(--border);
		flex-shrink: 0;
	}

	.count {
		font-family: var(--font-mono);
		font-size: 11px;
		color: var(--muted);
		letter-spacing: 0.3px;
	}

	.add-btn {
		background: var(--ink);
		color: var(--paper);
		border: var(--border);
		border-radius: 6px;
		padding: 9px 20px;
		font-family: var(--font-serif);
		font-size: 15px;
		cursor: pointer;
	}
	.add-btn:disabled { opacity: 0.35; cursor: not-allowed; }

	@media (max-width: 640px) {
		.overlay { align-items: flex-end; background: rgba(26, 26, 26, 0.5); }
		.modal {
			width: 100%;
			max-width: 100%;
			max-height: 92vh;
			border-radius: 12px 12px 0 0;
			border-bottom: none;
		}
	}
</style>
