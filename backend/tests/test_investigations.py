"""tests/test_investigations.py"""

import pytest
from fastapi.testclient import TestClient
from tests.conftest import get_token


def _aud_headers(client: TestClient) -> dict:
    return {"Authorization": f"Bearer {get_token(client, 'test_auditor', 'pass123')}"}


def _mgr_headers(client: TestClient) -> dict:
    return {"Authorization": f"Bearer {get_token(client, 'test_manager', 'pass123')}"}

def _create_project_and_get_ids(client: TestClient, mgr_headers: dict) -> tuple[str, str | None]:
    resp = client.post("/api/v1/projects", json={
        "work_id": "INV-PROJECT-001",
        "description": "Investigation test project",
        "recommended_amount": 3000000,
    }, headers=mgr_headers)
    if resp.status_code == 201:
        project_id = resp.json()["project_id"]
    else:
        p = client.get("/api/v1/projects/INV-PROJECT-001", headers=mgr_headers)
        project_id = p.json()["project_id"]

    # Get prediction_id if available
    pred_resp = client.get("/api/v1/projects/INV-PROJECT-001/prediction", headers=_aud_headers(client))
    prediction_id = pred_resp.json().get("prediction_id") if pred_resp.status_code == 200 else None
    return project_id, prediction_id


def _get_auditor_user_id(client: TestClient) -> str:
    headers = _aud_headers(client)
    resp = client.get("/api/v1/auth/me", headers=headers)
    return resp.json()["user_id"]


def test_create_investigation(client: TestClient):
    mgr_headers = _mgr_headers(client)
    aud_headers = _aud_headers(client)
    project_id, prediction_id = _create_project_and_get_ids(client, mgr_headers)
    auditor_id = _get_auditor_user_id(client)

    resp = client.post("/api/v1/investigations", json={
        "project_id": project_id,
        "prediction_id": prediction_id,
        "assigned_to": auditor_id,
        "findings": "Preliminary review initiated",
    }, headers=aud_headers)
    assert resp.status_code == 201
    data = resp.json()
    assert data["status"] == "OPEN"
    assert data["project_id"] == project_id


def test_get_investigation(client: TestClient):
    mgr_headers = _mgr_headers(client)
    aud_headers = _aud_headers(client)
    project_id, prediction_id = _create_project_and_get_ids(client, mgr_headers)
    auditor_id = _get_auditor_user_id(client)

    create_resp = client.post("/api/v1/investigations", json={
        "project_id": project_id,
        "prediction_id": prediction_id,
        "assigned_to": auditor_id,
    }, headers=aud_headers)
    inv_id = create_resp.json()["investigation_id"]

    resp = client.get(f"/api/v1/investigations/{inv_id}", headers=aud_headers)
    assert resp.status_code == 200
    assert resp.json()["investigation_id"] == inv_id


def test_update_investigation(client: TestClient):
    mgr_headers = _mgr_headers(client)
    aud_headers = _aud_headers(client)
    project_id, prediction_id = _create_project_and_get_ids(client, mgr_headers)
    auditor_id = _get_auditor_user_id(client)

    create_resp = client.post("/api/v1/investigations", json={
        "project_id": project_id,
        "assigned_to": auditor_id,
    }, headers=aud_headers)
    inv_id = create_resp.json()["investigation_id"]

    resp = client.put(f"/api/v1/investigations/{inv_id}", json={
        "findings": "Documents reviewed. Irregularities found.",
        "status": "IN_PROGRESS",
    }, headers=aud_headers)
    assert resp.status_code == 200
    assert resp.json()["findings"] == "Documents reviewed. Irregularities found."


def test_investigation_manager_cannot_create(client: TestClient):
    """DATA_MANAGER must be forbidden from creating investigations."""
    mgr_headers = _mgr_headers(client)
    project_id, _ = _create_project_and_get_ids(client, mgr_headers)
    resp = client.post("/api/v1/investigations", json={
        "project_id": project_id,
        "assigned_to": "some-user-id",
    }, headers=mgr_headers)
    assert resp.status_code == 403


def test_investigation_not_found(client: TestClient):
    aud_headers = _aud_headers(client)
    resp = client.get("/api/v1/investigations/nonexistent-id", headers=aud_headers)
    assert resp.status_code == 404
