export interface BaseSong {
	id: number;
	title: string;
	artist_name: string;
	album_name: string | null;
	album_art_url: string | null;
}

export interface RankedSong extends BaseSong {
	elo_score: number;
	matchup_count: number;
}
