"""services/dashboard_service.py - aggregate data for dashboard APIs"""

from sqlalchemy import func
from sqlalchemy.orm import Session

from models.project import Project
from models.ml_prediction import MLPrediction
from models.investigation import Investigation
from models.user import User


def get_summary(db: Session, current_user: User) -> dict:
    q_proj = db.query(Project.project_id)
    if current_user.role == "DATA_MANAGER":
        q_proj = q_proj.filter(Project.uploaded_by == current_user.user_id)
    total_projects = q_proj.with_entities(func.count(Project.project_id)).scalar() or 0

    q_risk = db.query(MLPrediction.risk_level, func.count(MLPrediction.prediction_id)).join(Project, Project.project_id == MLPrediction.project_id)
    if current_user.role == "DATA_MANAGER":
        q_risk = q_risk.filter(Project.uploaded_by == current_user.user_id)
    risk_counts = q_risk.group_by(MLPrediction.risk_level).all()
    level_map = {r: c for r, c in risk_counts}

    q_inv = db.query(Investigation.status, func.count(Investigation.investigation_id)).join(Project, Project.project_id == Investigation.project_id)
    if current_user.role == "DATA_MANAGER":
        q_inv = q_inv.filter(Project.uploaded_by == current_user.user_id)
    inv_counts = q_inv.group_by(Investigation.status).all()

    open_statuses = {"OPEN", "UNDER_REVIEW", "IN_PROGRESS"}
    investigations_open = sum(c for s, c in inv_counts if s in open_statuses)
    investigations_closed = sum(c for s, c in inv_counts if s not in open_statuses)

    return {
        "total_projects": total_projects,
        "low_count": level_map.get("Low", 0),
        "medium_count": level_map.get("Medium", 0),
        "high_count": level_map.get("High", 0),
        "critical_count": level_map.get("Critical", 0),
        "investigations_open": investigations_open,
        "investigations_closed": investigations_closed,
    }


def get_risk_distribution(db: Session, current_user: User) -> list[dict]:
    q_risk = db.query(MLPrediction.risk_level, func.count(MLPrediction.prediction_id)).join(Project, Project.project_id == MLPrediction.project_id)
    if current_user.role == "DATA_MANAGER":
        q_risk = q_risk.filter(Project.uploaded_by == current_user.user_id)
    rows = q_risk.group_by(MLPrediction.risk_level).all()
    return [{"risk_level": r, "count": c} for r, c in rows]


def get_high_risk_projects(db: Session, current_user: User, limit: int = 50) -> list[dict]:
    q_proj = db.query(Project, MLPrediction).join(MLPrediction, MLPrediction.project_id == Project.project_id).filter(MLPrediction.risk_level.in_(["High", "Critical"]))
    if current_user.role == "DATA_MANAGER":
        q_proj = q_proj.filter(Project.uploaded_by == current_user.user_id)
        
    rows = q_proj.order_by(MLPrediction.risk_score.desc()).limit(limit).all()
    
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
