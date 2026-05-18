-- ============================================================================
-- PROJECT: Small Pharmacy Inventory & Prescription System (COMP2082 Final Project)
-- FILE: 04_queries.sql
-- DESCRIPTION: 15 Advanced Analytical Queries for Business Intelligence.
-- SYNTAX: PostgreSQL 15+ Standard
-- ============================================================================

-- ============================================================================
-- QUERY 1: Monthly Sales Revenue, VAT, and Discount Analytics
-- PURPOSE: Summarize monthly financial performance (Gross, VAT, Net, Discounts)
--          to analyze growth trends and tax collections over time.
-- SQL CONCEPTS: Common Table Expressions (CTEs), Aggregate Functions (SUM, COUNT),
--               Date Formatting (TO_CHAR), Grouping, and Ordering.
-- ============================================================================
WITH monthly_metrics AS (
    SELECT 
        TO_CHAR(sale_timestamp, 'YYYY-MM') AS sale_month,
        COUNT(id) AS total_transactions,
        SUM(total_gross) AS gross_sales,
        SUM(tax_amount) AS vat_collected,
        SUM(discount_amount) AS discounts_given,
        SUM(total_net) AS net_revenue
    FROM sales
    GROUP BY TO_CHAR(sale_timestamp, 'YYYY-MM')
)
SELECT 
    sale_month,
    total_transactions,
    gross_sales AS gross_sales_kgs,
    vat_collected AS vat_collected_kgs,
    discounts_given AS discounts_given_kgs,
    net_revenue AS net_revenue_kgs,
    ROUND((vat_collected / NULLIF(gross_sales, 0)) * 100, 2) AS effective_tax_rate_percent
FROM monthly_metrics
ORDER BY sale_month DESC;


-- ============================================================================
-- QUERY 2: Top 10 Best-Selling Medicines by Volume and Net Profit
-- PURPOSE: Identify which pharmaceutical products generate the highest unit volume
--          and net profit margins to optimize stock levels and shelf layout.
-- SQL CONCEPTS: Multi-Table INNER JOINs, Aggregate Math, Aliasing,
--               Grouping, Sorting, and Result Limits.
-- ============================================================================
SELECT 
    m.trade_name,
    m.generic_name,
    c.name AS therapeutic_category,
    SUM(si.quantity) AS total_units_sold,
    SUM(si.subtotal) AS gross_revenue_kgs,
    SUM(si.quantity * b.purchase_price) AS cost_of_goods_sold_kgs,
    SUM(si.subtotal) - SUM(si.quantity * b.purchase_price) AS net_profit_kgs,
    ROUND(((SUM(si.subtotal) - SUM(si.quantity * b.purchase_price)) / NULLIF(SUM(si.subtotal), 0)) * 100, 2) AS profit_margin_percent
FROM sale_items si
JOIN batches b ON si.batch_id = b.id
JOIN medicines m ON b.medicine_id = m.id
JOIN categories c ON m.category_id = c.id
GROUP BY m.id, m.trade_name, m.generic_name, c.name
ORDER BY net_profit_kgs DESC
LIMIT 10;


-- ============================================================================
-- QUERY 3: Low Stock Alerts and Reorder Status
-- PURPOSE: Identify medicines where total stock across all active batches falls
--          below a critical threshold (50 units) and calculate reorder sizes.
-- SQL CONCEPTS: SUM Aggregation, Grouping, CASE WHEN Conditional Logic,
--               COALESCE Handling, and HAVING Filtering.
-- ============================================================================
SELECT 
    m.id AS medicine_id,
    m.trade_name,
    m.generic_name,
    COALESCE(SUM(b.current_quantity), 0) AS total_units_in_stock,
    COUNT(CASE WHEN b.current_quantity > 0 THEN 1 END) AS active_undepleted_batches,
    CASE 
        WHEN COALESCE(SUM(b.current_quantity), 0) = 0 THEN 'CRITICAL: OUT OF STOCK'
        WHEN COALESCE(SUM(b.current_quantity), 0) < 20 THEN 'HIGH ALERT: REORDER NOW'
        ELSE 'ALERT: LOW STOCK'
    END AS stock_status,
    (150 - COALESCE(SUM(b.current_quantity), 0)) AS recommended_reorder_qty
