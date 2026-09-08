"""tests/test_duplicate_matches.py"""

import pytest
from fastapi.testclient import TestClient
from tests.conftest import get_token


def _aud_headers(client: TestClient) -> dict:
    return {"Authorization": f"Bearer {get_token(client, 'test_auditor', 'pass123')}"}


def _mgr_headers(client: TestClient) -> dict:
    return {"Authorization": f"Bearer {get_token(client, 'test_manager', 'pass123')}"}

def _get_two_project_ids(client: TestClient, mgr_headers: dict) -> tuple[str, str]:
    """Create two projects and return their project_ids."""
    p1 = client.post("/api/v1/projects", json={"work_id": "DUP-A-001", "recommended_amount": 100000}, headers=mgr_headers)
    p2 = client.post("/api/v1/projects", json={"work_id": "DUP-B-001", "recommended_amount": 200000}, headers=mgr_headers)
    # Handle already-exists gracefully
    id1 = p1.json().get("project_id") or _get_project_id(client, "DUP-A-001", mgr_headers)
    id2 = p2.json().get("project_id") or _get_project_id(client, "DUP-B-001", mgr_headers)
    return id1, id2


def _get_project_id(client: TestClient, work_id: str, headers: dict) -> str:
    resp = client.get(f"/api/v1/projects/{work_id}", headers=headers)
    return resp.json()["project_id"]


def test_create_duplicate_match(client: TestClient):
    mgr_headers = _mgr_headers(client)
    aud_headers = _aud_headers(client)
    id1, id2 = _get_two_project_ids(client, mgr_headers)

    resp = client.post("/api/v1/duplicate-matches", json={
        "project_id": id1,
        "matched_project_id": id2,
        "similarity_score": 0.87,
        "detection_method": "TF-IDF",
        "match_reason": "Similar description and amount",
    }, headers=aud_headers)
    assert resp.status_code == 201
    data = resp.json()
    assert data["similarity_score"] == 0.87
    assert data["project_id"] == id1


def test_get_duplicates_for_project(client: TestClient):
    mgr_headers = _mgr_headers(client)
    aud_headers = _aud_headers(client)
    resp = client.get("/api/v1/projects/DUP-A-001/duplicates", headers=aud_headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_list_all_duplicates(client: TestClient):
    aud_headers = _aud_headers(client)
    resp = client.get("/api/v1/duplicate-matches", headers=aud_headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_duplicate_invalid_project_ref(client: TestClient):
    aud_headers = _aud_headers(client)
    resp = client.post("/api/v1/duplicate-matches", json={
        "project_id": "nonexistent-id",
        "matched_project_id": "also-nonexistent",
    }, headers=aud_headers)
    assert resp.status_code == 404
