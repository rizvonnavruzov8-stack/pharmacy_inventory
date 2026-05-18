# 💊 Small Pharmacy Inventory & Prescription System (Kyrgyzstan Context)
### COMP2082 Final Project - Advanced DBMS & Relational Architectures

A production-grade, highly optimized PostgreSQL 15+ database architecture for community pharmacies in the Kyrgyz Republic. This project features SQL-standard identity columns, native enums, advanced PL/pgSQL validation triggers, high-performance indexes, operational views, group-level Role-Based Access Control (RBAC), and transactional integrity with ACID compliance.

---

## 📂 Submission Package Structure

This project has been structured for academic submission with all database scripts organized within the `sql/` directory:

*   `sql/01_schema.sql` (Core database schema, domains, and check constraints)
*   `sql/02_seed_data.sql` (Programmatic Kyrgyzstan-context seed dataset)
*   `sql/03_views.sql` (Operational reporting views)
*   `sql/04_queries.sql` (15 analytical business intelligence queries)
*   `sql/05_roles.sql` (Least-privilege RBAC role configurations)
*   `sql/06_transactions.sql` (ACID transaction execution models)
*   `sql/triggers.sql` (Inventory deduction and prescription validation triggers)
*   `sql/views.sql` (Frontend operational search views)

---

## 🛠️ Tech Stack & Requirements
- **DBMS**: PostgreSQL 15+ (tested on PostgreSQL 18.3)
- **Currency**: Kyrgyz Som (`KGS`)
- **Key Constraints**: Personal PIN (`^[12]\d{13}$`), Corporate TIN (`^[012]\d{13}$`), Phone Format (`^\+996\d{9}$`), and Kyrgyz standard VAT (**12%**).

---

## 📂 Project Structure
All SQL scripts are numbered and organized in topological dependency order for direct, execution-safe deployment:

```
├── 01_schema.sql          # Core tables, domains, PK/FK indexes, and CHECK constraints
├── triggers.sql           # PL/pgSQL triggers for stock deductions and Rx validations
├── 03_views.sql           # Operational views (low stock, expiring batches, Rx histories)
├── 04_queries.sql         # 15 business intelligence and auditing SQL queries
├── 05_roles.sql           # Group-level roles and Least Privilege RBAC policies
├── 06_transactions.sql    # ACID-compliant transactional checkout and rollback examples
├── final_project_report.md# Complete academic report (3NF/BCNF proofs, analysis)
└── README.md              # Installation and deployment manual (This File)
```

---

## 🚀 Installation & Setup Guide

Ensure you have a running PostgreSQL instance and a client CLI (`psql`) installed.

### Step 1: Create the Database
Connect to your PostgreSQL server and execute:
```sql
CREATE DATABASE pharmacy_db;
```

### Step 2: Sequential Deployment
Run the scripts in the following order using `psql` to guarantee that all dependencies, views, triggers, and seeding structures compile and link correctly:

```bash
# 1. Execute Core Relational Layout
psql -d pharmacy_db -f sql/01_schema.sql

# 2a. Deploy Automated Trigger Validations
psql -d pharmacy_db -f sql/triggers.sql

# 2b. Deploy Front-End Search Views
psql -d pharmacy_db -f sql/views.sql

# 3. Create Operational Reporting Views
psql -d pharmacy_db -f sql/03_views.sql

# 4. Configure RBAC Group Permissions & Schema Privileges
psql -d pharmacy_db -f sql/05_roles.sql

# 5. Populate Database with 3,000+ logically consistent records
psql -d pharmacy_db -f sql/02_seed_data.sql

# 6. Run Advanced Business Intelligence Queries
psql -d pharmacy_db -f sql/04_queries.sql

# 7. Execute ACID Transaction Models & Verification Checks
psql -d pharmacy_db -f sql/06_transactions.sql
```

---

## 💡 Automated Operations & Validation Triggers
- **`tg_deduct_inventory`**: Runs on sales checkouts. Locks selected batch rows using `SELECT FOR UPDATE` to prevent race conditions, overrides unit prices with master batch selling prices, validates non-expiration, checks quantities, and deducts stock.
- **`tg_validate_prescription`**: Automatically checks prescription-only medicines, verifies patient and doctor authorizations, validates remaining quantities, and auto-transitions the prescription status (`pending` $\rightarrow$ `partially_filled` $\rightarrow$ `filled`).
- **`tg_sale_items_totals`**: Recalculates gross sales, standard **12% Kyrgyz VAT**, and net totals dynamically upon invoice line modifications to maintain auditing consistency.
- **`tg_sync_inventory_adjustment`**: Captures inventory audit deltas (spoilage, breakage, warehouse count reconciliations) to keep counts balanced.

---

## Creating the Database Backup

To back up your database, run the following exact command:
```bash
pg_dump -U postgres -d pharmacy_db -F c -b -v -f pharmacy_db_backup.dump
```

To restore your database, run the following exact command:
```bash
pg_restore -U postgres -d pharmacy_db -v pharmacy_db_backup.dump
```

---

## 🔒 Security Policy (Least Privilege)
The database enforces role isolation using group-level permissions. To run operations under specific roles to verify security boundaries, use:
```sql
SET ROLE cashier;
-- Try to update prices or view employee credentials (will return Permission Denied)

SET ROLE pharmacist;
-- Try to write prescriptions (authorized) or edit inventory costs (denied)

RESET ROLE; -- Return to administrator bypass
```

---
*Developed as part of the USIT Advanced DBMS Design Lab COMP2082 Spring 2026.*
