"""routes/auth_routes.py"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database.connection import get_db
from auth.password import verify_password, hash_password
from auth.jwt_handler import create_access_token, get_current_user
from schemas.auth import LoginRequest, SignupRequest, TokenResponse, UserOut
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
        
    if user.role != data.role:
        raise HTTPException(status_code=403, detail="Role mismatch. You are not authorized for this role.")

    token = create_access_token({"sub": user.user_id, "role": user.role})
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        role=user.role,
        name=user.name,
        user_id=user.user_id,
    )


@router.post("/signup", response_model=TokenResponse, summary="Sign up a new user and receive JWT")
def signup(data: SignupRequest, db: Session = Depends(get_db)):
    # Check if username or email already exists
    existing_user = db.query(User).filter(
        (User.username == data.username) | (User.email == data.email)
    ).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Username or email already registered")

    new_user = User(
        name=data.name,
        username=data.username,
        email=data.email,
        password_hash=hash_password(data.password),
        role=data.role,
        department=data.department
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    token = create_access_token({"sub": new_user.user_id, "role": new_user.role})
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        role=new_user.role,
        name=new_user.name,
        user_id=new_user.user_id,
    )


@router.get("/me", response_model=UserOut, summary="Get current authenticated user")
def get_me(current_user: User = Depends(get_current_user)):
    return current_user
