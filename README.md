# MPLAD Sanchalan

MPLAD Sanchalan is an **SIH prototype** for detecting statistically unusual MPLADS projects and helping auditors prioritize investigations using an AI/ML engine. 

**Unique Selling Proposition (USP):**
The system detects statistical anomalies rather than declaring fraud, acting as an intelligent, bias-free prioritization tool for human auditors. It provides a seamless, end-to-end platform bridging data ingestion, machine learning inference, cloud database management, and a dedicated dashboard.

## Frontend
*Details to be added.*

## Database
Powered by **Supabase (PostgreSQL)**. 
The database schema is fully managed via SQLAlchemy ORM (version 2.0) and securely stores project metadata, real-time ML predictions, evidence upload records, and audit investigation states. 
Demo accounts (demo_manager and demo_auditor) are auto-seeded on initialization for seamless testing and presentation.

## ML Model
The production ML engine utilizes an **Isolation Forest** algorithm to process 7 distinct statistical features derived from raw MPLADS projects (e.g., description length, recommended amount logs, completion delays). 
It outputs a standardized Risk Score (0-100) and categorizes projects into Low, Medium, High, or Critical risk brackets to generate immediate investigation signals for the dashboard.

## Backend
Built on **FastAPI** with Pydantic validation, providing a robust, async REST API layer. 
The backend integrates secure authentication via JWT tokens with bcrypt password hashing. It manages Role-Based Access Control (RBAC) separating DATA_MANAGER and AUDITOR permissions. The API serves as the central hub, accepting CSV bulk uploads, orchestrating real-time ML inference, and serving aggregated risk-distribution data to the frontend.

## Quick Start & Testing

### Running the Live Server
To activate both the Backend API and the ML Engine simultaneously, ensure you are in the root Prototype/ directory and run:
```bash
python run.py
```
This will start the FastAPI server on http://localhost:8000 and automatically load the ML engine artifacts.

### Testing the Backend
The backend has a robust suite of automated tests. You do not need to worry about corrupting live data; the tests will safely spin up a temporary, invisible SQLite database that deletes itself when finished.
```bash
python -m pytest backend/tests/ -v
```

### Testing the ML Engine
The ML engine has its own isolated test suite to verify the Isolation Forest pipeline.
```bash
python -m pytest ml_engine/tests/ -v
```

## Team Members
- **Team Leader & Database Admin:** Ati Srivastava (Provisioned Supabase PostgreSQL and managed cloud credentials)
- **Frontend Developer:** Sulagna Bhattacharya & Shruti Pandey (Developed Flutter UI and Dashboard)
- **Backend Developer:** Soumyadip Khan Sarkar(Integrated FastAPI, JWT Auth, and ML pipelines)
- **ML Engineer:** Sudeb Kundu (Developed Isolation Forest model and inference logic)
- **PPT & Graphics:** Saniya Yasmin (SIH Presentation)