FROM medicines m
LEFT JOIN batches b ON m.id = b.medicine_id AND b.expiry_date > CURRENT_DATE
GROUP BY m.id, m.trade_name, m.generic_name
HAVING COALESCE(SUM(b.current_quantity), 0) < 50
ORDER BY total_units_in_stock ASC;


-- ============================================================================
-- QUERY 4: Soon-to-Expire Inventory Dead-Stock Risk Forecast
-- PURPOSE: Audit batches expiring within 90 days to implement markdown clearances
--          and prevent total loss on expiring assets.
-- SQL CONCEPTS: Date Comparisons, Intervals, Aggregate Calculations,
--               Conditional String Tiers, and Multi-Table Joins.
-- ============================================================================
SELECT 
    b.batch_number,
    m.trade_name,
    s.name AS supplier_name,
    b.current_quantity,
    b.expiry_date,
    b.expiry_date - CURRENT_DATE AS days_until_expiry,
    CASE 
        WHEN b.expiry_date <= CURRENT_DATE THEN 'DEAD STOCK: EXPIRED'
        WHEN b.expiry_date - CURRENT_DATE <= 30 THEN 'CRITICAL RISK: EXPIRES < 30 DAYS'
        ELSE 'MODERATE RISK: EXPIRES < 90 DAYS'
    END AS risk_classification,
    (b.current_quantity * b.purchase_price) AS wholesale_cost_tied_up_kgs,
    (b.current_quantity * b.selling_price) AS potential_retail_loss_kgs
FROM batches b
JOIN medicines m ON b.medicine_id = m.id
JOIN suppliers s ON b.supplier_id = s.id
WHERE b.current_quantity > 0 
  AND b.expiry_date <= (CURRENT_DATE + INTERVAL '90 days')
ORDER BY b.expiry_date ASC;


-- ============================================================================
-- QUERY 5: Supplier Product Variety and Wholesale Contribution Index
-- PURPOSE: Find suppliers providing the widest therapeutic variety and calculate
--          our cumulative wholesale acquisition spending with them.
-- SQL CONCEPTS: COUNT(DISTINCT) Unique tallies, SUM Aggregations, Grouping,
--               HAVING filter, and Multi-Table Joins.
-- ============================================================================
SELECT 
    s.id AS supplier_id,
    s.name AS supplier_name,
    s.phone AS supplier_phone,
    COUNT(DISTINCT m.id) AS unique_medicines_supplied,
    COUNT(DISTINCT m.category_id) AS distinct_therapeutic_categories,
    SUM(b.initial_quantity * b.purchase_price) AS total_wholesale_spending_kgs,
    ROUND(AVG(b.purchase_price), 2) AS average_item_cost_kgs
FROM suppliers s
JOIN batches b ON s.id = b.supplier_id
JOIN medicines m ON b.medicine_id = m.id
GROUP BY s.id, s.name, s.phone
HAVING COUNT(DISTINCT m.id) > 2
ORDER BY unique_medicines_supplied DESC;


-- ============================================================================
-- QUERY 6: Patients with the Highest Volume of Issued Prescriptions
-- PURPOSE: Identify chronic patients relying heavily on prescription medicines
--          to establish wellness programs and coordinate repeat checkouts.
-- SQL CONCEPTS: Multi-Table JOINs (Patients, Prescriptions, items), Count,
--               Sum Aggregations, Grouping, and Ordering.
-- ============================================================================
SELECT 
    p.id AS patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.pin_inn AS patient_pin,
    COUNT(DISTINCT r.id) AS total_prescriptions_written,
    COUNT(ri.medicine_id) AS total_individual_drugs_prescribed,
    SUM(ri.prescribed_qty) AS cumulative_units_prescribed,
    SUM(ri.dispensed_qty) AS cumulative_units_dispensed,
    ROUND((SUM(ri.dispensed_qty)::numeric / NULLIF(SUM(ri.prescribed_qty), 0)) * 100, 2) AS fulfillment_rate_percent
