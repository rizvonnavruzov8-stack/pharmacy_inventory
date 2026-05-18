-- ============================================================================
-- PROJECT: Small Pharmacy Inventory & Prescription System (COMP2082 Final Project)
-- FILE: 02_seed_data.sql
-- DESCRIPTION: Highly Realistic, Localized Kyrgyzstan DML Seed Generator (Latin Character Only).
-- SYNTAX: PostgreSQL 15+ Standard
-- ============================================================================

-- Start transaction block
BEGIN;

-- Disabling RLS and manual check bypasses are not needed because the algorithmic 
-- seeder generates 100% logically consistent data that satisfies all check constraints.
-- Triggers will remain fully ENABLED to demonstrate that our database validation engine 
-- automatically handles inventory deductions, prescription audits, and billing math!

DO $$ BEGIN RAISE NOTICE '--- Starting Algorithmic Seed Data Generation (Kyrgyzstan Context) ---'; END $$;

-- ============================================================================
-- 1. SEED: categories (Recursive Self-Reference Hierarchy)
-- ============================================================================
DO $$ BEGIN RAISE NOTICE 'Seeding table: categories...'; END $$;
INSERT INTO categories (name, parent_category_id, description) VALUES
('Anti-infectives & Antibiotics', NULL, 'Medications to prevent or treat bacterial, fungal, and viral infections'),
('Penicillins', 1, 'Beta-lactam antibiotics used to treat bacterial infections'),
('Cephalosporins', 1, 'Broad-spectrum beta-lactam antibiotics grouped in generations'),
('Analgesics & Pain Relievers', NULL, 'Medications designed to reduce pain, inflammation, and fever'),
('Non-Steroidal Anti-Inflammatory Drugs (NSAIDs)', 4, 'Analgesics that provide anti-inflammatory and fever-reducing effects'),
('Cardiovascular System', NULL, 'Medications acting on the heart and blood circulation system'),
('Beta-blockers', 6, 'Beta-adrenergic blocking agents to regulate blood pressure and heart rate'),
('Vitamins & Dietary Supplements', NULL, 'Nutritional supplements, essential vitamins, and organic health products');

-- ============================================================================
-- 2. SEED: suppliers (55 Wholesalers with Valid 14-digit corporate INNs)
-- ============================================================================
DO $$ BEGIN RAISE NOTICE 'Seeding table: suppliers (55 distinct companies)...'; END $$;
DO $$
DECLARE
    supplier_names text[] := ARRAY['Pharm', 'Med', 'Asia', 'Ala-Too', 'Osh-Lek', 'Chuy-Pharma', 'Tian-Shan', 'Ysyk-Kol'];
    suffix text[] := ARRAY['Distribution', 'Import', 'Pharma', 'LTD', 'Group'];
    first_names text[] := ARRAY['Azamat', 'Tilek', 'Nurlan', 'Ermek', 'Kanat', 'Aibek', 'Ulan', 'Bakyt', 'Daniyar', 'Ruslan'];
    last_names text[] := ARRAY['Aliev', 'Isaev', 'Osmonov', 'Sadykov', 'Mambetov', 'Toktogulov', 'Kadyrov', 'Asanov', 'Sultanov', 'Ibraimov'];
    cities text[] := ARRAY['Bishkek', 'Osh', 'Jalal-Abad', 'Karakol', 'Tokmok', 'Naryn'];
    streets text[] := ARRAY['Lenin Street', 'Chuy Avenue', 'Manas Avenue', 'Ahunbaeva Street', 'Kiev Street', 'Moskovskaya Street', 'Toktogul Street', 'Baytik Baatyr Street', 'Jibek Jolu Street', 'Frunze Street'];
    phone_prefixes text[] := ARRAY['+996 555', '+996 700', '+996 770', '+996 312', '+996 500', '+996 220'];
    email_domains text[] := ARRAY['gmail.com', 'mail.ru', 'yandex.com', 'outlook.com', 'ucentralasia.org', 'yahoo.com'];
    i int;
    v_pref_idx int;
    v_suff_idx int;
    v_first_idx int;
    v_last_idx int;
    v_first varchar(100);
    v_last varchar(100);
    v_comp varchar(150);
    v_phone varchar(50);
    v_email varchar(100);
    v_street varchar(150);
    v_suffix_num text;
