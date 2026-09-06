"""models/ml_prediction.py — ml_predictions table"""

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Float, ForeignKey, JSON, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database.connection import Base


def _now() -> datetime:
    return datetime.now(timezone.utc)


class MLPrediction(Base):
    __tablename__ = "ml_predictions"

    prediction_id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    project_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("projects.project_id"), nullable=False
    )
    model_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    model_version: Mapped[str | None] = mapped_column(String(50), nullable=True)
    raw_anomaly_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    risk_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    risk_level: Mapped[str | None] = mapped_column(String(20), nullable=True)
    why_flagged: Mapped[list | None] = mapped_column(JSON, nullable=True)
    rules_triggered: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    processed_features: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    prediction_created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_now
    )

    # Relationships
    project: Mapped["Project"] = relationship(  # noqa: F821
        "Project", back_populates="predictions"
    )
    investigations: Mapped[list["Investigation"]] = relationship(  # noqa: F821
        "Investigation", back_populates="prediction"
    )
