"""routes/investigation_routes.py"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database.connection import get_db
from auth.rbac import auditor_only
from models.user import User
from schemas.investigation import InvestigationCreate, InvestigationUpdate, InvestigationOut
from services.investigation_service import (
    create_investigation,
    get_investigation,
    update_investigation,
)

router = APIRouter(prefix="/investigations", tags=["Investigations"])


@router.post("", response_model=InvestigationOut, status_code=201, summary="Start an investigation")
def start_investigation(
    data: InvestigationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(auditor_only),
):
    return create_investigation(db, data, user_id=current_user.user_id)


@router.get("/{investigation_id}", response_model=InvestigationOut, summary="Get investigation details")
def get_investigation_detail(
    investigation_id: str,
    db: Session = Depends(get_db),
    _: User = Depends(auditor_only),
):
    return get_investigation(db, investigation_id)


@router.put(
    "/{investigation_id}",
    response_model=InvestigationOut,
    summary="Update investigation findings/status",
)
def update_investigation_detail(
    investigation_id: str,
    data: InvestigationUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(auditor_only),
):
    return update_investigation(db, investigation_id, data, user_id=current_user.user_id)
