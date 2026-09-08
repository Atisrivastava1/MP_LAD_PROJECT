import os
import sys

# Ensure backend directory is in path
sys.path.append(os.getcwd())

from database.connection import engine, Base
import models.user
import models.project
import models.ml_prediction
import models.duplicate_match
import models.investigation
import models.evidence
import models.audit_log
from database.schema import init_db

print('Dropping all tables...')
Base.metadata.drop_all(bind=engine)
print('Recreating tables and seeding...')
init_db()
print('Database reset complete.')