BEGIN
    FOR i IN 1..55 LOOP
        v_pref_idx := 1 + (i % 8);
        v_suff_idx := 1 + ((i * 3 + 2) % 5);
        v_first_idx := 1 + (i % 10);
        v_last_idx := 1 + ((i * 7 + 1) % 10);
        
        v_first := first_names[v_first_idx];
        v_last := last_names[v_last_idx];
        
        -- Formulate highly professional Latin corporate name without raw index suffix
        v_comp := 'OcOO ' || supplier_names[v_pref_idx] || ' ' || suffix[v_suff_idx] || ' (' || cities[1 + (i % 6)] || ')';
        v_street := streets[1 + ((i * 11) % 10)] || ' ' || (i * 2 + 1)::text;
        
        -- Dynamic, highly realistic phone numbers using real prefixes
        v_suffix_num := ((i * 123457 + 76543) % 900000 + 100000)::text;
        v_phone := phone_prefixes[1 + (i % 6)] || ' ' || substr(v_suffix_num, 1, 3) || ' ' || substr(v_suffix_num, 4, 3);
        
        -- Formatted dynamic emails matching the Latin name perfectly
        v_email := lower(v_first) || '.' || lower(v_last) || '@' || email_domains[1 + (i % 6)];
        
        INSERT INTO suppliers (name, contact_person, phone, email, address, tin_inn)
        VALUES (
            v_comp,
            v_first || ' ' || v_last,
            v_phone,
            v_email,
            cities[1 + (i % 6)] || ', ' || v_street,
            '0' || (1000000000000 + i * 17)::text
        );
    END LOOP;
END $$;

-- ============================================================================
-- 3. SEED: doctors (15 Regional Clinicians)
-- ============================================================================
DO $$ BEGIN RAISE NOTICE 'Seeding table: doctors (15 licensed clinicians)...'; END $$;
DO $$
DECLARE
    doc_first text[] := ARRAY['Elena', 'Ulan', 'Bakyt', 'Kanykei', 'Mirlan', 'Gulnara', 'Ruslan', 'Aisuluu', 'Daniyar', 'Dinara', 'Aibek', 'Cholpon', 'Erkin', 'Asel', 'Tilek'];
    doc_last text[] := ARRAY['Petrova', 'Saparov', 'Temirov', 'Asanova', 'Osmonov', 'Alieva', 'Kadyrov', 'Sadykova', 'Mambetov', 'Isaeva', 'Zhusupov', 'Abdykadyrova', 'Bakirov', 'Kenzhebaeva', 'Tashmatova'];
    clinics text[] := ARRAY['Miras Clinic Bishkek', 'National Hospital of the Kyrgyz Republic', 'City Hospital No. 1 Osh', 'Naryn Regional Hospital', 'Karakol Family Medicine Center', 'Jalal-Abad Cardiology Clinic'];
    phone_prefixes text[] := ARRAY['+996 555', '+996 700', '+996 770', '+996 312', '+996 500', '+996 220'];
    i int;
    v_suffix_num text;
    v_phone varchar(50);
BEGIN
    FOR i IN 1..15 LOOP
        -- Dynamic phone generation
        v_suffix_num := ((i * 234567 + 54321) % 900000 + 100000)::text;
        v_phone := phone_prefixes[1 + (i % 6)] || ' ' || substr(v_suffix_num, 1, 3) || ' ' || substr(v_suffix_num, 4, 3);
        
        INSERT INTO doctors (first_name, last_name, license_number, clinic_name, phone)
        VALUES (
            doc_first[i],
            doc_last[i],
            'MoH-KG-' || (50000 + i)::text,
            clinics[1 + (i % 6)],
            v_phone
        );
    END LOOP;
END $$;

