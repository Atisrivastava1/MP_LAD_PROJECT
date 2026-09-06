import pandas as pd

from ml_engine.preprocessing import prepare_features
from ml_engine.anomaly import calculate_anomaly_score
from ml_engine.risk_score import calculate_risk_score
from ml_engine.rules import evaluate_rules
from ml_engine.duplicate_detection import detect_duplicates


def test_preprocessing():

    project = {
        "Recommended Amount (₹)": 5000000,
        "Description": "Construction of community infrastructure",
        "Has Images": 0,
        "completion_delay_days_clean": None,
        "completion_date_inconsistent": 0,
        "completion_delay_missing": 1
    }

    X = prepare_features(project)

    assert X.shape == (1, 7)
    assert X.isna().sum().sum() == 0


def test_anomaly_score():

    X = pd.DataFrame([{
        "recommended_amount_log": 13.12,
        "description_length": 56,
        "description_word_count": 6,
        "has_images_flag": 0,
        "completion_delay_days_clean": 334,
        "completion_date_inconsistent": 0,
        "completion_delay_missing": 0
    }])

    score = calculate_anomaly_score(X)

    assert len(score) == 1


def test_risk_score():

    score = calculate_risk_score(0.0025)

    assert 0 <= score <= 100


def test_rules():

    project = {
        "Recommended Amount (₹)": 5000000,
        "completion_delay_missing": 1,
        "completion_date_inconsistent": 0
    }

    reasons = evaluate_rules(project)

    assert len(reasons) >= 1


def test_duplicate_detection():

    df = pd.DataFrame({
        "Work ID": [1, 1, 2],
        "Description": [
            "Construction of road",
            "Construction of road",
            "School building"
        ],
        "Recommended Amount (₹)": [
            100000,
            100000,
            200000
        ]
    })

    result = detect_duplicates(df)

    assert result["work_id_duplicate_count"] == 2
