import { BrowserRouter, Routes, Route, Navigate, useLocation } from "react-router-dom";
import { OrderList } from "./components/OrderList";
import { OrderDetailPage } from "./components/OrderDetail";
import { OrderForm } from "./components/OrderForm";
import devStandImage from "./assets/dev-stand.png";

function AppLayout() {
  const location = useLocation();
  const isHomePage = location.pathname === "/";

  return (
    <div className="container">
      <div className="dev-stand-chip" aria-label="Development stand" tabIndex={0}>
        DEV STAND
        <span className="dev-stand-tooltip" role="tooltip">
          Тестовый контур для обучения и демонстраций
        </span>
      </div>

      <header className="app-header">
        <div className="header-left">
          <nav>
            <a href="/docs" target="_blank" rel="noopener">OpenAPI Docs</a>
          </nav>
        </div>
        <a href="/" className="logo logo-centered">E-commerce Orders</a>
        <div className="header-right">
          {isHomePage ? <img className="header-cat" src={devStandImage} alt="Dev stand cat" /> : null}
        </div>
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
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AppLayout />
    </BrowserRouter>
  );
}