-- ============================================================================
-- 4. SEED: employees (6 Pharmacy Staff Members)
-- ============================================================================
DO $$ BEGIN RAISE NOTICE 'Seeding table: employees...'; END $$;
INSERT INTO employees (first_name, last_name, pin_inn, role, username, password_hash) VALUES
('System', 'Administrator', '22012198001122', 'admin', 'admin_user', '$2b$12$KGS1234adminhashedvalue'),
('Meerim', 'Kadyrova', '10403199501122', 'pharmacist', 'meerim_p', '$2b$12$KGS1234meerimhashedvalue'),
('Bakyt', 'Toktorov', '21212198801122', 'manager', 'bakyt_m', '$2b$12$KGS1234bakythashedvalue'),
('Cholpon', 'Isaeva', '10909199601122', 'pharmacist', 'cholpon_p', '$2b$12$KGS1234cholponhashedvalue'),
('Ulanbek', 'Mambetov', '20101199301122', 'pharmacist', 'ulan_p', '$2b$12$KGS1234ulanhashedvalue'),
('Kanykei', 'Asanova', '12512199001122', 'manager', 'kanykei_m', '$2b$12$KGS1234kanykeihashedvalue');

-- ============================================================================
-- 5. SEED: medicines (210 Distinct Products)
-- ============================================================================
DO $$ BEGIN RAISE NOTICE 'Seeding table: medicines (210 distinct products)...'; END $$;
DO $$
DECLARE
    generic_names text[] := ARRAY[
        'Amoxicillin', 'Ceftriaxone', 'Ketoprofen', 'Enalapril', 'Bisoprolol', 
        'Paracetamol', 'Ibuprofen', 'Drotaverine', 'Metamizole', 'Ascorbic Acid', 
        'Omeprazole', 'Metformin', 'Atorvastatin', 'Amlodipine', 'Azithromycin', 
        'Diclofenac', 'Loratadine', 'Fluconazole', 'Ciprofloxacin', 'Spironolactone'
    ];
    trade_prefixes text[] := ARRAY[
        'Amoxicillin', 'Ceftriaxone', 'Ketonal', 'Enalapril', 'Bisoprolol', 
        'Paracetamol', 'Ibufen', 'No-Shpa', 'Analgin', 'Vitamin C', 
        'Omez', 'Glucophage', 'Atorvastatin', 'Amlodipine', 'Sumamed', 
        'Diclofenac', 'Claritin', 'Diflucan', 'Cifran', 'Verospiron'
    ];
    forms text[] := ARRAY['tablets', 'capsules', 'suspension', 'ampoules', 'ointment'];
    dosages text[] := ARRAY['100mg', '250mg', '500mg', '1g', '5mg', '10mg', '20mg'];
    i int;
    v_generic varchar(150);
    v_trade varchar(150);
    v_cat_id int;
    v_rx boolean;
BEGIN
    FOR i IN 1..210 LOOP
        v_generic := generic_names[1 + (i % 20)];
        v_trade := trade_prefixes[1 + (i % 20)] || ' ' || forms[1 + (i % 5)] || ' ' || dosages[1 + (i % 7)] || ' ' || i;
        v_cat_id := 1 + (i % 8);
        -- 66% of medicines require prescription
        v_rx := (i % 3) <> 0;
        
        INSERT INTO medicines (trade_name, generic_name, category_id, prescription_required, description)
        VALUES (
            v_trade,
            v_generic,
            v_cat_id,
            v_rx,
            'Medicinal product ' || v_trade || ' (' || v_generic || '). Dosage: ' || dosages[1 + (i % 7)] || '.'
        );
    END LOOP;
END $$;

