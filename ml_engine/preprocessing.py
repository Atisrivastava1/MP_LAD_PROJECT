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
    """
    Convert one raw MPLADS project into the
    exact 7 production model features.

    Returns:
        pandas.DataFrame with exactly 7 columns
        in frozen production order.
    """

    # --------------------------------------------------------
    # Recommended amount
    # --------------------------------------------------------

    amount = _safe_float(
        project_data.get("Recommended Amount (₹)")
    )

    if pd.isna(amount) or amount < 0:
        recommended_amount_log = np.nan
    else:
        recommended_amount_log = math.log1p(amount)


    # --------------------------------------------------------
    # Description
    # --------------------------------------------------------

    description = _safe_text(
        project_data.get("Description", "")
    )

    description_length = len(description)

    description_word_count = len(
        description.split()
    )


    # --------------------------------------------------------
    # Images
    # --------------------------------------------------------

    has_images = project_data.get(
        "has_images_flag",
        project_data.get("Has Images", 0)
    )

    try:
        has_images_flag = float(has_images)
    except (TypeError, ValueError):
        has_images_flag = np.nan


    # --------------------------------------------------------
    # Completion information
    # --------------------------------------------------------

    completion_delay = _safe_float(
        project_data.get(
            "completion_delay_days_clean"
        )
    )

    completion_missing = project_data.get(
        "completion_delay_missing"
    )

    if completion_missing is None:

        completion_delay_missing = (
            1.0 if pd.isna(completion_delay) else 0.0
        )

    else:

        try:
            completion_delay_missing = float(
                completion_missing
            )
        except (TypeError, ValueError):
            completion_delay_missing = 1.0


    # --------------------------------------------------------
    # Completion date inconsistency
    # --------------------------------------------------------

    completion_inconsistent = project_data.get(
        "completion_date_inconsistent",
        0
    )

    try:
        completion_date_inconsistent = float(
            completion_inconsistent
        )
    except (TypeError, ValueError):
        completion_date_inconsistent = np.nan


    # --------------------------------------------------------
    # Create feature row
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
            completion_delay,

        "completion_date_inconsistent":
            completion_date_inconsistent,

        "completion_delay_missing":
            completion_delay_missing,
    }


    X = pd.DataFrame([row])


    # --------------------------------------------------------
    # Apply frozen production medians
    # --------------------------------------------------------

    for feature in FEATURES:

        X[feature] = pd.to_numeric(
            X[feature],
            errors="coerce"
        )

        X[feature] = X[feature].fillna(
            IMPUTATION_VALUES[feature]
        )



    # --------------------------------------------------------
    # Final order
    # --------------------------------------------------------

    X = X[FEATURES]

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