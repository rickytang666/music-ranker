import type { BaseSong } from '$lib/types';

export type FlagType = 'overrated' | 'underrated' | 'unsure';

export interface QueuedPair {
	song_a: BaseSong;
	song_b: BaseSong;
}

let queue = $state<QueuedPair[]>([]);
let flags = $state<Map<number, FlagType>>(new Map());

function enqueue(pairs: QueuedPair[], songId: number, type: FlagType) {
	queue = [...queue, ...pairs];
	const next = new Map(flags);
	next.set(songId, type);
	flags = next;
}

function dequeue(): QueuedPair | undefined {
	if (queue.length === 0) return undefined;
	const [first, ...rest] = queue;
	queue = rest;
	// auto-clear flag when all queued pairs for this song are played
	const songAId = first.song_a.id;
	if (!rest.some((p) => p.song_a.id === songAId)) {
		const next = new Map(flags);
		next.delete(songAId);
		flags = next;
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
	const next = new Map(flags);
	next.delete(songId);
	flags = next;
}

export const matchupStore = { enqueue, dequeue, hasQueue, queueLength, isFlagged, getFlagType, clearFlag };
