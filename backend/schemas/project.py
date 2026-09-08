"""schemas/project.py — Project create/out + CSV upload result"""

from datetime import datetime
from pydantic import BaseModel


class ProjectCreate(BaseModel):
    work_id: str
    mp_name: str | None = None
    state: str | None = None
    constituency: str | None = None
    description: str | None = None
    recommended_amount: float | None = None
    has_images: bool | None = None
    completion_date: str | None = None
    completion_delay_days: int | None = None
    completion_date_inconsistent: bool | None = None
    completion_delay_missing: bool | None = None
    project_status: str = "SUBMITTED"


class ProjectOut(BaseModel):
    project_id: str
    work_id: str
    mp_name: str | None
    state: str | None
    constituency: str | None
    description: str | None
    recommended_amount: float | None
    has_images: bool | None
    completion_date: str | None
    completion_delay_days: int | None
    completion_date_inconsistent: bool | None
    completion_delay_missing: bool | None
    project_status: str
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class CSVRowResult(BaseModel):
    work_id: str
    status: str            # "created" | "skipped" | "error"
    reason: str | None = None


class CSVUploadResult(BaseModel):
    total_rows: int
    created: int
    skipped: int
    errors: int
    results: list[CSVRowResult]
