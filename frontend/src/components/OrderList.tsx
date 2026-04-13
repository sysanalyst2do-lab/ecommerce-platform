import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { fetchOrders, deleteOrder } from "../api/orders";
import type { OrderListItem } from "../types/order";
import { STATUS_LABELS, STATUS_COLORS } from "../types/order";
import { StatusBadge } from "./StatusBadge";

export function OrderList() {
  const [orders, setOrders] = useState<OrderListItem[]>([]);
  const [total, setTotal] = useState(0);
  const [statusFilter, setStatusFilter] = useState("");
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    try {
      const res = await fetchOrders({ status: statusFilter || undefined });
      setOrders(res.data);
      setTotal(res.total);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, [statusFilter]);

  const handleDelete = async (id: string) => {
    if (!confirm(`Удалить заказ ${id}?`)) return;
    await deleteOrder(id);
    load();
  };

  return (
    <div>
      <div className="toolbar">
        <h1>Заказы ({total})</h1>
        <div className="toolbar-actions">
          <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
            <option value="">Все статусы</option>
            {Object.entries(STATUS_LABELS).map(([k, v]) => (
              <option key={k} value={k}>{v}</option>
            ))}
          </select>
          <Link to="/orders/new" className="btn btn-primary">+ Новый заказ</Link>
        </div>
      </div>

      {loading ? (
        <p className="loading">Загрузка...</p>
      ) : orders.length === 0 ? (
        <p className="empty">Заказов не найдено</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Клиент</th>
              <th>Статус</th>
              <th>Сумма</th>
              <th>Дата</th>
              <th>Действия</th>
            </tr>
          </thead>
          <tbody>
            {orders.map((o) => (
              <tr key={o.order_id}>
                <td><Link to={`/orders/${o.order_id}`}>{o.order_id}</Link></td>
                <td>{o.customer.name}</td>
                <td><StatusBadge status={o.status} /></td>
                <td>{o.total != null ? `${o.total.toLocaleString("ru-RU")} ₽` : "—"}</td>
                <td>{new Date(o.created_at).toLocaleDateString("ru-RU")}</td>
                <td>
                  <Link to={`/orders/${o.order_id}`} className="btn btn-sm">Открыть</Link>
                  <button className="btn btn-sm btn-danger" onClick={() => handleDelete(o.order_id)}>
                    Удалить
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
