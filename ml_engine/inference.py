"""
MPLADS AI Anomaly Detection
Production Inference Module
"""

from pathlib import Path
import json

import joblib
import numpy as np
import pandas as pd


# ============================================================
# 1. PATHS
# ============================================================

BASE_DIR = Path(__file__).resolve().parent
ARTIFACT_DIR = BASE_DIR / "artifacts"

MODEL_PATH = ARTIFACT_DIR / "mplads_anomaly_model_v1.joblib"
METADATA_PATH = ARTIFACT_DIR / "mplads_model_metadata_v1.json"
REFERENCE_SCORES_PATH = (
    ARTIFACT_DIR / "mplads_reference_anomaly_scores_v1.npy"
)


# ============================================================
# 2. VERIFY ARTIFACTS
# ============================================================

if not MODEL_PATH.exists():
    raise FileNotFoundError(
        f"Model artifact not found: {MODEL_PATH}"
    )

if not METADATA_PATH.exists():
    raise FileNotFoundError(
        f"Metadata file not found: {METADATA_PATH}"
    )

if not REFERENCE_SCORES_PATH.exists():
    raise FileNotFoundError(
        f"Reference score file not found: {REFERENCE_SCORES_PATH}"
    )


# ============================================================
# 3. LOAD ARTIFACTS
# ============================================================

MODEL_BUNDLE = joblib.load(MODEL_PATH)

with open(METADATA_PATH, "r", encoding="utf-8") as f:
    METADATA = json.load(f)

REFERENCE_ANOMALY_SCORES = np.load(
    REFERENCE_SCORES_PATH
)

REFERENCE_ANOMALY_SCORES = np.sort(
    REFERENCE_ANOMALY_SCORES.astype(float)
)


# ============================================================
# 4. EXTRACT MODEL COMPONENTS
# ============================================================

MODEL = MODEL_BUNDLE["model"]

FEATURES = MODEL_BUNDLE["features"]

IMPUTATION_VALUES = MODEL_BUNDLE["imputation_values"]

MODEL_CONFIG = MODEL_BUNDLE["model_config"]

RISK_THRESHOLDS = MODEL_BUNDLE["risk_thresholds"]


# ============================================================
# 5. BUILD PRODUCTION FEATURES
# ============================================================

def build_production_features(project_data):

    recommended_amount = pd.to_numeric(
        project_data.get(
            "Recommended Amount (₹)",
            np.nan
        ),
        errors="coerce"
    )

    if pd.notna(recommended_amount):
        recommended_amount_log = np.log1p(
            max(recommended_amount, 0)
        )
    else:
        recommended_amount_log = np.nan


    description = project_data.get(
        "Work Description",
        ""
    )

    if pd.isna(description):
        description = ""

    description = str(description)

    description_length = len(description)

    description_word_count = len(
        description.split()
    )


    has_images = project_data.get(
        "Has Images",
        np.nan
    )

    has_images_flag = int(
        str(has_images).strip().lower()
        in ["true", "1", "yes"]
    )


    recommendation_date = pd.to_datetime(
        project_data.get(
            "Recommendation Date",
            pd.NaT
        ),
        errors="coerce"
    )

    completed_date = pd.to_datetime(
        project_data.get(
            "Completed Date",
            pd.NaT
        ),
        errors="coerce"
    )


    if (
        pd.notna(recommendation_date)
        and pd.notna(completed_date)
    ):

        completion_delay_days = (
            completed_date - recommendation_date
        ).days

    else:
        completion_delay_days = np.nan


    completion_date_inconsistent = int(
        pd.notna(completion_delay_days)
        and completion_delay_days < 0
    )


    if (
        pd.notna(completion_delay_days)
        and completion_delay_days >= 0
    ):

        completion_delay_days_clean = (
            completion_delay_days
        )

    else:
        completion_delay_days_clean = np.nan


    completion_delay_missing = int(
        pd.isna(completion_delay_days_clean)
    )


    features = pd.DataFrame([
        {
            "recommended_amount_log":
                recommended_amount_log,

            "description_length":
                description_length,

            "description_word_count":
                description_word_count,

            "has_images_flag":
                has_images_flag,

            "completion_delay_days_clean":
                completion_delay_days_clean,

            "completion_date_inconsistent":
                completion_date_inconsistent,

            "completion_delay_missing":
                completion_delay_missing,
        }
    ])


    # EXACT frozen feature order
    features = features[FEATURES]

    return features


