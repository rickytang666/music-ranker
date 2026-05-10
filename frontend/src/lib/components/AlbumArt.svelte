<script lang="ts">
	let { src, alt, size, shape = 'square' }: {
		src: string | null;
		alt: string;
		size: number;
		shape?: 'square' | 'round';
	} = $props();
</script>

{#if src}
	<img {src} {alt} class="art {shape}" style="width:{size}px;height:{size}px" />
{:else}
	<div class="art {shape} placeholder" style="width:{size}px;height:{size}px"></div>
{/if}

<style>
	.art {
		object-fit: cover;
		flex-shrink: 0;
		display: block;
	}
	.art.square { border-radius: 3px; border: 1px solid rgba(26,26,26,0.12); }
	.art.round  { border-radius: 50%; border: 1px solid rgba(26,26,26,0.12); }
	.art.placeholder {
		background: repeating-linear-gradient(135deg, transparent 0 5px, rgba(0,0,0,0.06) 5px 6px);
		border: var(--border);
	}
</style>