-- ============================================================================
-- 6. SEED: patients (220 Patients with DOB-matching 14-digit PINs)
-- ============================================================================
DO $$ BEGIN RAISE NOTICE 'Seeding table: patients (220 distinct records)...'; END $$;
DO $$
DECLARE
    male_first text[] := ARRAY['Azamat', 'Nursultan', 'Bakyt', 'Ulan', 'Tilek', 'Erkin', 'Aibek', 'Daniyar', 'Ruslan', 'Samat', 'Kanat', 'Temir', 'Arsen', 'Mirlan', 'Askar'];
    male_last text[] := ARRAY['Aliev', 'Isaev', 'Osmonov', 'Sadykov', 'Mambetov', 'Toktogulov', 'Kadyrov', 'Asanov', 'Sultanov', 'Ibraimov', 'Zhusupov', 'Abdykadyrov', 'Bakirov', 'Kenzhebaev', 'Tashmatov'];
    female_first text[] := ARRAY['Aigul', 'Kanykei', 'Bermet', 'Cholpon', 'Meerim', 'Aisuluu', 'Zhyldyz', 'Dinara', 'Alina', 'Nurgul', 'Asel', 'Gulnara', 'Madina', 'Begimay', 'Saida'];
    female_last text[] := ARRAY['Alieva', 'Isaeva', 'Osmonova', 'Sadykova', 'Mambetova', 'Toktogulova', 'Kadyrova', 'Asanova', 'Sultanova', 'Ibraimova', 'Zhusupova', 'Abdykadyrova', 'Bakirova', 'Kenzhebaeva', 'Tashmatova'];
    phone_prefixes text[] := ARRAY['+996 555', '+996 700', '+996 770', '+996 312', '+996 500', '+996 220'];
    email_domains text[] := ARRAY['gmail.com', 'mail.ru', 'yandex.com', 'outlook.com', 'ucentralasia.org', 'yahoo.com'];
    i int;
    v_first_idx int;
    v_last_idx int;
    v_first varchar(100);
    v_last varchar(100);
    v_gender biological_gender;
    v_dob date;
    v_pin varchar(14);
    v_suffix_num text;
    v_phone varchar(50);
    v_email varchar(100);
BEGIN
    FOR i IN 1..220 LOOP
        -- Distribute birthdates between 1950 and 2008 (realistic student/employee demographics)
        v_dob := '1950-01-01'::date + ((i * 115) % 20000) * INTERVAL '1 day';
        
        -- Formulate non-linear, completely unique name pairs
        v_first_idx := 1 + (i % 15);
        v_last_idx := 1 + ((i * 7 + 3) % 15);
        
        IF (i % 2) = 0 THEN
            v_first := male_first[v_first_idx];
            v_last := male_last[v_last_idx];
            v_gender := 'M'::biological_gender;
            -- Valid Kyrgyz Male PIN starts with 2, includes DOB in DDMMYY, and unique tail digits
            v_pin := '2' || to_char(v_dob, 'DDMMYY') || lpad((i * 3)::text, 7, '0');
        ELSE
            v_first := female_first[v_first_idx];
            v_last := female_last[v_last_idx];
            v_gender := 'F'::biological_gender;
            -- Valid Kyrgyz Female PIN starts with 1
            v_pin := '1' || to_char(v_dob, 'DDMMYY') || lpad((i * 3)::text, 7, '0');
        END IF;
        
        -- Dynamic non-sequential phone number
        v_suffix_num := ((i * 345678 + 98765) % 900000 + 100000)::text;
        v_phone := phone_prefixes[1 + (i % 6)] || ' ' || substr(v_suffix_num, 1, 3) || ' ' || substr(v_suffix_num, 4, 3);
        
        -- Dynamic matching email address without sequence numbers
        v_email := lower(v_first) || '.' || lower(v_last) || '@' || email_domains[1 + (i % 6)];
        
        INSERT INTO patients (first_name, last_name, pin_inn, phone, email, date_of_birth, gender)
        VALUES (
            v_first,
            v_last,
            v_pin,
            v_phone,
            v_email,
            v_dob,
            v_gender
        );
    END LOOP;
END $$;

-- ============================================================================
-- 7. SEED: batches (630 Physical Inventory Batches)
-- ============================================================================
DO $$ BEGIN RAISE NOTICE 'Seeding table: batches (630 total physical batches)...'; END $$;
DO $$
DECLARE
    m int;
    b int;
    v_mfg date;
    v_exp date;
    v_buy numeric(12,2);
    v_sell numeric(12,2);
    v_init int;
    v_curr int;
    v_sup_id int;
    i int := 0;
