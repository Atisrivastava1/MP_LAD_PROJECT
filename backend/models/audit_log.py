"""models/audit_log.py — audit_logs table"""

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database.connection import Base


def _now() -> datetime:
    return datetime.now(timezone.utc)


class AuditLog(Base):
    __tablename__ = "audit_logs"

    log_id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    user_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("users.user_id"), nullable=True
    )
    project_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("projects.project_id"), nullable=True
    )
    investigation_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("investigations.investigation_id"), nullable=True
    )
    action: Mapped[str] = mapped_column(String(100), nullable=False)
    old_value: Mapped[str | None] = mapped_column(Text, nullable=True)
    new_value: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str | None] = mapped_column(String(50), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="audit_logs")  # noqa: F821
    project: Mapped["Project"] = relationship("Project", back_populates="audit_logs")  # noqa: F821
    investigation: Mapped["Investigation"] = relationship(  # noqa: F821
        "Investigation", back_populates="audit_logs"
    )
