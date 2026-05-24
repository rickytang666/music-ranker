<script lang="ts">
	import { IconTrendingDown, IconTrendingUp, IconQuestionMark, IconX } from '@tabler/icons-svelte';
	import type { BaseSong } from '$lib/types';
	import type { FlagType } from '$lib/stores/signals.svelte';

	let {
		song,
		tilt,
		disabled,
		flag,
		onClearFlag
	}: {
		song: BaseSong;
		tilt: number;
		disabled: boolean;
		flag?: FlagType;
		onClearFlag?: () => void;
	} = $props();

	const flagIcon = { overrated: IconTrendingDown, underrated: IconTrendingUp, unsure: IconQuestionMark };
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
		{#if flag}
			{@const Icon = flagIcon[flag]}
			<button class="flag-badge" onclick={(e) => { e.stopPropagation(); onClearFlag?.(); }}>
				<Icon size={11} />
				{flag}
				<IconX size={10} />
			</button>
		{/if}
	</div>
</div>

<style>
	.card {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 16px;
		transition: opacity 0.15s ease;
		cursor: pointer;
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
		gap: 6px;
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

	.flag-badge {
		display: flex;
		align-items: center;
		gap: 4px;
		padding: 3px 8px;
		border: var(--border);
		border-radius: 20px;
		background: none;
		font-family: var(--font-mono);
		font-size: 10px;
		letter-spacing: 0.5px;
		color: var(--ink);
		cursor: pointer;
		transition: background 0.1s;
	}
	.flag-badge:hover { background: rgba(26,26,26,0.06); }

	@media (max-width: 640px) {
		.card { transform: none !important; gap: 10px; }
		.art { width: 120px; height: 120px; }
		.meta { max-width: 160px; }
		.title { font-size: 13px; max-width: 160px; }
		.artist { font-size: 10px; }
	}
</style>