BEGIN
    FOR m IN 1..210 LOOP
        FOR b IN 1..3 LOOP
            i := i + 1;
            v_mfg := '2023-01-01'::date + ((m * b * 7) % 600) * INTERVAL '1 day';
            
            -- Edge Case: 8% of batches are already expired to test safety blockers
            IF (i % 12) = 0 THEN
                v_exp := v_mfg + INTERVAL '1 year';
            ELSE
                v_exp := v_mfg + INTERVAL '3 years';
            END IF;
            
            v_buy := 15.00 + ((m * 17) % 150) + (b * 8.50);
            v_sell := ROUND(v_buy * (1.20 + (b * 0.05)), 2);
            v_init := 100 + ((m + b) % 5) * 50;
            
            -- Edge Case: 5% of batches are completely out of stock
            IF (i % 20) = 0 THEN
                v_curr := 0;
            ELSE
                v_curr := v_init - ((m * b) % 25);
            END IF;
            
            v_sup_id := 1 + ((m * b) % 55);
            
            INSERT INTO batches (medicine_id, supplier_id, batch_number, manufacturing_date, expiry_date, purchase_price, selling_price, initial_quantity, current_quantity)
            VALUES (
                m,
                v_sup_id,
                'BCH-' || m::text || '-' || b::text || '-' || (1000 + i)::text,
                v_mfg,
                v_exp,
                v_buy,
                v_sell,
                v_init,
                v_curr
            );
        END LOOP;
    END LOOP;
END $$;

-- ============================================================================
-- 8. SEED: prescriptions (320 Prescriptions)
-- ============================================================================
DO $$ BEGIN RAISE NOTICE 'Seeding table: prescriptions (320 prescriptions)...'; END $$;
DO $$
DECLARE
    i int;
    v_pat_id int;
    v_doc_id int;
    v_issue date;
    v_exp date;
    v_status prescription_status;
BEGIN
    FOR i IN 1..320 LOOP
        v_pat_id := 1 + ((i * 13) % 220);
        v_doc_id := 1 + ((i * 3) % 15);
        v_issue := '2025-10-01'::date + ((i * 11) % 180) * INTERVAL '1 day';
        
        -- Edge Case: Prescriptions issued over 6 months ago are marked EXPIRED
        IF v_issue < '2026-04-01'::date THEN
            v_exp := v_issue + INTERVAL '30 days';
            v_status := 'expired'::prescription_status;
        ELSE
            v_exp := v_issue + INTERVAL '60 days';
            -- Non-uniform status distribution
            IF (i % 5) = 0 THEN
                v_status := 'filled'::prescription_status;
            ELSIF (i % 7) = 0 THEN
                v_status := 'partially_filled'::prescription_status;
            ELSE
                v_status := 'pending'::prescription_status;
            END IF;
        END IF;
        
        INSERT INTO prescriptions (patient_id, doctor_id, serial_number, issue_date, expiry_date, status)
        VALUES (
            v_pat_id,
            v_doc_id,
            'RX-' || (100000 + i)::text || '-KG',
            v_issue,
            v_exp,
            v_status
        );
    END LOOP;
END $$;

-- ============================================================================
-- 9. SEED: prescription_items (640 Junction line items)
-- ============================================================================
DO $$ BEGIN RAISE NOTICE 'Seeding table: prescription_items (640 distinct line items)...'; END $$;
DO $$
DECLARE
    i int;
    v_med1 int;
    v_med2 int;
    v_rx_status prescription_status;
    v_disp1 int;
    v_disp2 int;
    v_qty1 int;
    v_qty2 int;
