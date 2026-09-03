import type { RankedSong } from '$lib/types';

/**
 * shared so the albums view and the songs filter cannot drift apart: if these
 * keys were derived in two places a mismatch would silently match nothing
 */
export function albumKey(song: RankedSong): string {
	return song.spotify_album_id ?? song.album_name ?? `__singles__${song.artist_name}`;
}

export function albumLabel(song: RankedSong): string {
	return song.album_name ?? 'Singles';
}
