import type { BaseSong } from '$lib/types';
import { SvelteMap } from 'svelte/reactivity';

export type FlagType = 'overrated' | 'underrated' | 'unsure';

export interface QueuedPair {
	song_a: BaseSong;
	song_b: BaseSong;
}

let queue = $state<QueuedPair[]>([]);
const flags = new SvelteMap<number, FlagType>();

function enqueue(pairs: QueuedPair[], songId: number, type: FlagType) {
	queue = [...queue, ...pairs];
	flags.set(songId, type);
}

function dequeue(): QueuedPair | undefined {
	if (queue.length === 0) return undefined;
	const [first, ...rest] = queue;
	queue = rest;
	const songAId = first.song_a.id;
	if (!rest.some((p) => p.song_a.id === songAId)) {
		flags.delete(songAId);
	}
	return first;
}

function hasQueue(): boolean {
	return queue.length > 0;
}

function queueLength(): number {
	return queue.length;
}

function isFlagged(songId: number): boolean {
	return flags.has(songId);
}

function getFlagType(songId: number): FlagType | undefined {
	return flags.get(songId);
}

function clearFlag(songId: number) {
	queue = queue.filter((p) => p.song_a.id !== songId);
	flags.delete(songId);
}

export const matchupStore = { enqueue, dequeue, hasQueue, queueLength, isFlagged, getFlagType, clearFlag };