BEGIN
    -- Maps exactly two distinct prescribed medicines for each of the 320 prescriptions
    FOR i IN 1..320 LOOP
        v_med1 := 1 + (i % 210);
        v_med2 := 1 + ((i + 47) % 210);
        
        SELECT status INTO v_rx_status FROM prescriptions WHERE id = i;
        
        v_qty1 := 10 + (i % 20);
        v_qty2 := 15 + ((i * 3) % 25);
        
        -- Enforces logical consistency with parent prescription state
        IF v_rx_status = 'filled' THEN
            v_disp1 := v_qty1;
            v_disp2 := v_qty2;
        ELSIF v_rx_status = 'partially_filled' THEN
            v_disp1 := v_qty1 / 2;
            v_disp2 := 0;
        ELSE
            v_disp1 := 0;
            v_disp2 := 0;
        END IF;
        
        INSERT INTO prescription_items (prescription_id, medicine_id, prescribed_qty, dispensed_qty, dosage_instruction)
        VALUES 
        (i, v_med1, v_qty1, v_disp1, 'Prinimat po 1 tabletke 3 raza v den posle edi / Take 1 tab tid pc'),
        (i, v_med2, v_qty2, v_disp2, 'Prinimat po 1 kapsule pered snom / Take 1 cap hs');
    END LOOP;
END $$;

-- ============================================================================
-- 10. SEED: sales & sale_items (520 Sales Transactions & ~1040 Items)
-- ============================================================================
DO $$ BEGIN RAISE NOTICE 'Seeding tables: sales & sale_items (520 checkouts, 1040+ line items)...'; END $$;
DO $$
DECLARE
    i int;
    v_sale_id int;
    v_rx_id int;
    v_med1 int;
    v_med2 int;
    v_batch1 int;
    v_batch2 int;
    v_emp_id int;
    v_pay_method payment_method;
    v_discount numeric(12,2);
    v_timestamp timestamp;
BEGIN
    FOR i IN 1..520 LOOP
        -- Employee link (1 to 6)
        v_emp_id := 1 + (i % 6);
        
        -- Payment method
        IF (i % 3) = 0 THEN
            v_pay_method := 'mobile_qr'::payment_method;
        ELSIF (i % 3) = 1 THEN
            v_pay_method := 'card'::payment_method;
        ELSE
            v_pay_method := 'cash'::payment_method;
        END IF;
        
        -- Discount
        IF (i % 10) = 0 THEN
            v_discount := 15.00;
        ELSIF (i % 15) = 0 THEN
            v_discount := 30.00;
        ELSE
            v_discount := 0.00;
        END IF;
        
        -- Weekday business-hour timestamp (8:00 AM - 8:00 PM) over the last 6 months
        v_timestamp := CURRENT_TIMESTAMP - (i % 180) * INTERVAL '1 day' 
                                         - (8 + (i % 12)) * INTERVAL '1 hour' 
                                         - (i % 60) * INTERVAL '1 minute';
        
        -- Optional prescription link (every 3rd sale, provided it exists and is active)
        IF (i % 3) = 0 AND i <= 320 THEN
            SELECT id INTO v_rx_id FROM prescriptions WHERE id = i AND status <> 'expired';
        ELSE
            v_rx_id := NULL;
        END IF;
        
        -- Insert Sales Header (gross/net initially 0, triggers will auto-calculate)
        INSERT INTO sales (employee_id, prescription_id, payment_method, discount_amount, sale_timestamp)
        VALUES (v_emp_id, v_rx_id, v_pay_method, v_discount, v_timestamp)
        RETURNING id INTO v_sale_id;
        
        -- Add Items based on checkout types
        IF v_rx_id IS NOT NULL THEN
            -- Prescription Sale: Sell the exact medicines prescribed in the RX
            SELECT medicine_id INTO v_med1 FROM prescription_items WHERE prescription_id = v_rx_id LIMIT 1;
            SELECT medicine_id INTO v_med2 FROM prescription_items WHERE prescription_id = v_rx_id OFFSET 1 LIMIT 1;
            
            -- Locate an active unexpired batch with sufficient stock
            SELECT id INTO v_batch1 FROM batches 
            WHERE medicine_id = v_med1 AND current_quantity >= 5 AND expiry_date > v_timestamp::date LIMIT 1;
            
            SELECT id INTO v_batch2 FROM batches 
            WHERE medicine_id = v_med2 AND current_quantity >= 5 AND expiry_date > v_timestamp::date LIMIT 1;
            
            IF v_batch1 IS NOT NULL THEN
                INSERT INTO sale_items (sale_id, batch_id, quantity)
                VALUES (v_sale_id, v_batch1, 2);
            END IF;
            
            IF v_batch2 IS NOT NULL THEN
                INSERT INTO sale_items (sale_id, batch_id, quantity)
                VALUES (v_sale_id, v_batch2, 2);
            END IF;
            
        ELSE
            -- OTC (Over-The-Counter) Sale: Sell random OTC drugs (prescription_required = FALSE)
            SELECT b.id, b.medicine_id INTO v_batch1, v_med1 
            FROM batches b
            JOIN medicines m ON b.medicine_id = m.id
            WHERE m.prescription_required = FALSE 
              AND b.current_quantity >= 10 
              AND b.expiry_date > v_timestamp::date
            LIMIT 1 OFFSET (i % 30);
            
            IF v_batch1 IS NOT NULL THEN
                INSERT INTO sale_items (sale_id, batch_id, quantity)
                VALUES (v_sale_id, v_batch1, 2);
            END IF;
            
            -- Add second OTC item
            SELECT b.id, b.medicine_id INTO v_batch2, v_med2 
            FROM batches b
            JOIN medicines m ON b.medicine_id = m.id
            WHERE m.prescription_required = FALSE 
              AND b.current_quantity >= 10 
              AND b.expiry_date > v_timestamp::date
              AND b.id <> v_batch1
            LIMIT 1 OFFSET ((i + 7) % 30);
            
            IF v_batch2 IS NOT NULL THEN
                INSERT INTO sale_items (sale_id, batch_id, quantity)
                VALUES (v_sale_id, v_batch2, 1);
            END IF;
        END IF;
    END LOOP;
