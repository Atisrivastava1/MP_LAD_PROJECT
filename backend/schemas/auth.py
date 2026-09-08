"""schemas/auth.py - Login request, token response, current-user output"""

from datetime import datetime
from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    username: str
    password: str
    role: str


class SignupRequest(BaseModel):
    name: str
    username: str
    email: EmailStr
    password: str
    role: str
    department: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    name: str
    user_id: str


class UserOut(BaseModel):
    user_id: str
    name: str
    username: str
    email: str
    role: str
    department: str | None
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True
