# Kyrgyzstan-Based Seed Data Strategy & Analytics Specification

This document defines the comprehensive **Seed Data Strategy and Analytical Framework** for the Small Pharmacy Inventory & Prescription System in Kyrgyzstan. It is designed to satisfy university realism requirements for **COMP2082** by replacing random placeholders with high-fidelity, country-specific datasets, realistic transaction distributions, and meaningful business intelligence queries.

---

## 🗺️ 1. Kyrgyzstan Local Context Integration

To achieve absolute realism, our data generation maps directly to the regulatory, cultural, and financial norms of the Kyrgyz Republic:

1.  **Base Currency**: All prices are modeled in **Kyrgyz Som (KGS)**. Wholesale buying costs and retail selling prices are kept realistic (e.g., standard generic pain relievers cost around 20–100 KGS, imported advanced antibiotics or chronic disease therapies cost 150–800 KGS).
2.  **14-Digit PIN/INN (ПИН/ИНН)**: Citizen personal identifiers on Kyrgyz passports are strictly validated via regular expression `^[12]\d{13}$`. They follow authentic distributions:
    -   Starts with `2` for males, `1` for females.
    -   Digits 2–7 represent the Date of Birth (DDMMYY).
    -   Remaining digits contain century markers and unique sequence numbers.
    -   *Example*: Patient Azamat born on October 12, 1985 has a PIN of `21210198500234`.
3.  **Local Mobile QR Payments**: In Kyrgyzstan, cashless payments are dominated by mobile QR channels (primarily **MBank**, **Elcart**, **O!Money**). The `payment_method` enum specifically includes `mobile_qr` to mirror local merchant behavior.
4.  **Regional Geography**: Doctors, suppliers, and patients are distributed across primary Kyrgyz administrative centers:
    -   **Bishkek** (Chuy Region - Capital City)
    -   **Osh** (Osh Region - Southern Capital)
    -   **Jalal-Abad** (Jalal-Abad Region - Agricultural/Industrial hub)
    -   **Tokmok** (Chuy Valley)
    -   **Karakol** (Issyk-Kul Region)
    -   **Naryn** (High-altitude Mountainous Region)

---

## 📈 2. Data Distributions & Row Counts

For a realistic university presentation, the database represents a small-to-medium retail pharmacy operating for a period of **6 months**. The targeted table row counts are defined as follows:

```
[categories] 8 rows
[suppliers]  5 rows
[doctors]    15 rows
[employees]  6 rows
[patients]   80 rows
[medicines]  24 rows
[batches]    45 batches (active, unexpired, and expired)
[prescriptions] 60 records
[prescription_items] 120 line items
[sales]      180 transactions (OTC and prescription checkouts)
[sale_items] 380 invoice line items
[inventory_adjustments] 12 audit entries
```

### Realistic Distributions
-   **Patient Cohort**: Divided into young adults (Vitamins/Painkillers, 40%), pediatric parents (Antibiotics, 30%), and senior citizens (Hypertension/Cardiovascular therapies, 30%).
-   **Seasonal Sales Activity**: Recreates Kyrgyzstan seasonal trends:
    -   **Winter Flu Spikes (Nov–Feb)**: Antibiotics (Amoxicillin, Ceftriaxone) and Vitamin C represent 65% of sales.
    -   **Year-Round Constant**: Cardiovascular drugs (Enalapril, Bisoprolol) and pain relievers (Ketonal, Analgin) remain flat.
-   **Prescription Frequency**: Mapped at 40% of sales. Pharmacists cannot bypass the database trigger: prescription-only medicines force the presence of a valid `prescription_id`.
-   **Batch Expiry Profile**: 
    -   75% active, unexpired batches.
    -   15% near-expiry batches (expiring in 30–90 days, flagged for clearance discounts).
    -   10% expired batches (preserved in inventory with positive quantities to test system blockade triggers).

---

## 🛠️ 3. Seed Generation Strategy (Hand-Crafted vs. Algorithmic)

To save database memory while maximizing visual presentation, we employ a mixed-generation strategy:

