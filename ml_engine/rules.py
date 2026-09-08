"""
MPLADS ML Engine - Production Rule Engine

Purpose:
    Apply deterministic business/data-quality rules
    alongside the ML anomaly detector.

Important:
    Rules do NOT determine fraud.
    They provide additional investigation signals.
"""


# ============================================================
# RULE THRESHOLDS
# ============================================================

# High recommended amount threshold.
# This is a prototype investigation rule and can be
# calibrated later using domain/expert guidance.
HIGH_AMOUNT_THRESHOLD = 5_000_000


# ============================================================
# MAIN RULE ENGINE
# ============================================================

def evaluate_rules(project_data):
    """
    Evaluate deterministic investigation rules.

    Parameters
    ----------
    project_data : dict
        Raw MPLADS project information.

    Returns
    -------
    list[str]
        Human-readable investigation reasons.
    """

    reasons = []

    # --------------------------------------------------------
    # Recommended amount
    # --------------------------------------------------------

    amount = project_data.get(
        "Recommended Amount (₹)"
    )

    try:
        amount = float(amount)
    except (TypeError, ValueError):
        amount = None

    if (
        amount is not None
        and amount >= HIGH_AMOUNT_THRESHOLD
    ):
        reasons.append(
            f"High recommended amount (₹{amount:,.0f})"
        )

    # --------------------------------------------------------
    # Completion information
    # --------------------------------------------------------

    completion_missing = project_data.get(
        "completion_delay_missing"
    )

    if completion_missing is not None:

        try:
            if float(completion_missing) == 1:
                reasons.append(
                    "Completion information missing/unavailable"
                )
        except (TypeError, ValueError):
            pass

    # --------------------------------------------------------
    # Completion date inconsistency
    # --------------------------------------------------------

    date_inconsistent = project_data.get(
        "completion_date_inconsistent"
    )

    if date_inconsistent is not None:

        try:
            if float(date_inconsistent) == 1:
                reasons.append(
                    "Completion date information is inconsistent"
                )
        except (TypeError, ValueError):
            pass

    return reasons


# ============================================================
# COMBINE ML + RULE EXPLANATIONS
# ============================================================

def generate_why_flagged(
    project_data,
    risk_score,
    risk_level
):
    """
    Combine ML risk information with deterministic
    rule-based investigation signals.

    Returns
    -------
    list[str]
        Final explanation list.
    """

    reasons = []

    # --------------------------------------------------------
    # ML risk signal
    # --------------------------------------------------------

    if risk_level == "Critical":

        reasons.append(
            "Critical statistical anomaly detected by ML model"
        )

    elif risk_level == "High":

        reasons.append(
            "High statistical anomaly detected by ML model"
        )

    elif risk_level == "Medium":

        reasons.append(
            "Moderate statistical anomaly detected by ML model"
        )

    # --------------------------------------------------------
    # Rule-based signals
    # --------------------------------------------------------

    rule_reasons = evaluate_rules(project_data)

    for reason in rule_reasons:

        if reason not in reasons:
            reasons.append(reason)

    # --------------------------------------------------------
    # Safe fallback
    # --------------------------------------------------------

    if not reasons:

        reasons.append(
            "No major rule-based investigation signal detected"
        )

    return reasons