import sys
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.main import app


client = TestClient(app)


def test_auth_login_and_me():
    login_resp = client.post("/api/v1/auth/login", json={"username": "student", "password": "student123"})
    assert login_resp.status_code == 200
    payload = login_resp.json()
    assert "access_token" in payload
    assert "refresh_token" in payload

    me_resp = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {payload['access_token']}"})
    assert me_resp.status_code == 200
    me_body = me_resp.json()
    assert me_body["sub"] == "student"
    assert me_body["role"] == "student"


def test_auth_refresh_and_logout():
    login_resp = client.post("/api/v1/auth/login", json={"username": "teacher", "password": "teacher123"})
    assert login_resp.status_code == 200
    refresh_token = login_resp.json()["refresh_token"]

    refresh_resp = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert refresh_resp.status_code == 200
    new_refresh = refresh_resp.json()["refresh_token"]

    logout_resp = client.post("/api/v1/auth/logout", json={"refresh_token": new_refresh})
    assert logout_resp.status_code == 200

    refresh_after_logout = client.post("/api/v1/auth/refresh", json={"refresh_token": new_refresh})
    assert refresh_after_logout.status_code == 401
