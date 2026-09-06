"""schemas/auth.py — Login request, token response, current-user output"""

from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    username: str
    password: str


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
    role: str
    department: str | None
    email: str
    is_active: bool

    model_config = {"from_attributes": True}
