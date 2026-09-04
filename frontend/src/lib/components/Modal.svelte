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

	let modalEl = $state<HTMLElement | null>(null);

	// aria-modal requires focus inside the dialog; restore it to the trigger on close
	$effect(() => {
		const trigger = document.activeElement as HTMLElement | null;
		const focusTimer = setTimeout(() => {
			// a child that manages its own focus, like a typed confirm, wins
			if (modalEl && !modalEl.contains(document.activeElement)) modalEl.focus();
		}, 0);
		return () => {
			clearTimeout(focusTimer);
			trigger?.focus?.();
		};
	});

	function focusables(): HTMLElement[] {
		if (!modalEl) return [];
		return [
			...modalEl.querySelectorAll<HTMLElement>(
				'a[href],button:not([disabled]),input:not([disabled]),select:not([disabled]),textarea:not([disabled]),[tabindex]:not([tabindex="-1"])'
			)
		].filter((el) => el.offsetParent !== null);
	}

	function onOverlayClick(e: MouseEvent) {
		if (e.target === e.currentTarget) onClose();
	}

	function onKeydown(e: KeyboardEvent) {
		if (e.key === 'Escape') {
			onClose();
			return;
		}
		if (e.key !== 'Tab') return;
		const focusable = focusables();
		if (focusable.length === 0) return;
		const first = focusable[0];
		const last = focusable[focusable.length - 1];
		if (e.shiftKey && document.activeElement === first) {
			e.preventDefault();
			last.focus();
		} else if (!e.shiftKey && document.activeElement === last) {
			e.preventDefault();
			first.focus();
		}
	}
</script>

<svelte:window onkeydown={onKeydown} />

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div class="overlay" onclick={onOverlayClick}>
	<div
		class="modal"
		role="dialog"
		aria-modal="true"
		aria-label={title}
		tabindex="-1"
		bind:this={modalEl}
		style="width: {width}"
	>
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
		background: var(--scrim);
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
		font-family: var(--font-ui);
		font-size: 11px;
		color: var(--text-muted);
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
		.overlay { align-items: flex-end; background: var(--scrim-heavy); }
		.modal {
			width: 100% !important;
			max-width: 100%;
			max-height: 92vh;
			border-radius: 12px 12px 0 0;
			border-bottom: none;
		}
	}
</style>
