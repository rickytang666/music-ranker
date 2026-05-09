<script lang="ts">
	import { auth } from '$lib/stores/auth.svelte';
</script>

<main>
	<p>logged in{auth.user ? ` as ${auth.user.display_name}` : ''}</p>
</main>
