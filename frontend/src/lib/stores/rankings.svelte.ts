export interface Ranking {
	id: number;
	name: string;
	created_at: string;
}

let list = $state<Ranking[]>([]);

function set(rankings: Ranking[]) {
	list = rankings;
}

function add(ranking: Ranking) {
	list = [...list, ranking];
}

function update(ranking: Ranking) {
	list = list.map((r) => (r.id === ranking.id ? ranking : r));
}

function remove(id: number) {
	list = list.filter((r) => r.id !== id);
}

export const rankings = {
	get list() { return list; },
	set,
	add,
	update,
	remove
};
