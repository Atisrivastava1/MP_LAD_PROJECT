"""auth/rbac.py — Role-based access control dependencies"""

from typing import Callable
from fastapi import Depends, HTTPException, status
from models.user import User
from auth.jwt_handler import get_current_user


def require_role(*roles: str) -> Callable:
    """
    Dependency factory.
    Usage:
        @router.get("/...", dependencies=[Depends(require_role("AUDITOR"))])
    Or as a typed parameter:
        current_user: User = Depends(require_role("DATA_MANAGER", "AUDITOR"))
    """
    def _check(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required role(s): {', '.join(roles)}",
            )
        return current_user

    return _check


# Convenience aliases used by route files
data_manager_only = require_role("DATA_MANAGER")
auditor_only = require_role("AUDITOR")
any_authenticated = require_role("DATA_MANAGER", "AUDITOR")
