"""
database/schema.py
Creates all tables on startup and optionally seeds demo users.
"""

import logging
from sqlalchemy.orm import Session

from database.connection import engine, Base, SessionLocal
from auth.password import hash_password

logger = logging.getLogger(__name__)


def init_db() -> None:
    """Create all tables (if they don't already exist) and seed demo users."""
    # Import all models so Base knows about them before create_all
    import models.user          # noqa: F401
    import models.project       # noqa: F401
    import models.ml_prediction # noqa: F401
    import models.duplicate_match  # noqa: F401
    import models.investigation # noqa: F401
    import models.evidence      # noqa: F401
    import models.audit_log     # noqa: F401

    Base.metadata.create_all(bind=engine)
    logger.info("Database tables created / verified.")

    db: Session = SessionLocal()
    try:
        _seed_demo_users(db)
    finally:
        db.close()


def _seed_demo_users(db: Session) -> None:
    """Seed one DATA_MANAGER and one AUDITOR user for SIH demo convenience."""
    from models.user import User

    demo_users = [
        {
            "name": "Demo Data Manager",
            "username": "demo_manager",
            "password": "Demo@1234",
            "role": "DATA_MANAGER",
            "department": "Data Management",
            "email": "demo.manager@mplads.gov.in",
        },
        {
            "name": "Demo Auditor",
            "username": "demo_auditor",
            "password": "Demo@1234",
            "role": "AUDITOR",
            "department": "Audit & Compliance",
            "email": "demo.auditor@mplads.gov.in",
        },
    ]

    for u in demo_users:
        existing = db.query(User).filter(User.username == u["username"]).first()
        if not existing:
            user = User(
                name=u["name"],
                username=u["username"],
                password_hash=hash_password(u["password"]),
                role=u["role"],
                department=u["department"],
                email=u["email"],
                is_active=True,
            )
            db.add(user)
            logger.info("Seeded demo user: %s (%s)", u["username"], u["role"])

    db.commit()
