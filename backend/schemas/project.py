"""schemas/project.py - Project create/out + CSV upload result + History"""

from datetime import datetime, date
from pydantic import BaseModel
from typing import Optional


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
    update_validity_days: int | None = None


class ProjectUpdate(BaseModel):
    project_status: str | None = None
    completion_delay_days: int | None = None
    recommended_amount: float | None = None
    update_validity_days: int | None = None
    # Add more fields if needed for single-project updates


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
    next_update_due: date | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class ProjectHistoryOut(BaseModel):
    history_id: str
    project_id: str
    snapshot_date: datetime
    completion_delay_days: int | None
    recommended_amount: float | None
    project_status: str
    next_update_due: date | None

    model_config = {"from_attributes": True}


class CSVRowResult(BaseModel):
    work_id: str
    status: str            # "created" | "updated" | "skipped" | "error"
    reason: str | None = None


class CSVUploadResult(BaseModel):
    total_rows: int
    created: int
    updated: int
    skipped: int
    errors: int
    results: list[CSVRowResult]
