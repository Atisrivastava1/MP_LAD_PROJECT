"""routes/duplicate_routes.py"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database.connection import get_db
from auth.rbac import any_authenticated, auditor_only
from models.user import User
from schemas.duplicate_match import DuplicateMatchCreate, DuplicateMatchOut
from services.duplicate_service import (
    create_duplicate_match,
    get_matches_for_project,
    get_all_matches,
)

router = APIRouter(tags=["Duplicate Matches"])


@router.get(
    "/projects/{work_id}/duplicates",
    response_model=list[DuplicateMatchOut],
    summary="Get duplicate matches for a project",
)
def get_project_duplicates(
    work_id: str,
    db: Session = Depends(get_db),
    _: User = Depends(any_authenticated),
):
    from models.project import Project
    from fastapi import HTTPException
    project = db.query(Project).filter(Project.work_id == work_id).first()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    return get_matches_for_project(db, project.project_id)


@router.get(
    "/duplicate-matches",
    response_model=list[DuplicateMatchOut],
    summary="List all duplicate matches",
)
def list_duplicates(
    db: Session = Depends(get_db),
    _: User = Depends(any_authenticated),
):
    return get_all_matches(db)


@router.post(
    "/duplicate-matches",
    response_model=DuplicateMatchOut,
    status_code=201,
    summary="Create a duplicate match (for duplicate-detector integration)",
)
def create_match(
    data: DuplicateMatchCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(auditor_only),
):
    return create_duplicate_match(db, data, user_id=current_user.user_id)
