interface User {
	spotify_id: string;
	display_name: string | null;
}

let token = $state<string | null>(null);
let user = $state<User | null>(null);

function init() {
	if (typeof localStorage !== 'undefined') {
		token = localStorage.getItem('token');
	}
}

function setToken(t: string) {
	token = t;
	localStorage.setItem('token', t);
}

function setUser(u: User) {
	user = u;
}

function clear() {
	token = null;
	user = null;
	localStorage.removeItem('token');
}

export const auth = {
	get token() { return token; },
	get user() { return user; },
	init,
	setToken,
	setUser,
	clear
};
