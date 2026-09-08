"""schemas/investigation.py"""

from datetime import datetime
from pydantic import BaseModel


class InvestigationCreate(BaseModel):
    project_id: str
    prediction_id: str | None = None
    assigned_to: str
    findings: str | None = None
    remarks: str | None = None


class InvestigationUpdate(BaseModel):
    findings: str | None = None
    remarks: str | None = None
    status: str | None = None


class InvestigationOut(BaseModel):
    investigation_id: str
    project_id: str
    prediction_id: str | None
    assigned_to: str
    findings: str | None
    remarks: str | None
    status: str
    started_at: datetime
    submitted_at: datetime | None
    updated_at: datetime

    model_config = {"from_attributes": True}