```
+------------------------+-------------------+-----------------------------------------+
| Table Name             | Generation Type   | Rationale                               |
+------------------------+-------------------+-----------------------------------------+
| categories             | Hand-Crafted      | Ensures clean recursive self-references  |
| suppliers              | Hand-Crafted      | Validates exact Kyrgyz corporate INNs   |
| doctors                | AI/Hand-Crafted   | Authentic clinical names and clinics    |
| employees              | Hand-Crafted      | Fixed logins for role testing (RBAC)    |
| medicines              | Hand-Crafted      | Accurate generic vs. brand associations |
| batches                | Hand-Crafted      | Controlled dates to test trigger rules  |
| patients               | Algorithmic/Faker | High-volume directory with custom PINs  |
| prescriptions          | Algorithmic/Faker | Correctly mapped junction matches       |
| sales & sale_items     | Algorithmic/Faker | High-volume invoice logs over 6 months  |
| adjustments            | Hand-Crafted      | Audit-trail anomalies (spoilage/theft)  |
+------------------------+-------------------+-----------------------------------------+
```

---

## 📦 4. Baseline Reference Catalogs ( Kyrgyzstan Customized)

These master data catalogs are pre-designed for immediate seeding:

### 4.1 Medicine Category Tree (Recursive Self-Reference)
-   **Systemic Anti-infectives (Antibiotics)** [Parent: NULL]
    -   *Penicillins* [Parent: Anti-infectives]
    -   *Cephalosporins* [Parent: Anti-infectives]
-   **Cardiovascular System** [Parent: NULL]
    -   *ACE Inhibitors* [Parent: Cardiovascular]
    -   *Beta-blocking Agents* [Parent: Cardiovascular]
-   **Analgesics & Pain Relievers** [Parent: NULL]
    -   *Non-Steroidal Anti-Inflammatory Drugs (NSAIDs)* [Parent: Analgesics]
-   **Vitamins & Minerals** [Parent: NULL]

### 4.2 Supplier Companies
1.  **ОсОО Неман-Фарм (Neman-Pharm)**
    -   *TIN/INN*: `01203200510123` (Kyrgyz corporate INN)
    -   *Location*: Bishkek, Gorky Str 1A
2.  **ОсОО Еврофарм (Europharm)**
    -   *TIN/INN*: `00908199710111`
    -   *Location*: Osh, Kurmanjan Datka 22
3.  **ОсОО Фармамир (Farmamir)**
    -   *TIN/INN*: `02511201010199`
    -   *Location*: Jalal-Abad, Lenin Str 85

### 4.3 Doctor Specializations & Bishkek Clinics
1.  **Cardiologist**: Dr. Ulan Saparov — *National Hospital of the Kyrgyz Republic* (Bishkek)
2.  **Pediatrician**: Dr. Elena Petrova — *Miras Clinic* (Bishkek)
3.  **General Practitioner**: Dr. Bakyt Temirov — *City Hospital No. 1* (Osh)
4.  **Endocrinologist**: Dr. Kanykei Asanova — *Naryn Regional Hospital* (Naryn)

---

## ⚡ 5. Realistic Edge Cases to Include

To make the database testing highly robust, the seed data contains several custom-designed anomalies:

1.  **The Expired Batch**: Batch `AMX-2023-09` of Amoxicillin has an expiry date set in 2025. It contains a stock of 12 units. This batch remains in the database to verify that our trigger prevents sales of expired drugs.
2.  **The Depleted Stock**: A batch of Ketonal Duo has `current_quantity = 0`, verifying that the inventory engine handles stock-outs correctly.
3.  **The Expired Prescription**: An expired prescription (`RX-44219-KG`) written for Ceftriaxone, proving that the checkout trigger blocks sales on stale prescriptions.
4.  **The Overrun Adjustment**: An entry in `inventory_adjustments` where a pharmacist accidentally inputs a breakage quantity that exceeds the current batch inventory, which is rejected by the database's check constraints.
5.  **The Near-Expiry Clearance**: A batch of Ascorbic Acid expiring in 45 days, marked down in price to allow clearance sales.

---

## 📊 6. Critical Business Intelligence Queries

Once seeded, the database is designed to support high-performance analytical queries for pharmacy operations:

