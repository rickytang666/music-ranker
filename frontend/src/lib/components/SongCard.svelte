<script lang="ts">
	import type { BaseSong } from '$lib/types';

	let {
		song,
		tilt,
		disabled,
		onPick
	}: {
		song: BaseSong;
		tilt: number;
		disabled: boolean;
		onPick: () => void;
	} = $props();
</script>

<div class="card" style="transform: rotate({tilt}deg)" class:disabled>
	{#if song.album_art_url}
		<img src={song.album_art_url} alt={song.album_name ?? song.title} class="art" />
	{:else}
		<div class="art placeholder"></div>
	{/if}
	<div class="meta">
		<p class="title">{song.title}</p>
		<p class="artist">{song.artist_name}</p>
	</div>
	<button class="pick-btn" onclick={onPick} {disabled}>Pick ♥</button>
</div>

<style>
	.card {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 16px;
		transition: opacity 0.15s ease;
	}
	.card.disabled { opacity: 0.5; pointer-events: none; }

	.art {
		width: 240px;
		height: 240px;
		object-fit: cover;
		border: var(--border);
		border-radius: 4px;
		box-shadow: 4px 4px 0 0 rgba(0, 0, 0, 0.08);
		display: block;
	}
	.art.placeholder {
		background: repeating-linear-gradient(135deg, transparent 0 8px, rgba(0, 0, 0, 0.06) 8px 9px);
	}

	.meta {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 4px;
		max-width: 240px;
	}

	.title {
		font-family: var(--font-serif);
		font-size: 18px;
		text-align: center;
		line-height: 1.2;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		max-width: 240px;
	}

	.artist {
		font-family: var(--font-mono);
		font-size: 11px;
		color: var(--muted);
		letter-spacing: 0.5px;
		text-transform: uppercase;
	}

	.pick-btn {
		border: var(--border);
		border-radius: 6px;
		background: var(--ink);
		color: var(--paper);
		font-family: var(--font-serif);
		font-size: 18px;
		padding: 10px 32px;
		cursor: pointer;
		width: 200px;
		margin-top: 4px;
	}
	.pick-btn:hover:not(:disabled) {
		background: #333;
	}
	.pick-btn:disabled { cursor: not-allowed; }

	@media (max-width: 640px) {
		.card { transform: none !important; }
		.art { width: 160px; height: 160px; }
		.meta { max-width: 200px; }
		.title { font-size: 15px; max-width: 200px; }
		.pick-btn { width: 160px; font-size: 15px; padding: 8px 0; }
	}
</style>