# ============================================================
# 6. APPLY FROZEN IMPUTATION
# ============================================================

def apply_imputation(features):

    X = features.copy()

    X = X[FEATURES]

    for column in X.columns:

        X[column] = pd.to_numeric(
            X[column],
            errors="coerce"
        )


    for column in FEATURES:

        if X[column].isna().any():

            X[column] = X[column].fillna(
                IMPUTATION_VALUES[column]
            )


    return X


# ============================================================
# 7. RAW ANOMALY SCORE
# ============================================================

def calculate_raw_anomaly_score(X):

    decision_score = MODEL.decision_function(X)

    # Isolation Forest:
    # higher decision_function = more normal
    # therefore negate it
    raw_anomaly_score = -decision_score

    return np.asarray(
        raw_anomaly_score,
        dtype=float
    )


# ============================================================
# 8. RISK SCORE
# ============================================================

def calculate_risk_score(raw_anomaly_score):

    n = len(REFERENCE_ANOMALY_SCORES)

    if n == 0:
        raise ValueError(
            "Reference anomaly-score distribution is empty."
        )


    score = float(raw_anomaly_score)


    left = np.searchsorted(
        REFERENCE_ANOMALY_SCORES,
        score,
        side="left"
    )


    right = np.searchsorted(
        REFERENCE_ANOMALY_SCORES,
        score,
        side="right"
    )


    # Tie-aware percentile
    percentile = (
        (left + right) / 2
    ) / n * 100


    return float(
        np.clip(percentile, 0, 100)
    )


# ============================================================
# 9. RISK LEVEL
# ============================================================

def determine_risk_level(risk_score):

    score = float(risk_score)

    if score <= 50:
        return "Low"

    elif score <= 75:
        return "Medium"

    elif score <= 90:
        return "High"

    else:
        return "Critical"


# ============================================================
# 10. WHY FLAGGED
# ============================================================

def generate_why_flagged(
    project_data,
    risk_score,
    risk_level
):

    reasons = []


    # ML anomaly
    if risk_score >= 90:

        reasons.append(
            "Critical statistical anomaly detected by ML model"
        )

    elif risk_score >= 75:

        reasons.append(
            "High statistical anomaly detected by ML model"
        )


    # High recommended amount
    recommended_amount = pd.to_numeric(
        project_data.get(
            "Recommended Amount (₹)",
            np.nan
        ),
        errors="coerce"
    )


    HIGH_AMOUNT_THRESHOLD = 2_000_000


    if (
        pd.notna(recommended_amount)
        and recommended_amount >= HIGH_AMOUNT_THRESHOLD
    ):

        reasons.append(
            f"High recommended amount "
            f"(₹{recommended_amount:,.0f})"
        )


    # Dates
    recommendation_date = pd.to_datetime(
        project_data.get(
            "Recommendation Date",
            pd.NaT
        ),
        errors="coerce"
    )


    completed_date = pd.to_datetime(
        project_data.get(
            "Completed Date",
            pd.NaT
        ),
        errors="coerce"
    )


    if (
        pd.notna(recommendation_date)
        and pd.notna(completed_date)
    ):

        completion_delay = (
            completed_date - recommendation_date
        ).days


        if completion_delay < 0:

            reasons.append(
                "Completion date precedes recommendation date"
            )


    # Missing completion
    if pd.isna(completed_date):

        reasons.append(
            "Completion information missing/unavailable"
        )


    # Missing description
    description = project_data.get(
        "Work Description",
        ""
    )


    if pd.isna(description):
        description = ""


    if not str(description).strip():

        reasons.append(
            "Work description missing"
        )


    # Financial deviation
    final_amount = pd.to_numeric(
        project_data.get(
            "Final Amount (₹)",
            np.nan
        ),
        errors="coerce"
    )


    if (
        pd.notna(recommended_amount)
        and pd.notna(final_amount)
        and recommended_amount > 0
    ):

        deviation_pct = (
            abs(
                final_amount - recommended_amount
            )
            / recommended_amount
            * 100
        )


        if deviation_pct >= 100:

            reasons.append(
                f"Extreme financial deviation "
                f"({deviation_pct:.2f}%)"
            )

        elif deviation_pct >= 50:

            reasons.append(
                f"Financial deviation "
                f"({deviation_pct:.2f}%)"
            )


    # Fallback
    if not reasons:

        reasons.append(
            "Model-based anomaly prioritization; "
            "no additional deterministic rule triggered"
        )


    return reasons


