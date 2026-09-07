# Database

This project uses PostgreSQL.

## Database Name

`mplads_db`

## Tables

- users
- projects
- ml_predictions
- duplicate_matches
- investigations
- evidence
- audit_logs

## Setup

1. Install PostgreSQL.
2. Create a database named `mplads_db`.
3. Run `schema.sql`.
4. Configure the `DATABASE_URL` in `.env`.

## Relationships

### Users

- `users → investigations`
- `users → evidence`
- `users → audit_logs`

### Projects

- `projects → ml_predictions`
- `projects → duplicate_matches`
- `projects → investigations`
- `projects → audit_logs`

### ML Predictions

- `ml_predictions → investigations`

### Investigations

- `investigations → evidence`
- `investigations → audit_logs`