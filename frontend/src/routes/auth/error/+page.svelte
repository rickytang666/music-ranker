<script lang="ts">
	import { goto } from '$app/navigation';
</script>

<div class="container">
	<p class="title">spotify auth failed</p>
	<p class="hint">spotify may be temporarily unavailable. please try again in a moment.</p>
	<button class="btn" onclick={() => goto('/login')}>back to login</button>
</div>

<style>
	.container {
		min-height: 100vh;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 16px;
		padding: 40px;
	}

	.title {
		font-family: var(--font-serif);
		font-size: 22px;
		color: var(--ink);
	}

	.hint {
		font-family: var(--font-mono);
		font-size: 12px;
		color: var(--muted);
		letter-spacing: 0.3px;
	}

	.btn {
		margin-top: 8px;
		background: var(--ink);
		color: var(--paper);
		border: none;
		border-radius: 6px;
		padding: 10px 22px;
		font-family: var(--font-serif);
		font-size: 15px;
		cursor: pointer;
	}
</style>
