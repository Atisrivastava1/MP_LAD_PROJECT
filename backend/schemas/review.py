"""schemas/review.py — review submission and decision schemas"""

from pydantic import BaseModel


class ReviewSubmit(BaseModel):
    review_notes: str | None = None
    status: str = "UNDER_REVIEW"     # auditor moves investigation to review


class DecisionSubmit(BaseModel):
    decision: str                    # e.g. "CLOSED_FRAUD_SUSPECTED" | "CLOSED_NO_ISSUE" | "ESCALATED"
    remarks: str | None = None
