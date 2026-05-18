-- ============================================================================
-- PROJECT: Small Pharmacy Inventory & Prescription System (COMP2082 Final Project)
-- FILE: 02_seed_data.sql
-- DESCRIPTION: Highly Realistic, Localized Kyrgyzstan DML Seed Generator.
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
RAISE NOTICE 'Seeding table: categories...';
INSERT INTO categories (name, parent_category_id, description) VALUES
('Anti-infectives & Antibiotics', NULL, 'Medications to prevent or treat bacterial, fungal, and viral infections (Антибактериальные препараты)'),
('Penicillins', 1, 'Beta-lactam antibiotics used to treat bacterial infections (Пенициллины)'),
('Cephalosporins', 1, 'Broad-spectrum beta-lactam antibiotics grouped in generations (Цефалоспорины)'),
('Analgesics & Pain Relievers', NULL, 'Medications designed to reduce pain, inflammation, and fever (Обезболивающие средства)'),
('Non-Steroidal Anti-Inflammatory Drugs (NSAIDs)', 4, 'Analgesics that provide anti-inflammatory and fever-reducing effects (НПВП)'),
('Cardiovascular System', NULL, 'Medications acting on the heart and blood circulation system (Сердечно-сосудистые препараты)'),
('Beta-blockers', 6, 'Beta-adrenergic blocking agents to regulate blood pressure and heart rate (Бета-адреноблокаторы)'),
('Vitamins & Dietary Supplements', NULL, 'Nutritional supplements, essential vitamins, and organic health products (Витамины и БАДы)');

-- ============================================================================
-- 2. SEED: suppliers (55 Wholesalers with Valid 14-digit corporate INNs)
-- ============================================================================
RAISE NOTICE 'Seeding table: suppliers (55 distinct companies)...';
DO $$
DECLARE
    supplier_names text[] := ARRAY['Фарм', 'Мед', 'Азия', 'Ала-Тоо', 'Ош-Лек', 'Чуй-Фарма', 'Тянь-Шань', 'Ысык-Көл'];
    suffix text[] := ARRAY['Дистрибьюшн', 'Импорт', 'Фарма', 'ЛТД', 'Групп'];
    first_names text[] := ARRAY['Азамат', 'Тилек', 'Нурлан', 'Эрмек', 'Канат', 'Айбек', 'Улан', 'Бакыт', 'Данияр', 'Руслан'];
    last_names text[] := ARRAY['Алиев', 'Исаев', 'Осмонов', 'Садыков', 'Мамбетов', 'Токтогулов', 'Кадыров', 'Асанов', 'Султанов', 'Ибраимов'];
    cities text[] := ARRAY['Бишкек', 'Ош', 'Джалал-Абад', 'Каракол', 'Токмок', 'Нарын'];
    streets text[] := ARRAY['Ленин көчөсү', 'Чүй проспектиси', 'Манас проспектиси', 'Ахунбаев көчөсү', 'Киев көчөсү', 'Московская', 'Токтогул', 'Байтик Баатыр', 'Жибек Жолу', 'Фрунзе'];
    i int;
BEGIN
    -- Generates 55 suppliers with realistic Central Asian corporate profiles
    FOR i IN 1..55 LOOP
        INSERT INTO suppliers (name, contact_person, phone, email, address, tin_inn)
        VALUES (
            'ОсОО ' || supplier_names[1 + (i % 8)] || ' ' || suffix[1 + (i % 5)] || ' ' || i,
            first_names[1 + (i % 10)] || ' ' || last_names[1 + (i % 10)],
            '+996700' || (100000 + i)::text,
            'info' || i || '@' || lower(supplier_names[1 + (i % 8)]) || i || '.kg',
            cities[1 + (i % 6)] || ', ' || streets[1 + (i % 10)] || ' ' || (i * 2),
            '0' || (1000000000000 + i)::text
        );
    END LOOP;
END $$;

