<script lang="ts">
	import { PUBLIC_API_BASE_URL } from '$env/static/public';
</script>

<div class="page">
	<div class="card">
		<p class="eyebrow">welcome to</p>
		<h1 class="title">music ranker</h1>
		<p class="sub">rank your songs through head-to-head matchups</p>
		<a class="login-btn" href="{PUBLIC_API_BASE_URL}/auth/spotify">
			<svg class="spotify-icon" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
				<path d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2zm4.586 14.424a.622.622 0 0 1-.857.207c-2.348-1.435-5.304-1.76-8.785-.964a.623.623 0 0 1-.277-1.215c3.809-.87 7.076-.496 9.712 1.115a.623.623 0 0 1 .207.857zm1.223-2.722a.78.78 0 0 1-1.072.257c-2.687-1.652-6.785-2.13-9.965-1.166a.78.78 0 0 1-.973-.519.781.781 0 0 1 .519-.973c3.632-1.102 8.147-.568 11.234 1.329a.78.78 0 0 1 .257 1.072zm.105-2.835C14.692 8.95 9.375 8.775 6.297 9.71a.937.937 0 1 1-.543-1.794c3.532-1.072 9.404-.865 13.115 1.338a.937.937 0 0 1-.955 1.613z"/>
			</svg>
			continue with spotify
		</a>
	</div>
</div>

<style>
	.page {
		height: 100vh;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 24px;
	}

	.card {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 12px;
		text-align: center;
		max-width: 360px;
		width: 100%;
	}

	.eyebrow {
		font-family: var(--font-mono);
		font-size: 10px;
		letter-spacing: 2px;
		text-transform: uppercase;
		color: var(--muted);
	}

	.title {
		font-family: var(--font-serif);
		font-size: 42px;
		font-weight: 500;
		line-height: 1;
		letter-spacing: -0.5px;
	}

	.sub {
		font-family: var(--font-mono);
		font-size: 11px;
		color: var(--muted);
		letter-spacing: 0.3px;
		margin-top: 4px;
		margin-bottom: 12px;
	}

	.login-btn {
		display: flex;
		align-items: center;
		gap: 10px;
		padding: 12px 24px;
		background: var(--ink);
		color: var(--paper);
		border-radius: 6px;
		text-decoration: none;
		font-family: var(--font-mono);
		font-size: 12px;
		letter-spacing: 0.5px;
		transition: opacity 0.15s;
	}
	.login-btn:hover { opacity: 0.85; }

	.spotify-icon {
		width: 18px;
		height: 18px;
		flex-shrink: 0;
	}
</style>
