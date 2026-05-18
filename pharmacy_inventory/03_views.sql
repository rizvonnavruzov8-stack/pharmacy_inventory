-- ============================================================================
-- PROJECT: Small Pharmacy Inventory & Prescription System (COMP2082 Final Project)
-- FILE: 03_views.sql
-- DESCRIPTION: High-Value Analytics and Auditing Views.
-- SYNTAX: PostgreSQL 15+ Standard
-- ============================================================================

-- Clean up existing views in reverse dependency order
DROP VIEW IF EXISTS v_supplier_medicine_summary CASCADE;
DROP VIEW IF EXISTS v_patient_prescription_history CASCADE;
DROP VIEW IF EXISTS v_pharmacy_sales_summary CASCADE;
DROP VIEW IF EXISTS v_expiring_medicines CASCADE;
DROP VIEW IF EXISTS v_low_stock_medicines CASCADE;

-- ============================================================================
-- 1. VIEW: v_low_stock_medicines
-- PURPOSE: Real-time dashboard for inventory managers showing medicines that
--          fall below a critical threshold (50 units) across active unexpired batches.
-- ============================================================================
CREATE VIEW v_low_stock_medicines AS
SELECT 
    m.id AS medicine_id,
    m.trade_name,
    m.generic_name,
    c.name AS category_name,
    COALESCE(SUM(b.current_quantity), 0) AS total_units_available,
    COUNT(CASE WHEN b.current_quantity > 0 THEN 1 END) AS active_batches_count,
    CASE 
        WHEN COALESCE(SUM(b.current_quantity), 0) = 0 THEN 'OUT OF STOCK'
        WHEN COALESCE(SUM(b.current_quantity), 0) < 20 THEN 'CRITICAL STOCK'
        ELSE 'LOW STOCK'
    END AS stock_status_alert,
    (150 - COALESCE(SUM(b.current_quantity), 0)) AS suggested_restock_amount
FROM medicines m
JOIN categories c ON m.category_id = c.id
LEFT JOIN batches b ON m.id = b.medicine_id AND b.expiry_date > CURRENT_DATE
GROUP BY m.id, m.trade_name, m.generic_name, c.name;

COMMENT ON VIEW v_low_stock_medicines IS 'Real-time alert tracker for depleted and low-stock pharmaceuticals';

-- ============================================================================
-- 2. VIEW: v_expiring_medicines
-- PURPOSE: Auditing dashboard displaying batches expiring within 90 days
--          to calculate gross and net wholesale capital risk values.
-- ============================================================================
CREATE VIEW v_expiring_medicines AS
SELECT 
    b.id AS batch_id,
    b.batch_number,
    m.trade_name,
    m.generic_name,
    s.name AS supplier_name,
    b.current_quantity,
    b.expiry_date,
    b.expiry_date - CURRENT_DATE AS days_until_expiry,
    CASE 
        WHEN b.expiry_date <= CURRENT_DATE THEN 'EXPIRED'
        ELSE 'NEAR EXPIRY (CLEARANCE)'
    END AS life_cycle_state,
    ROUND(b.current_quantity * b.purchase_price, 2) AS tied_up_cost_kgs,
    ROUND(b.current_quantity * b.selling_price, 2) AS potential_retail_loss_kgs
FROM batches b
JOIN medicines m ON b.medicine_id = m.id
JOIN suppliers s ON b.supplier_id = s.id
WHERE b.current_quantity > 0 
  AND b.expiry_date <= (CURRENT_DATE + INTERVAL '90 days');

COMMENT ON VIEW v_expiring_medicines IS 'Risk management ledger detailing inventory assets close to expiration';

-- ============================================================================
-- 3. VIEW: v_pharmacy_sales_summary
-- PURPOSE: Business Intelligence monthly sales aggregate reporting gross, net,
--          VAT collections, and discount tallies.
-- ============================================================================
CREATE VIEW v_pharmacy_sales_summary AS
SELECT 
    TO_CHAR(s.sale_timestamp, 'YYYY-MM') AS sale_month,
    COUNT(s.id) AS total_receipts_issued,
    ROUND(SUM(s.total_gross), 2) AS total_gross_sales_kgs,
    ROUND(SUM(s.tax_amount), 2) AS standard_12pct_vat_collected_kgs,
    ROUND(SUM(s.discount_amount), 2) AS customer_discounts_granted_kgs,
    ROUND(SUM(s.total_net), 2) AS net_revenue_kgs,
    ROUND(AVG(s.total_net), 2) AS average_order_value_kgs,
    COUNT(DISTINCT s.prescription_id) AS linked_prescriptions_filled
FROM sales s
GROUP BY TO_CHAR(s.sale_timestamp, 'YYYY-MM');

COMMENT ON VIEW v_pharmacy_sales_summary IS 'Monthly business intelligence sales, tax, and discount aggregate dashboard';

-- ============================================================================
-- 4. VIEW: v_patient_prescription_history
-- PURPOSE: Clinical auditing history detailing what patients have been prescribed,
--          which doctor issued it, and cumulative dispensed amounts.
-- ============================================================================
CREATE VIEW v_patient_prescription_history AS
SELECT 
    p.id AS patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.pin_inn AS patient_pin,
    rx.serial_number AS rx_serial,
    rx.issue_date,
    rx.expiry_date,
    rx.status AS prescription_status,
    m.trade_name AS prescribed_medicine,
    rxi.prescribed_qty,
    rxi.dispensed_qty,
    rxi.prescribed_qty - rxi.dispensed_qty AS remaining_dispensation_limit,
    d.first_name || ' ' || d.last_name AS doctor_name,
    d.clinic_name AS issuing_clinic
FROM patients p
JOIN prescriptions rx ON p.id = rx.patient_id
JOIN prescription_items rxi ON rx.id = rxi.prescription_id
JOIN medicines m ON rxi.medicine_id = m.id
JOIN doctors d ON rx.doctor_id = d.id;

COMMENT ON VIEW v_patient_prescription_history IS 'Clinical safety audit trace linking patients, doctors, prescriptions, and inventory limits';

-- ============================================================================
-- 5. VIEW: v_supplier_medicine_summary
-- PURPOSE: Wholesale procurement dashboard indexing active supplier product variety,
--          average acquisition costs, and total stock provided.
-- ============================================================================
CREATE VIEW v_supplier_medicine_summary AS
SELECT 
    s.id AS supplier_id,
    s.name AS supplier_name,
    s.tin_inn AS supplier_tin,
    COUNT(DISTINCT b.medicine_id) AS unique_medicines_procured,
    COUNT(b.id) AS total_batches_provided,
    ROUND(AVG(b.purchase_price), 2) AS average_unit_cost_kgs,
    SUM(b.initial_quantity) AS cumulative_units_delivered_historical,
    SUM(b.current_quantity) AS current_units_remaining_shelf
FROM suppliers s
LEFT JOIN batches b ON s.id = b.supplier_id
GROUP BY s.id, s.name, s.tin_inn;

COMMENT ON VIEW v_supplier_medicine_summary IS 'Supplier index analyzing procurement volumes, catalog range, and cost averages';
