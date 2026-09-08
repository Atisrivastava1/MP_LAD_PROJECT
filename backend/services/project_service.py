"""services/project_service.py - create, update, upsert (CSV), and queries"""

import io
import logging
from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from fastapi import HTTPException

import pandas as pd

from models.project import Project, ProjectHistory
from schemas.project import ProjectCreate, ProjectUpdate, CSVRowResult, CSVUploadResult
from services.prediction_service import run_and_store_prediction
from services.audit_service import log_action

logger = logging.getLogger(__name__)

# Required CSV columns
_REQUIRED_CSV_COLS = {"work_id"}


def _calculate_next_update_due(status: str, validity_days: int | None):
    if status == "COMPLETED" or not validity_days:
        return None
    return (datetime.now(timezone.utc) + timedelta(days=validity_days)).date()


def _snapshot_history(db: Session, project: Project) -> None:
    history = ProjectHistory(
        project_id=project.project_id,
        completion_delay_days=project.completion_delay_days,
        recommended_amount=project.recommended_amount,
        project_status=project.project_status,
        next_update_due=project.next_update_due
    )
    db.add(history)


def create_project(
    db: Session, data: ProjectCreate, user_id: str | None = None
) -> Project:
    existing = db.query(Project).filter(Project.work_id == data.work_id).first()
    if existing:
        raise HTTPException(status_code=409, detail=f"work_id '{data.work_id}' already exists")

    project_data = data.model_dump(exclude={"update_validity_days"})
    project = Project(**project_data)
    
    project.next_update_due = _calculate_next_update_due(project.project_status, data.update_validity_days)

    project.uploaded_by = user_id
    db.add(project)
    db.commit()
    db.refresh(project)

    log_action(db, action="PROJECT_CREATED", user_id=user_id, project_id=project.project_id, new_value=f"work_id={project.work_id}", status="SUCCESS")

    try:
        run_and_store_prediction(db, project_id=project.project_id, project_data=project_data, user_id=user_id)
    except Exception as exc:
        logger.error("ML inference failed: %s", exc)
        log_action(db, action="PREDICTION_FAILED", user_id=user_id, project_id=project.project_id, new_value=str(exc), status="ERROR")

    return project


def update_project_single(
    db: Session, work_id: str, data: ProjectUpdate, user_id: str | None = None
) -> Project:
    project = db.query(Project).filter(Project.work_id == work_id).first()
    if not project:
        raise HTTPException(status_code=404, detail=f"Project '{work_id}' not found")

    _snapshot_history(db, project)

    update_data = data.model_dump(exclude_unset=True, exclude={"update_validity_days"})
    for key, value in update_data.items():
        setattr(project, key, value)
    
    if data.update_validity_days is not None:
        project.next_update_due = _calculate_next_update_due(project.project_status, data.update_validity_days)
    elif project.project_status == "COMPLETED":
        project.next_update_due = None

    db.commit()
    db.refresh(project)

    log_action(db, action="PROJECT_UPDATED", user_id=user_id, project_id=project.project_id, new_value=f"work_id={work_id}", status="SUCCESS")

    project_dict = {c.name: getattr(project, c.name) for c in project.__table__.columns}
    try:
        run_and_store_prediction(db, project_id=project.project_id, project_data=project_dict, user_id=user_id)
    except Exception as exc:
        logger.error("ML inference failed: %s", exc)

    return project


def get_project_by_work_id(db: Session, work_id: str) -> Project:
    project = db.query(Project).filter(Project.work_id == work_id).first()
    if not project:
        raise HTTPException(status_code=404, detail=f"Project '{work_id}' not found")
    return project


def get_all_projects(db: Session, skip: int = 0, limit: int = 100, current_user: User | None = None) -> list[Project]:
    q = db.query(Project)
    if current_user and current_user.role == "DATA_MANAGER":
        q = q.filter(Project.uploaded_by == current_user.user_id)
    return q.offset(skip).limit(limit).all()


def get_project_history(db: Session, work_id: str) -> list[ProjectHistory]:
    project = get_project_by_work_id(db, work_id)
    return db.query(ProjectHistory).filter(ProjectHistory.project_id == project.project_id).order_by(ProjectHistory.snapshot_date.asc()).all()


