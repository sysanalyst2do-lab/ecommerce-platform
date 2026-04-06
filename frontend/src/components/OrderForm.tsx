import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { createOrder } from "../api/orders";
import type { OrderCreatePayload, OrderItem } from "../types/order";

const EMPTY_ITEM = { product_id: "", name: "", quantity: 1, price: 0 };

export function OrderForm() {
  const navigate = useNavigate();
  const [customerId, setCustomerId] = useState(1);
  const [comment, setComment] = useState("");
  const [source, setSource] = useState("web");
  const [paymentMethod, setPaymentMethod] = useState("card");
  const [items, setItems] = useState([{ ...EMPTY_ITEM }]);
  const [error, setError] = useState("");

  const updateItem = (idx: number, field: string, value: string | number) => {
    const copy = [...items];
    (copy[idx] as Record<string, unknown>)[field] = value;
    setItems(copy);
  };

  const addItem = () => setItems([...items, { ...EMPTY_ITEM }]);
  const removeItem = (idx: number) => setItems(items.filter((_, i) => i !== idx));

  const total = items.reduce((sum, it) => sum + it.price * it.quantity, 0);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");

    const payload: OrderCreatePayload = {
      customer_id: customerId,
      comment: comment || undefined,
      source,
      items: items.map((it) => ({
        product_id: it.product_id,
        name: it.name,
        quantity: it.quantity,
        price: it.price,
      })),
      payment: { method: paymentMethod, total },
    };

    try {
      const result = await createOrder(payload);
      navigate(`/orders/${result.order_id}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Ошибка создания заказа");
    }
  };

  return (
    <div>
      <Link to="/" className="back-link">← Назад к списку</Link>
      <h1>Новый заказ</h1>

      {error && <p className="error">{error}</p>}

      <form onSubmit={handleSubmit}>
        <div className="form-grid">
          <div className="form-group">
            <label>ID клиента</label>
            <input type="number" value={customerId} onChange={(e) => setCustomerId(+e.target.value)} required min={1} />
          </div>
          <div className="form-group">
            <label>Источник</label>
            <select value={source} onChange={(e) => setSource(e.target.value)}>
              <option value="web">Web</option>
              <option value="mobile">Mobile</option>
            </select>
          </div>
          <div className="form-group">
            <label>Метод оплаты</label>
            <select value={paymentMethod} onChange={(e) => setPaymentMethod(e.target.value)}>
              <option value="card">Карта</option>
              <option value="cash">Наличные</option>
              <option value="sbp">СБП</option>
            </select>
          </div>
          <div className="form-group full-width">
            <label>Комментарий</label>
            <input type="text" value={comment} onChange={(e) => setComment(e.target.value)} placeholder="Необязательно" />
          </div>
        </div>

        <h3>Позиции</h3>
        {items.map((item, idx) => (
          <div key={idx} className="item-row">
            <input placeholder="SKU" value={item.product_id} onChange={(e) => updateItem(idx, "product_id", e.target.value)} required />
            <input placeholder="Название" value={item.name} onChange={(e) => updateItem(idx, "name", e.target.value)} required />
            <input type="number" placeholder="Кол-во" value={item.quantity} onChange={(e) => updateItem(idx, "quantity", +e.target.value)} min={1} required />
            <input type="number" placeholder="Цена" value={item.price} onChange={(e) => updateItem(idx, "price", +e.target.value)} min={0} step="0.01" required />
            {items.length > 1 && (
              <button type="button" className="btn btn-sm btn-danger" onClick={() => removeItem(idx)}>✗</button>
            )}
          </div>
        ))}
        <button type="button" className="btn btn-sm" onClick={addItem}>+ Добавить позицию</button>

        <div className="form-footer">
          <p className="total">Итого: {total.toLocaleString("ru-RU")} ₽</p>
          <button type="submit" className="btn btn-primary btn-lg">Создать заказ</button>
        </div>
      </form>
    </div>
  );
}
