import type { OrderListItem, OrderDetail, OrderCreatePayload } from "../types/order";

const BASE = "/api/v1";

async function request<T>(url: string, init?: RequestInit): Promise<T> {
  const res = await fetch(url, {
    headers: { "Content-Type": "application/json" },
    ...init,
  });
  if (res.status === 204) return undefined as T;
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.detail?.message || err.message || res.statusText);
  }
  return res.json();
}

export async function fetchOrders(params?: {
  status?: string;
  limit?: number;
  offset?: number;
}): Promise<{ data: OrderListItem[]; total: number }> {
  const sp = new URLSearchParams();
  if (params?.status) sp.set("status", params.status);
  if (params?.limit) sp.set("limit", String(params.limit));
  if (params?.offset) sp.set("offset", String(params.offset));
  const qs = sp.toString();
  return request(`${BASE}/orders${qs ? `?${qs}` : ""}`);
}

export async function fetchOrder(id: string): Promise<OrderDetail> {
  return request(`${BASE}/orders/${id}`);
}

export async function createOrder(
  payload: OrderCreatePayload
): Promise<{ order_id: string }> {
  return request(`${BASE}/orders`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export async function updateStatus(
  id: string,
  status: string
): Promise<{ order_id: string; status: string }> {
  return request(`${BASE}/orders/${id}/status`, {
    method: "PATCH",
    body: JSON.stringify({ status }),
  });
}

export async function deleteOrder(id: string): Promise<void> {
  return request(`${BASE}/orders/${id}`, { method: "DELETE" });
}
