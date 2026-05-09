<script lang="ts">
	import {
		IconSearch,
		IconX,
		IconChevronRight,
		IconCheck,
		IconLoader2
	} from '@tabler/icons-svelte';
	import { api } from '$lib/api';

	interface Artist {
		id: string;
		name: string;
		image_url: string | null;
	}

	interface Track {
		id: number;
		title: string;
		artist_name: string;
		album_name: string | null;
		album_art_url: string | null;
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
		onAdded: (count: number) => void;
	} = $props();

	type Phase = 'idle' | 'searching' | 'artists' | 'loading-tracks' | 'tracks' | 'no-results' | 'error';

	let phase = $state<Phase>('idle');
	let query = $state('');
	let artists = $state<Artist[]>([]);
	let tracks = $state<Track[]>([]);
	let selected = $state(new Set<number>());
	let activeArtist = $state<Artist | null>(null);
	let errorMsg = $state('');
	let saving = $state(false);

	let searchTimer: ReturnType<typeof setTimeout>;

	function onInput() {
		clearTimeout(searchTimer);
		const q = query.trim();
		if (!q) { phase = 'idle'; return; }
		searchTimer = setTimeout(() => searchArtists(q), 400);
	}

	async function searchArtists(q: string) {
		phase = 'searching';
		try {
			const results = await api.get<Artist[]>(`/api/v1/spotify/search/artists?q=${encodeURIComponent(q)}`);
			artists = results;
			phase = results.length ? 'artists' : 'no-results';
		} catch {
			errorMsg = 'search failed. check your connection.';
			phase = 'error';
		}
	}

	async function loadTracks(artist: Artist) {
		activeArtist = artist;
		phase = 'loading-tracks';
		selected = new Set();
		try {
			const results = await api.get<Track[]>(`/api/v1/spotify/artists/${artist.id}/tracks`);
			tracks = results;
			phase = 'tracks';
		} catch {
			errorMsg = 'failed to load tracks. try again.';
			phase = 'error';
		}
	}

	function toggleTrack(id: number) {
		const next = new Set(selected);
		next.has(id) ? next.delete(id) : next.add(id);
		selected = next;
	}

	function toggleAll() {
		selected = selected.size === tracks.length
			? new Set()
			: new Set(tracks.map((t) => t.id));
	}

	function backToArtists() {
		phase = 'artists';
		activeArtist = null;
	}

	async function addSongs() {
		if (!selected.size || saving) return;
		saving = true;
		try {
			const result = await api.post<{ added: number }>(
				`/api/v1/rankings/${rankingId}/songs`,
				{ song_ids: [...selected] }
			);
			onAdded(result.added);
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

		<div class="search-row">
			<IconSearch size={16} class="search-icon" />
			<!-- svelte-ignore a11y_autofocus -->
			<input
				type="search"
				placeholder="Search for an artist…"
				bind:value={query}
				oninput={onInput}
				autofocus
			/>
		</div>

		<div class="content">
			{#if phase === 'idle'}
				<p class="hint">search for an artist to import their songs</p>

			{:else if phase === 'searching'}
				<div class="spinner-row">
					<IconLoader2 size={18} class="spin" />
					<span>searching…</span>
				</div>

			{:else if phase === 'artists'}
				<ul class="artist-list">
					{#each artists as artist (artist.id)}
						<li>
							<button class="artist-row" onclick={() => loadTracks(artist)}>
								{#if artist.image_url}
									<img src={artist.image_url} alt={artist.name} class="artist-img" />
								{:else}
									<div class="artist-img placeholder"></div>
								{/if}
								<span class="artist-name">{artist.name}</span>
								<IconChevronRight size={14} class="chevron" />
							</button>
						</li>
					{/each}
				</ul>

			{:else if phase === 'loading-tracks'}
				<div class="spinner-row">
					<IconLoader2 size={18} class="spin" />
					<span>importing {activeArtist?.name} discography…</span>
				</div>

			{:else if phase === 'tracks'}
				<div class="tracks-header">
					<button class="back-btn" onclick={backToArtists}>← {activeArtist?.name}</button>
					<button class="select-all-btn" onclick={toggleAll}>
						{selected.size === tracks.length ? 'deselect all' : 'select all'}
					</button>
				</div>
				<ul class="track-list">
					{#each tracks as track (track.id)}
						{@const isSelected = selected.has(track.id)}
						<li>
							<button
								class="track-row"
								class:selected={isSelected}
								onclick={() => toggleTrack(track.id)}
							>
								{#if track.album_art_url}
									<img src={track.album_art_url} alt={track.album_name ?? ''} class="track-img" />
								{:else}
									<div class="track-img placeholder"></div>
								{/if}
								<div class="track-info">
									<span class="track-title">{track.title}</span>
									<span class="track-sub">{track.album_name ?? track.artist_name}</span>
								</div>
								<div class="check" class:visible={isSelected}>
									<IconCheck size={12} />
								</div>
							</button>
						</li>
					{/each}
				</ul>

			{:else if phase === 'no-results'}
				<p class="hint">no artists found for "{query}"</p>

			{:else if phase === 'error'}
				<p class="hint error">{errorMsg}</p>
			{/if}
		</div>

		<footer>
			<span class="count">
				{selected.size > 0 ? `${selected.size} selected` : ''}
			</span>
			<button
				class="add-btn"
				onclick={addSongs}
				disabled={selected.size === 0 || saving}
			>
				{saving ? 'adding…' : `Add ${selected.size || ''} songs`.trim()}
			</button>
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

	.modal-title {
		font-family: var(--font-serif);
		font-size: 20px;
	}

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

	.content {
		flex: 1;
		overflow-y: auto;
		padding: 12px 0;
	}

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

	:global(.spin) {
		animation: spin 1s linear infinite;
	}
	@keyframes spin { to { transform: rotate(360deg); } }

	ul { list-style: none; }

	.artist-list { padding: 0 8px; }

	.artist-row {
		display: flex;
		align-items: center;
		gap: 12px;
		width: 100%;
		padding: 10px 12px;
		background: none;
		border: none;
		border-radius: 6px;
		cursor: pointer;
		text-align: left;
		color: var(--ink);
	}
	.artist-row:hover { background: rgba(26, 26, 26, 0.04); }

	.artist-img {
		width: 40px;
		height: 40px;
		border-radius: 50%;
		object-fit: cover;
		flex-shrink: 0;
	}
	.artist-img.placeholder {
		background: repeating-linear-gradient(135deg, transparent 0 6px, rgba(0,0,0,0.06) 6px 7px);
		border: var(--border);
		border-radius: 50%;
	}

	.artist-name {
		flex: 1;
		font-family: var(--font-serif);
		font-size: 16px;
	}

	:global(.chevron) { color: var(--muted); }

	.tracks-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 4px 20px 10px;
		flex-shrink: 0;
	}

	.back-btn {
		background: none;
		border: none;
		font-family: var(--font-mono);
		font-size: 11px;
		color: var(--muted);
		cursor: pointer;
		letter-spacing: 0.3px;
		padding: 0;
	}
	.back-btn:hover { color: var(--ink); }

	.select-all-btn {
		background: none;
		border: none;
		font-family: var(--font-mono);
		font-size: 11px;
		color: var(--muted);
		cursor: pointer;
		letter-spacing: 0.3px;
		padding: 0;
	}
	.select-all-btn:hover { color: var(--ink); }

	.track-list { padding: 0 8px; }

	.track-row {
		display: flex;
		align-items: center;
		gap: 12px;
		width: 100%;
		padding: 8px 12px;
		background: none;
		border: none;
		border-radius: 6px;
		cursor: pointer;
		text-align: left;
		color: var(--ink);
	}
	.track-row:hover { background: rgba(26, 26, 26, 0.04); }
	.track-row.selected { background: rgba(26, 26, 26, 0.06); }

	.track-img {
		width: 36px;
		height: 36px;
		border-radius: 3px;
		object-fit: cover;
		flex-shrink: 0;
	}
	.track-img.placeholder {
		background: repeating-linear-gradient(135deg, transparent 0 5px, rgba(0,0,0,0.06) 5px 6px);
		border: var(--border);
		border-radius: 3px;
	}

	.track-info {
		flex: 1;
		display: flex;
		flex-direction: column;
		gap: 3px;
		min-width: 0;
	}

	.track-title {
		font-family: var(--font-serif);
		font-size: 15px;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.track-sub {
		font-family: var(--font-mono);
		font-size: 10px;
		color: var(--muted);
		letter-spacing: 0.3px;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.check {
		width: 20px;
		height: 20px;
		border: var(--border);
		border-radius: 4px;
		display: flex;
		align-items: center;
		justify-content: center;
		flex-shrink: 0;
		background: transparent;
		opacity: 0;
	}
	.check.visible {
		background: var(--ink);
		color: var(--paper);
		opacity: 1;
	}

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
	.add-btn:disabled {
		opacity: 0.35;
		cursor: not-allowed;
	}
</style>
