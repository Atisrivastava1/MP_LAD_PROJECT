"""routes/prediction_routes.py"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database.connection import get_db
from auth.rbac import any_authenticated
from models.user import User
from models.project import Project
from schemas.prediction import PredictionOut
from services.prediction_service import (
    get_prediction_by_project_id,
    get_all_predictions,
    get_high_risk_predictions,
)

router = APIRouter(tags=["Predictions"])


def _enrich(pred, db: Session) -> PredictionOut:
    """Attach work_id to prediction output."""
    project = db.query(Project).filter(Project.project_id == pred.project_id).first()
    data = PredictionOut.model_validate(pred)
    data.work_id = project.work_id if project else None
    return data


@router.get(
    "/projects/{work_id}/prediction",
    response_model=PredictionOut,
    summary="Get latest prediction for a project",
)
def get_project_prediction(
    work_id: str,
    db: Session = Depends(get_db),
    _: User = Depends(any_authenticated),
):
    project = db.query(Project).filter(Project.work_id == work_id).first()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    pred = get_prediction_by_project_id(db, project.project_id)
    if not pred:
        raise HTTPException(status_code=404, detail="No prediction found for this project")
    return _enrich(pred, db)


@router.get("/predictions", response_model=list[PredictionOut], summary="List all predictions")
def list_predictions(
    db: Session = Depends(get_db),
    _: User = Depends(any_authenticated),
):
    return [_enrich(p, db) for p in get_all_predictions(db)]


@router.get(
    "/predictions/high-risk",
    response_model=list[PredictionOut],
    summary="List High + Critical risk predictions",
)
def list_high_risk(
    db: Session = Depends(get_db),
    _: User = Depends(any_authenticated),
):
    return [_enrich(p, db) for p in get_high_risk_predictions(db)]
