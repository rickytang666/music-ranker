<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { IconPlus, IconLoader2, IconArrowsShuffle } from '@tabler/icons-svelte';
	import { api } from '$lib/api';
	import { rankings } from '$lib/stores/rankings.svelte';
	import { flagStore } from '$lib/stores/signals.svelte';
	import SongCard from '$lib/components/SongCard.svelte';
	import SongImportModal from '$lib/components/SongImportModal.svelte';
	import RankedList, { type RankedSong } from '$lib/components/RankedList.svelte';

	interface Song {
		id: number;
		title: string;
		artist_name: string;
		album_name: string | null;
		album_art_url: string | null;
	}

	interface Matchup {
		song_a: Song;
		song_b: Song;
	}

	let rankingId = $derived(parseInt($page.params.id ?? '0'));
	let ranking = $derived(rankings.list.find((r) => r.id === rankingId));

	let matchup = $state<Matchup | null>(null);
	let matchupPhase = $state<'loading' | 'ready' | 'picking' | 'empty' | 'error'>('loading');
	let rankedSongs = $state<RankedSong[]>([]);
	let importOpen = $state(false);

	$effect(() => {
		if (rankingId) {
			loadNext();
			loadSongs();
		}
	});

	async function loadNext() {
		matchupPhase = 'loading';
		try {
			const result = await api.get<Matchup>(`/api/v1/rankings/${rankingId}/matchups/next${flagStore.toQueryString()}`);
			matchup = result;
			matchupPhase = 'ready';
		} catch (err: unknown) {
			const e = err as { status?: number };
			matchupPhase = e?.status === 422 ? 'empty' : 'error';
		}
	}

	async function loadSongs() {
		try {
			rankedSongs = await api.get<RankedSong[]>(`/api/v1/rankings/${rankingId}/songs`);
		} catch {
			// non-critical — list just stays stale
		}
	}

	async function pick(winnerId: number) {
		if (!matchup || matchupPhase !== 'ready') return;
		matchupPhase = 'picking';
		try {
			await api.post(`/api/v1/rankings/${rankingId}/matchups`, {
				matchup: {
					winner_id: winnerId,
					song_a_id: matchup.song_a.id,
					song_b_id: matchup.song_b.id
				}
			});
			flagStore.tick();
			await Promise.all([loadNext(), loadSongs()]);
		} catch {
			matchupPhase = 'error';
		}
	}

	function skip() {
		loadNext();
	}

	async function onSongsAdded() {
		await Promise.all([loadNext(), loadSongs()]);
	}

	function onKeydown(e: KeyboardEvent) {
		if (!matchup || matchupPhase !== 'ready') return;
		if (e.key === 'ArrowLeft') pick(matchup.song_a.id);
		if (e.key === 'ArrowRight') pick(matchup.song_b.id);
		if (e.key === 's' || e.key === 'S') skip();
	}

	onMount(() => {
		return () => { matchup = null; };
	});
</script>

<svelte:window onkeydown={onKeydown} />

