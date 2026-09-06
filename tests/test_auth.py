"""tests/test_auth.py"""

import pytest
from fastapi.testclient import TestClient


def test_login_valid_manager(client: TestClient, manager_token: str):
    assert manager_token is not None
    assert len(manager_token) > 10


def test_login_valid_auditor(client: TestClient, auditor_token: str):
    assert auditor_token is not None


def test_login_invalid_password(client: TestClient):
    resp = client.post("/api/v1/auth/login", json={"username": "test_manager", "password": "WRONG"})
    assert resp.status_code == 401
    assert "Invalid" in resp.json()["error"]


def test_login_unknown_user(client: TestClient):
    resp = client.post("/api/v1/auth/login", json={"username": "nobody", "password": "x"})
    assert resp.status_code == 401


def test_get_me_manager(client: TestClient, manager_token: str):
    resp = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {manager_token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["role"] == "DATA_MANAGER"
    assert "password_hash" not in data


def test_get_me_auditor(client: TestClient, auditor_token: str):
    resp = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {auditor_token}"})
    assert resp.status_code == 200
    assert resp.json()["role"] == "AUDITOR"


def test_get_me_no_token(client: TestClient):
    resp = client.get("/api/v1/auth/me")
    # FastAPI HTTPBearer returns 403 when Authorization header is missing
    assert resp.status_code in (401, 403)


def test_get_me_invalid_token(client: TestClient):
    resp = client.get("/api/v1/auth/me", headers={"Authorization": "Bearer invalidtoken"})
    assert resp.status_code == 401
