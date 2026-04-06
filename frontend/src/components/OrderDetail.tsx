import { useEffect, useState } from "react";
import { useParams, Link, useNavigate } from "react-router-dom";
import { fetchOrder, updateStatus, deleteOrder } from "../api/orders";
import type { OrderDetail as OrderDetailType } from "../types/order";
import { STATUS_LABELS } from "../types/order";
import { StatusBadge } from "./StatusBadge";

const TRANSITIONS: Record<string, string[]> = {
  created: ["paid", "cancelled"],
  paid: ["processing", "cancelled"],
  processing: ["shipped", "cancelled"],
  shipped: ["delivered"],
  delivered: ["cancelled"],
};

export function OrderDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [order, setOrder] = useState<OrderDetailType | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!id) return;
    fetchOrder(id).then(setOrder).catch((e) => setError(e.message));
  }, [id]);

  const handleStatus = async (newStatus: string) => {
    if (!id) return;
    await updateStatus(id, newStatus);
    const updated = await fetchOrder(id);
    setOrder(updated);
  };

  const handleDelete = async () => {
    if (!id || !confirm("Удалить заказ?")) return;
    await deleteOrder(id);
    navigate("/");
  };

  if (error) return <p className="error">Ошибка: {error}</p>;
  if (!order) return <p className="loading">Загрузка...</p>;

  const nextStatuses = TRANSITIONS[order.status] || [];

  return (
    <div>
      <Link to="/" className="back-link">← Назад к списку</Link>

      <div className="detail-header">
        <h1>{order.order_id}</h1>
        <StatusBadge status={order.status} />
      </div>

      <div className="detail-grid">
        <section className="card">
          <h3>Клиент</h3>
          <p><strong>{order.customer.name}</strong></p>
          <p>{order.customer.email}</p>
          {order.customer.phone && <p>{order.customer.phone}</p>}
        </section>

        <section className="card">
          <h3>Оплата</h3>
          {order.payment ? (
            <>
              <p className="total">{order.payment.total.toLocaleString("ru-RU")} {order.payment.currency}</p>
              <p>Метод: {order.payment.method}</p>
              {order.payment.paid_at && (
                <p>Оплачен: {new Date(order.payment.paid_at).toLocaleString("ru-RU")}</p>
              )}
            </>
          ) : (
            <p className="muted">Нет данных об оплате</p>
          )}
        </section>

        <section className="card">
          <h3>Метаданные</h3>
          <p>Источник: {order.meta.source || "—"}</p>
          <p>IP: {order.meta.ip || "—"}</p>
          {order.meta.tags && order.meta.tags.length > 0 && (
            <div className="tags">
              {order.meta.tags.map((t) => <span key={t} className="tag">{t}</span>)}
            </div>
          )}
          {order.comment && <p className="comment">Комментарий: {order.comment}</p>}
        </section>
      </div>

      <section className="card">
        <h3>Позиции заказа</h3>
        <table>
          <thead>
            <tr>
              <th>SKU</th>
              <th>Название</th>
              <th>Кол-во</th>
              <th>Цена</th>
              <th>Итого</th>
              <th>В наличии</th>
            </tr>
          </thead>
          <tbody>
            {order.items.map((item) => (
              <tr key={item.product_id}>
                <td className="mono">{item.product_id}</td>
                <td>{item.name}</td>
                <td>{item.quantity}</td>
                <td>{item.price.toLocaleString("ru-RU")} ₽</td>
                <td>{(item.price * item.quantity).toLocaleString("ru-RU")} ₽</td>
                <td>{item.in_stock ? "✓" : "✗"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="card actions-card">
        <h3>Действия</h3>
        <div className="actions">
          {nextStatuses.map((s) => (
            <button key={s} className="btn btn-primary" onClick={() => handleStatus(s)}>
              → {STATUS_LABELS[s]}
            </button>
          ))}
          <button className="btn btn-danger" onClick={handleDelete}>Удалить заказ</button>
        </div>
      </section>

      <p className="meta-dates">
        Создан: {new Date(order.created_at).toLocaleString("ru-RU")} |
        Обновлён: {new Date(order.updated_at).toLocaleString("ru-RU")}
      </p>
    </div>
  );
}