def process_csv_upload(
    db: Session, file_bytes: bytes, user_id: str | None = None
) -> CSVUploadResult:
    try:
        df = pd.read_csv(io.BytesIO(file_bytes))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"CSV parse error: {exc}")

    df.columns = [c.strip().lower() for c in df.columns]

    missing = _REQUIRED_CSV_COLS - set(df.columns)
    if missing:
        raise HTTPException(status_code=400, detail=f"Missing columns: {missing}")

    results: list[CSVRowResult] = []
    created = updated = skipped = errors = 0

    for _, row in df.iterrows():
        work_id = str(row.get("work_id", "")).strip()
        if not work_id:
            errors += 1
            results.append(CSVRowResult(work_id="(blank)", status="error", reason="work_id is blank"))
            continue

        validity_days = _safe_int(row, "update_validity_days")
        status_val = _safe_str(row, "project_status") or "SUBMITTED"

        existing = db.query(Project).filter(Project.work_id == work_id).first()
        if existing:
            try:
                _snapshot_history(db, existing)
                
                existing.mp_name = _safe_str(row, "mp_name") or existing.mp_name
                existing.state = _safe_str(row, "state") or existing.state
                existing.constituency = _safe_str(row, "constituency") or existing.constituency
                existing.description = _safe_str(row, "description") or existing.description
                existing.recommended_amount = _safe_float(row, "recommended_amount") or existing.recommended_amount
                existing.has_images = _safe_bool(row, "has_images") if pd.notna(row.get("has_images")) else existing.has_images
                existing.completion_date = _safe_str(row, "completion_date") or existing.completion_date
                existing.completion_delay_days = _safe_int(row, "completion_delay_days") if pd.notna(row.get("completion_delay_days")) else existing.completion_delay_days
                existing.completion_date_inconsistent = _safe_bool(row, "completion_date_inconsistent") if pd.notna(row.get("completion_date_inconsistent")) else existing.completion_date_inconsistent
                existing.completion_delay_missing = _safe_bool(row, "completion_delay_missing") if pd.notna(row.get("completion_delay_missing")) else existing.completion_delay_missing
                existing.project_status = status_val
                existing.uploaded_by = user_id
                
                if validity_days is not None:
                    existing.next_update_due = _calculate_next_update_due(status_val, validity_days)
                elif status_val == "COMPLETED":
                    existing.next_update_due = None

                db.commit()
                db.refresh(existing)
                
                project_dict = {c.name: getattr(existing, c.name) for c in existing.__table__.columns}
                run_and_store_prediction(db, project_id=existing.project_id, project_data=project_dict, user_id=user_id)

                updated += 1
                results.append(CSVRowResult(work_id=work_id, status="updated"))
            except Exception as exc:
                db.rollback()
                errors += 1
                results.append(CSVRowResult(work_id=work_id, status="error", reason=str(exc)))
            continue

        try:
            data = ProjectCreate(
                work_id=work_id,
                mp_name=_safe_str(row, "mp_name"),
                state=_safe_str(row, "state"),
                constituency=_safe_str(row, "constituency"),
                description=_safe_str(row, "description"),
                recommended_amount=_safe_float(row, "recommended_amount"),
                has_images=_safe_bool(row, "has_images"),
                completion_date=_safe_str(row, "completion_date"),
                completion_delay_days=_safe_int(row, "completion_delay_days"),
                completion_date_inconsistent=_safe_bool(row, "completion_date_inconsistent"),
                completion_delay_missing=_safe_bool(row, "completion_delay_missing"),
                project_status=status_val,
                update_validity_days=validity_days
            )
            create_project(db, data, user_id=user_id)
            created += 1
            results.append(CSVRowResult(work_id=work_id, status="created"))
        except HTTPException as exc:
            errors += 1
            results.append(CSVRowResult(work_id=work_id, status="error", reason=exc.detail))
        except Exception as exc:
            errors += 1
            results.append(CSVRowResult(work_id=work_id, status="error", reason=str(exc)))

    log_action(db, action="CSV_UPLOAD", user_id=user_id, new_value=f"created={created}, updated={updated}, errors={errors}", status="SUCCESS")

    return CSVUploadResult(total_rows=len(df), created=created, updated=updated, skipped=skipped, errors=errors, results=results)

def _safe_str(row, col: str) -> str | None:
    val = row.get(col)
    if val is None or (isinstance(val, float) and pd.isna(val)): return None
    return str(val).strip() or None

def _safe_float(row, col: str) -> float | None:
    try:
        val = row.get(col)
        if val is None or (isinstance(val, float) and pd.isna(val)): return None
        return float(val)
    except (ValueError, TypeError): return None

def _safe_int(row, col: str) -> int | None:
    try:
        val = row.get(col)
        if val is None or (isinstance(val, float) and pd.isna(val)): return None
        return int(float(val))
    except (ValueError, TypeError): return None

def _safe_bool(row, col: str) -> bool | None:
    val = row.get(col)
    if val is None or (isinstance(val, float) and pd.isna(val)): return None
    if isinstance(val, bool): return val
    return str(val).strip().lower() in ("1", "true", "yes")
