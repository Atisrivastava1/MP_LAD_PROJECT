"""services/dashboard_service.py — aggregate data for dashboard APIs"""

from sqlalchemy import func
from sqlalchemy.orm import Session

from models.project import Project
from models.ml_prediction import MLPrediction
from models.investigation import Investigation


def get_summary(db: Session) -> dict:
    total_projects = db.query(func.count(Project.project_id)).scalar() or 0

    risk_counts = (
        db.query(MLPrediction.risk_level, func.count(MLPrediction.prediction_id))
        .group_by(MLPrediction.risk_level)
        .all()
    )
    level_map = {r: c for r, c in risk_counts}

    inv_counts = (
        db.query(Investigation.status, func.count(Investigation.investigation_id))
        .group_by(Investigation.status)
        .all()
    )
    open_statuses = {"OPEN", "UNDER_REVIEW", "IN_PROGRESS"}
    investigations_open = sum(
        c for s, c in inv_counts if s in open_statuses
    )
    investigations_closed = sum(
        c for s, c in inv_counts if s not in open_statuses
    )

    return {
        "total_projects": total_projects,
        "low_count": level_map.get("Low", 0),
        "medium_count": level_map.get("Medium", 0),
        "high_count": level_map.get("High", 0),
        "critical_count": level_map.get("Critical", 0),
        "investigations_open": investigations_open,
        "investigations_closed": investigations_closed,
    }


def get_risk_distribution(db: Session) -> list[dict]:
    rows = (
        db.query(MLPrediction.risk_level, func.count(MLPrediction.prediction_id))
        .group_by(MLPrediction.risk_level)
        .all()
    )
    return [{"risk_level": r, "count": c} for r, c in rows]


def get_high_risk_projects(db: Session, limit: int = 50) -> list[dict]:
    rows = (
        db.query(Project, MLPrediction)
        .join(MLPrediction, MLPrediction.project_id == Project.project_id)
        .filter(MLPrediction.risk_level.in_(["High", "Critical"]))
        .order_by(MLPrediction.risk_score.desc())
        .limit(limit)
        .all()
    )
    result = []
    for project, pred in rows:
        result.append({
            "project_id": project.project_id,
            "work_id": project.work_id,
            "mp_name": project.mp_name,
            "state": project.state,
            "risk_score": pred.risk_score,
            "risk_level": pred.risk_level,
            "why_flagged": pred.why_flagged,
        })
    return result
