#!/bin/bash
# COMP2082 — One-command full deployment for pharmacy_db
set -e
DB=pharmacy_db
echo "Creating database..."
psql -U postgres -c "DROP DATABASE IF EXISTS $DB WITH (FORCE);"
psql -U postgres -c "CREATE DATABASE $DB;"
echo "Deploying schema..."
psql -U postgres -d $DB -f sql/01_schema.sql
echo "Deploying triggers..."
psql -U postgres -d $DB -f sql/triggers.sql
echo "Deploying views..."
psql -U postgres -d $DB -f sql/views.sql
psql -U postgres -d $DB -f sql/03_views.sql
echo "Deploying roles..."
psql -U postgres -d $DB -f sql/05_roles.sql
echo "Seeding data..."
psql -U postgres -d $DB -f sql/02_seed_data.sql
echo "Running queries (output to queries_output.txt)..."
psql -U postgres -d $DB -f sql/04_queries.sql > queries_output.txt 2>&1 || true
echo "Running transaction examples..."
psql -U postgres -d $DB -f sql/06_transactions.sql
echo "Done. Database $DB is ready."
