import { useEffect, useState } from "react";
import {
  disableAnalytics,
  endSession,
  ensureCart,
  getCookieStatus,
  savePreferences,
  startSession,
  type CookieStatus,
} from "../api/cookies";

const LAST_ITEM_OPTIONS = [
  "TEA-DAHONGPAO-050",
  "TEA-LONGJING-050",
  "BOOK-CLEAN-CODE",
  "BOOK-DDD",
];

const CONSENT_OPTIONS = [
  { value: "necessary_only", label: "Только необходимые" },
  { value: "accepted_all", label: "Принять все" },
  { value: "accepted_analytics", label: "Только аналитика" },
];

export function CookieDemo() {
  const [status, setStatus] = useState<CookieStatus | null>(null);
  const [locale, setLocale] = useState("ru-RU");
  const [consent, setConsent] = useState("necessary_only");
  const [lastItem, setLastItem] = useState(LAST_ITEM_OPTIONS[0]);
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);

  const refresh = async () => {
    const data = await getCookieStatus();
    setStatus(data);
    if (data.locale) setLocale(data.locale);
    if (data.cookieConsent) setConsent(data.cookieConsent);
    if (data.lastVisitedItem) setLastItem(data.lastVisitedItem);
  };

  useEffect(() => {
    refresh().catch((e: Error) => setMessage(e.message));
  }, []);

  const runAction = async (fn: () => Promise<{ message: string }>) => {
    setLoading(true);
    setMessage("");
    try {
      const res = await fn();
      setMessage(res.message);
      await refresh();
    } catch (e) {
      setMessage(e instanceof Error ? e.message : "Ошибка");
    } finally {
      setLoading(false);
    }
  };

  return (
    <section className="card cookie-demo">
      <h3>Демо cookie (учебный режим)</h3>
      <p className="muted">
        Набор: <code>sessionId</code>, <code>csrfToken</code>, <code>cartId</code>,{" "}
        <code>locale</code>, <code>lastVisitedItem</code>, <code>cookieConsent</code>.
      </p>

      <div className="cookie-grid">
        <button className="btn" onClick={() => runAction(startSession)} disabled={loading}>
          Старт сессии
        </button>
        <button className="btn" onClick={() => runAction(endSession)} disabled={loading}>
          Завершить сессию
        </button>
        <button className="btn" onClick={() => runAction(ensureCart)} disabled={loading}>
          Создать/обновить cartId
        </button>
      </div>

      <div className="cookie-grid cookie-controls">
        <label>
          Locale
          <select value={locale} onChange={(e) => setLocale(e.target.value)}>
            <option value="ru-RU">ru-RU</option>
            <option value="en-US">en-US</option>
          </select>
        </label>

        <label>
          Cookie consent
          <select value={consent} onChange={(e) => setConsent(e.target.value)}>
            {CONSENT_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </label>

        <label>
          Last visited item
          <select value={lastItem} onChange={(e) => setLastItem(e.target.value)}>
            {LAST_ITEM_OPTIONS.map((item) => (
              <option key={item} value={item}>
                {item}
              </option>
            ))}
          </select>
        </label>
      </div>

      <div className="cookie-grid">
        <button
          className="btn btn-primary"
          onClick={() =>
            runAction(() =>
              savePreferences({
                locale,
                cookie_consent: consent,
                last_visited_item: lastItem,
              }),
            )
          }
          disabled={loading}
        >
          Сохранить preferences
        </button>
        <button className="btn" onClick={() => runAction(disableAnalytics)} disabled={loading}>
          Отозвать analytics
        </button>
        <button className="btn" onClick={() => refresh()} disabled={loading}>
          Обновить статус
        </button>
      </div>

      {message && <p className="cookie-message">{message}</p>}

      <pre className="cookie-status">
{JSON.stringify(
  {
    server_status: status,
    document_cookie: document.cookie || "(пусто или только HttpOnly cookie)",
  },
  null,
  2,
)}
      </pre>
    </section>
  );
}
