# MPLADS AI — Production ML Engine

## Purpose

This module provides production inference for the MPLADS anomaly-detection system.

The system identifies statistically unusual MPLADS projects and assigns an investigation-priority risk score.

The risk score is NOT a probability of fraud.

---

## Architecture

```text
Raw MPLADS Project
        |
        v
preprocessing.py
        |
        v
7 Production Features
        |
        v
anomaly.py
        |
        v
Isolation Forest
        |
        v
Raw Anomaly Score
        |
        v
risk_score.py
        |
        v
Risk Score (0-100)
        |
        v
Risk Level
        |
        +------------------+
        |                  |
        v                  v
rules.py          duplicate_detection.py
        |                  |
        +--------+---------+
                 |
                 v
            Investigation
              Signals
                 |
                 v
             Backend API
                 |
                 v
          Frontend Dashboard
