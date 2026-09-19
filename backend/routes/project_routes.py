"""routes/project_routes.py"""

from fastapi import APIRouter, Depends, File, Query, UploadFile, Form
from sqlalchemy.orm import Session

from database.connection import get_db
from auth.rbac import any_authenticated, data_manager_only
from models.user import User
from schemas.project import ProjectCreate, ProjectUpdate, ProjectOut, ProjectHistoryOut, CSVUploadResult
from services.project_service import (
    create_project,
    update_project_single,
    get_project_by_work_id,
    get_all_projects,
    get_project_history,
    process_csv_upload,
    trigger_batch_ml,
)

router = APIRouter(prefix="/projects", tags=["Projects"])


@router.get("/history", summary="Get upload history across batches")
def upload_history(
    db: Session = Depends(get_db),
    _: User = Depends(any_authenticated),
) -> list[dict]:
    # Group by created_at date or just return recent distinct project batches
    # For now, let's return some recent projects as upload history
    from models.project import Project
    recent = db.query(Project).order_by(Project.created_at.desc()).limit(10).all()
    return [
        {
            "workId": p.work_id,
            "mpName": p.mp_name or "Unknown",
            "fileName": f"batch_{p.created_at.strftime('%Y%m%d')}.csv",
            "projectStatus": p.project_status,
            "validationStatus": "Passed" if p.project_status != "REJECTED" else "Failed",
            "detectionStatus": "Completed",
            "date": p.created_at.strftime("%Y-%m-%d %H:%M")
        } for p in recent
    ]


@router.post("", response_model=ProjectOut, status_code=201, summary="Create a single project")
def add_project(
    data: ProjectCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(data_manager_only),
):
    return create_project(db, data, user_id=current_user.user_id)


@router.put("/{work_id}", response_model=ProjectOut, summary="Update a single project")
def update_project(
    work_id: str,
    data: ProjectUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(data_manager_only),
):
    return update_project_single(db, work_id, data, user_id=current_user.user_id)


@router.post(
    "/upload",
    response_model=CSVUploadResult,
    summary="Upload/Update projects via CSV (Data Manager only)",
)
async def upload_csv(
    file: UploadFile = File(..., description="CSV file containing project data"),
    validity_days: int | None = Form(None, description="Update validity days"),
    db: Session = Depends(get_db),
    current_user: User = Depends(data_manager_only),
):
    content = await file.read()
    return process_csv_upload(db, content, user_id=current_user.user_id, validity_days=validity_days)


@router.get("", response_model=list[ProjectOut], summary="List all projects")
def list_projects(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    _: User = Depends(any_authenticated),
):
    return get_all_projects(db, skip=skip, limit=limit, current_user=_)


@router.get("/{work_id}", response_model=ProjectOut, summary="Get project by work_id")
def get_project(
    work_id: str,
    db: Session = Depends(get_db),
    _: User = Depends(any_authenticated),
):
    return get_project_by_work_id(db, work_id)


@router.get("/{work_id}/history", response_model=list[ProjectHistoryOut], summary="Get project history timeline")
def get_history(
    work_id: str,
    db: Session = Depends(get_db),
    _: User = Depends(any_authenticated),
):
    return get_project_history(db, work_id)


from pydantic import BaseModel

class TriggerMLRequest(BaseModel):
    work_ids: list[str]

@router.post("/trigger-ml", summary="Trigger ML batch for uploaded projects")
def trigger_ml(
    data: TriggerMLRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(data_manager_only),
):
    processed = trigger_batch_ml(db, data.work_ids, user_id=current_user.user_id)
    return {"status": "success", "processed": processed}


