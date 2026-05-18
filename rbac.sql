-- ============================================================================
-- PROJECT: Small Pharmacy Inventory & Prescription System (COMP2082 Final Project)
-- FILE: rbac.sql
-- DESCRIPTION: Role-Based Access Control (RBAC) and Row-Level Security (RLS).
-- ============================================================================

-- Clean up existing roles (ignoring warnings if they do not exist)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'role_pharmacist') THEN
        REVOKE ALL ON ALL TABLES IN SCHEMA public FROM role_pharmacist;
        DROP ROLE role_pharmacist;
    END IF;
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'role_manager') THEN
        REVOKE ALL ON ALL TABLES IN SCHEMA public FROM role_manager;
        DROP ROLE role_manager;
    END IF;
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'role_admin') THEN
        REVOKE ALL ON ALL TABLES IN SCHEMA public FROM role_admin;
        DROP ROLE role_admin;
    END IF;
END
$$;

-- ============================================================================
-- 1. ROLE DEFINITIONS
-- ============================================================================

-- Create Roles with specific login and capability configurations
CREATE ROLE role_pharmacist WITH NOLOGIN;
CREATE ROLE role_manager WITH NOLOGIN;
CREATE ROLE role_admin WITH NOLOGIN;

-- ============================================================================
-- 2. PRIVILEGE GRANTS
-- ============================================================================

-- 2.1 General Schema Read Rights
GRANT USAGE ON SCHEMA public TO role_pharmacist, role_manager, role_admin;

-- 2.2 Pharmacist Privileges (Limited to Sales and Prescription Validation)
-- Pharmacists need to view stock, patients, and prescriptions, and register checkouts.
GRANT SELECT ON categories, medicines, suppliers, patients, doctors, batches TO role_pharmacist;
GRANT SELECT, INSERT, UPDATE ON prescriptions, prescription_items TO role_pharmacist;
GRANT SELECT, INSERT ON sales, sale_items TO role_pharmacist;
GRANT SELECT ON v_active_inventory TO role_pharmacist;

-- Grant sequence usage to allow inserting records
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO role_pharmacist;

-- 2.3 Manager Privileges (Full Inventory Control and Adjustments)
-- Managers handle inventory intake, adjust stocks, add suppliers, and read analytics.
GRANT SELECT, INSERT, UPDATE ON categories, medicines, suppliers, batches TO role_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON patients, doctors, prescriptions, prescription_items TO role_manager;
GRANT SELECT, INSERT, UPDATE ON sales, sale_items TO role_manager;
GRANT SELECT, INSERT ON inventory_adjustments TO role_manager;
GRANT SELECT ON v_active_inventory, v_expired_or_near_expiry, v_sales_dashboard TO role_manager;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO role_manager;

-- 2.4 Admin Privileges (Full Superuser Control)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO role_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO role_admin;


-- ============================================================================
-- 3. ROW-LEVEL SECURITY (RLS) ON SENSITIVE EMPLOYEE DATA
-- ============================================================================

-- Enable RLS on the employees table to protect Personal PIN/INN and password hashes.
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- Policy 1: Employees can view their own record when authenticated
-- Matches the active database username with the employees.username column
CREATE POLICY employee_self_select ON employees
    FOR SELECT
    TO role_pharmacist
    USING (username = CURRENT_USER);

-- Policy 2: Managers can view and search all employees (for scheduling/auditing)
CREATE POLICY employee_manager_all ON employees
    FOR ALL
    TO role_manager
    USING (TRUE);

-- Policy 3: Administrators have unrestricted bypass access to the employees table
CREATE POLICY employee_admin_all ON employees
    FOR ALL
    TO role_admin
    USING (TRUE);
