"""
ml_client/inference_client.py

Single public entry point: predict_project(project_data) -> dict

Reads ML_MODE from environment:
  mock  — returns realistic-looking data without the real ML package
  real  — imports ml_engine.inference and calls it (teammate's package)

Switching mock → real requires ONLY changing ML_MODE=real in .env.
"""

import hashlib
import logging
import math

from database.connection import settings

logger = logging.getLogger(__name__)

# ─── Risk level thresholds (frozen — match ML engine spec) ────────────────────
_THRESHOLDS = [
    (90.0, "Critical"),
    (75.0, "High"),
    (50.0, "Medium"),
    (0.0,  "Low"),
]


def _risk_level_from_score(risk_score: float) -> str:
    for threshold, level in _THRESHOLDS:
        if risk_score >= threshold:
            return level
    return "Low"


# ─── Public interface ─────────────────────────────────────────────────────────

def predict_project(project_data: dict) -> dict:
    """
    Call the ML engine and return a standardised result dict.
    project_data should be the raw project fields (NOT the 7 processed features).
    """
    mode = settings.ML_MODE.lower()

    if mode == "real":
        return _real_predict(project_data)
    else:
        logger.debug("ML_MODE=mock — using mock inference for work_id=%s", project_data.get("work_id"))
        return _mock_predict(project_data)


# ─── Mock implementation ──────────────────────────────────────────────────────

def _mock_predict(project_data: dict) -> dict:
    """
    Deterministic mock that returns a consistent result for the same work_id.
    Uses a hash of work_id to derive scores — no random variation between calls.
    Does NOT implement Isolation Forest or any ML logic.
    """
    work_id = str(project_data.get("work_id", "unknown"))

    # Derive a deterministic 0–1 value from work_id hash
    digest = int(hashlib.sha256(work_id.encode()).hexdigest(), 16)
    fraction = (digest % 10_000) / 10_000.0   # 0.0 → 0.9999

    # Map to raw anomaly score (Isolation Forest scores are typically negative)
    raw_anomaly_score = -0.5 + (fraction * 0.6)   # range: -0.5 → +0.1

    # Convert raw anomaly score → risk_score (0–100)
    # Lower (more negative) raw scores = higher risk, mimicking real logic
    risk_score = round(max(0.0, min(100.0, (0.1 - raw_anomaly_score) / 0.6 * 100)), 2)

    risk_level = _risk_level_from_score(risk_score)

    # Build realistic features from project fields
    recommended_amount = project_data.get("recommended_amount") or 0.0
    description = project_data.get("description") or ""
    has_images = project_data.get("has_images")
    completion_delay_days = project_data.get("completion_delay_days")
    completion_date_inconsistent = project_data.get("completion_date_inconsistent")
    completion_delay_missing = project_data.get("completion_delay_missing")

    features = {
        "recommended_amount_log": round(math.log1p(float(recommended_amount)), 4) if recommended_amount else 0.0,
        "description_length": len(description),
        "description_word_count": len(description.split()) if description else 0,
        "has_images_flag": 1 if has_images else 0,
        "completion_delay_days_clean": float(completion_delay_days) if completion_delay_days is not None else 0.0,
        "completion_date_inconsistent": 1 if completion_date_inconsistent else 0,
        "completion_delay_missing": 1 if completion_delay_missing else 0,
    }

    why_flagged = _build_why_flagged(risk_level, features, recommended_amount)

    return {
        "work_id": work_id,
        "model_name": "mplads_anomaly_model_mock",
        "model_version": "v1-mock",
        "raw_anomaly_score": round(raw_anomaly_score, 6),
        "risk_score": risk_score,
        "risk_level": risk_level,
        "why_flagged": why_flagged,
        "rules_triggered": {},
        "features": features,
    }


def _build_why_flagged(risk_level: str, features: dict, recommended_amount: float) -> list[str]:
    reasons = []
    if risk_level == "Critical":
        reasons.append("Critical statistical anomaly detected by ML model")
    elif risk_level == "High":
        reasons.append("High statistical anomaly detected by ML model")
    elif risk_level == "Medium":
        reasons.append("Moderate anomaly detected by ML model")
    else:
        reasons.append("No significant anomaly detected")

    if recommended_amount and recommended_amount > 5_000_000:
        reasons.append("High recommended amount")
    if features.get("completion_delay_missing"):
        reasons.append("Completion information missing/unavailable")
    if features.get("completion_date_inconsistent"):
        reasons.append("Completion date inconsistency detected")
    if features.get("has_images_flag") == 0:
        reasons.append("No project images available")
    if features.get("completion_delay_days_clean", 0) > 180:
        reasons.append("Significant completion delay")

    return reasons


# ─── Real ML integration ──────────────────────────────────────────────────────

def _translate_to_ml_fields(project_data: dict) -> dict:
    """
    The ML engine (ml_engine/inference.py) expects the original CSV column names.
    Our backend stores fields in snake_case.
    This mapper bridges the two without changing either side.

    ML engine field names  ←→  Our backend field names
    ────────────────────────────────────────────────────
    "Recommended Amount (₹)" ← recommended_amount
    "Work Description"        ← description
    "Has Images"              ← has_images
    "Completed Date"          ← completion_date
    "Recommendation Date"     ← (not stored; ML handles NaT gracefully)
    """
    return {
        "Recommended Amount (₹)": project_data.get("recommended_amount"),
        "Work Description":        project_data.get("description", ""),
        "Has Images":              project_data.get("has_images", False),
        "Completed Date":          project_data.get("completion_date"),
        "Recommendation Date":     None,
    }


def _real_predict(project_data: dict) -> dict:
    """
    Calls the teammate's ml_engine package.
    Translates our snake_case fields to ML engine's expected CSV column names.

    Setup required:
      1. ml_engine/ folder must sit alongside backend/ in the project root
      2. pip install -r ml_engine/requirements.txt
      3. ML_MODE=real in .env
      4. Artifact files must be present in ml_engine/artifacts/
    """
    try:
        from ml_engine.inference import predict_project as ml_predict  # type: ignore
        translated = _translate_to_ml_fields(project_data)
        return ml_predict(translated)
    except ImportError as exc:
        logger.error(
            "ML_MODE=real but ml_engine package not found. "
            "Falling back to mock. Error: %s", exc
        )
        logger.warning("Falling back to mock ML for work_id=%s", project_data.get("work_id"))
        return _mock_predict(project_data)
    except Exception as exc:
        logger.error("Real ML inference failed: %s", exc)
        raise RuntimeError(f"ML engine error: {exc}") from exc
