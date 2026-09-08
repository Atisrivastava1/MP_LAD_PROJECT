"""schemas/evidence.py"""

from datetime import datetime
from pydantic import BaseModel


class EvidenceOut(BaseModel):
    evidence_id: str
    investigation_id: str
    uploaded_by: str
    file_name: str
    file_path: str
    file_type: str | None
    description: str | None
    uploaded_at: datetime

    model_config = {"from_attributes": True}
