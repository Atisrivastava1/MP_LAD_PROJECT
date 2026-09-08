"""services/duplicate_service.py — duplicate-match CRUD + mock adapter"""

from sqlalchemy.orm import Session
from fastapi import HTTPException

from models.duplicate_match import DuplicateMatch
from models.project import Project
from schemas.duplicate_match import DuplicateMatchCreate
from services.audit_service import log_action


def create_duplicate_match(
    db: Session, data: DuplicateMatchCreate, user_id: str | None = None
) -> DuplicateMatch:
    # Validate both project references exist
    for pid in (data.project_id, data.matched_project_id):
        if not db.query(Project).filter(Project.project_id == pid).first():
            raise HTTPException(status_code=404, detail=f"Project '{pid}' not found")

    match = DuplicateMatch(**data.model_dump())
    db.add(match)
    db.commit()
    db.refresh(match)

    log_action(
        db,
        action="DUPLICATE_MATCH_CREATED",
        user_id=user_id,
        project_id=data.project_id,
        new_value=f"matched_project_id={data.matched_project_id}, score={data.similarity_score}",
        status="SUCCESS",
    )
    return match


def get_matches_for_project(db: Session, project_id: str) -> list[DuplicateMatch]:
    return (
        db.query(DuplicateMatch)
        .filter(DuplicateMatch.project_id == project_id)
        .all()
    )


def get_all_matches(db: Session) -> list[DuplicateMatch]:
    return db.query(DuplicateMatch).order_by(DuplicateMatch.created_at.desc()).all()
