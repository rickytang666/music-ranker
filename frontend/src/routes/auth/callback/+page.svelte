<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { auth } from '$lib/stores/auth.svelte';

	onMount(() => {
		const params = new URLSearchParams(window.location.search);
		const token = params.get('token');

		if (token) {
			auth.setToken(token);
			goto('/');
		} else {
			goto('/login');
		}
	});
</script>
