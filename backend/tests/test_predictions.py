"""tests/test_predictions.py"""

import pytest
from fastapi.testclient import TestClient
from tests.conftest import get_token


def _aud_headers(client: TestClient) -> dict:
    return {"Authorization": f"Bearer {get_token(client, 'test_auditor', 'pass123')}"}


def _mgr_headers(client: TestClient) -> dict:
    return {"Authorization": f"Bearer {get_token(client, 'test_manager', 'pass123')}"}


def test_prediction_created_after_project(client: TestClient):
    """After creating a project, a prediction should exist."""
    headers = _mgr_headers(client)
    resp = client.post("/api/v1/projects", json={
        "work_id": "PRED-TEST-001",
        "description": "Test prediction project",
        "recommended_amount": 8000000,
        "has_images": False,
        "completion_delay_missing": True,
    }, headers=headers)
    # 201 = new, 409 = already exists from previous run — both are fine
    assert resp.status_code in (201, 409)

    aud_headers = _aud_headers(client)
    resp = client.get("/api/v1/projects/PRED-TEST-001/prediction", headers=aud_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "risk_score" in data
    assert "risk_level" in data
    assert "why_flagged" in data
    assert data["risk_level"] in ("Low", "Medium", "High", "Critical")


def test_prediction_has_processed_features(client: TestClient):
    """Prediction must include the 7 ML features."""
    # Ensure the project exists
    mgr_headers = _mgr_headers(client)
    client.post("/api/v1/projects", json={
        "work_id": "PRED-TEST-001",
        "recommended_amount": 8000000,
        "completion_delay_missing": True,
    }, headers=mgr_headers)

    aud_headers = _aud_headers(client)
    resp = client.get("/api/v1/projects/PRED-TEST-001/prediction", headers=aud_headers)
    assert resp.status_code == 200
    features = resp.json().get("processed_features", {})
    expected_keys = {
        "recommended_amount_log",
        "description_length",
        "description_word_count",
        "has_images_flag",
        "completion_delay_days_clean",
        "completion_date_inconsistent",
        "completion_delay_missing",
    }
    for key in expected_keys:
        assert key in features, f"Missing feature: {key}"


def test_list_all_predictions(client: TestClient):
    aud_headers = _aud_headers(client)
    resp = client.get("/api/v1/predictions", headers=aud_headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_high_risk_predictions(client: TestClient):
    aud_headers = _aud_headers(client)
    resp = client.get("/api/v1/predictions/high-risk", headers=aud_headers)
    assert resp.status_code == 200
    for item in resp.json():
        assert item["risk_level"] in ("High", "Critical")


def test_prediction_not_modifiable_by_auditor(client: TestClient):
    """Auditor must not be able to POST/PUT to ML prediction endpoints — route doesn't exist."""
    aud_headers = _aud_headers(client)
    resp = client.put("/api/v1/predictions/some-id", json={"risk_score": 99}, headers=aud_headers)
    # Either 404 (route not found) or 405 (method not allowed) — both confirm the endpoint is not there
    assert resp.status_code in (404, 405)
