import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { OrderList } from "./components/OrderList";
import { OrderDetailPage } from "./components/OrderDetail";
import { OrderForm } from "./components/OrderForm";

export default function App() {
  return (
    <BrowserRouter>
      <div className="container">
        <header>
          <a href="/" className="logo">E-commerce Orders</a>
          <nav>
            <a href="/docs" target="_blank" rel="noopener">OpenAPI Docs</a>
          </nav>
        </header>

        <main>
          <Routes>
            <Route path="/" element={<OrderList />} />
            <Route path="/orders/new" element={<OrderForm />} />
            <Route path="/orders/:id" element={<OrderDetailPage />} />
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  );
}
