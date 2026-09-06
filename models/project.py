"""models/project.py — projects table"""

import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Float, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database.connection import Base


def _now() -> datetime:
    return datetime.now(timezone.utc)


class Project(Base):
    __tablename__ = "projects"

    project_id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    work_id: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    mp_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    state: Mapped[str | None] = mapped_column(String(100), nullable=True)
    constituency: Mapped[str | None] = mapped_column(String(255), nullable=True)
    description: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    recommended_amount: Mapped[float | None] = mapped_column(Float, nullable=True)
    has_images: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    completion_date: Mapped[str | None] = mapped_column(String(50), nullable=True)
    completion_delay_days: Mapped[int | None] = mapped_column(Integer, nullable=True)
    completion_date_inconsistent: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    completion_delay_missing: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    project_status: Mapped[str] = mapped_column(String(50), default="SUBMITTED")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_now, onupdate=_now
    )

    # Relationships
    predictions: Mapped[list["MLPrediction"]] = relationship(  # noqa: F821
        "MLPrediction", back_populates="project", cascade="all, delete-orphan"
    )
    duplicate_matches: Mapped[list["DuplicateMatch"]] = relationship(  # noqa: F821
        "DuplicateMatch",
        foreign_keys="DuplicateMatch.project_id",
        back_populates="project",
        cascade="all, delete-orphan",
    )
    investigations: Mapped[list["Investigation"]] = relationship(  # noqa: F821
        "Investigation", back_populates="project", cascade="all, delete-orphan"
    )
    audit_logs: Mapped[list["AuditLog"]] = relationship(  # noqa: F821
        "AuditLog", back_populates="project"
    )