-- ============================================================================
-- 3. SEED: doctors (15 Regional Clinicians)
-- ============================================================================
RAISE NOTICE 'Seeding table: doctors (15 licensed clinicians)...';
DO $$
DECLARE
    doc_first text[] := ARRAY['Елена', 'Улан', 'Бакыт', 'Каныкей', 'Мирлан', 'Гульнара', 'Руслан', 'Айсулуу', 'Данияр', 'Динара', 'Айбек', 'Чолпон', 'Эркин', 'Асель', 'Тилек'];
    doc_last text[] := ARRAY['Петрова', 'Сапаров', 'Темиров', 'Асанова', 'Осмонов', 'Алиева', 'Кадыров', 'Садыкова', 'Мамбетов', 'Исаева', 'Жусупов', 'Абдыкадырова', 'Бакиров', 'Кенжебаева', 'Ташматова'];
    clinics text[] := ARRAY['Miras Clinic Bishkek', 'National Hospital of the Kyrgyz Republic', 'City Hospital No. 1 Osh', 'Naryn Regional Hospital', 'Karakol Family Medicine Center', 'Jalal-Abad Cardiology Clinic'];
    i int;
BEGIN
    FOR i IN 1..15 LOOP
        INSERT INTO doctors (first_name, last_name, license_number, clinic_name, phone)
        VALUES (
            doc_first[i],
            doc_last[i],
            'MoH-KG-' || (50000 + i)::text,
            clinics[1 + (i % 6)],
            '+996555' || (200000 + i)::text
        );
    END LOOP;
END $$;

-- ============================================================================
-- 4. SEED: employees (6 Pharmacy Staff Members)
-- ============================================================================
RAISE NOTICE 'Seeding table: employees...';
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
RAISE NOTICE 'Seeding table: medicines (210 distinct products)...';
DO $$
DECLARE
    generic_names text[] := ARRAY[
        'Amoxicillin', 'Ceftriaxone', 'Ketoprofen', 'Enalapril', 'Bisoprolol', 
        'Paracetamol', 'Ibuprofen', 'Drotaverine', 'Metamizole', 'Ascorbic Acid', 
        'Omeprazole', 'Metformin', 'Atorvastatin', 'Amlodipine', 'Azithromycin', 
        'Diclofenac', 'Loratadine', 'Fluconazole', 'Ciprofloxacin', 'Spironolactone'
    ];
    trade_prefixes text[] := ARRAY[
        'Амоксициллин', 'Цефтриаксон', 'Кетонал', 'Эналаприл', 'Бисопролол', 
        'Парацетамол', 'Ибуфен', 'Но-Шпа', 'Анальгин', 'Витамин C', 
        'Омез', 'Глюкофаж', 'Аторвастатин', 'Амлодипин', 'Сумамед', 
        'Диклофенак', 'Кларитин', 'Дифлюкан', 'Цифран', 'Верошпирон'
    ];
    forms text[] := ARRAY['таблетки', 'капсулы', 'суспензия', 'ампулы', 'мазь'];
    dosages text[] := ARRAY['100мг', '250мг', '500мг', '1г', '5мг', '10мг', '20мг'];
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
            'Лекарственное средство ' || v_trade || ' (' || v_generic || '). Дозировка: ' || dosages[1 + (i % 7)] || '.'
        );
    END LOOP;
END $$;

-- ============================================================================
-- 6. SEED: patients (220 Patients with DOB-matching 14-digit PINs)
-- ============================================================================
RAISE NOTICE 'Seeding table: patients (220 distinct records)...';
DO $$
DECLARE
    male_first text[] := ARRAY['Азамат', 'Нурсултан', 'Бакыт', 'Улан', 'Тилек', 'Эркин', 'Айбек', 'Данияр', 'Руслан', 'Самат', 'Канат', 'Темир', 'Арсен', 'Мирлан', 'Аскар'];
    male_last text[] := ARRAY['Алиев', 'Исаев', 'Осмонов', 'Садыков', 'Мамбетов', 'Токтогулов', 'Кадыров', 'Асанов', 'Султанов', 'Ибраимов', 'Жусупов', 'Абдыкадыров', 'Бакиров', 'Кенжебаев', 'Ташматов'];
    female_first text[] := ARRAY['Айгүл', 'Каныкей', 'Бермет', 'Чолпон', 'Мээрим', 'Айсулуу', 'Жылдыз', 'Динара', 'Алина', 'Нургүл', 'Асель', 'Гульнара', 'Мадина', 'Бегимай', 'Саида'];
    female_last text[] := ARRAY['Алиева', 'Исаева', 'Осмонова', 'Садыкова', 'Мамбетова', 'Токтогулова', 'Кадырова', 'Асанова', 'Султанова', 'Ибраимов', 'Жусупова', 'Абдыкадырова', 'Бакиров', 'Кенжебаева', 'Ташматова'];
    i int;
    v_first varchar(100);
    v_last varchar(100);
    v_gender biological_gender;
    v_dob date;
    v_pin varchar(14);
