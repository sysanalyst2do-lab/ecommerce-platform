import sys
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.main import app


client = TestClient(app)


class _DummySMTP:
    def __init__(self, host, port, timeout):
        self.host = host
        self.port = port
        self.timeout = timeout
        self.sent = []

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def send_message(self, message):
        self.sent.append(message)


class _FailingSMTP:
    def __init__(self, host, port, timeout):
        raise OSError("connection refused")


def test_mail_demo_success(monkeypatch):
    from app.routers import mail as mail_router

    monkeypatch.setattr(mail_router.smtplib, "SMTP", _DummySMTP)
    response = client.post(
        "/api/v1/mail/test",
        json={"to": "student@example.com", "subject": "Demo", "body": "Hello"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["message"] == "mail queued"
    assert "smtp_host" in body
    assert "smtp_port" in body


def test_mail_demo_failure(monkeypatch):
    from app.routers import mail as mail_router

    monkeypatch.setattr(mail_router.smtplib, "SMTP", _FailingSMTP)
    response = client.post(
        "/api/v1/mail/test",
        json={"to": "student@example.com"},
    )
    assert response.status_code == 502
