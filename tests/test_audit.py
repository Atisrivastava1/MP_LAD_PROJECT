"""tests/test_audit.py"""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from tests.conftest import get_token


def _aud_headers(client: TestClient) -> dict:
    return {"Authorization": f"Bearer {get_token(client, 'test_auditor', 'pass123')}"}


def _mgr_headers(client: TestClient) -> dict:
    return {"Authorization": f"Bearer {get_token(client, 'test_manager', 'pass123')}"}

def test_audit_log_created_on_project_creation(client: TestClient, db: Session):
    from models.audit_log import AuditLog

    mgr = _mgr_headers(client)
    client.post("/api/v1/projects", json={
        "work_id": "AUDIT-PROJECT-001",
        "recommended_amount": 750000,
    }, headers=mgr)

    logs = db.query(AuditLog).filter(AuditLog.action == "PROJECT_CREATED").all()
    assert len(logs) > 0


def test_audit_log_created_on_prediction(client: TestClient, db: Session):
    from models.audit_log import AuditLog

    logs = db.query(AuditLog).filter(AuditLog.action == "PREDICTION_GENERATED").all()
    assert len(logs) > 0


def test_audit_log_created_on_investigation(client: TestClient, db: Session):
    from models.audit_log import AuditLog

    mgr = _mgr_headers(client)
    aud = _aud_headers(client)

    client.post("/api/v1/projects", json={"work_id": "AUDIT-INV-001", "recommended_amount": 1000000}, headers=mgr)
    proj = client.get("/api/v1/projects/AUDIT-INV-001", headers=mgr)
    project_id = proj.json()["project_id"]

    me = client.get("/api/v1/auth/me", headers=aud)
    auditor_id = me.json()["user_id"]

    client.post("/api/v1/investigations", json={
        "project_id": project_id,
        "assigned_to": auditor_id,
    }, headers=aud)

    logs = db.query(AuditLog).filter(AuditLog.action == "INVESTIGATION_CREATED").all()
    assert len(logs) > 0


def test_audit_log_api_requires_auditor(client: TestClient):
    mgr = _mgr_headers(client)
    resp = client.get("/api/v1/audit-logs", headers=mgr)
    assert resp.status_code == 403


def test_audit_log_api_auditor_access(client: TestClient):
    aud = _aud_headers(client)
    resp = client.get("/api/v1/audit-logs", headers=aud)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)
