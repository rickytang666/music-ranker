<script lang="ts">
	import { IconCheck } from '@tabler/icons-svelte';
	import AlbumArt from './AlbumArt.svelte';

	let { imageUrl, imageShape = 'square', name, sub, variant = 'check', selected = false, onSelect }: {
		imageUrl: string | null;
		imageShape?: 'square' | 'round';
		name: string;
		sub?: string;
		variant?: 'check' | 'navigate';
		selected?: boolean;
		onSelect: () => void;
	} = $props();
</script>

<button class="item-row" class:selected={variant === 'check' && selected} onclick={onSelect}>
	<AlbumArt src={imageUrl} alt={name} size={38} shape={imageShape} />
	<div class="item-info">
		<span class="item-name">{name}</span>
		{#if sub}<span class="item-sub">{sub}</span>{/if}
	</div>
	{#if variant === 'check'}
		<div class="check" class:visible={selected}><IconCheck size={12} /></div>
	{:else}
		<span class="item-nav">→</span>
	{/if}
</button>

<style>
	.item-row {
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
	.item-row:hover { background: rgba(26, 26, 26, 0.04); }
	.item-row.selected { background: rgba(26, 26, 26, 0.06); }

	.item-info {
		flex: 1;
		display: flex;
		flex-direction: column;
		gap: 3px;
		min-width: 0;
	}

	.item-name {
		font-family: var(--font-serif);
		font-size: 15px;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.item-sub {
		font-family: var(--font-mono);
		font-size: 10px;
		color: var(--muted);
		letter-spacing: 0.3px;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.item-nav {
		font-family: var(--font-mono);
		font-size: 14px;
		color: var(--muted);
		flex-shrink: 0;
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
		opacity: 0;
	}
	.check.visible {
		background: var(--ink);
		color: var(--paper);
		opacity: 1;
	}
</style>
