<script lang="ts">
	import { onMount, untrack } from 'svelte';
	import { page } from '$app/stores';
	import { api } from '$lib/api';
	import { rankings } from '$lib/stores/rankings.svelte';
	import Sidebar from '$lib/components/Sidebar.svelte';
	import { IconMenu2 } from '@tabler/icons-svelte';

	const RANKINGS_CACHE = 'rankings_cache';

	let { children } = $props();
	let drawerOpen = $state(false);

	let activeId = $derived(
		$page.params.id ? parseInt($page.params.id) : undefined
	);

	// populate sidebar immediately from cache, then refresh from API
	try {
		const cached = localStorage.getItem(RANKINGS_CACHE);
		if (cached) rankings.set(JSON.parse(cached));
	} catch {}

	// close drawer on navigation
	$effect(() => {
		const _ = $page.url.pathname;
		untrack(() => { drawerOpen = false; });
	});

	onMount(async () => {
		try {
			const data = await api.get<typeof rankings.list>('/api/v1/rankings');
			rankings.set(data);
			localStorage.setItem(RANKINGS_CACHE, JSON.stringify(data));
		} catch {}
	});
</script>

{#if drawerOpen}
	<!-- svelte-ignore a11y_click_events_have_key_events -->
	<!-- svelte-ignore a11y_no_static_element_interactions -->
	<div class="drawer-overlay" onclick={() => drawerOpen = false}></div>
{/if}

<div class="shell">
	<Sidebar {activeId} {drawerOpen} onClose={() => drawerOpen = false} />
	<div class="main">
		<div class="mobile-topbar">
			<button class="hamburger" onclick={() => drawerOpen = !drawerOpen}>
				<IconMenu2 size={20} />
			</button>
			<span class="app-title">music ranker</span>
		</div>
		<div class="page-content">
			{@render children()}
		</div>
	</div>
</div>

<style>
	.shell {
		display: flex;
		height: 100vh;
		overflow: hidden;
	}
	.main {
		flex: 1;
		display: flex;
		flex-direction: column;
		overflow: hidden;
	}
	.page-content {
		flex: 1;
		display: flex;
		overflow: hidden;
	}
	@media (max-width: 640px) {
		.page-content { flex-direction: column; }
	}
	.mobile-topbar {
		display: none;
		align-items: center;
		gap: 12px;
		padding: 10px 16px;
		border-bottom: var(--border);
		flex-shrink: 0;
	}
	.hamburger {
		background: none;
		border: var(--border);
		border-radius: 4px;
		width: 32px;
		height: 32px;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		color: var(--ink);
		flex-shrink: 0;
	}
	.app-title {
		font-family: var(--font-serif);
		font-size: 18px;
	}
	.drawer-overlay {
		position: fixed;
		inset: 0;
		background: rgba(26, 26, 26, 0.4);
		z-index: 199;
	}
	@media (max-width: 640px) {
		.mobile-topbar { display: flex; }
	}
</style>
