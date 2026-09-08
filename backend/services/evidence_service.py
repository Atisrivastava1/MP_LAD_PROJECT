"""services/evidence_service.py — file upload + metadata persistence"""

import os
import uuid
import aiofiles

from sqlalchemy.orm import Session
from fastapi import HTTPException, UploadFile

from database.connection import settings
from models.evidence import Evidence
from models.investigation import Investigation
from services.audit_service import log_action

# Allowed MIME types for prototype
_ALLOWED_TYPES = {
    "application/pdf",
    "image/jpeg",
    "image/png",
    "image/jpg",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",  # xlsx
    "application/vnd.ms-excel",  # xls
    "text/csv",
    "application/zip",
}
_MAX_FILE_SIZE_MB = 10
_MAX_FILE_SIZE_BYTES = _MAX_FILE_SIZE_MB * 1024 * 1024


async def upload_evidence(
    db: Session,
    investigation_id: str,
    file: UploadFile,
    description: str | None,
    uploader_id: str,
) -> Evidence:
    # Validate investigation exists
    inv = db.query(Investigation).filter(
        Investigation.investigation_id == investigation_id
    ).first()
    if not inv:
        raise HTTPException(status_code=404, detail="Investigation not found")

    # Validate file type
    if file.content_type not in _ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"File type '{file.content_type}' not allowed. Allowed: {_ALLOWED_TYPES}",
        )

    # Read and validate size
    content = await file.read()
    if len(content) > _MAX_FILE_SIZE_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"File exceeds maximum size of {_MAX_FILE_SIZE_MB} MB",
        )

    # Save file to disk
    inv_dir = os.path.join(settings.UPLOAD_DIRECTORY, investigation_id)
    os.makedirs(inv_dir, exist_ok=True)
    unique_name = f"{uuid.uuid4()}_{file.filename}"
    file_path = os.path.join(inv_dir, unique_name)

    async with aiofiles.open(file_path, "wb") as f:
        await f.write(content)

    # Persist metadata
    ev = Evidence(
        investigation_id=investigation_id,
        uploaded_by=uploader_id,
        file_name=file.filename,
        file_path=file_path,
        file_type=file.content_type,
        description=description,
    )
    db.add(ev)
    db.commit()
    db.refresh(ev)

    log_action(
        db,
        action="EVIDENCE_UPLOADED",
        user_id=uploader_id,
        project_id=inv.project_id,
        investigation_id=investigation_id,
        new_value=f"file={file.filename}",
        status="SUCCESS",
    )
    return ev


def get_evidence_for_investigation(db: Session, investigation_id: str) -> list[Evidence]:
    return (
        db.query(Evidence)
        .filter(Evidence.investigation_id == investigation_id)
        .order_by(Evidence.uploaded_at.desc())
        .all()
    )
