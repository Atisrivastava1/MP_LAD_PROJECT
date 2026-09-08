# run.py — start the MPLADS Sentinel backend from the project root
# Usage: python run.py
# This ensures ml_engine/ is importable alongside backend/

import sys
import os
from pathlib import Path

# Add project root to Python path so both backend/ and ml_engine/ are importable
PROJECT_ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(PROJECT_ROOT))

# Change working directory to backend/ so relative imports inside backend work
BACKEND_DIR = PROJECT_ROOT / "backend"
os.chdir(BACKEND_DIR)
sys.path.insert(0, str(BACKEND_DIR))

import uvicorn

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        reload_dirs=[str(BACKEND_DIR)],
    )