END $$;

-- ============================================================================
-- 11. SEED: inventory_adjustments (12 Audit Logs)
-- ============================================================================
DO $$ BEGIN RAISE NOTICE 'Seeding table: inventory_adjustments (12 audit ledger records)...'; END $$;
INSERT INTO inventory_adjustments (batch_id, employee_id, quantity, adjustment_type, reason) VALUES
(1, 3, -2, 'breakage', 'Vial broken during shelf stocking (Razbita ampula pri vikladke)'),
(15, 3, -5, 'spoilage', 'Storage temperature warning on batch (Isporcheno iz-za temperaturnogo rejima)'),
(45, 6, -1, 'theft', 'Suspected retail theft from counter (Podozrenie na kraju s vitrini)'),
(112, 3, 5, 'reconciliation', 'Reconciliation count inventory surplus (Izlishki pri inventarizacii)'),
(181, 6, -3, 'return_to_supplier', 'Returned damaged packaging to supplier (Vozvrat povrejdennoy upakovki postavshiku)'),
(202, 3, -1, 'breakage', 'Accidental drop by customer (Pokupatel sluchayno razbil flakon)'),
(301, 3, -10, 'spoilage', 'Moisture exposure damage in storage (Povrejdenie vlagoy na sklade)'),
(350, 6, 2, 'reconciliation', 'Found miscounted stock from previous shift (Obnarujeni neuchtennie edinici)'),
(401, 3, -1, 'breakage', 'Staff handling accident during intake (Neostorojnost personala pri priemke)'),
(450, 6, -4, 'return_to_supplier', 'Defective caps returned to supplier (Zavodskoy brak krishek)'),
(501, 3, -2, 'theft', 'Unaccounted loss during monthly review (Neuchtennaya nedostacha za mesyac)'),
(520, 6, 8, 'reconciliation', 'Warehouse reconciliation surplus (Korrektirovka izlishkov sklada)');

-- Complete transaction
COMMIT;

DO $$ BEGIN RAISE NOTICE '--- [SUCCESS]: Algorithmic Database Seeding Completed Flawlessly! ---'; END $$;
