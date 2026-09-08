"""schemas/prediction.py — ML prediction output schemas"""

from datetime import datetime
from pydantic import BaseModel


class ProcessedFeatures(BaseModel):
    recommended_amount_log: float | None = None
    description_length: int | None = None
    description_word_count: int | None = None
    has_images_flag: int | None = None
    completion_delay_days_clean: float | None = None
    completion_date_inconsistent: int | None = None
    completion_delay_missing: int | None = None


class PredictionOut(BaseModel):
    prediction_id: str
    project_id: str
    work_id: str | None = None          # joined from project for convenience
    model_name: str | None
    model_version: str | None
    raw_anomaly_score: float | None
    risk_score: float | None
    risk_level: str | None
    why_flagged: list[str] | None
    rules_triggered: dict | None
    processed_features: dict | None
    prediction_created_at: datetime

    model_config = {"from_attributes": True}


class PredictionSummary(BaseModel):
    prediction_id: str
    project_id: str
    work_id: str | None = None
    risk_score: float | None
    risk_level: str | None
    prediction_created_at: datetime

    model_config = {"from_attributes": True}
