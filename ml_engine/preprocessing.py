"""
MPLADS ML Engine - Production Preprocessing
"""

from pathlib import Path
import json
import math
import numpy as np
import pandas as pd


# ============================================================
# PATHS
# ============================================================

BASE_DIR = Path(__file__).resolve().parent
ARTIFACT_DIR = BASE_DIR / "artifacts"

METADATA_PATH = ARTIFACT_DIR / "mplads_model_metadata_v1.json"


# ============================================================
# LOAD METADATA
# ============================================================

with open(METADATA_PATH, "r", encoding="utf-8") as f:
    METADATA = json.load(f)


FEATURES = METADATA["features"]
IMPUTATION_VALUES = METADATA["imputation_values"]


# ============================================================
# HELPER FUNCTIONS
# ============================================================

def _safe_float(value):
    try:
        if value is None:
            return np.nan

        value = float(value)

        if not np.isfinite(value):
            return np.nan

        return value

    except (TypeError, ValueError):
        return np.nan


def _safe_text(value):
    if value is None:
        return ""

    if pd.isna(value):
        return ""

    return str(value).strip()


# ============================================================
# FEATURE BUILDER
# ============================================================
def build_features(project_data):
    # --------------------------------------------------------
    # Recommended amount
    # --------------------------------------------------------
    amount = _safe_float(
        project_data.get(
            "Recommended Amount (₹)",
            project_data.get("recommended_amount", np.nan)
        )
    )

    if pd.isna(amount) or amount < 0:
        recommended_amount_log = np.nan
    else:
        recommended_amount_log = math.log1p(amount)

    # --------------------------------------------------------
    # Work description
    # Accept both application/API and ML-test naming
    # --------------------------------------------------------
    description = _safe_text(
        project_data.get(
            "Work Description",
            project_data.get(
                "Description",
                project_data.get("description", "")
            )
        )
    )

    description_length = len(description)
    description_word_count = len(description.split())

    # --------------------------------------------------------
    # Images
    # --------------------------------------------------------
    has_images = project_data.get(
        "Has Images",
        project_data.get(
            "has_images_flag",
            project_data.get("has_images", 0)
        )
    )

    if isinstance(has_images, str):
        has_images_flag = (
            1.0
            if has_images.strip().lower()
            in {"true", "1", "yes", "y"}
            else 0.0
        )
    else:
        try:
            has_images_flag = float(bool(has_images))
        except (TypeError, ValueError):
            has_images_flag = np.nan

    # --------------------------------------------------------
    # Completion dates
    # Derive completion features from normal MPLADS fields
    # --------------------------------------------------------
    recommendation_date = pd.to_datetime(
        project_data.get(
            "Recommendation Date",
            project_data.get("recommendation_date", pd.NaT)
        ),
        errors="coerce"
    )

    completed_date = pd.to_datetime(
        project_data.get(
            "Completed Date",
            project_data.get("completed_date", pd.NaT)
        ),
        errors="coerce"
    )

    # Explicit derived value is accepted if supplied
    supplied_delay = _safe_float(
        project_data.get(
            "completion_delay_days_clean",
            np.nan
        )
    )

    if not pd.isna(supplied_delay):
        completion_delay_days_clean = (
            supplied_delay if supplied_delay >= 0 else np.nan
        )
    elif (
        not pd.isna(recommendation_date)
        and not pd.isna(completed_date)
    ):
        delay = (
            completed_date - recommendation_date
        ).days

        completion_delay_days_clean = (
            float(delay) if delay >= 0 else np.nan
        )
    else:
        completion_delay_days_clean = np.nan

    # --------------------------------------------------------
    # Date inconsistency
    # --------------------------------------------------------
    supplied_inconsistent = project_data.get(
        "completion_date_inconsistent",
        None
    )

    if supplied_inconsistent is not None:
        try:
            completion_date_inconsistent = float(
                supplied_inconsistent
            )
        except (TypeError, ValueError):
            completion_date_inconsistent = 0.0
    elif (
        not pd.isna(recommendation_date)
        and not pd.isna(completed_date)
    ):
        completion_date_inconsistent = float(
            completed_date < recommendation_date
        )
    else:
        completion_date_inconsistent = 0.0

    # --------------------------------------------------------
    # Completion missing
    # --------------------------------------------------------
    supplied_missing = project_data.get(
        "completion_delay_missing",
        None
    )

    if supplied_missing is not None:
        try:
            completion_delay_missing = float(
                supplied_missing
            )
        except (TypeError, ValueError):
            completion_delay_missing = 1.0
    else:
        completion_delay_missing = float(
            pd.isna(completion_delay_days_clean)
        )

    # --------------------------------------------------------
    # Exact frozen 7-feature schema
    # --------------------------------------------------------
    row = {
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

    X = pd.DataFrame([row])

    # Exact frozen feature order + frozen training medians
    for feature in FEATURES:
        X[feature] = pd.to_numeric(
            X[feature],
            errors="coerce"
        )

        X[feature] = X[feature].fillna(
            IMPUTATION_VALUES[feature]
        )

    return X

# ============================================================
# PRODUCTION PREPROCESSING WRAPPER
# ============================================================

def prepare_features(data):
    """
    Production entry point for preprocessing.

    Supports:
        1. Single project dictionary
        2. pandas DataFrame containing multiple projects

    Returns:
        pandas.DataFrame containing exactly the 7
        frozen production model features.
    """

    # --------------------------------------------------------
    # Single project
    # --------------------------------------------------------

    if isinstance(data, dict):
        return build_features(data)

    # --------------------------------------------------------
    # Batch DataFrame
    # --------------------------------------------------------

    if isinstance(data, pd.DataFrame):

        if data.empty:
            raise ValueError("Input DataFrame is empty.")

        rows = []

        for _, record in data.iterrows():
            rows.append(
                build_features(record.to_dict()).iloc[0]
            )

        X = pd.DataFrame(rows)

        # Guarantee exact production feature order
        X = X[FEATURES]

        return X

    raise TypeError(
        "Input must be either a dictionary or pandas DataFrame."
    )