-- ============================================================================
-- PROJECT: Small Pharmacy Inventory & Prescription System (COMP2082 Final Project)
-- FILE: 05_roles.sql
-- DESCRIPTION: Role-Based Access Control (RBAC) and Security Policy.
-- SYNTAX: PostgreSQL 15+ Standard
-- ============================================================================

-- Clean up existing group permissions and drop roles if they exist
-- (Note: In a live database, active sessions must be terminated before dropping roles)
DO $$
BEGIN
    -- Revoke object memberships and safe drop
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pharmacy_admin') THEN
        DROP OWNED BY pharmacy_admin;
        DROP ROLE pharmacy_admin;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pharmacist') THEN
        DROP OWNED BY pharmacist;
        DROP ROLE pharmacist;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cashier') THEN
        DROP OWNED BY cashier;
        DROP ROLE cashier;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'inventory_manager') THEN
        DROP OWNED BY inventory_manager;
        DROP ROLE inventory_manager;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'readonly_auditor') THEN
        DROP OWNED BY readonly_auditor;
        DROP ROLE readonly_auditor;
    END IF;
END $$;

-- ============================================================================
-- 1. DEFINE PRINCIPLE OF LEAST PRIVILEGE SCHEMA ISOLATION
-- ============================================================================
-- By default, all users are granted connect and usage on the "public" schema. 
-- To satisfy strict university and enterprise security compliance, we revoke 
-- default PUBLIC access to isolate our tables entirely.
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

-- ============================================================================
-- 2. CREATE ROLES (NOLOGIN Group Roles for Permission Inheritance)
-- ============================================================================
CREATE ROLE pharmacy_admin WITH NOLOGIN;
CREATE ROLE pharmacist WITH NOLOGIN;
CREATE ROLE cashier WITH NOLOGIN;
CREATE ROLE inventory_manager WITH NOLOGIN;
CREATE ROLE readonly_auditor WITH NOLOGIN;

-- Grant schema visibility to all functional roles
GRANT USAGE ON SCHEMA public TO pharmacy_admin, pharmacist, cashier, inventory_manager, readonly_auditor;

-- ============================================================================
-- 3. SPECIFY DETAILED PRIVILEGES BY ROLE (Least Privilege Enforcement)
-- ============================================================================

-- 3.1 Role: readonly_auditor
-- Purpose: Read-only access for corporate tax reviews or academic grading audit.
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_auditor;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO readonly_auditor;

-- 3.2 Role: cashier
-- Purpose: Process OTC and Rx sales transactions. Restricted from altering prices, 
--          restocking shelves, or viewing security hashes.
-- Cashiers need SELECT on catalog entities to read details:
GRANT SELECT ON TABLE categories, medicines, patients, doctors, prescriptions, prescription_items TO cashier;
-- Cashiers need SELECT and UPDATE (column-level) on batches to look up prices and allow trigger deductions:
GRANT SELECT, UPDATE (current_quantity) ON TABLE batches TO cashier;
-- Cashiers need INSERT on sales and sale_items to checkout customers:
GRANT SELECT, INSERT ON TABLE sales, sale_items TO cashier;
-- Cashiers need sequence grants to generate transaction IDs:
GRANT USAGE, SELECT ON SEQUENCE sales_id_seq, sale_items_id_seq TO cashier;

-- 3.3 Role: pharmacist
-- Purpose: Dispense regulated drugs, manage prescriptions, and read inventory.
--          Excludes sensitive staff records (PINs, passwords).
GRANT SELECT ON TABLE categories, medicines, suppliers, patients, doctors, batches TO pharmacist;
-- Pharmacists need full DML (Select, Insert, Update) on clinical scripts:
GRANT SELECT, INSERT, UPDATE ON TABLE prescriptions, prescription_items TO pharmacist;
-- Pharmacists need column-level SELECT on employees to check cashier shifts, but cannot read passwords or PINs:
GRANT SELECT (id, first_name, last_name, role, is_active) ON TABLE employees TO pharmacist;
-- Pharmacists can create checkout sales:
GRANT SELECT, INSERT ON TABLE sales, sale_items TO pharmacist;
-- Grant sequence controls:
GRANT USAGE, SELECT ON SEQUENCE prescriptions_id_seq, sales_id_seq, sale_items_id_seq TO pharmacist;

-- 3.4 Role: inventory_manager
-- Purpose: Control physical stock intakes, restock batches, adjust spoilages, and select suppliers.
--          Excluded from editing patient profiles, clinical prescriptions, or selling items.
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE categories, medicines, suppliers, batches, inventory_adjustments TO inventory_manager;
-- Inventory managers can read transaction stats to perform forecasting:
GRANT SELECT ON TABLE sales, sale_items, patients, doctors TO inventory_manager;
-- Grant sequence controls:
GRANT USAGE, SELECT ON SEQUENCE categories_id_seq, medicines_id_seq, suppliers_id_seq, batches_id_seq, inventory_adjustments_id_seq TO inventory_manager;

-- 3.5 Role: pharmacy_admin
-- Purpose: Superuser bypass role with full administrative privileges.
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO pharmacy_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO pharmacy_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO pharmacy_admin;

-- ============================================================================
-- 4. VERIFY POLICY RULES (Database Administrative Comments)
-- ============================================================================
COMMENT ON ROLE readonly_auditor IS 'Read-only access across all tables, views, and schemas';
COMMENT ON ROLE cashier IS 'Can view products, lookup patients, and register sales checkouts';
COMMENT ON ROLE pharmacist IS 'Can write clinical prescriptions, authorize refills, and checkout sales';
COMMENT ON ROLE inventory_manager IS 'Can restock batches, adjust stock levels, and register supplier catalogs';
COMMENT ON ROLE pharmacy_admin IS 'Full schema owner with administrative privileges';
