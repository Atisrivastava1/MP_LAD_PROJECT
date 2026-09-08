"""models/duplicate_match.py — duplicate_matches table"""

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database.connection import Base


def _now() -> datetime:
    return datetime.now(timezone.utc)


class DuplicateMatch(Base):
    __tablename__ = "duplicate_matches"

    duplicate_match_id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    project_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("projects.project_id"), nullable=False
    )
    matched_project_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("projects.project_id"), nullable=False
    )
    similarity_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    detection_method: Mapped[str | None] = mapped_column(String(100), nullable=True)
    match_reason: Mapped[str | None] = mapped_column(String(500), nullable=True)
    status: Mapped[str] = mapped_column(String(50), default="PENDING")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)

    # Relationships — two separate FKs to projects
    project: Mapped["Project"] = relationship(  # noqa: F821
        "Project",
        foreign_keys=[project_id],
        back_populates="duplicate_matches",
    )
    matched_project: Mapped["Project"] = relationship(  # noqa: F821
        "Project",
        foreign_keys=[matched_project_id],
    )
