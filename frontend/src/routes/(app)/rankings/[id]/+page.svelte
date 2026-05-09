<script lang="ts">
	import { page } from '$app/stores';
	import { IconPlus } from '@tabler/icons-svelte';
	import { rankings } from '$lib/stores/rankings.svelte';
	import SongImportModal from '$lib/components/SongImportModal.svelte';

	let rankingId = $derived(parseInt($page.params.id ?? '0'));
	let ranking = $derived(rankings.list.find((r) => r.id === rankingId));

	let importOpen = $state(false);
	let songCount = $state(0);

	function onSongsAdded(count: number) {
		songCount += count;
	}
</script>

<!-- center: matchup area (built in next step) -->
<div class="center">
	{#if ranking}
		<div class="matchup-placeholder">
			<p class="label">which do you prefer?</p>
			<p class="ranking-name">{ranking.name}</p>
			<p class="sub">matchup screen coming next</p>
		</div>
	{/if}
</div>

<!-- right: ranked list panel -->
<aside class="right-panel">
	<div class="panel-header">
		<div class="panel-title">
			<span class="title-text">Your ranking</span>
			{#if songCount > 0}
				<span class="song-count">{songCount} songs</span>
			{/if}
		</div>
		<button class="add-songs-btn" onclick={() => (importOpen = true)} title="Add songs">
			<IconPlus size={14} />
		</button>
	</div>

	{#if songCount === 0}
		<div class="empty-list">
			<p>add songs to start ranking</p>
		</div>
	{:else}
		<div class="list-placeholder">
			<p class="sub">ranked list coming next step</p>
		</div>
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
	.center {
		flex: 1;
		border-right: var(--border);
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 48px;
	}

	.matchup-placeholder {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 8px;
		text-align: center;
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
		font-size: 32px;
	}

	.sub {
		font-family: var(--font-mono);
		font-size: 10px;
		color: var(--muted);
		letter-spacing: 0.3px;
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

	.list-placeholder {
		flex: 1;
		display: flex;
		align-items: center;
		justify-content: center;
	}
</style>
