"""routes/evidence_routes.py"""

from fastapi import APIRouter, Depends, File, Form, UploadFile
from sqlalchemy.orm import Session

from database.connection import get_db
from auth.rbac import auditor_only
from models.user import User
from schemas.evidence import EvidenceOut
from services.evidence_service import upload_evidence, get_evidence_for_investigation

router = APIRouter(prefix="/investigations", tags=["Evidence"])


@router.post(
    "/{investigation_id}/evidence",
    response_model=EvidenceOut,
    status_code=201,
    summary="Upload evidence file for an investigation",
)
async def upload_evidence_file(
    investigation_id: str,
    file: UploadFile = File(...),
    description: str | None = Form(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(auditor_only),
):
    return await upload_evidence(
        db,
        investigation_id=investigation_id,
        file=file,
        description=description,
        uploader_id=current_user.user_id,
    )


@router.get(
    "/{investigation_id}/evidence",
    response_model=list[EvidenceOut],
    summary="List all evidence for an investigation",
)
def list_evidence(
    investigation_id: str,
    db: Session = Depends(get_db),
    _: User = Depends(auditor_only),
):
    return get_evidence_for_investigation(db, investigation_id)
