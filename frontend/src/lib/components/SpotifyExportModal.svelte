<script lang="ts">
	import { IconX, IconMinus, IconPlus, IconExternalLink } from '@tabler/icons-svelte';
	import { PUBLIC_API_BASE_URL } from '$env/static/public';
	import { api } from '$lib/api';
	import type { RankedSong } from '$lib/types';

	let {
		rankingId,
		rankingName,
		spotifyPlaylistId,
		lastExportCount,
		rankedSongs,
		onClose,
		onExported
	}: {
		rankingId: number;
		rankingName: string;
		spotifyPlaylistId: string | null;
		lastExportCount: number | null;
		rankedSongs: RankedSong[];
		onClose: () => void;
		onExported: (playlistId: string, exportedCount: number) => void;
	} = $props();

	type Phase = 'idle' | 'loading' | 'success' | 'error' | 'reauth';

	let name = $state(rankingName);
	let count = $state(Math.min(lastExportCount ?? 20, rankedSongs.length));
	let isPublic = $state(false);
	let phase = $state<Phase>('idle');
	let resultMsg = $state('');
	let playlistUrl = $state('');

	let preview = $derived(rankedSongs.slice(0, count));
	let hasExisting = $derived(!!spotifyPlaylistId);

	function decrement() { if (count > 1) count--; }
	function increment() { if (count < rankedSongs.length) count++; }

	function onCountInput(e: Event) {
		const val = parseInt((e.target as HTMLInputElement).value);
		if (!isNaN(val)) count = Math.max(1, Math.min(rankedSongs.length, val));
	}

	async function submit() {
		if (phase === 'loading') return;
		phase = 'loading';
		try {
			const result = await api.post<{ status: string; playlist_url: string }>(
				`/api/v1/rankings/${rankingId}/export/spotify`,
				{ name: name.trim() || rankingName, count, public: isPublic }
			);
			playlistUrl = result.playlist_url;
			resultMsg = result.status === 'created' ? 'playlist created' : 'playlist updated';
			phase = 'success';
			const id = result.playlist_url.split('/').pop() ?? '';
			onExported(id, count);
		} catch (err: unknown) {
			const msg = err instanceof Error ? err.message : String(err);
			if (msg.includes('spotify_scope_required') || msg.includes('403')) {
				phase = 'reauth';
			} else {
				resultMsg = msg || 'export failed. try again.';
				phase = 'error';
			}
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
			<span class="modal-title">export to spotify</span>
			<button class="close-btn" onclick={onClose} aria-label="Close">
				<IconX size={16} />
			</button>
		</header>

		{#if phase === 'success'}
			<div class="result-area">
				<p class="result-msg">{resultMsg}</p>
				<a class="open-link" href={playlistUrl} target="_blank" rel="noopener noreferrer">
					open in spotify <IconExternalLink size={13} />
				</a>
			</div>
			<footer>
				<span></span>
				<button class="submit-btn" onclick={onClose}>done</button>
			</footer>

		{:else if phase === 'reauth'}
			<div class="result-area">
				<p class="result-msg error">spotify permissions required</p>
				<p class="reauth-hint">reconnect your spotify account to grant playlist access, then close that tab and try again.</p>
				<a class="reauth-link" href="{PUBLIC_API_BASE_URL}/auth/spotify" target="_blank" rel="noopener noreferrer">reconnect spotify</a>
			</div>
			<footer>
				<span></span>
				<button class="submit-btn secondary" onclick={onClose}>cancel</button>
			</footer>

		{:else}
			<div class="form">
				<label class="field">
					<span class="label">playlist name</span>
					<input
						type="text"
						bind:value={name}
						placeholder={rankingName}
						maxlength={100}
					/>
				</label>

				<div class="field">
					<span class="label">songs to export</span>
					<div class="stepper">
						<button class="step-btn" onclick={decrement} disabled={count <= 1}>
							<IconMinus size={12} />
						</button>
						<input
							class="count-input"
							type="number"
							min={1}
							max={rankedSongs.length}
							value={count}
							oninput={onCountInput}
						/>
						<button class="step-btn" onclick={increment} disabled={count >= rankedSongs.length}>
							<IconPlus size={12} />
						</button>
						<span class="count-of">of {rankedSongs.length}</span>
					</div>
				</div>

				<div class="field visibility-field">
					<span class="label">visibility</span>
					<div class="toggle-row">
						<button
							class="toggle-opt"
							class:active={!isPublic}
							onclick={() => (isPublic = false)}
						>private</button>
						<button
							class="toggle-opt"
							class:active={isPublic}
							onclick={() => (isPublic = true)}
						>public</button>
					</div>
				</div>
			</div>

			<div class="preview-header">
				<span class="label">preview ({count} songs)</span>
			</div>
			<ul class="preview-list">
				{#each preview as song, i (song.id)}
					<li class="preview-row">
						<span class="preview-rank">{i + 1}</span>
						{#if song.album_art_url}
							<img class="preview-art" src={song.album_art_url} alt="" width="24" height="24" />
						{/if}
						<span class="preview-title">{song.title}</span>
						<span class="preview-artist">{song.artist_name}</span>
					</li>
				{/each}
			</ul>

			<footer>
				{#if phase === 'error'}
					<span class="error-msg">{resultMsg}</span>
				{:else}
					<span></span>
				{/if}
				<button class="submit-btn" onclick={submit} disabled={phase === 'loading'}>
					{#if phase === 'loading'}
						exporting…
					{:else if hasExisting}
						update spotify playlist
					{:else}
						export to spotify
					{/if}
				</button>
			</footer>
		{/if}
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
		width: 480px;
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

	.modal-title {
		font-family: var(--font-serif);
		font-size: 20px;
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

	.form {
		padding: 16px 20px;
		display: flex;
		flex-direction: column;
		gap: 14px;
		flex-shrink: 0;
		border-bottom: var(--border);
	}

	.field {
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	.label {
		font-family: var(--font-mono);
		font-size: 10px;
		letter-spacing: 0.8px;
		text-transform: uppercase;
		color: var(--muted);
	}

	.field input[type='text'] {
		font-family: var(--font-serif);
		font-size: 15px;
		color: var(--ink);
		background: none;
		border: var(--border);
		border-radius: 4px;
		padding: 7px 10px;
		outline: none;
		width: 100%;
		box-sizing: border-box;
	}
	.field input[type='text']:focus {
		border-color: var(--ink);
	}

	.stepper {
		display: flex;
		align-items: center;
		gap: 6px;
	}

	.step-btn {
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
	.step-btn:disabled { opacity: 0.3; cursor: not-allowed; }

	.count-input {
		font-family: var(--font-mono);
		font-size: 14px;
		color: var(--ink);
		background: none;
		border: var(--border);
		border-radius: 4px;
		padding: 4px 8px;
		width: 54px;
		text-align: center;
		outline: none;
		-moz-appearance: textfield;
	}
	.count-input::-webkit-inner-spin-button,
	.count-input::-webkit-outer-spin-button { -webkit-appearance: none; }

	.count-of {
		font-family: var(--font-mono);
		font-size: 11px;
		color: var(--muted);
	}

	.toggle-row {
		display: flex;
		gap: 0;
		border: var(--border);
		border-radius: 4px;
		overflow: hidden;
		width: fit-content;
	}

	.toggle-opt {
		background: none;
		border: none;
		font-family: var(--font-mono);
		font-size: 11px;
		letter-spacing: 0.4px;
		padding: 6px 14px;
		cursor: pointer;
		color: var(--muted);
	}
	.toggle-opt.active {
		background: var(--ink);
		color: var(--paper);
	}
	.toggle-opt:first-child { border-right: var(--border); }

	.preview-header {
		padding: 10px 20px 6px;
		flex-shrink: 0;
	}

	.preview-list {
		list-style: none;
		overflow-y: auto;
		flex: 1;
		padding: 0 0 4px;
	}

	.preview-row {
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 5px 20px;
	}
	.preview-row:hover { background: rgba(0,0,0,0.03); }

	.preview-rank {
		font-family: var(--font-mono);
		font-size: 10px;
		color: var(--muted);
		width: 18px;
		text-align: right;
		flex-shrink: 0;
	}

	.preview-art {
		border-radius: 2px;
		flex-shrink: 0;
		object-fit: cover;
	}

	.preview-title {
		font-family: var(--font-serif);
		font-size: 13px;
		color: var(--ink);
		flex: 1;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		min-width: 0;
	}

	.preview-artist {
		font-family: var(--font-mono);
		font-size: 10px;
		color: var(--muted);
		flex-shrink: 0;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		max-width: 120px;
	}

	footer {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 14px 20px;
		border-top: var(--border);
		flex-shrink: 0;
	}

	.submit-btn {
		background: #1db954;
		color: #fff;
		border: none;
		border-radius: 6px;
		padding: 9px 20px;
		font-family: var(--font-serif);
		font-size: 15px;
		cursor: pointer;
	}
	.submit-btn:disabled { opacity: 0.5; cursor: not-allowed; }
	.submit-btn.secondary {
		background: none;
		border: var(--border);
		color: var(--ink);
	}

	.error-msg {
		font-family: var(--font-mono);
		font-size: 11px;
		color: var(--accent);
	}

	.result-area {
		flex: 1;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 12px;
		padding: 40px 20px;
	}

	.result-msg {
		font-family: var(--font-serif);
		font-size: 18px;
		color: var(--ink);
	}
	.result-msg.error { color: var(--accent); }

	.open-link {
		display: flex;
		align-items: center;
		gap: 5px;
		font-family: var(--font-mono);
		font-size: 11px;
		color: #1db954;
		text-decoration: none;
		letter-spacing: 0.3px;
	}
	.open-link:hover { text-decoration: underline; }

	.reauth-hint {
		font-family: var(--font-mono);
		font-size: 11px;
		color: var(--muted);
		text-align: center;
	}

	.reauth-link {
		font-family: var(--font-mono);
		font-size: 11px;
		color: var(--ink);
		text-decoration: underline;
		letter-spacing: 0.3px;
	}

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
