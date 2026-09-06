# MPLADS Sentinel — Backend

## Overview

MPLADS Sentinel is an **SIH prototype** for detecting statistically unusual MPLADS projects and helping auditors prioritize investigations using an AI/ML engine.

> The system detects **statistical anomalies** — it does NOT declare fraud.
> ML output is used for **audit prioritization**, not evidence of wrongdoing.

---

## Tech Stack

| Layer | Technology |
|---|---|
| API Framework | FastAPI |
| Database (target) | PostgreSQL |
| Database (tests) | SQLite in-memory |
| ORM | SQLAlchemy 2.0 |
| Validation | Pydantic v2 |
| Authentication | JWT (python-jose + passlib/bcrypt) |
| ML Integration | Custom adapter (`ml_client/inference_client.py`) |
| CSV Processing | pandas |
| Testing | pytest + httpx TestClient |

---

## Prototype Roles

Only **2 roles** are implemented:

| Role | What they can do |
|---|---|
| `DATA_MANAGER` | Login, create/upload projects, view project list |
| `AUDITOR` | Login, view projects + predictions, start investigations, upload evidence, submit decisions, view audit logs |

---

## Quick Start

### 1. Install dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Configure environment

```bash
cp .env.example .env
# Edit .env to set your PostgreSQL DATABASE_URL
```

Default `.env` values:
- `DATABASE_URL=postgresql://postgres:postgres@localhost:5432/mplads_db`
- `ML_MODE=mock` ← runs without the real ML package

### 3. Run the server

```bash
uvicorn main:app --reload
```

### 4. Open Swagger UI

```
http://localhost:8000/docs
```

**Demo credentials (auto-seeded on startup):**
- Data Manager: `demo_manager` / `Demo@1234`
- Auditor: `demo_auditor` / `Demo@1234`

---

## Running Tests

Tests use SQLite in-memory — no PostgreSQL needed:

```bash
cd backend
pytest tests/ -v
```

---

## API Summary

All routes are prefixed with `/api/v1`.

| Method | Path | Role | Description |
|---|---|---|---|
| POST | `/auth/login` | Any | Login, get JWT |
| GET | `/auth/me` | Any | Current user info |
| POST | `/projects` | DATA_MANAGER | Create a single project |
| POST | `/projects/upload` | DATA_MANAGER | Bulk upload via CSV |
| GET | `/projects` | Both | List all projects |
| GET | `/projects/{work_id}` | Both | Get project by work_id |
| GET | `/projects/{work_id}/prediction` | Both | Get ML prediction |
| GET | `/predictions` | Both | All predictions |
| GET | `/predictions/high-risk` | Both | High + Critical only |
| GET | `/projects/{work_id}/duplicates` | Both | Duplicate matches |
| GET | `/duplicate-matches` | Both | All duplicate matches |
| POST | `/duplicate-matches` | AUDITOR | Create duplicate match |
| POST | `/investigations` | AUDITOR | Start investigation |
| GET | `/investigations/{id}` | AUDITOR | Get investigation |
| PUT | `/investigations/{id}` | AUDITOR | Update findings/status |
| POST | `/investigations/{id}/evidence` | AUDITOR | Upload evidence file |
| GET | `/investigations/{id}/evidence` | AUDITOR | List evidence |
| POST | `/investigations/{id}/review` | AUDITOR | Submit for review |
| PUT | `/investigations/{id}/decision` | AUDITOR | Submit final decision |
| GET | `/audit-logs` | AUDITOR | View audit history |
| GET | `/dashboard/summary` | Both | Project + investigation counts |
| GET | `/dashboard/risk-distribution` | Both | Count by risk level |
| GET | `/dashboard/high-risk` | Both | High/Critical projects |

---

## Risk Levels

| Risk Score | Level |
|---|---|
| 0 – <50 | Low |
| 50 – <75 | Medium |
| 75 – <90 | High |
| 90 – 100 | Critical |

---

## ML Integration

### Current: Mock Mode (`ML_MODE=mock`)
The mock returns deterministic results based on `work_id` hash.
No randomness — same project always produces the same score.

### When real ML arrives: (`ML_MODE=real`)
Set `ML_MODE=real` in `.env`.
The system will call `ml_engine.inference.predict_project(project_data)`.

**Only one env var change required. No code changes needed.**

---

## CSV Upload Format

Required column: `work_id`

Optional columns:
```
mp_name, state, constituency, description, recommended_amount,
has_images, completion_date, completion_delay_days,
completion_date_inconsistent, completion_delay_missing, project_status
```

**The CSV must NOT contain the 7 ML features — these are computed by the ML engine.**

---

## Directory Structure

```
backend/
├── main.py                    ← FastAPI app, startup, routers
├── requirements.txt
├── .env / .env.example
├── auth/                      ← JWT, bcrypt, RBAC
├── database/                  ← Connection, table init, demo seed
├── models/                    ← 7 SQLAlchemy ORM models
├── schemas/                   ← 7 Pydantic request/response schemas
├── services/                  ← Business logic (8 services)
├── routes/                    ← 9 API route files
├── ml_client/                 ← ML adapter (mock + real interface)
├── uploads/                   ← Evidence files (not stored in DB)
└── tests/                     ← pytest suite (7 test files)
```

---

## Flutter Integration

Flutter communicates **only** through the REST API.
Flutter must NOT access PostgreSQL or the ML engine directly.

Base URL for Flutter: `http://<server>:8000/api/v1`

The dashboard endpoints pre-aggregate all data Flutter needs:
- `/dashboard/summary`
- `/dashboard/risk-distribution`
- `/dashboard/high-risk`

---

## Connecting Teammate Components

### ML Engine (teammate)
1. Drop `ml_engine/` folder into the project root (alongside `backend/`)
2. Set `ML_MODE=real` in `.env`
3. The backend calls `ml_engine.inference.predict_project()`

### Duplicate Detector (teammate)
The duplicate detector should call:
```
POST /api/v1/duplicate-matches
```
with the match results. Authentication required (AUDITOR token).

---

## Security Notes

- Passwords hashed with bcrypt (never stored in plaintext)
- JWT tokens expire after 60 minutes (configurable)
- RBAC enforced on every protected route
- No stack traces exposed to API clients
- Evidence files saved to disk, only metadata in DB
- CORS is open for prototype — tighten before production