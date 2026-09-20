from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
import io

from database.connection import get_db
from services import report_service

router = APIRouter(prefix="/reports", tags=["Reports"])

def create_streaming_response(csv_str: str, filename: str):
    return StreamingResponse(
        iter([csv_str]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

@router.get("/overall")
def export_overall_report(db: Session = Depends(get_db)):
    csv_str = report_service.get_overall_status_report(db)
    return create_streaming_response(csv_str, "overall_status_report.csv")

@router.get("/anomaly")
def export_anomaly_breakdown(db: Session = Depends(get_db)):
    csv_str = report_service.get_anomaly_breakdown(db)
    return create_streaming_response(csv_str, "anomaly_breakdown.csv")

@router.get("/clean")
def export_clean_data(db: Session = Depends(get_db)):
    csv_str = report_service.get_clean_data(db)
    return create_streaming_response(csv_str, "clean_data.csv")

@router.get("/flagged")
def export_flagged_data(db: Session = Depends(get_db)):
    csv_str = report_service.get_flagged_data(db)
    return create_streaming_response(csv_str, "flagged_data.csv")
