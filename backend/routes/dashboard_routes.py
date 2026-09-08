"""routes/dashboard_routes.py"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database.connection import get_db
from auth.rbac import any_authenticated
from models.user import User
from services.dashboard_service import get_summary, get_risk_distribution, get_high_risk_projects

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/summary", summary="Overall project and investigation summary")
def dashboard_summary(
    db: Session = Depends(get_db),
    _: User = Depends(any_authenticated),
) -> dict:
    return get_summary(db, current_user=_)


@router.get("/risk-distribution", summary="Count of projects per risk level")
def risk_distribution(
    db: Session = Depends(get_db),
    _: User = Depends(any_authenticated),
) -> list[dict]:
    return get_risk_distribution(db, current_user=_)


@router.get("/high-risk", summary="List of High + Critical risk projects with prediction info")
def high_risk_projects(
    db: Session = Depends(get_db),
    _: User = Depends(any_authenticated),
) -> list[dict]:
    return get_high_risk_projects(db, current_user=_)
