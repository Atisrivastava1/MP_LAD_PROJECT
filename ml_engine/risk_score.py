"""
MPLADS ML Engine - Risk Score
"""

from pathlib import Path
import numpy as np


BASE_DIR = Path(__file__).resolve().parent

REFERENCE_PATH = (
    BASE_DIR
    / "artifacts"
    / "mplads_reference_anomaly_scores_v1.npy"
)


if not REFERENCE_PATH.exists():
    raise FileNotFoundError(
        f"Reference score artifact not found: {REFERENCE_PATH}"
    )


# ============================================================
# LOAD REFERENCE DISTRIBUTION
# ============================================================

REFERENCE_SCORES = np.load(
    REFERENCE_PATH
)

REFERENCE_SCORES_SORTED = np.sort(
    REFERENCE_SCORES
)


# ============================================================
# RISK SCORE
# ============================================================

def calculate_risk_score(raw_anomaly_score):
    """
    Convert raw anomaly score into percentile
    risk score from 0 to 100.
    """

    percentile = (
        np.searchsorted(
            REFERENCE_SCORES_SORTED,
            raw_anomaly_score,
            side="right"
        )
        / len(REFERENCE_SCORES_SORTED)
    ) * 100

    return float(
        np.clip(percentile, 0, 100)
    )


# ============================================================
# RISK LEVEL
# ============================================================

def determine_risk_level(risk_score):

    if risk_score <= 50:
        return "Low"

    elif risk_score <= 75:
        return "Medium"

    elif risk_score <= 90:
        return "High"

    else:
        return "Critical"