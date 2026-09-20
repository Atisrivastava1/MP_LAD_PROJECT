import csv
import io
from sqlalchemy.orm import Session
from models.project import Project

def _generate_csv_stream(projects: list[Project]) -> str:
    # Helper to convert a list of projects into a CSV string.
    output = io.StringIO()
    writer = csv.writer(output)
    
    # Header
    writer.writerow([
        "work_id", 
        "mp_name", 
        "state", 
        "constituency", 
        "description", 
        "recommended_amount", 
        "project_status", 
        "risk_score", 
        "risk_level"
    ])
    
    # Rows
    for p in projects:
        writer.writerow([
            p.work_id,
            p.mp_name or "",
            p.state or "",
            p.constituency or "",
            p.description or "",
            p.recommended_amount or 0.0,
            p.project_status,
            p.risk_score if p.risk_score is not None else "",
            p.risk_level or ""
        ])
    
    return output.getvalue()


def get_overall_status_report(db: Session) -> str:
    projects = db.query(Project).all()
    return _generate_csv_stream(projects)


def get_anomaly_breakdown(db: Session) -> str:
    projects = db.query(Project).all()
    anomalies = [p for p in projects if p.risk_score is not None and p.risk_score >= 75]
    return _generate_csv_stream(anomalies)


def get_clean_data(db: Session) -> str:
    projects = db.query(Project).all()
    clean = [p for p in projects if p.risk_score is not None and p.risk_score < 50]
    return _generate_csv_stream(clean)


def get_flagged_data(db: Session) -> str:
    projects = db.query(Project).all()
    flagged = [p for p in projects if p.risk_score is not None and p.risk_score >= 50]
    return _generate_csv_stream(flagged)
