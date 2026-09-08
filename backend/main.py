"""
main.py â€” MPLADS Sentinel FastAPI application entry point

Run with:
    uvicorn main:app --reload

Swagger UI:
    http://localhost:8000/docs
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from database.schema import init_db
from routes.auth_routes import router as auth_router
from routes.project_routes import router as project_router
from routes.prediction_routes import router as prediction_router
from routes.duplicate_routes import router as duplicate_router
from routes.investigation_routes import router as investigation_router
from routes.evidence_routes import router as evidence_router
from routes.review_routes import router as review_router
from routes.audit_routes import router as audit_router
from routes.dashboard_routes import router as dashboard_router

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Create tables and seed demo users on startup."""
    logger.info("Starting MPLADS Sentinel backend...")
    init_db()
    logger.info("Database ready. Demo users: demo_manager / demo_auditor (password: Demo@1234)")
    yield
    logger.info("Shutting down MPLADS Sentinel backend.")


app = FastAPI(
    title="MPLAD Sanchalan API",
    description=(
        "AI-Based Fraud & Anomaly Detection for MPLADS Projects â€” SIH Prototype.\n\n"
        "**Demo credentials**\n"
        "- Data Manager: `demo_manager` / `Demo@1234`\n"
        "- Auditor: `demo_auditor` / `Demo@1234`\n\n"
        "Use the **Authorize** button with the token returned from `POST /api/v1/auth/login`."
    ),
    version="1.0.0-prototype",
    lifespan=lifespan,
)

# â”€â”€â”€ CORS (open for prototype â€” tighten for production) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# â”€â”€â”€ Global error handlers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.detail, "status_code": exc.status_code},
    )


@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    logger.error("Unhandled exception: %s", exc, exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "status_code": 500},
    )


# â”€â”€â”€ Routes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
PREFIX = "/api/v1"

app.include_router(auth_router,          prefix=PREFIX)
app.include_router(project_router,       prefix=PREFIX)
app.include_router(prediction_router,    prefix=PREFIX)
app.include_router(duplicate_router,     prefix=PREFIX)
app.include_router(investigation_router, prefix=PREFIX)
app.include_router(evidence_router,      prefix=PREFIX)
app.include_router(review_router,        prefix=PREFIX)
app.include_router(audit_router,         prefix=PREFIX)
app.include_router(dashboard_router,     prefix=PREFIX)


@app.get("/", tags=["Health"], summary="Health check")
def root():
    return {"status": "ok", "service": "MPLADS Sentinel API", "version": "1.0.0-prototype"}


@app.get("/health", tags=["Health"], summary="Liveness check")
def health():
    return {"status": "healthy"}
