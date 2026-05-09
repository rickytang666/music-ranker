<div class="center">
	<div class="empty">
		<p class="heading">Pick a ranking<br />or start a new one</p>
		<p class="hint">Use the sidebar to select or create a ranking.</p>
	</div>
</div>

<style>
	.center {
		flex: 1;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 48px;
	}
	.empty {
		border: 1.5px dashed var(--ink);
		border-radius: 8px;
		padding: 56px 64px;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 16px;
		text-align: center;
		max-width: 480px;
	}
	.heading {
		font-family: var(--font-serif);
		font-size: 32px;
		line-height: 1.2;
	}
	.hint {
		font-family: var(--font-mono);
		font-size: 11px;
		letter-spacing: 0.5px;
		color: var(--muted);
		text-transform: uppercase;
	}
</style>
