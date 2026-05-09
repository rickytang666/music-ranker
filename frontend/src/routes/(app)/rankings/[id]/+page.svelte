<script lang="ts">
	import { page } from '$app/stores';

	let rankingId = $derived(parseInt($page.params.id ?? '0'));
</script>

<div class="placeholder">
	<p>ranking {rankingId} — matchup coming in next step</p>
</div>

<style>
	.placeholder {
		flex: 1;
		display: flex;
		align-items: center;
		justify-content: center;
		font-family: var(--font-mono);
		font-size: 12px;
		color: var(--muted);
	}
</style>
