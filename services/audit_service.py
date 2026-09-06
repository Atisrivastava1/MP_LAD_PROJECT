"""services/audit_service.py — create audit log entries"""

from sqlalchemy.orm import Session
from models.audit_log import AuditLog


def log_action(
    db: Session,
    *,
    action: str,
    user_id: str | None = None,
    project_id: str | None = None,
    investigation_id: str | None = None,
    old_value: str | None = None,
    new_value: str | None = None,
    status: str | None = None,
) -> AuditLog:
    """Create and commit a single audit log entry."""
    entry = AuditLog(
        action=action,
        user_id=user_id,
        project_id=project_id,
        investigation_id=investigation_id,
        old_value=old_value,
        new_value=new_value,
        status=status,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry
