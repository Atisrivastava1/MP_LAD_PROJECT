"""
tests/conftest.py
Shared fixtures — uses SQLite (file-based, not :memory:) so all sessions share state.
"""

import os
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Override env BEFORE importing anything from the app
os.environ["ML_MODE"] = "mock"
os.environ["DATABASE_URL"] = "sqlite:///./test_mplads.db"
os.environ["JWT_SECRET"] = "test-secret-key"
os.environ["JWT_ALGORITHM"] = "HS256"
os.environ["JWT_EXPIRATION_MINUTES"] = "60"
os.environ["UPLOAD_DIRECTORY"] = "test_uploads"

from database.connection import Base, get_db  # noqa: E402
from main import app  # noqa: E402

_TEST_DB_URL = "sqlite:///./test_mplads.db"
_engine = create_engine(_TEST_DB_URL, connect_args={"check_same_thread": False})
_TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=_engine)


def _override_get_db():
    db = _TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = _override_get_db


@pytest.fixture(scope="session", autouse=True)
def setup_db():
    """Create all tables and seed test users once for the whole test session."""
    import models.user
    import models.project
    import models.ml_prediction
    import models.duplicate_match
    import models.investigation
    import models.evidence
    import models.audit_log

    Base.metadata.create_all(bind=_engine)

    # Seed test users once — they persist for the session
    _seed_test_users()

    yield

    Base.metadata.drop_all(bind=_engine)
    if os.path.exists("test_mplads.db"):
        try:
            os.remove("test_mplads.db")
        except PermissionError:
            pass  # Windows may lock the file; harmless


def _seed_test_users():
    """Insert test DATA_MANAGER and AUDITOR into the test DB."""
    from models.user import User
    from auth.password import hash_password
    import uuid

    db = _TestingSessionLocal()
    try:
        for username, role, email in [
            ("test_manager", "DATA_MANAGER", "mgr@test.com"),
            ("test_auditor", "AUDITOR", "aud@test.com"),
        ]:
            existing = db.query(User).filter(User.username == username).first()
            if not existing:
                u = User(
                    user_id=str(uuid.uuid4()),
                    name=f"Test {role}",
                    username=username,
                    password_hash=hash_password("pass123"),
                    role=role,
                    department="Test",
                    email=email,
                    is_active=True,
                )
                db.add(u)
        db.commit()
    finally:
        db.close()


# ─── Client fixture ───────────────────────────────────────────────────────────

@pytest.fixture
def client() -> TestClient:
    return TestClient(app)


@pytest.fixture
def db():
    session = _TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()


# ─── Token fixtures ───────────────────────────────────────────────────────────

def get_token(client: TestClient, username: str, password: str) -> str:
    resp = client.post("/api/v1/auth/login", json={"username": username, "password": password})
    assert resp.status_code == 200, f"Login failed for {username}: {resp.json()}"
    return resp.json()["access_token"]


@pytest.fixture
def manager_token(client):
    return get_token(client, "test_manager", "pass123")


@pytest.fixture
def auditor_token(client):
    return get_token(client, "test_auditor", "pass123")
