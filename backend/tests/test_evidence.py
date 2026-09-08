"""tests/test_evidence.py"""

import io
import pytest
from fastapi.testclient import TestClient
from tests.conftest import get_token


def _aud_headers(client: TestClient) -> dict:
    return {"Authorization": f"Bearer {get_token(client, 'test_auditor', 'pass123', 'AUDITOR')}"}


def _mgr_headers(client: TestClient) -> dict:
    return {"Authorization": f"Bearer {get_token(client, 'test_manager', 'pass123', 'DATA_MANAGER')}"}

def _setup_investigation(client: TestClient) -> str:
    mgr = _mgr_headers(client)
    aud = _aud_headers(client)

    # Create project (ignore if exists)
    client.post("/api/v1/projects", json={
        "work_id": "EV-PROJECT-001",
        "recommended_amount": 500000,
    }, headers=mgr)

    proj_resp = client.get("/api/v1/projects/EV-PROJECT-001", headers=mgr)
    project_id = proj_resp.json()["project_id"]

    me_resp = client.get("/api/v1/auth/me", headers=aud)
    auditor_id = me_resp.json()["user_id"]

    inv_resp = client.post("/api/v1/investigations", json={
        "project_id": project_id,
        "assigned_to": auditor_id,
    }, headers=aud)
    return inv_resp.json()["investigation_id"]


def test_upload_evidence(client: TestClient):
    aud_headers = _aud_headers(client)
    inv_id = _setup_investigation(client)

    pdf_bytes = b"%PDF-1.4 fake pdf content"
    files = {"file": ("doc.pdf", io.BytesIO(pdf_bytes), "application/pdf")}
    data = {"description": "Supporting document"}

    resp = client.post(
        f"/api/v1/investigations/{inv_id}/evidence",
        files=files,
        data=data,
        headers=aud_headers,
    )
    assert resp.status_code == 201
    ev = resp.json()
    assert ev["file_name"] == "doc.pdf"
    assert ev["file_type"] == "application/pdf"
    assert ev["investigation_id"] == inv_id


def test_get_evidence_list(client: TestClient):
    aud_headers = _aud_headers(client)
    inv_id = _setup_investigation(client)

    resp = client.get(f"/api/v1/investigations/{inv_id}/evidence", headers=aud_headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_upload_invalid_file_type(client: TestClient):
    aud_headers = _aud_headers(client)
    inv_id = _setup_investigation(client)

    files = {"file": ("script.exe", io.BytesIO(b"malicious"), "application/x-msdownload")}
    resp = client.post(
        f"/api/v1/investigations/{inv_id}/evidence",
        files=files,
        headers=aud_headers,
    )
    assert resp.status_code == 400


def test_manager_cannot_upload_evidence(client: TestClient):
    mgr_headers = _mgr_headers(client)
    inv_id = _setup_investigation(client)

    files = {"file": ("doc.pdf", io.BytesIO(b"fake"), "application/pdf")}
    resp = client.post(
        f"/api/v1/investigations/{inv_id}/evidence",
        files=files,
        headers=mgr_headers,
    )
    assert resp.status_code == 403
