"""
MPLADS ML Engine - Duplicate Detection

Purpose:
    Detect potentially duplicate MPLADS project records.

This module does NOT replace database-level unique constraints.
It provides similarity-based investigation signals.
"""

import re
import pandas as pd


# ============================================================
# NORMALIZATION
# ============================================================

def normalize_text(value):
    """Normalize text for comparison."""

    if value is None:
        return ""

    text = str(value).lower().strip()

    text = re.sub(r"[^a-z0-9\s]", " ", text)
    text = re.sub(r"\s+", " ", text)

    return text


# ============================================================
# EXACT WORK-ID DUPLICATES
# ============================================================

def find_work_id_duplicates(data):
    """
    Find exact duplicate Work IDs.

    Returns:
        DataFrame containing duplicate records.
    """

    if not isinstance(data, pd.DataFrame):
        raise TypeError("Input must be a pandas DataFrame.")

    if "Work ID" not in data.columns:
        return pd.DataFrame()

    mask = data["Work ID"].duplicated(
        keep=False
    )

    return data.loc[mask].copy()


# ============================================================
# SIMILAR PROJECT DETECTION
# ============================================================

def find_similar_projects(
    data,
    description_column="Description",
    amount_column="Recommended Amount (₹)"
):
    """
    Detect potentially similar project records.

    Uses:
        - normalized description
        - recommended amount

    This is an investigation aid, not proof of duplication.
    """

    if not isinstance(data, pd.DataFrame):
        raise TypeError("Input must be a pandas DataFrame.")

    if description_column not in data.columns:
        return pd.DataFrame()

    records = []

    normalized_descriptions = (
        data[description_column]
        .fillna("")
        .apply(normalize_text)
    )

    amounts = None

    if amount_column in data.columns:
        amounts = pd.to_numeric(
            data[amount_column],
            errors="coerce"
        )

    for i in range(len(data)):

        for j in range(i + 1, len(data)):

            desc_i = normalized_descriptions.iloc[i]
            desc_j = normalized_descriptions.iloc[j]

            if not desc_i or not desc_j:
                continue

            # Exact normalized description match
            description_match = (
                desc_i == desc_j
            )

            # Similarity using token overlap
            words_i = set(desc_i.split())
            words_j = set(desc_j.split())

            if words_i and words_j:

                intersection = len(
                    words_i.intersection(words_j)
                )

                union = len(
                    words_i.union(words_j)
                )

                similarity = (
                    intersection / union
                    if union > 0
                    else 0
                )

            else:
                similarity = 0

            amount_match = False

            if amounts is not None:

                amount_i = amounts.iloc[i]
                amount_j = amounts.iloc[j]

                if (
                    pd.notna(amount_i)
                    and pd.notna(amount_j)
                ):
                    amount_match = (
                        amount_i == amount_j
                    )

            if description_match or (
                similarity >= 0.80
                and amount_match
            ):

                records.append({
                    "row_1": i,
                    "row_2": j,
                    "description_similarity":
                        round(similarity, 4),
                    "same_recommended_amount":
                        amount_match,
                    "duplicate_signal":
                        "Potential duplicate project"
                })

    return pd.DataFrame(records)


# ============================================================
# COMPLETE DUPLICATE ANALYSIS
# ============================================================

def detect_duplicates(data):
    """
    Run all duplicate checks.

    Returns:
        Dictionary containing duplicate findings.
    """

    exact_duplicates = find_work_id_duplicates(
        data
    )

    similar_projects = find_similar_projects(
        data
    )

    return {
        "work_id_duplicates":
            exact_duplicates,

        "similar_projects":
            similar_projects,

        "work_id_duplicate_count":
            len(exact_duplicates),

        "similar_project_count":
            len(similar_projects)
    }