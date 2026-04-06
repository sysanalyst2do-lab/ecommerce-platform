export interface CustomerShort {
  id: number;
  name: string;
}

export interface CustomerFull extends CustomerShort {
  email: string;
  phone: string | null;
}

export interface OrderItem {
  product_id: string;
  name: string;
  quantity: number;
  price: number;
  in_stock: boolean;
}

export interface Payment {
  method: string;
  total: number;
  currency: string;
  paid_at: string | null;
}

export interface OrderMeta {
  source: string | null;
  ip: string | null;
  tags: string[] | null;
}

export interface OrderListItem {
  order_id: string;
  status: string;
  is_paid: boolean;
  customer: CustomerShort;
  total: number | null;
  created_at: string;
}

export interface OrderDetail {
  order_id: string;
  created_at: string;
  updated_at: string;
  status: string;
  is_paid: boolean;
  comment: string | null;
  meta: OrderMeta;
  customer: CustomerFull;
  items: OrderItem[];
  payment: Payment | null;
}

export interface OrderCreatePayload {
  customer_id: number;
  comment?: string;
  source?: string;
  tags?: string[];
  items: Omit<OrderItem, "in_stock">[];
  payment?: { method: string; total: number; currency?: string };
}

export const STATUS_LABELS: Record<string, string> = {
  created: "Новый",
  paid: "Оплачен",
  processing: "В обработке",
  shipped: "Отгружен",
  delivered: "Доставлен",
  cancelled: "Отменён",
};

export const STATUS_COLORS: Record<string, string> = {
  created: "#6b7280",
  paid: "#2563eb",
  processing: "#d97706",
  shipped: "#7c3aed",
  delivered: "#16a34a",
  cancelled: "#dc2626",
};
