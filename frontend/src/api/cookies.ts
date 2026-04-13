type CookieStatus = {
  sessionId_present: boolean;
  csrfToken_present: boolean;
  cartId: string | null;
  locale: string | null;
  lastVisitedItem: string | null;
  cookieConsent: string | null;
};

const BASE = "/api/v1/cookies";

async function request<T>(url: string, init?: RequestInit): Promise<T> {
  const res = await fetch(url, {
    headers: { "Content-Type": "application/json" },
    credentials: "include",
    ...init,
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.detail?.message || err.message || res.statusText);
  }
  return res.json();
}

export async function getCookieStatus(): Promise<CookieStatus> {
  return request(`${BASE}/status`);
}

export async function startSession(): Promise<{ message: string }> {
  return request(`${BASE}/session/start`, { method: "POST" });
}

export async function endSession(): Promise<{ message: string }> {
  return request(`${BASE}/session/end`, { method: "POST" });
}

export async function ensureCart(): Promise<{ message: string }> {
  return request(`${BASE}/cart/ensure`, { method: "POST" });
}

export async function savePreferences(payload: {
  locale: string;
  cookie_consent: string;
  last_visited_item?: string;
}): Promise<{ message: string }> {
  return request(`${BASE}/preferences`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export async function disableAnalytics(): Promise<{ message: string }> {
  return request(`${BASE}/analytics/disable`, { method: "POST" });
}

export type { CookieStatus };