# ============================================================
# 11. MAIN PRODUCTION FUNCTION
# ============================================================

def predict_project(project_data):

    # Build exact 7 features
    raw_features = build_production_features(
        project_data
    )


    # Frozen preprocessing
    X = apply_imputation(
        raw_features
    )


    # ML anomaly score
    raw_score = calculate_raw_anomaly_score(
        X
    )[0]


    # Percentile risk score
    risk_score = calculate_risk_score(
        raw_score
    )


    # Risk level
    risk_level = determine_risk_level(
        risk_score
    )


    # Explanation
    why_flagged = generate_why_flagged(
        project_data,
        risk_score,
        risk_level
    )


    return {

        "model_name":
            METADATA.get(
                "model_name",
                "MPLADS_Retrospective_Project_Anomaly_Model"
            ),

        "model_version":
            METADATA.get(
                "model_version",
                "1.0.0"
            ),

        "work_id":
            project_data.get(
                "Work ID",
                None
            ),

        "raw_anomaly_score":
            float(raw_score),

        "risk_score":
            round(
                float(risk_score),
                2
            ),

        "risk_level":
            risk_level,

        "why_flagged":
            why_flagged,

        "features": {
            column: float(
                X.iloc[0][column]
            )
            for column in FEATURES
        }
    }


# ============================================================
# 12. MODEL INFORMATION
# ============================================================

def get_model_info():

    return {

        "model_name":
            METADATA.get("model_name"),

        "model_version":
            METADATA.get("model_version"),

        "model_type":
            METADATA.get("model_type"),

        "feature_count":
            len(FEATURES),

        "features":
            FEATURES,

        "reference_records":
            len(REFERENCE_ANOMALY_SCORES),

        "model_estimators":
            getattr(
                MODEL,
                "n_estimators",
                None
            ),

        "risk_thresholds":
            RISK_THRESHOLDS,

        "artifacts_loaded":
            True
    }


# ============================================================
# 13. LOCAL DEMO TEST
# ============================================================

if __name__ == "__main__":

    print("=" * 70)
    print("MPLADS PRODUCTION INFERENCE")
    print("=" * 70)


    test_project = {

        "Work ID":
            "DEMO-001",

        "Recommended Amount (₹)":
            5000000,

        "Work Description":
            "Construction and development of community infrastructure",

        "Has Images":
            False,

        "Recommendation Date":
            "2025-01-15",

        "Completed Date":
            None,

        "Final Amount (₹)":
            None
    }


    result = predict_project(
        test_project
    )


    print(
        f"Work ID     : "
        f"{result['work_id']}"
    )

    print(
        f"Raw Score   : "
        f"{result['raw_anomaly_score']:.6f}"
    )

    print(
        f"Risk Score  : "
        f"{result['risk_score']:.2f}"
    )

    print(
        f"Risk Level  : "
        f"{result['risk_level']}"
    )


    print("\nWhy Flagged:")

    for reason in result["why_flagged"]:

        print(f" • {reason}")


    print("\nFeatures:")

    for feature, value in result["features"].items():

        print(
            f" • {feature}: {value}"
        )
# ============================================================
# BATCH PRODUCTION INFERENCE
# ============================================================

def predict_batch(data):
    """
    Run production inference on multiple MPLADS projects.

    Parameters
    ----------
    data : pandas.DataFrame

    Returns
    -------
    pandas.DataFrame
    """

    if not isinstance(data, pd.DataFrame):
        raise TypeError(
            "Input must be a pandas DataFrame."
        )

    if data.empty:
        raise ValueError(
            "Input DataFrame is empty."
        )

    results = []

    for _, row in data.iterrows():

        project = row.to_dict()

        result = predict_project(project)

        results.append(result)

    return pd.DataFrame(results)