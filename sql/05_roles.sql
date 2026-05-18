
DO $$
BEGIN
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

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

CREATE ROLE pharmacy_admin WITH NOLOGIN;
CREATE ROLE pharmacist WITH NOLOGIN;
CREATE ROLE cashier WITH NOLOGIN;
CREATE ROLE inventory_manager WITH NOLOGIN;
CREATE ROLE readonly_auditor WITH NOLOGIN;

GRANT USAGE ON SCHEMA public TO pharmacy_admin, pharmacist, cashier, inventory_manager, readonly_auditor;


GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_auditor;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO readonly_auditor;

GRANT SELECT ON TABLE categories, medicines, patients, doctors, prescriptions, prescription_items TO cashier;
GRANT SELECT, UPDATE (current_quantity) ON TABLE batches TO cashier;
GRANT SELECT, INSERT ON TABLE sales, sale_items TO cashier;
GRANT USAGE, SELECT ON SEQUENCE sales_id_seq, sale_items_id_seq TO cashier;

GRANT SELECT ON TABLE categories, medicines, suppliers, patients, doctors, batches TO pharmacist;
GRANT SELECT, INSERT, UPDATE ON TABLE prescriptions, prescription_items TO pharmacist;
GRANT SELECT (id, first_name, last_name, role, is_active) ON TABLE employees TO pharmacist;
GRANT SELECT, INSERT ON TABLE sales, sale_items TO pharmacist;
GRANT USAGE, SELECT ON SEQUENCE prescriptions_id_seq, sales_id_seq, sale_items_id_seq TO pharmacist;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE categories, medicines, suppliers, batches, inventory_adjustments TO inventory_manager;
GRANT SELECT ON TABLE sales, sale_items, patients, doctors TO inventory_manager;
GRANT USAGE, SELECT ON SEQUENCE categories_id_seq, medicines_id_seq, suppliers_id_seq, batches_id_seq, inventory_adjustments_id_seq TO inventory_manager;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO pharmacy_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO pharmacy_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO pharmacy_admin;

COMMENT ON ROLE readonly_auditor IS 'Read-only access across all tables, views, and schemas';
COMMENT ON ROLE cashier IS 'Can view products, lookup patients, and register sales checkouts';
COMMENT ON ROLE pharmacist IS 'Can write clinical prescriptions, authorize refills, and checkout sales';
COMMENT ON ROLE inventory_manager IS 'Can restock batches, adjust stock levels, and register supplier catalogs';
COMMENT ON ROLE pharmacy_admin IS 'Full schema owner with administrative privileges';