### Query 1: Dead-Stock Expiration & Risk Forecast
**Business Goal**: Identify batches that are either expired or expiring within 90 days, calculating the wholesale money tied up ("dead-stock value") and potential retail loss.
```sql
SELECT 
    b.batch_number,
    m.trade_name,
    s.name AS supplier_name,
    b.current_quantity,
    b.expiry_date,
    b.expiry_date - CURRENT_DATE AS days_until_expiry,
    CASE 
        WHEN b.expiry_date <= CURRENT_DATE THEN 'EXPIRED'
        ELSE 'NEAR EXPIRY'
    END AS risk_tier,
    (b.current_quantity * b.purchase_price) AS wholesale_cost_tied_up_kgs,
    (b.current_quantity * b.selling_price) AS potential_retail_loss_kgs
FROM batches b
JOIN medicines m ON b.medicine_id = m.id
JOIN suppliers s ON b.supplier_id = s.id
WHERE b.current_quantity > 0 
  AND b.expiry_date <= (CURRENT_DATE + INTERVAL '90 days')
ORDER BY b.expiry_date ASC;
```

---

### Query 2: Sales and Profitability Analytics by Category
**Business Goal**: Analyze net revenue, VAT collected, total unit volume, and net profit margins across different medical categories.
```sql
SELECT 
    c.name AS category_name,
    COUNT(DISTINCT s.id) AS total_sales_count,
    SUM(si.quantity) AS total_units_sold,
    SUM(si.subtotal) AS gross_revenue_kgs,
    SUM(si.quantity * b.purchase_price) AS cost_of_goods_sold_kgs,
    SUM(si.subtotal) - SUM(si.quantity * b.purchase_price) AS net_profit_kgs,
    ROUND(( (SUM(si.subtotal) - SUM(si.quantity * b.purchase_price)) / SUM(si.subtotal) ) * 100, 2) AS profit_margin_percent
FROM sale_items si
JOIN sales s ON si.sale_id = s.id
JOIN batches b ON si.batch_id = b.id
JOIN medicines m ON b.medicine_id = m.id
JOIN categories c ON m.category_id = c.id
GROUP BY c.name
ORDER BY net_profit_kgs DESC;
```

---

### Query 3: Pharmacist Performance & Commission Dashboard
**Business Goal**: Calculate total sales processed, average order value (AOV), and 1% pharmacist commission bonus for performance reviews.
```sql
SELECT 
    e.first_name || ' ' || e.last_name AS employee_name,
    e.role AS employee_role,
    COUNT(s.id) AS total_transactions_processed,
    SUM(s.total_gross) AS total_gross_sales_kgs,
    ROUND(AVG(s.total_gross), 2) AS average_order_value_kgs,
    SUM(s.discount_amount) AS total_discounts_given_kgs,
    SUM(s.total_net) AS net_revenue_kgs,
    ROUND(SUM(s.total_net) * 0.01, 2) AS sales_commission_1_percent_kgs -- 1% employee sales incentive
FROM sales s
JOIN employees e ON s.employee_id = e.id
GROUP BY e.id, e.first_name, e.last_name, e.role
ORDER BY net_revenue_kgs DESC;
```

---

### Query 4: Safety & Regulatory Prescription Audit
**Business Goal**: Audit all regulated (prescription-only) medicine transactions, listing patient details, clinic names, prescribing doctors, and verifying that the dispensed quantity matches the prescription constraints.
```sql
SELECT 
    s.id AS sale_id,
    s.sale_timestamp,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.pin_inn AS patient_pin,
    m.trade_name AS regulated_medicine,
    si.quantity AS quantity_sold,
    rx.serial_number AS rx_serial,
    d.first_name || ' ' || d.last_name AS prescribing_doctor,
    d.clinic_name AS issuing_clinic,
    rxi.prescribed_qty AS total_authorized,
    rxi.dispensed_qty AS cumulative_dispensed_so_far
FROM sale_items si
JOIN sales s ON si.sale_id = s.id
JOIN batches b ON si.batch_id = b.id
JOIN medicines m ON b.medicine_id = m.id
JOIN prescriptions rx ON s.prescription_id = rx.id
JOIN patients p ON rx.patient_id = p.id
JOIN doctors d ON rx.doctor_id = d.id
JOIN prescription_items rxi ON rx.id = rxi.prescription_id AND m.id = rxi.medicine_id
WHERE m.prescription_required = TRUE
ORDER BY s.sale_timestamp DESC;
```
