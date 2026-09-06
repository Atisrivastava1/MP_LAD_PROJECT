"""services/review_service.py — review and decision workflow"""

from datetime import datetime, timezone

from sqlalchemy.orm import Session
from fastapi import HTTPException

from models.investigation import Investigation
from schemas.review import ReviewSubmit, DecisionSubmit
from services.audit_service import log_action

_VALID_DECISIONS = {
    "CLOSED_NO_ISSUE",
    "CLOSED_FRAUD_SUSPECTED",
    "CLOSED_REFERRED",
    "ESCALATED",
}


def submit_review(
    db: Session,
    investigation_id: str,
    data: ReviewSubmit,
    user_id: str,
) -> Investigation:
    inv = _get_or_404(db, investigation_id)
    old_status = inv.status
    inv.status = data.status
    if data.review_notes:
        inv.remarks = (inv.remarks or "") + f"\n[REVIEW] {data.review_notes}"
    inv.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(inv)

    log_action(
        db,
        action="REVIEW_SUBMITTED",
        user_id=user_id,
        project_id=inv.project_id,
        investigation_id=investigation_id,
        old_value=f"status={old_status}",
        new_value=f"status={inv.status}",
        status=inv.status,
    )
    return inv


def submit_decision(
    db: Session,
    investigation_id: str,
    data: DecisionSubmit,
    user_id: str,
) -> Investigation:
    if data.decision not in _VALID_DECISIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid decision. Valid values: {_VALID_DECISIONS}",
        )

    inv = _get_or_404(db, investigation_id)
    old_status = inv.status
    inv.status = data.decision
    inv.submitted_at = datetime.now(timezone.utc)
    if data.remarks:
        inv.remarks = (inv.remarks or "") + f"\n[DECISION] {data.remarks}"
    inv.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(inv)

    log_action(
        db,
        action="DECISION_SUBMITTED",
        user_id=user_id,
        project_id=inv.project_id,
        investigation_id=investigation_id,
        old_value=f"status={old_status}",
        new_value=f"decision={data.decision}",
        status=data.decision,
    )
    return inv


def _get_or_404(db: Session, investigation_id: str) -> Investigation:
    inv = db.query(Investigation).filter(
        Investigation.investigation_id == investigation_id
    ).first()
    if not inv:
        raise HTTPException(status_code=404, detail="Investigation not found")
    return inv
