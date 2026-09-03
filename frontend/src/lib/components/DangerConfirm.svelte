<script lang="ts">
	import Modal from '$lib/components/Modal.svelte';
	import { describeError } from '$lib/api';

	let {
		title,
		body,
		confirmLabel,
		confirmPhrase = null,
		onConfirm,
		onClose
	}: {
		title: string;
		body: string;
		confirmLabel: string;
		/** when set, the phrase must be typed exactly; use for irreversible actions only */
		confirmPhrase?: string | null;
		onConfirm: () => void | Promise<void>;
		onClose: () => void;
	} = $props();

	let typed = $state('');
	let phraseInput = $state<HTMLInputElement | null>(null);

	// the autofocus attribute does not fire on a node mounted after load, so the
	// dialog opened unfocused and typing went nowhere
	$effect(() => {
		phraseInput?.focus();
	});
	let armed = $derived(confirmPhrase === null || typed.trim() === confirmPhrase);

	let busy = $state(false);
	let failure = $state('');

	// only close once the work actually succeeded, otherwise the dialog would
	// vanish on failure and the action would look like it silently did nothing
	async function confirm() {
		if (!armed || busy) return;
		busy = true;
		failure = '';
		try {
			await onConfirm();
			onClose();
		} catch (e) {
			console.error('[danger confirm] action failed', e);
			failure = describeError(e).message;
		} finally {
			busy = false;
		}
	}
</script>

<Modal {title} onClose={onClose} width="420px">
	<p class="body">{body}</p>

	{#if confirmPhrase !== null}
		<label class="prompt" for="danger-phrase">
			type <strong>{confirmPhrase}</strong> to confirm
		</label>
		<input
			id="danger-phrase"
			class="phrase"
			bind:this={phraseInput}
			bind:value={typed}
			autocomplete="off"
			autocorrect="off"
			spellcheck="false"
			onkeydown={(e) => e.key === 'Enter' && confirm()}
		/>
	{/if}

	{#if failure}
		<p class="failure" role="alert">{failure}</p>
	{/if}

	<div class="actions">
		<button class="cancel" onclick={onClose} disabled={busy}>cancel</button>
		<button class="danger" disabled={!armed || busy} onclick={confirm}>
			{busy ? 'working…' : confirmLabel}
		</button>
	</div>
</Modal>

<style>
	.body {
		font-family: var(--font-serif);
		font-size: 15px;
		line-height: 1.5;
		color: var(--ink);
	}
	.prompt {
		display: block;
		margin-top: 18px;
		font-family: var(--font-ui);
		font-size: 12px;
		color: var(--text-muted);
	}
	.prompt strong {
		color: var(--ink);
		font-weight: 600;
	}
	.phrase {
		width: 100%;
		margin-top: 6px;
		padding: 8px 10px;
		font-family: var(--font-ui);
		font-size: 14px;
		color: var(--ink);
		background: var(--paper);
		border: 1.5px solid var(--line-soft);
		border-radius: 6px;
	}
	.phrase:focus {
		outline: none;
		border-color: var(--ink);
	}
	.failure {
		margin-top: 16px;
		padding: 10px 12px;
		font-family: var(--font-ui);
		font-size: 13px;
		line-height: 1.45;
		color: var(--danger);
		background: var(--danger-soft);
		border: 1px solid var(--danger-edge);
		border-radius: 6px;
	}
	.actions {
		display: flex;
		justify-content: flex-end;
		gap: 8px;
		margin-top: 20px;
	}
	.cancel,
	.danger {
		font-family: var(--font-ui);
		font-size: 13px;
		padding: 8px 16px;
		border-radius: 6px;
		cursor: pointer;
	}
	.cancel {
		background: none;
		border: 1.5px solid var(--ink);
		color: var(--ink);
	}
	.cancel:hover { background: var(--surface-hover); }
	.danger {
		background: var(--danger);
		border: 1.5px solid var(--danger);
		color: var(--paper);
	}
	.danger:hover:not(:disabled) { background: var(--danger-deep); border-color: var(--danger-deep); }
	.danger:disabled {
		background: none;
		border-color: var(--line-soft);
		color: var(--text-muted);
		cursor: not-allowed;
	}
</style>
