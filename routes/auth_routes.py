"""routes/auth_routes.py"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database.connection import get_db
from auth.password import verify_password
from auth.jwt_handler import create_access_token, get_current_user
from schemas.auth import LoginRequest, TokenResponse, UserOut
from models.user import User

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/login", response_model=TokenResponse, summary="Login and receive JWT")
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user: User | None = db.query(User).filter(
        User.username == data.username,
        User.is_active.is_(True),
    ).first()

    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid username or password")

    token = create_access_token({"sub": user.user_id, "role": user.role})
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        role=user.role,
        name=user.name,
        user_id=user.user_id,
    )


@router.get("/me", response_model=UserOut, summary="Get current authenticated user")
def get_me(current_user: User = Depends(get_current_user)):
    return current_user
