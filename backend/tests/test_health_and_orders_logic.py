import re

from fastapi.testclient import TestClient

from app.main import app
from app.routers.orders import ALLOWED_TRANSITIONS, VALID_STATUSES, _next_order_id


client = TestClient(app)


def test_health_basic_returns_ok():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_next_order_id_has_expected_format():
    order_id = _next_order_id()
    assert re.match(r"^ORD-\d{4}-[A-F0-9]{4}$", order_id)


def test_status_transitions_reference_only_known_statuses():
    assert set(ALLOWED_TRANSITIONS.keys()) == VALID_STATUSES
    for source, destinations in ALLOWED_TRANSITIONS.items():
        assert source in VALID_STATUSES
        assert destinations.issubset(VALID_STATUSES)
