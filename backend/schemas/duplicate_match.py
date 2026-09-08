"""schemas/duplicate_match.py"""

from datetime import datetime
from pydantic import BaseModel


class DuplicateMatchCreate(BaseModel):
    project_id: str
    matched_project_id: str
    similarity_score: float | None = None
    detection_method: str | None = None
    match_reason: str | None = None
    status: str = "PENDING"


class DuplicateMatchOut(BaseModel):
    duplicate_match_id: str
    project_id: str
    matched_project_id: str
    similarity_score: float | None
    detection_method: str | None
    match_reason: str | None
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}