FROM patients p
JOIN prescriptions r ON p.id = r.patient_id
JOIN prescription_items ri ON r.id = ri.prescription_id
GROUP BY p.id, p.first_name, p.last_name, p.pin_inn
ORDER BY total_prescriptions_written DESC
LIMIT 10;


-- ============================================================================
-- QUERY 7: Dead Stock Audit - Medicines Never Sold
-- PURPOSE: Identify completely inactive medicines that have never recorded a single
--          sale to discontinue ordering them and reclaim shelf space.
-- SQL CONCEPTS: NOT EXISTS Correlated Subquery, LEFT JOIN Anti-Pattern,
--               and View Reference.
-- ============================================================================
SELECT 
    m.id AS medicine_id,
    m.trade_name,
    m.generic_name,
    c.name AS category_name,
    m.prescription_required
FROM medicines m
JOIN categories c ON m.category_id = c.id
WHERE NOT EXISTS (
    SELECT 1 
    FROM sale_items si
    JOIN batches b ON si.batch_id = b.id
    WHERE b.medicine_id = m.id
)
ORDER BY c.name, m.trade_name;


-- ============================================================================
-- QUERY 8: Average Prescribed and Dispensed Financial Value of Prescriptions
-- PURPOSE: Determine the average monetary value of prescriptions written compared
--          to what patients actually chose to buy (dispensed value).
-- SQL CONCEPTS: Layered Common Table Expressions (CTEs), Subtotals,
--               Average aggregate functions.
-- ============================================================================
WITH rx_monetary_values AS (
    SELECT 
        ri.prescription_id,
        -- Calculate retail value of prescribed amounts based on current batch price
        SUM(ri.prescribed_qty * b.selling_price) AS prescribed_value_kgs,
        -- Calculate actual retail value of what has been dispensed so far
        SUM(ri.dispensed_qty * b.selling_price) AS dispensed_value_kgs
    FROM prescription_items ri
    JOIN medicines m ON ri.medicine_id = m.id
    -- Join onto active batch to get current shelf rate
    LEFT JOIN LATERAL (
        SELECT selling_price FROM batches 
        WHERE medicine_id = m.id 
        ORDER BY expiry_date DESC LIMIT 1
    ) b ON TRUE
    GROUP BY ri.prescription_id
)
SELECT 
    COUNT(prescription_id) AS total_prescriptions_audited,
    ROUND(AVG(prescribed_value_kgs), 2) AS average_written_value_kgs,
    ROUND(AVG(dispensed_value_kgs), 2) AS average_dispensed_revenue_kgs,
    ROUND(AVG(prescribed_value_kgs - dispensed_value_kgs), 2) AS average_unclaimed_loss_kgs,
    ROUND((AVG(dispensed_value_kgs) / NULLIF(AVG(prescribed_value_kgs), 0)) * 100, 2) AS average_conversion_rate_percent
FROM rx_monetary_values;


-- ============================================================================
-- QUERY 9: Peak Sales Hour and Day Analysis
-- PURPOSE: Analyze transaction volume by hour and day of week to optimize
--          pharmacist scheduling and cash drawer pickups.
-- SQL CONCEPTS: Date Extractions (EXTRACT DOW and HOUR), COUNT aggregates,
--               Groupings, and Double-Sort ordering.
-- ============================================================================
SELECT 
    CASE EXTRACT(ISODOW FROM sale_timestamp)
        WHEN 1 THEN 'Monday (Дүйшөмбү)'
        WHEN 2 THEN 'Tuesday (Шейшемби)'
        WHEN 3 THEN 'Wednesday (Шаршемби)'
        WHEN 4 THEN 'Thursday (Бейшемби)'
        WHEN 5 THEN 'Friday (Жума)'
        WHEN 6 THEN 'Saturday (Ишемби)'
        WHEN 7 THEN 'Sunday (Жекшемби)'
    END AS day_of_week,
    EXTRACT(HOUR FROM sale_timestamp) AS hour_of_day,
    COUNT(id) AS total_transactions,
    ROUND(SUM(total_net), 2) AS net_revenue_kgs,
    ROUND(AVG(total_net), 2) AS average_ticket_kgs