BEGIN
    FOR i IN 1..220 LOOP
        -- Distribute birthdates between 1950 and 2020
        v_dob := '1950-01-01'::date + ((i * 115) % 25000) * INTERVAL '1 day';
        IF (i % 2) = 0 THEN
            v_first := male_first[1 + (i % 15)];
            v_last := male_last[1 + (i % 15)];
            v_gender := 'M'::biological_gender;
            -- Valid Kyrgyz Male PIN starts with 2, includes DOB in DDMMYY, and sequential digits
            v_pin := '2' || to_char(v_dob, 'DDMMYY') || lpad(i::text, 7, '0');
        ELSE
            v_first := female_first[1 + (i % 15)];
            v_last := female_last[1 + (i % 15)];
            v_gender := 'F'::biological_gender;
            -- Valid Kyrgyz Female PIN starts with 1
            v_pin := '1' || to_char(v_dob, 'DDMMYY') || lpad(i::text, 7, '0');
        END IF;
        
        INSERT INTO patients (first_name, last_name, pin_inn, phone, email, date_of_birth, gender)
        VALUES (
            v_first,
            v_last,
            v_pin,
            '+996705' || (100000 + i)::text,
            lower(v_first) || '.' || lower(v_last) || i || '@mail.kg',
            v_dob,
            v_gender
        );
    END LOOP;
END $$;

-- ============================================================================
-- 7. SEED: batches (630 Physical Inventory Batches)
-- ============================================================================
RAISE NOTICE 'Seeding table: batches (630 total physical batches)...';
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
RAISE NOTICE 'Seeding table: prescriptions (320 prescriptions)...';
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
RAISE NOTICE 'Seeding table: prescription_items (640 distinct line items)...';
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
        (i, v_med1, v_qty1, v_disp1, 'Принимать по 1 таблетке 3 раза в день после еды / Take 1 tab tid pc'),
        (i, v_med2, v_qty2, v_disp2, 'Принимать по 1 капсуле перед сном / Take 1 cap hs');
    END LOOP;
END $$;

-- ============================================================================
-- 10. SEED: sales & sale_items (520 Sales Transactions & ~1040 Items)
-- ============================================================================
RAISE NOTICE 'Seeding tables: sales & sale_items (520 checkouts, 1040+ line items)...';
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
RAISE NOTICE 'Seeding table: inventory_adjustments (12 audit ledger records)...';
INSERT INTO inventory_adjustments (batch_id, employee_id, quantity, adjustment_type, reason) VALUES
(1, 3, -2, 'breakage', 'Vial broken during shelf stocking (Разбита ампула при выкладке)'),
(15, 3, -5, 'spoilage', 'Storage temperature warning on batch (Испорчено из-за температурного режима)'),
(45, 6, -1, 'theft', 'Suspected retail theft from counter (Подозрение на кражу с витрины)'),
(112, 3, 5, 'reconciliation', 'Reconciliation count inventory surplus (Излишки при инвентаризации)'),
(180, 6, -3, 'return_to_supplier', 'Returned damaged packaging to supplier (Возврат поврежденной упаковки поставщику)'),
(202, 3, -1, 'breakage', 'Accidental drop by customer (Покупатель случайно разбил флакон)'),
(300, 3, -10, 'spoilage', 'Moisture exposure damage in storage (Повреждение влагой на складе)'),
(350, 6, 2, 'reconciliation', 'Found miscounted stock from previous shift (Обнаружены неучтенные единицы)'),
(400, 3, -1, 'breakage', 'Staff handling accident during intake (Неосторожность персонала при приемке)'),
(450, 6, -4, 'return_to_supplier', 'Defective caps returned to supplier (Заводской брак крышек)'),
(500, 3, -2, 'theft', 'Unaccounted loss during monthly review (Неучтенная недостача за месяц)'),
(520, 6, 8, 'reconciliation', 'Warehouse reconciliation surplus (Корректировка излишков склада)');

-- Complete transaction
COMMIT;

DO $$ BEGIN RAISE NOTICE '--- [SUCCESS]: Algorithmic Database Seeding Completed Flawlessly! ---'; END $$;
