"""services/project_service.py — create projects (single + CSV) and queries"""

import io
import logging
from sqlalchemy.orm import Session
from fastapi import HTTPException

import pandas as pd

from models.project import Project
from schemas.project import ProjectCreate, CSVRowResult, CSVUploadResult
from services.prediction_service import run_and_store_prediction
from services.audit_service import log_action

logger = logging.getLogger(__name__)

# Required CSV columns
_REQUIRED_CSV_COLS = {"work_id"}

# Valid project_status values
_VALID_STATUSES = {"SUBMITTED", "UNDER_REVIEW", "COMPLETED", "REJECTED"}


def create_project(
    db: Session, data: ProjectCreate, user_id: str | None = None
) -> Project:
    """Validate → store project → run ML → store prediction (transaction safe)."""
    # Check for duplicate work_id
    existing = db.query(Project).filter(Project.work_id == data.work_id).first()
    if existing:
        raise HTTPException(status_code=409, detail=f"work_id '{data.work_id}' already exists")

    project = Project(**data.model_dump())
    db.add(project)
    db.commit()
    db.refresh(project)

    log_action(
        db,
        action="PROJECT_CREATED",
        user_id=user_id,
        project_id=project.project_id,
        new_value=f"work_id={project.work_id}",
        status="SUCCESS",
    )

    # Run ML inference — if it fails we still keep the project, just log the error
    try:
        run_and_store_prediction(
            db,
            project_id=project.project_id,
            project_data=data.model_dump(),
            user_id=user_id,
        )
    except Exception as exc:
        logger.error("ML inference failed for work_id=%s: %s", data.work_id, exc)
        log_action(
            db,
            action="PREDICTION_FAILED",
            user_id=user_id,
            project_id=project.project_id,
            new_value=str(exc),
            status="ERROR",
        )

    return project


def get_project_by_work_id(db: Session, work_id: str) -> Project:
    project = db.query(Project).filter(Project.work_id == work_id).first()
    if not project:
        raise HTTPException(status_code=404, detail=f"Project '{work_id}' not found")
    return project


def get_all_projects(db: Session, skip: int = 0, limit: int = 100) -> list[Project]:
    return db.query(Project).offset(skip).limit(limit).all()


def process_csv_upload(
    db: Session, file_bytes: bytes, user_id: str | None = None
) -> CSVUploadResult:
    """Parse CSV, create projects row-by-row, run ML for each, return summary."""
    try:
        df = pd.read_csv(io.BytesIO(file_bytes))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"CSV parse error: {exc}")

    # Normalise column names
    df.columns = [c.strip().lower() for c in df.columns]

    missing = _REQUIRED_CSV_COLS - set(df.columns)
    if missing:
        raise HTTPException(
            status_code=400,
            detail=f"CSV missing required columns: {missing}",
        )

    results: list[CSVRowResult] = []
    created = skipped = errors = 0

    for _, row in df.iterrows():
        work_id = str(row.get("work_id", "")).strip()
        if not work_id:
            errors += 1
            results.append(CSVRowResult(work_id="(blank)", status="error", reason="work_id is blank"))
            continue

        existing = db.query(Project).filter(Project.work_id == work_id).first()
        if existing:
            skipped += 1
            results.append(CSVRowResult(work_id=work_id, status="skipped", reason="duplicate work_id"))
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
                project_status=_safe_str(row, "project_status") or "SUBMITTED",
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

    log_action(
        db,
        action="CSV_UPLOAD",
        user_id=user_id,
        new_value=f"created={created}, skipped={skipped}, errors={errors}",
        status="SUCCESS",
    )

    return CSVUploadResult(
        total_rows=len(df),
        created=created,
        skipped=skipped,
        errors=errors,
        results=results,
    )


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _safe_str(row, col: str) -> str | None:
    val = row.get(col)
    if val is None or (isinstance(val, float) and pd.isna(val)):
        return None
    return str(val).strip() or None


def _safe_float(row, col: str) -> float | None:
    try:
        val = row.get(col)
        if val is None or (isinstance(val, float) and pd.isna(val)):
            return None
        return float(val)
    except (ValueError, TypeError):
        return None


def _safe_int(row, col: str) -> int | None:
    try:
        val = row.get(col)
        if val is None or (isinstance(val, float) and pd.isna(val)):
            return None
        return int(float(val))
    except (ValueError, TypeError):
        return None


def _safe_bool(row, col: str) -> bool | None:
    val = row.get(col)
    if val is None or (isinstance(val, float) and pd.isna(val)):
        return None
    if isinstance(val, bool):
        return val
    return str(val).strip().lower() in ("1", "true", "yes")