FROM sales
GROUP BY EXTRACT(ISODOW FROM sale_timestamp), EXTRACT(HOUR FROM sale_timestamp)
ORDER BY total_transactions DESC, hour_of_day ASC
LIMIT 12;


-- ============================================================================
-- QUERY 10: Running Total of Revenue and Cashier Checkout Contribution Share
-- PURPOSE: Track daily cumulative net revenue chronologically and evaluate
--          each cashier's performance share relative to company totals.
-- SQL CONCEPTS: Window Aggregate Functions (SUM() OVER), Running partition overlays,
--               Transaction timestamps, and percentages.
-- ============================================================================
SELECT 
    s.id AS sale_id,
    s.sale_timestamp,
    e.first_name || ' ' || e.last_name AS pharmacist_name,
    s.total_net AS sale_net_kgs,
    -- Running total across all historical time
    ROUND(SUM(s.total_net) OVER (ORDER BY s.sale_timestamp ASC), 2) AS cumulative_running_total_kgs,
    -- running total partitioned by individual cashier
    ROUND(SUM(s.total_net) OVER (PARTITION BY e.id ORDER BY s.sale_timestamp ASC), 2) AS cashier_running_total_kgs,
    -- Pharmacist percentage contribution relative to gross company revenues
    ROUND((s.total_net / NULLIF(SUM(s.total_net) OVER (), 0)) * 100, 4) AS percentage_of_company_total
FROM sales s
JOIN employees e ON s.employee_id = e.id
ORDER BY s.sale_timestamp ASC
LIMIT 15;


-- ============================================================================
-- QUERY 11: Dense Ranking of Medicines Within Categories by Unit Sales
-- PURPOSE: Rank products within their therapeutic categories to pinpoint bestsellers
--          and underperformers in each drug class.
-- SQL CONCEPTS: Window Ranking Functions (DENSE_RANK() OVER), Partition overlays,
--               CTEs, Multi-Table Joins, and aggregations.
-- ============================================================================
WITH category_sales AS (
    SELECT 
        c.name AS category_name,
        m.trade_name,
        m.generic_name,
        SUM(si.quantity) AS units_sold,
        SUM(si.subtotal) AS net_revenue
    FROM sale_items si
    JOIN batches b ON si.batch_id = b.id
    JOIN medicines m ON b.medicine_id = m.id
    JOIN categories c ON m.category_id = c.id
    GROUP BY c.name, m.trade_name, m.generic_name
)
SELECT 
    category_name,
    trade_name,
    generic_name,
    units_sold,
    net_revenue AS net_revenue_kgs,
    DENSE_RANK() OVER (PARTITION BY category_name ORDER BY units_sold DESC) AS ranking_in_category
FROM category_sales
ORDER BY category_name ASC, ranking_in_category ASC;


-- ============================================================================
-- QUERY 12: Super-Prescribers - Doctors Writing High Volumes of Prescriptions
-- PURPOSE: Identify doctors who write the most clinical scripts to establish
--          pharmacy relationship outreach and coordinate inventory supplies.
-- SQL CONCEPTS: JOINs, Count Aggregations, Grouping, HAVING filters,
--               and Sorting.
-- ============================================================================
SELECT 
    d.id AS doctor_id,
    d.first_name || ' ' || d.last_name AS doctor_name,
    d.clinic_name,
    d.phone AS doctor_phone,
    COUNT(r.id) AS total_prescriptions_issued,
    COUNT(CASE WHEN r.status = 'filled' THEN 1 END) AS fully_completed_prescriptions,
    COUNT(CASE WHEN r.status = 'expired' THEN 1 END) AS expired_unclaimed_prescriptions,
    ROUND((COUNT(CASE WHEN r.status = 'filled' THEN 1 END)::numeric / COUNT(r.id)) * 100, 2) AS completion_rate_percent
