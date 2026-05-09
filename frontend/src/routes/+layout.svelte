<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { auth } from '$lib/stores/auth.svelte';

	let { children } = $props();

	const publicRoutes = ['/login', '/auth/callback'];

	onMount(() => {
		auth.init();
		if (!auth.token && !publicRoutes.includes($page.url.pathname)) {
			goto('/login');
		}
	});
</script>

{@render children()}
