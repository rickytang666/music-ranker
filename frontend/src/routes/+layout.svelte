<script lang="ts">
  import { goto } from "$app/navigation";
  import { page } from "$app/stores";
  import { auth } from "$lib/stores/auth.svelte";

  let { children } = $props();

  const publicRoutes = ["/login", "/auth/callback"];

  // ssr is disabled, so localStorage is available here synchronously.
  // must run before child layouts mount so their onMount sees a valid token.
  auth.init();

  $effect(() => {
    if (!auth.token && !publicRoutes.includes($page.url.pathname)) {
      goto("/login");
    }
  });
</script>

{@render children()}
