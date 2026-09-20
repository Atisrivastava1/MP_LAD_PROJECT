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

    # Project Status counts
    q_status = db.query(Project.project_status, func.count(Project.project_id))
    if current_user.role == "DATA_MANAGER":
        q_status = q_status.filter(Project.uploaded_by == current_user.user_id)
    status_counts = q_status.group_by(Project.project_status).all()
    status_map = {s: c for s, c in status_counts}

    # Get the latest prediction for each project
    subquery = db.query(
        MLPrediction.project_id,
        func.max(MLPrediction.prediction_created_at).label('max_prediction_created_at')
    ).group_by(MLPrediction.project_id).subquery()

    q_risk = db.query(MLPrediction.risk_level, func.count(MLPrediction.prediction_id)).join(
        subquery,
        (MLPrediction.project_id == subquery.c.project_id) & (MLPrediction.prediction_created_at == subquery.c.max_prediction_created_at)
    ).join(Project, Project.project_id == MLPrediction.project_id)

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
        "status_submitted": status_map.get("SUBMITTED", 0),
        "status_in_progress": status_map.get("IN_PROGRESS", 0),
        "status_completed": status_map.get("COMPLETED", 0),
        "status_rejected": status_map.get("REJECTED", 0),
        "low_count": level_map.get("Low", 0),
        "medium_count": level_map.get("Medium", 0),
        "high_count": level_map.get("High", 0),
        "critical_count": level_map.get("Critical", 0),
        "investigations_open": investigations_open,
        "investigations_closed": investigations_closed,
    }


def get_risk_distribution(db: Session, current_user: User) -> list[dict]:
    subquery = db.query(
        MLPrediction.project_id,
        func.max(MLPrediction.prediction_created_at).label('max_prediction_created_at')
    ).group_by(MLPrediction.project_id).subquery()

    q_risk = db.query(MLPrediction.risk_level, func.count(MLPrediction.prediction_id)).join(
        subquery,
        (MLPrediction.project_id == subquery.c.project_id) & (MLPrediction.prediction_created_at == subquery.c.max_prediction_created_at)
    ).join(Project, Project.project_id == MLPrediction.project_id)

    if current_user.role == "DATA_MANAGER":
        q_risk = q_risk.filter(Project.uploaded_by == current_user.user_id)
    rows = q_risk.group_by(MLPrediction.risk_level).all()
    return [{"risk_level": r, "count": c} for r, c in rows]


def get_high_risk_projects(db: Session, current_user: User, limit: int = 50) -> list[dict]:
    # Get latest prediction per project
    subquery = db.query(
        MLPrediction.project_id,
        func.max(MLPrediction.prediction_created_at).label('max_prediction_created_at')
    ).group_by(MLPrediction.project_id).subquery()

    q_proj = db.query(Project, MLPrediction).join(
        subquery,
        Project.project_id == subquery.c.project_id
    ).join(
        MLPrediction,
        (MLPrediction.project_id == subquery.c.project_id) & (MLPrediction.prediction_created_at == subquery.c.max_prediction_created_at)
    ).filter(MLPrediction.risk_level.in_(["High", "Critical"]))

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
            "district": project.constituency,
            "description": project.description,
            "recommendedAmount": project.recommended_amount,
            "completionDate": project.completion_date,
            "hasImages": project.has_images,
            "anomalyFlag": True,
            "isDuplicate": False,
            "risk_score": pred.risk_score,
            "risk_level": pred.risk_level,
            "why_flagged": pred.why_flagged,
        })
    return result


def get_data_quality(db: Session, current_user: User) -> dict:
    from sqlalchemy import func, or_
    
    q = db.query(Project)
    if current_user.role == "DATA_MANAGER":
        q = q.filter(Project.uploaded_by == current_user.user_id)
        
    total_projects = q.count()
    if total_projects == 0:
        return {
            'qualityScore': 0.0,
            'checksPassed': 0,
            'totalChecks': 5,
            'criticalIssues': 0,
            'checks': [
                {'name': 'Required Fields Complete', 'passed': False},
                {'name': 'Amount Values Valid', 'passed': False},
                {'name': 'Dates in Logical Range', 'passed': False},
                {'name': 'Status Mapping Correct', 'passed': False},
                {'name': 'No Duplicate IDs', 'passed': False},
            ]
        }
    
    # 1. Required Fields Complete
    missing_fields_count = q.filter(
        or_(
            Project.mp_name == None,
            Project.mp_name == "",
            Project.state == None,
            Project.state == "",
            Project.constituency == None,
            Project.constituency == ""
        )
    ).count()
    req_fields_passed = missing_fields_count == 0
    
    # 2. Amount Values Valid
    invalid_amounts_count = q.filter(
        or_(
            Project.recommended_amount == None,
            Project.recommended_amount <= 0
        )
    ).count()
    amounts_passed = invalid_amounts_count == 0
    
    # 3. Dates in Logical Range
    invalid_dates_count = q.filter(
        Project.project_status == "COMPLETED",
        or_(
            Project.completion_date == None,
            Project.completion_date == ""
        )
    ).count()
    dates_passed = invalid_dates_count == 0
    
    # 4. Status Mapping Correct
    valid_statuses = ["COMPLETED", "IN_PROGRESS", "REJECTED", "SUBMITTED"]
    invalid_status_count = q.filter(~Project.project_status.in_(valid_statuses)).count()
    status_passed = invalid_status_count == 0
    
    # 5. No Duplicate IDs
    distinct_ids = q.with_entities(func.count(func.distinct(Project.work_id))).scalar()
    duplicates_passed = (total_projects == distinct_ids)
    
    checks_passed = sum([req_fields_passed, amounts_passed, dates_passed, status_passed, duplicates_passed])
    quality_score = (checks_passed / 5.0) * 100.0
    
    critical_issues = missing_fields_count + invalid_amounts_count + invalid_status_count + (total_projects - distinct_ids)
    
    return {
        'qualityScore': quality_score,
        'checksPassed': checks_passed,
        'totalChecks': 5,
        'criticalIssues': critical_issues,
        'checks': [
            {'name': 'Required Fields Complete', 'passed': req_fields_passed},
            {'name': 'Amount Values Valid', 'passed': amounts_passed},
            {'name': 'Dates in Logical Range', 'passed': dates_passed},
            {'name': 'Status Mapping Correct', 'passed': status_passed},
            {'name': 'No Duplicate IDs', 'passed': duplicates_passed},
        ]
    }
