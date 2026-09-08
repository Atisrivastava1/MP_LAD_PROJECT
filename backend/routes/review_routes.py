"""routes/review_routes.py"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database.connection import get_db
from auth.rbac import auditor_only
from models.user import User
from schemas.review import ReviewSubmit, DecisionSubmit
from schemas.investigation import InvestigationOut
from services.review_service import submit_review, submit_decision

router = APIRouter(prefix="/investigations", tags=["Review & Decision"])


@router.post(
    "/{investigation_id}/review",
    response_model=InvestigationOut,
    summary="Submit investigation for review",
)
def review(
    investigation_id: str,
    data: ReviewSubmit,
    db: Session = Depends(get_db),
    current_user: User = Depends(auditor_only),
):
    return submit_review(db, investigation_id, data, user_id=current_user.user_id)


@router.put(
    "/{investigation_id}/decision",
    response_model=InvestigationOut,
    summary="Submit final decision on investigation",
)
def decision(
    investigation_id: str,
    data: DecisionSubmit,
    db: Session = Depends(get_db),
    current_user: User = Depends(auditor_only),
):
    return submit_decision(db, investigation_id, data, user_id=current_user.user_id)
