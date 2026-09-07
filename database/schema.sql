-- ============================================
-- MPLADS DATABASE SCHEMA
-- ============================================

-- 1. USERS
CREATE TABLE users (
    -- your users table definition
);


-- 2. PROJECTS
CREATE TABLE projects (
    project_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    work_id VARCHAR(100) NOT NULL UNIQUE,
    mp_name VARCHAR(150),
    state VARCHAR(100),
    constituency VARCHAR(150),
    description TEXT,
    recommended_amount NUMERIC(15, 2),
    has_images BOOLEAN NOT NULL DEFAULT FALSE,
    completion_date DATE,
    completion_delay_days INTEGER,
    completion_date_inconsistent BOOLEAN NOT NULL DEFAULT FALSE,
    completion_delay_missing BOOLEAN NOT NULL DEFAULT FALSE,
    project_status VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- 3. ML PREDICTIONS
CREATE TABLE ml_predictions (
    prediction_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_id BIGINT NOT NULL,

    model_name VARCHAR(100) NOT NULL,
    model_version VARCHAR(50),

    raw_anomaly_score NUMERIC(10, 6),
    risk_score NUMERIC(10, 6),
    risk_level VARCHAR(50),

    why_flagged TEXT,

    rules_triggered JSONB,
    processed_features JSONB,

    prediction_created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ml_predictions_project
        FOREIGN KEY (project_id)
        REFERENCES projects(project_id)
        ON DELETE CASCADE
);


-- 4. DUPLICATE MATCHES
CREATE TABLE duplicate_matches (
    duplicate_match_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    project_id BIGINT NOT NULL,
    matched_project_id BIGINT NOT NULL,

    similarity_score NUMERIC(10, 6),
    detection_method VARCHAR(100),
    match_reason TEXT,
    status VARCHAR(50),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_duplicate_project
        FOREIGN KEY (project_id)
        REFERENCES projects(project_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_duplicate_matched_project
        FOREIGN KEY (matched_project_id)
        REFERENCES projects(project_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_duplicate_projects_different
        CHECK (project_id <> matched_project_id)
);


-- 5. INVESTIGATIONS
CREATE TABLE investigations (
    investigation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    project_id BIGINT NOT NULL,
    prediction_id BIGINT,

    assigned_to BIGINT,

    findings TEXT,
    remarks TEXT,
    status VARCHAR(50),

    started_at TIMESTAMPTZ,
    submitted_at TIMESTAMPTZ,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_investigation_project
        FOREIGN KEY (project_id)
        REFERENCES projects(project_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_investigation_prediction
        FOREIGN KEY (prediction_id)
        REFERENCES ml_predictions(prediction_id)
        ON DELETE SET NULL,

    CONSTRAINT fk_investigation_assigned_user
        FOREIGN KEY (assigned_to)
        REFERENCES users(user_id)
        ON DELETE SET NULL
);


-- 6. EVIDENCE
CREATE TABLE evidence (
    evidence_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    investigation_id BIGINT NOT NULL,
    uploaded_by BIGINT,

    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_type VARCHAR(100),
    description TEXT,

    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_evidence_investigation
        FOREIGN KEY (investigation_id)
        REFERENCES investigations(investigation_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_evidence_uploaded_user
        FOREIGN KEY (uploaded_by)
        REFERENCES users(user_id)
        ON DELETE SET NULL
);
-- Table: public.audit_logs

-- DROP TABLE IF EXISTS public.audit_logs;

CREATE TABLE IF NOT EXISTS public.audit_logs
(
    log_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    user_id bigint,
    project_id bigint,
    investigation_id bigint,
    action character varying(100) COLLATE pg_catalog."default" NOT NULL,
    old_value jsonb,
    new_value jsonb,
    status character varying(50) COLLATE pg_catalog."default",
    created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT audit_logs_pkey PRIMARY KEY (log_id),
    CONSTRAINT fk_audit_investigation FOREIGN KEY (investigation_id)
        REFERENCES public.investigations (investigation_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE SET NULL,
    CONSTRAINT fk_audit_project FOREIGN KEY (project_id)
        REFERENCES public.projects (project_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE SET NULL,
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id)
        REFERENCES public.users (user_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE SET NULL
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.audit_logs
    OWNER to postgres;

CREATE INDEX idx_ml_predictions_project_id
ON ml_predictions(project_id);

CREATE INDEX idx_ml_predictions_risk_level
ON ml_predictions(risk_level);

CREATE INDEX idx_duplicate_matches_project_id
ON duplicate_matches(project_id);

CREATE INDEX idx_duplicate_matches_matched_project_id
ON duplicate_matches(matched_project_id);

CREATE INDEX idx_investigations_project_id
ON investigations(project_id);

CREATE INDEX idx_investigations_assigned_to
ON investigations(assigned_to);

CREATE INDEX idx_evidence_investigation_id
ON evidence(investigation_id);

CREATE INDEX idx_audit_logs_user_id
ON audit_logs(user_id);

CREATE INDEX idx_audit_logs_project_id
ON audit_logs(project_id);

CREATE INDEX idx_audit_logs_investigation_id
ON audit_logs(investigation_id);

CREATE INDEX idx_audit_logs_created_at
ON audit_logs(created_at);