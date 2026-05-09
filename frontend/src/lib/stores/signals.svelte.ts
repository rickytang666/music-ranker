export type FlagType = 'overrated' | 'underrated' | 'unsure';

interface Signal {
	type: FlagType;
	remaining: number;
}

let signals = $state<Record<number, Signal>>({});

function set(songId: number, type: FlagType) {
	signals = { ...signals, [songId]: { type, remaining: 5 } };
}

function clear(songId: number) {
	const next = { ...signals };
	delete next[songId];
	signals = next;
}

// call after each successful pick
function tick() {
	const next: Record<number, Signal> = {};
	for (const [id, sig] of Object.entries(signals)) {
		if (sig.remaining > 0) {
			next[Number(id)] = { ...sig, remaining: sig.remaining - 1 };
		}
	}
	signals = next;
}

function toQueryString() {
	const parts: string[] = [];
	for (const [id, sig] of Object.entries(signals)) {
		parts.push(`${sig.type}_ids[]=${id}`);
	}
	return parts.length ? `?${parts.join('&')}` : '';
}

function get(songId: number): Signal | undefined {
	return signals[songId];
}

export const flagStore = { get, set, clear, tick, toQueryString };