FROM doctors d
JOIN prescriptions r ON d.id = r.doctor_id
GROUP BY d.id, d.first_name, d.last_name, d.clinic_name, d.phone
HAVING COUNT(r.id) >= 5
ORDER BY total_prescriptions_issued DESC;


-- ============================================================================
-- QUERY 13: Over-The-Counter (OTC) vs. Prescription Sales Revenue Split
-- PURPOSE: Calculate the net financial share of OTC checkouts versus prescription-
--          linked drug checkouts to evaluate business dependency.
-- SQL CONCEPTS: Subqueries, Conditional aggregation sums, Ratio and percentage math.
-- ============================================================================
SELECT 
    COUNT(id) AS total_receipts,
    SUM(CASE WHEN prescription_id IS NOT NULL THEN 1 ELSE 0 END) AS prescription_sale_count,
    SUM(CASE WHEN prescription_id IS NULL THEN 1 ELSE 0 END) AS otc_sale_count,
    
    ROUND(SUM(CASE WHEN prescription_id IS NOT NULL THEN total_net ELSE 0 END), 2) AS rx_revenue_kgs,
    ROUND(SUM(CASE WHEN prescription_id IS NULL THEN total_net ELSE 0 END), 2) AS otc_revenue_kgs,
    
    ROUND((SUM(CASE WHEN prescription_id IS NOT NULL THEN total_net ELSE 0 END) / SUM(total_net)) * 100, 2) AS rx_revenue_share_percent,
    ROUND((SUM(CASE WHEN prescription_id IS NULL THEN total_net ELSE 0 END) / SUM(total_net)) * 100, 2) AS otc_revenue_share_percent
FROM sales;


-- ============================================================================
-- QUERY 14: Comprehensive Active Inventory Batch Listing (Using View)
-- PURPOSE: Query the active inventory view for live checkout searches,
--          cross-referencing categories and stock flags.
-- SQL CONCEPTS: VIEW selection, Nested ordering, Where clauses.
-- ============================================================================
SELECT 
    trade_name,
    generic_name,
    nearest_expiry_date,
    total_available_stock AS items_on_shelf,
    min_selling_price_kgs AS shelf_price_kgs,
    prescription_required
FROM v_active_inventory
WHERE total_available_stock > 10
ORDER BY trade_name ASC, nearest_expiry_date ASC;


-- ============================================================================
-- QUERY 15: Inventory Waste and Adjustment Loss Summary
-- PURPOSE: Quantify manual inventory adjustments (wastage, theft, breakage)
--          by type to calculate exact financial asset losses.
-- SQL CONCEPTS: CASE WHEN calculations, JOINs (batches, medicines), Sums,
--               Groupings, and sorting.
-- ============================================================================
SELECT 
    ia.adjustment_type,
    COUNT(ia.id) AS total_adjustment_events,
    SUM(CASE WHEN ia.quantity < 0 THEN ia.quantity ELSE 0 END) AS units_removed,
    SUM(CASE WHEN ia.quantity > 0 THEN ia.quantity ELSE 0 END) AS units_added,
    SUM(ia.quantity) AS net_unit_change,
    -- Financial audit value based on wholesale purchase cost
    ROUND(SUM(ABS(ia.quantity) * b.purchase_price), 2) AS gross_audit_impact_kgs,
    ROUND(SUM(ia.quantity * b.purchase_price), 2) AS net_financial_impact_kgs
FROM inventory_adjustments ia
JOIN batches b ON ia.batch_id = b.id
GROUP BY ia.adjustment_type
ORDER BY net_financial_impact_kgs ASC;
