"""routes/audit_routes.py"""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime

from database.connection import get_db
from auth.rbac import auditor_only, any_authenticated
from models.user import User
from models.audit_log import AuditLog

router = APIRouter(prefix="/audit-logs", tags=["Audit Logs"])


class AuditLogOut(BaseModel):
    log_id: str
    user_id: str | None
    project_id: str | None
    investigation_id: str | None
    action: str
    old_value: str | None
    new_value: str | None
    status: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


@router.get("", response_model=list[AuditLogOut], summary="View audit log history (Auditor only)")
def list_audit_logs(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    _: User = Depends(auditor_only),
):
    return (
        db.query(AuditLog)
        .order_by(AuditLog.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


@router.get("/notifications", summary="Get recent system notifications")
def system_notifications(
    db: Session = Depends(get_db),
    _: User = Depends(any_authenticated),
) -> list[dict]:
    # We can fetch recent audit logs as notifications
    from models.audit_log import AuditLog
    logs = db.query(AuditLog).order_by(AuditLog.created_at.desc()).limit(10).all()
    return [
        {
            "id": log.log_id,
            "title": "System Alert",
            "message": log.action,
            "time": log.created_at.strftime("%Y-%m-%d %H:%M"),
            "read": False,
            "type": "alert" if "failed" in log.action.lower() else "info"
        } for log in logs
    ]
