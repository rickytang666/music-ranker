<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { api } from '$lib/api';
	import { rankings } from '$lib/stores/rankings.svelte';
	import Sidebar from '$lib/components/Sidebar.svelte';

	let { children } = $props();

	let activeId = $derived(
		$page.params.id ? parseInt($page.params.id) : undefined
	);

	onMount(async () => {
		try {
			const data = await api.get<typeof rankings.list>('/api/v1/rankings');
			rankings.set(data);
		} catch {
			// auth guard in root layout handles unauth; silently ignore other errors here
		}
	});
</script>

<div class="shell">
	<Sidebar {activeId} />
	<div class="main">
		{@render children()}
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
		overflow: hidden;
	}
</style>