<!-- center: matchup -->
<div class="center">
	{#if ranking}
		<div class="matchup-header">
			<p class="label">which do you prefer?</p>
			<p class="ranking-name">{ranking.name}</p>
		</div>
	{/if}

	<div class="cards-area">
		{#if matchupPhase === 'loading' || matchupPhase === 'picking'}
			<div class="state-msg">
				<IconLoader2 size={24} class="spin" />
			</div>

		{:else if matchupPhase === 'empty'}
			<div class="state-msg">
				<p class="state-title">not enough songs</p>
				<p class="state-sub">add at least 2 songs using the + button</p>
			</div>

		{:else if matchupPhase === 'error'}
			<div class="state-msg">
				<p class="state-title">something went wrong</p>
				<button class="retry-btn" onclick={loadNext}>retry</button>
			</div>

		{:else if matchup}
			<SongCard
				song={matchup.song_a}
				tilt={-1.2}
				disabled={matchupPhase !== 'ready'}
				onPick={() => pick(matchup!.song_a.id)}
			/>
			<SongCard
				song={matchup.song_b}
				tilt={1.2}
				disabled={matchupPhase !== 'ready'}
				onPick={() => pick(matchup!.song_b.id)}
			/>
		{/if}
	</div>

	{#if matchupPhase === 'ready'}
		<div class="controls">
			<button class="control-btn" onclick={skip}>
				<IconArrowsShuffle size={14} />
				Skip
			</button>
			<p class="key-hint">← → to pick · S to skip</p>
		</div>
	{/if}
</div>

<!-- right: ranked list -->
<aside class="right-panel">
	<div class="panel-header">
		<div class="panel-title">
			<span class="title-text">Your ranking</span>
			{#if rankedSongs.length > 0}
				<span class="song-count">{rankedSongs.length} songs · sorted</span>
			{/if}
		</div>
		<button class="add-songs-btn" onclick={() => (importOpen = true)} title="Add songs">
			<IconPlus size={14} />
		</button>
	</div>

	{#if rankedSongs.length === 0}
		<div class="empty-list">
			<p>add songs to start ranking</p>
		</div>
	{:else}
		<RankedList songs={rankedSongs} />
	{/if}
</aside>

{#if importOpen && ranking}
	<SongImportModal
		{rankingId}
		rankingName={ranking.name}
		onClose={() => (importOpen = false)}
		onAdded={onSongsAdded}
	/>
{/if}

<style>
	:global(.spin) {
		animation: spin 1s linear infinite;
	}
	@keyframes spin { to { transform: rotate(360deg); } }

	.center {
		flex: 1;
		border-right: var(--border);
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		padding: 40px 56px;
		gap: 32px;
		overflow: hidden;
	}

	.matchup-header {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 6px;
		flex-shrink: 0;
	}

	.label {
		font-family: var(--font-mono);
		font-size: 10px;
		letter-spacing: 1px;
		text-transform: uppercase;
		color: var(--muted);
	}

	.ranking-name {
		font-family: var(--font-serif);
		font-size: 28px;
	}

	.cards-area {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 72px;
		flex: 1;
		min-height: 0;
	}

	.state-msg {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 12px;
		color: var(--muted);
	}

	.state-title {
		font-family: var(--font-serif);
		font-size: 20px;
		color: var(--ink);
	}

	.state-sub {
		font-family: var(--font-mono);
		font-size: 11px;
		color: var(--muted);
		letter-spacing: 0.3px;
	}

	.retry-btn {
		background: none;
		border: var(--border);
		border-radius: 6px;
		padding: 8px 18px;
		font-family: var(--font-mono);
		font-size: 11px;
		letter-spacing: 0.3px;
		cursor: pointer;
		color: var(--ink);
	}

	.controls {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 8px;
		flex-shrink: 0;
	}

	.control-btn {
		display: flex;
		align-items: center;
		gap: 6px;
		background: none;
		border: var(--border);
		border-radius: 20px;
		padding: 8px 16px;
		font-family: var(--font-serif);
		font-size: 14px;
		cursor: pointer;
		color: var(--ink);
	}
	.control-btn:hover { background: rgba(26, 26, 26, 0.04); }

	.key-hint {
		font-family: var(--font-mono);
		font-size: 10px;
		color: var(--muted);
		letter-spacing: 0.5px;
	}

	.right-panel {
		width: 320px;
		flex-shrink: 0;
		display: flex;
		flex-direction: column;
		background: var(--paper);
		overflow: hidden;
	}

	.panel-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 18px 18px 14px;
		border-bottom: var(--border);
		flex-shrink: 0;
	}

	.panel-title {
		display: flex;
		align-items: baseline;
		gap: 8px;
	}

	.title-text {
		font-family: var(--font-serif);
		font-size: 20px;
	}

	.song-count {
		font-family: var(--font-mono);
		font-size: 10px;
		color: var(--muted);
		letter-spacing: 0.5px;
		text-transform: uppercase;
	}

	.add-songs-btn {
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

	.empty-list {
		flex: 1;
		display: flex;
		align-items: center;
		justify-content: center;
		border: 1.5px dashed var(--muted);
		border-radius: 6px;
		margin: 16px;
		font-family: var(--font-mono);
		font-size: 11px;
		color: var(--muted);
		letter-spacing: 0.3px;
		text-align: center;
		padding: 24px;
	}
</style>
