import { PUBLIC_API_BASE_URL } from '$env/static/public';
import { auth } from '$lib/stores/auth.svelte';

export class ApiError extends Error {
	status: number;
	body: Record<string, unknown>;

	constructor(status: number, body: Record<string, unknown>) {
		super((body.error as string) ?? `HTTP ${status}`);
		this.status = status;
		this.body = body;
	}
}

function authHeaders(extra: Record<string, string> = {}): Record<string, string> {
	const headers: Record<string, string> = { ...extra };
	if (auth.token) headers['Authorization'] = `Bearer ${auth.token}`;
	return headers;
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
	const headers = authHeaders({
		'Content-Type': 'application/json',
		...(options.headers as Record<string, string>)
	});

	const res = await fetch(`${PUBLIC_API_BASE_URL}${path}`, { ...options, headers });

	if (!res.ok) {
		const body = await res.json().catch(() => ({}));
		throw new ApiError(res.status, body);
	}

	if (res.status === 204) return undefined as T;
	return res.json();
}

async function getText(path: string): Promise<string> {
	const headers = authHeaders({ Accept: 'text/plain' });
	const res = await fetch(`${PUBLIC_API_BASE_URL}${path}`, { headers });
	if (!res.ok) {
		const body = await res.json().catch(() => ({}));
		throw new ApiError(res.status, body);
	}
	return res.text();
}

export const api = {
	get: <T>(path: string) => request<T>(path),
	getText,
	post: <T>(path: string, body: unknown) =>
		request<T>(path, { method: 'POST', body: JSON.stringify(body) }),
	patch: <T>(path: string, body: unknown) =>
		request<T>(path, { method: 'PATCH', body: JSON.stringify(body) }),
	delete: <T>(path: string) => request<T>(path, { method: 'DELETE' })
};
