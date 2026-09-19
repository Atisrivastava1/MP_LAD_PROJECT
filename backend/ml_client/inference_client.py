"""
ml_client/inference_client.py

Single public entry point: predict_project(project_data) -> dict

Reads ML_MODE from environment:
  mock  — returns realistic-looking data without the real ML package
  real  — imports ml_engine.inference and calls it (teammate's package)

Switching mock → real requires ONLY changing ML_MODE=real in .env.
"""

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
    Data-aware mock that derives risk scores from actual project features.
    Mimics what a real Isolation Forest would flag: high amounts, long delays,
    missing images, short descriptions, date inconsistencies, etc.
    """
    work_id = str(project_data.get("work_id", "unknown"))

    # ── Extract real features ──────────────────────────────────────────
    recommended_amount = float(project_data.get("recommended_amount") or 0.0)
    description = str(project_data.get("description") or "")
    has_images = project_data.get("has_images")
    completion_delay_days = project_data.get("completion_delay_days")
    completion_date_inconsistent = project_data.get("completion_date_inconsistent")
    completion_delay_missing = project_data.get("completion_delay_missing")

    delay = float(completion_delay_days) if completion_delay_days is not None else 0.0

    # ── Rule-based scoring (weighted sum -> 0-100 scale) ────────────────
    score = 0.0

    # 1. Amount anomaly (max +30 pts)
    if recommended_amount > 50_000_000:
        score += 30
    elif recommended_amount >= 20_000_000:
        score += 22
    elif recommended_amount >= 10_000_000:
        score += 15
    elif recommended_amount >= 5_000_000:
        score += 8

    # 2. Completion delay (max +35 pts)
    if delay > 365:
        score += 35
    elif delay > 180:
        score += 28
    elif delay > 90:
        score += 16
    elif delay > 30:
        score += 8

    # 3. No images (flat +15 pts)
    if not has_images:
        score += 15

    # 4. Short / vague description (max +10 pts)
    word_count = len(description.split()) if description else 0
    if word_count <= 2:
        score += 10
    elif word_count <= 5:
        score += 5

    # 5. Date inconsistency (flat +10 pts)
    if completion_date_inconsistent:
        score += 10

    # 6. Delay data missing (flat +8 pts)
    if completion_delay_missing:
        score += 8

    risk_score = round(min(100.0, max(0.0, score)), 2)

    # ── Derive anomaly score (mock Isolation Forest output) ────────────
    raw_anomaly_score = round(0.1 - (risk_score / 100.0) * 0.6, 6)

    risk_level = _risk_level_from_score(risk_score)

    features = {
        "recommended_amount_log": round(math.log1p(recommended_amount), 4) if recommended_amount else 0.0,
        "description_length": len(description),
        "description_word_count": word_count,
        "has_images_flag": 1 if has_images else 0,
        "completion_delay_days_clean": delay,
        "completion_date_inconsistent": 1 if completion_date_inconsistent else 0,
        "completion_delay_missing": 1 if completion_delay_missing else 0,
    }

    why_flagged = _build_why_flagged(risk_level, features, recommended_amount)

    return {
        "work_id": work_id,
        "model_name": "mplads_anomaly_model_mock",
        "model_version": "v1-mock",
        "raw_anomaly_score": raw_anomaly_score,
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
    "Work ID"                 ← work_id
    "Recommended Amount (₹)" ← recommended_amount
    "Work Description"        ← description
    "Has Images"              ← has_images
    "Completed Date"          ← completion_date
    "Recommendation Date"     ← (not stored; ML handles NaT gracefully)
    """
    return {
        "Work ID":                 project_data.get("work_id"),
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
