<script lang="ts">
	import { IconX } from '@tabler/icons-svelte';

	let {
		title,
		subtitle,
		width = '480px',
		onClose,
		children
	}: {
		title: string;
		subtitle?: string;
		width?: string;
		onClose: () => void;
		children: import('svelte').Snippet;
	} = $props();

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
	<div class="modal" role="dialog" aria-modal="true" style="width: {width}">
		<header>
			<div class="header-text">
				<span class="modal-title">{title}</span>
				{#if subtitle}
					<span class="modal-subtitle">{subtitle}</span>
				{/if}
			</div>
			<button class="close-btn" onclick={onClose} aria-label="Close">
				<IconX size={16} />
			</button>
		</header>
		{@render children()}
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

	.modal-subtitle {
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

	@media (max-width: 640px) {
		.overlay { align-items: flex-end; background: rgba(26, 26, 26, 0.5); }
		.modal {
			width: 100% !important;
			max-width: 100%;
			max-height: 92vh;
			border-radius: 12px 12px 0 0;
			border-bottom: none;
		}
	}
</style>
