"""services/prediction_service.py — run ML inference and persist the result"""

import logging
from sqlalchemy.orm import Session

from models.ml_prediction import MLPrediction
from ml_client.inference_client import predict_project
from services.audit_service import log_action

logger = logging.getLogger(__name__)


def run_and_store_prediction(
    db: Session,
    *,
    project_id: str,
    project_data: dict,
    user_id: str | None = None,
) -> MLPrediction:
    """
    Call the ML client, persist the result into ml_predictions.
    If the ML call fails, raises an exception — does NOT corrupt the project.
    """
    ml_result = predict_project(project_data)

    prediction = MLPrediction(
        project_id=project_id,
        model_name=ml_result.get("model_name", "mplads_anomaly_model"),
        model_version=ml_result.get("model_version", "v1"),
        raw_anomaly_score=ml_result.get("raw_anomaly_score"),
        risk_score=ml_result.get("risk_score"),
        risk_level=ml_result.get("risk_level"),
        why_flagged=ml_result.get("why_flagged", []),
        rules_triggered=ml_result.get("rules_triggered", {}),
        processed_features=ml_result.get("features", {}),
    )
    db.add(prediction)
    db.commit()
    db.refresh(prediction)

    log_action(
        db,
        action="PREDICTION_GENERATED",
        user_id=user_id,
        project_id=project_id,
        new_value=f"risk_level={prediction.risk_level}, risk_score={prediction.risk_score}",
        status="SUCCESS",
    )

    return prediction


def get_prediction_by_project_id(db: Session, project_id: str) -> MLPrediction | None:
    return (
        db.query(MLPrediction)
        .filter(MLPrediction.project_id == project_id)
        .order_by(MLPrediction.prediction_created_at.desc())
        .first()
    )


def get_all_predictions(db: Session) -> list[MLPrediction]:
    return db.query(MLPrediction).order_by(MLPrediction.prediction_created_at.desc()).all()


def get_high_risk_predictions(db: Session) -> list[MLPrediction]:
    return (
        db.query(MLPrediction)
        .filter(MLPrediction.risk_level.in_(["High", "Critical"]))
        .order_by(MLPrediction.risk_score.desc())
        .all()
    )
