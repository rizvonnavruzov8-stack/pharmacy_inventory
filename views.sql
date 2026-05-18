-- ============================================================================
-- PROJECT: Small Pharmacy Inventory & Prescription System (COMP2082 Final Project)
-- FILE: views.sql
-- DESCRIPTION: High-Performance Database Views for Frontend and Analytics.
-- ============================================================================

DROP VIEW IF EXISTS v_sales_dashboard CASCADE;
DROP VIEW IF EXISTS v_expired_or_near_expiry CASCADE;
DROP VIEW IF EXISTS v_active_inventory CASCADE;

-- ============================================================================
-- 1. VIEW: v_active_inventory (Pharmacist Quick-Search Interface)
-- ============================================================================
-- Aggregates current available stock across all unexpired batches, providing 
-- prices and nearest expiry schedules in real-time.
CREATE OR REPLACE VIEW v_active_inventory AS
SELECT 
    m.id AS medicine_id,
    m.trade_name,
    m.generic_name,
    c.name AS category_name,
    m.prescription_required,
    SUM(b.current_quantity) AS total_available_stock,
    MIN(b.selling_price) AS min_selling_price_kgs,
    MAX(b.selling_price) AS max_selling_price_kgs,
    MIN(b.expiry_date) AS nearest_expiry_date,
    COUNT(b.id) AS active_batches_count
FROM medicines m
JOIN categories c ON m.category_id = c.id
LEFT JOIN batches b ON m.id = b.medicine_id 
    AND b.current_quantity > 0 
    AND b.expiry_date > CURRENT_DATE
WHERE m.is_active = TRUE
GROUP BY m.id, m.trade_name, m.generic_name, c.name, m.prescription_required;


-- ============================================================================
-- 2. VIEW: v_expired_or_near_expiry (Manager Inventory Warning System)
-- ============================================================================
-- Identifies batches that have expired or are set to expire within 90 days.
-- Enables managers to plan discount promotions or schedule supplier returns.
CREATE OR REPLACE VIEW v_expired_or_near_expiry AS
SELECT 
    b.id AS batch_id,
    m.trade_name,
    m.generic_name,
    b.batch_number,
    s.name AS supplier_name,
    b.current_quantity,
    b.expiry_date,
    b.expiry_date - CURRENT_DATE AS days_until_expiry,
    CASE 
        WHEN b.expiry_date <= CURRENT_DATE THEN 'EXPIRED'
        ELSE 'NEAR EXPIRY (90 days)'
    END AS status,
    b.purchase_price AS purchase_price_kgs,
    b.selling_price AS selling_price_kgs,
    (b.current_quantity * b.purchase_price) AS dead_stock_cost_kgs,
    (b.current_quantity * b.selling_price) AS potential_retail_loss_kgs
FROM batches b
JOIN medicines m ON b.medicine_id = m.id
JOIN suppliers s ON b.supplier_id = s.id
WHERE b.current_quantity > 0 
  AND b.expiry_date <= (CURRENT_DATE + INTERVAL '90 days')
ORDER BY b.expiry_date ASC;


-- ============================================================================
-- 3. VIEW: v_sales_dashboard (Management Analytics Dashboard)
-- ============================================================================
-- Combines transaction records, sales items, VAT tax metrics, and patient details
-- into a single source of truth for business intelligence reports.
CREATE OR REPLACE VIEW v_sales_dashboard AS
SELECT 
    s.id AS sale_id,
    s.sale_timestamp,
    e.username AS processed_by_employee,
    e.role AS employee_role,
    s.payment_method,
    COUNT(si.id) AS total_unique_items,
    SUM(si.quantity) AS total_units_sold,
    s.total_gross AS gross_amount_kgs,
    s.discount_amount AS discount_amount_kgs,
    s.tax_amount AS vat_12_percent_kgs,
    s.total_net AS net_revenue_kgs,
    p.pin_inn AS patient_pin_inn,
    p.first_name || ' ' || p.last_name AS patient_name,
    rx.serial_number AS rx_serial_number,
    rx.status AS rx_status
FROM sales s
JOIN employees e ON s.employee_id = e.id
LEFT JOIN sale_items si ON s.id = si.sale_id
LEFT JOIN prescriptions rx ON s.prescription_id = rx.id
LEFT JOIN patients p ON rx.patient_id = p.id
GROUP BY s.id, s.sale_timestamp, e.username, e.role, s.payment_method, 
         s.total_gross, s.discount_amount, s.tax_amount, s.total_net, 
         p.pin_inn, p.first_name, p.last_name, rx.serial_number, rx.status;
