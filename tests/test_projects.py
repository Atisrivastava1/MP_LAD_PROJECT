"""tests/test_projects.py"""

import io
import pytest
from fastapi.testclient import TestClient


_PROJECT_DATA = {
    "work_id": "TEST-001",
    "mp_name": "Test MP",
    "state": "Maharashtra",
    "constituency": "Mumbai North",
    "description": "Build a community hall",
    "recommended_amount": 2500000.0,
    "has_images": True,
    "completion_date": "2024-03-01",
    "completion_delay_days": 30,
    "completion_date_inconsistent": False,
    "completion_delay_missing": False,
    "project_status": "SUBMITTED",
}


def test_create_project_as_manager(client: TestClient, manager_token: str):
    headers = {"Authorization": f"Bearer {manager_token}"}
    resp = client.post("/api/v1/projects", json=_PROJECT_DATA, headers=headers)
    assert resp.status_code == 201
    data = resp.json()
    assert data["work_id"] == "TEST-001"
    assert "project_id" in data


def test_create_project_as_auditor_forbidden(client: TestClient, auditor_token: str):
    """Auditors must NOT be able to create projects."""
    headers = {"Authorization": f"Bearer {auditor_token}"}
    resp = client.post("/api/v1/projects", json=_PROJECT_DATA | {"work_id": "TEST-FORBIDDEN"}, headers=headers)
    assert resp.status_code == 403


def test_create_duplicate_work_id(client: TestClient, manager_token: str):
    headers = {"Authorization": f"Bearer {manager_token}"}
    resp = client.post("/api/v1/projects", json=_PROJECT_DATA, headers=headers)
    assert resp.status_code == 409
    assert "already exists" in resp.json()["error"]


def test_get_project_by_work_id(client: TestClient, auditor_token: str):
    headers = {"Authorization": f"Bearer {auditor_token}"}
    resp = client.get("/api/v1/projects/TEST-001", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["work_id"] == "TEST-001"


def test_get_project_not_found(client: TestClient, auditor_token: str):
    headers = {"Authorization": f"Bearer {auditor_token}"}
    resp = client.get("/api/v1/projects/NO-SUCH-ID", headers=headers)
    assert resp.status_code == 404


def test_list_projects(client: TestClient, auditor_token: str):
    headers = {"Authorization": f"Bearer {auditor_token}"}
    resp = client.get("/api/v1/projects", headers=headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_csv_upload_valid(client: TestClient, manager_token: str):
    headers = {"Authorization": f"Bearer {manager_token}"}
    csv_content = (
        "work_id,mp_name,state,constituency,description,recommended_amount,"
        "has_images,completion_date,completion_delay_days,"
        "completion_date_inconsistent,completion_delay_missing\n"
        "CSV-001,MP One,Delhi,East Delhi,Test project,1000000,true,2024-01-01,0,false,false\n"
        "CSV-002,MP Two,UP,Agra,Another project,2000000,false,,,true,true\n"
    )
    files = {"file": ("projects.csv", io.BytesIO(csv_content.encode()), "text/csv")}
    resp = client.post("/api/v1/projects/upload", files=files, headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["total_rows"] == 2
    assert data["created"] == 2


def test_csv_upload_duplicate_skipped(client: TestClient, manager_token: str):
    headers = {"Authorization": f"Bearer {manager_token}"}
    csv_content = "work_id\nCSV-001\n"   # CSV-001 already exists
    files = {"file": ("dup.csv", io.BytesIO(csv_content.encode()), "text/csv")}
    resp = client.post("/api/v1/projects/upload", files=files, headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["skipped"] == 1


def test_csv_upload_missing_column(client: TestClient, manager_token: str):
    headers = {"Authorization": f"Bearer {manager_token}"}
    csv_content = "mp_name,state\nTest MP,Delhi\n"   # missing work_id
    files = {"file": ("bad.csv", io.BytesIO(csv_content.encode()), "text/csv")}
    resp = client.post("/api/v1/projects/upload", files=files, headers=headers)
    assert resp.status_code == 400
