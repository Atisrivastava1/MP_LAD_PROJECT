"""
MPLADS ML Engine - Anomaly Detection
"""

from pathlib import Path
import joblib


# ============================================================
# PATHS
# ============================================================

BASE_DIR = Path(__file__).resolve().parent

MODEL_PATH = (
    BASE_DIR
    / "artifacts"
    / "mplads_anomaly_model_v1.joblib"
)


# ============================================================
# LOAD PRODUCTION MODEL BUNDLE
# ============================================================

if not MODEL_PATH.exists():
    raise FileNotFoundError(
        f"Model artifact not found: {MODEL_PATH}"
    )


MODEL_BUNDLE = joblib.load(MODEL_PATH)


# ============================================================
# EXTRACT ACTUAL ISOLATION FOREST MODEL
# ============================================================

if not isinstance(MODEL_BUNDLE, dict):
    raise TypeError(
        "Expected model artifact to be a dictionary bundle."
    )


if "model" not in MODEL_BUNDLE:
    raise KeyError(
        "Model bundle does not contain 'model'."
    )


MODEL = MODEL_BUNDLE["model"]


# ============================================================
# MODEL VALIDATION
# ============================================================

if not hasattr(MODEL, "decision_function"):
    raise TypeError(
        "Loaded 'model' does not support decision_function()."
    )


# ============================================================
# ANOMALY SCORE
# ============================================================

def calculate_anomaly_score(X):
    """
    Calculate the production anomaly score.

    Production specification:

        raw_anomaly_score =
            -IsolationForest.decision_function(X)

    Higher score = higher statistical anomaly.
    """

    decision_scores = MODEL.decision_function(X)

    raw_scores = -decision_scores

    return raw_scores