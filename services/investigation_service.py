"""services/investigation_service.py"""

from datetime import datetime, timezone

from sqlalchemy.orm import Session
from fastapi import HTTPException

from models.investigation import Investigation
from models.project import Project
from models.ml_prediction import MLPrediction
from schemas.investigation import InvestigationCreate, InvestigationUpdate
from services.audit_service import log_action


def create_investigation(
    db: Session, data: InvestigationCreate, user_id: str
) -> Investigation:
    # Validate project exists
    if not db.query(Project).filter(Project.project_id == data.project_id).first():
        raise HTTPException(status_code=404, detail="Project not found")

    # Validate prediction exists (if provided)
    if data.prediction_id:
        if not db.query(MLPrediction).filter(
            MLPrediction.prediction_id == data.prediction_id
        ).first():
            raise HTTPException(status_code=404, detail="Prediction not found")

    inv = Investigation(**data.model_dump())
    db.add(inv)
    db.commit()
    db.refresh(inv)

    log_action(
        db,
        action="INVESTIGATION_CREATED",
        user_id=user_id,
        project_id=data.project_id,
        investigation_id=inv.investigation_id,
        new_value=f"assigned_to={data.assigned_to}",
        status="OPEN",
    )
    return inv


def get_investigation(db: Session, investigation_id: str) -> Investigation:
    inv = db.query(Investigation).filter(
        Investigation.investigation_id == investigation_id
    ).first()
    if not inv:
        raise HTTPException(status_code=404, detail="Investigation not found")
    return inv


def update_investigation(
    db: Session, investigation_id: str, data: InvestigationUpdate, user_id: str
) -> Investigation:
    inv = get_investigation(db, investigation_id)
    old_status = inv.status

    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(inv, field, value)

    inv.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(inv)

    log_action(
        db,
        action="INVESTIGATION_UPDATED",
        user_id=user_id,
        project_id=inv.project_id,
        investigation_id=inv.investigation_id,
        old_value=f"status={old_status}",
        new_value=f"status={inv.status}",
        status=inv.status,
    )
    return inv
