interface User {
    spotify_id: string;
    display_name: string | null;
}

let token = $state<string | null>(null);
let user = $state<User | null>(null);
// survives clear() so /login can tell an expiry apart from a deliberate logout
let sessionExpired = $state(false);

function init() {
    if (typeof localStorage !== 'undefined') {
        token = localStorage.getItem('token');
    }
}

function setToken(t: string) {
    token = t;
    localStorage.setItem('token', t);
    sessionExpired = false;
}

function setUser(u: User) {
    user = u;
}

function clear() {
    token = null;
    user = null;
    localStorage.removeItem('token');
}

function expire() {
    clear();
    sessionExpired = true;
}

function consumeSessionExpired(): boolean {
    const was = sessionExpired;
    sessionExpired = false;
    return was;
}

export const auth = {
    get token() { return token; },
    get user() { return user; },
    init,
    setToken,
    setUser,
    clear,
    expire,
    consumeSessionExpired
};
