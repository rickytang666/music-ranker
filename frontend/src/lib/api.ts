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

// never settles: the layout redirects once auth.token is null, so no caller's catch flashes error ui
function sessionExpired<T>(): Promise<T> {
	auth.expire();
	return new Promise<T>(() => {});
}

export interface ErrorInfo {
	message: string;
	retryable: boolean;
}

// no 401 branch: request() intercepts it and redirects before any catch runs
export function describeError(
	e: unknown,
	opts: { subject?: string; forbiddenHint?: string } = {}
): ErrorInfo {
	const subject = opts.subject ?? 'the server';
	// a non-ApiError means fetch itself failed, so the request never reached the server
	if (!(e instanceof ApiError)) {
		return { message: 'could not reach the server. check your connection.', retryable: true };
	}
	const fromServer = typeof e.body.error === 'string' ? e.body.error : null;
	if (e.status === 429) {
		return { message: fromServer ?? `${subject} is rate limiting us. wait a moment, then retry.`, retryable: true };
	}
	if (e.status === 403) {
		const hint = opts.forbiddenHint ? ` ${opts.forbiddenHint}` : '';
		return { message: `${subject} refused this request.${hint}`, retryable: false };
	}
	if (e.status === 404) {
		return { message: `${subject} has nothing matching that.`, retryable: false };
	}
	if (e.status >= 500) {
		return { message: `${subject} is temporarily unavailable. try again in a moment.`, retryable: true };
	}
	return { message: fromServer ?? 'that request failed.', retryable: true };
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

	if (res.status === 401) return sessionExpired<T>();

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
	if (res.status === 401) return sessionExpired<string>();
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
