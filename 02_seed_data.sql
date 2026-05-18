
BEGIN;


DO $$ BEGIN RAISE NOTICE '--- Starting Algorithmic Seed Data Generation (Kyrgyzstan Context) ---'; END $$;

DO $$ BEGIN RAISE NOTICE 'Seeding table: categories...'; END $$;
INSERT INTO categories (name, parent_category_id, description) VALUES
('Anti-infectives & Antibiotics', NULL, 'Medications to prevent or treat bacterial, fungal, and viral infections (Антибактериальные препараты)'),
('Penicillins', 1, 'Beta-lactam antibiotics used to treat bacterial infections (Пенициллины)'),
('Cephalosporins', 1, 'Broad-spectrum beta-lactam antibiotics grouped in generations (Цефалоспорины)'),
('Analgesics & Pain Relievers', NULL, 'Medications designed to reduce pain, inflammation, and fever (Обезболивающие средства)'),
('Non-Steroidal Anti-Inflammatory Drugs (NSAIDs)', 4, 'Analgesics that provide anti-inflammatory and fever-reducing effects (НПВП)'),
('Cardiovascular System', NULL, 'Medications acting on the heart and blood circulation system (Сердечно-сосудистые препараты)'),
('Beta-blockers', 6, 'Beta-adrenergic blocking agents to regulate blood pressure and heart rate (Бета-адреноблокаторы)'),
('Vitamins & Dietary Supplements', NULL, 'Nutritional supplements, essential vitamins, and organic health products (Витамины и БАДы)');

DO $$ BEGIN RAISE NOTICE 'Seeding table: suppliers (55 distinct companies)...'; END $$;
DO $$
DECLARE
    supplier_names text[] := ARRAY['Фарм', 'Мед', 'Азия', 'Ала-Тоо', 'Ош-Лек', 'Чуй-Фарма', 'Тянь-Шань', 'Ысык-Көл'];
    suffix text[] := ARRAY['Дистрибьюшн', 'Импорт', 'Фарма', 'ЛТД', 'Групп'];
    first_names text[] := ARRAY['Azamat', 'Tilek', 'Nurlan', 'Ermek', 'Kanat', 'Aibek', 'Ulan', 'Bakyt', 'Daniyar', 'Ruslan', 'Maksat'];
    last_names text[] := ARRAY['Aliev', 'Isaev', 'Osmonov', 'Sadykov', 'Mambetov', 'Toktogulov', 'Kadyrov', 'Asanov', 'Sultanov', 'Ibraimov'];
    cities text[] := ARRAY['Бишкек', 'Ош', 'Джалал-Абад', 'Каракол', 'Токмок', 'Нарын'];
    streets text[] := ARRAY['Ленин көчөсү', 'Чүй проспектиси', 'Манас проспектиси', 'Ахунбаев көчөсү', 'Киев көчөсү', 'Московская', 'Токтогул', 'Байтик Баатыр', 'Жибек Жолу', 'Фрунзе'];
    phone_prefixes text[] := ARRAY['700', '555', '770', '500', '220', '705'];
    email_domains text[] := ARRAY['gmail.com', 'mail.ru', 'yandex.com', 'outlook.com', 'ucentralasia.org', 'yahoo.com'];
    i int;
    v_first_idx int;
    v_last_idx int;
    v_first varchar(100);
    v_last varchar(100);
    v_phone varchar(50);
    v_email varchar(100);
    v_suffix_num text;
BEGIN
    FOR i IN 1..55 LOOP
        v_first_idx := 1 + (i % 11);
        v_last_idx := 1 + ((i * 7 + 3) % 10);
        
        v_first := first_names[v_first_idx];
        v_last := last_names[v_last_idx];
        
        v_suffix_num := ((i * 123457 + 76543) % 900000 + 100000)::text;
        v_phone := '+996' || phone_prefixes[1 + (i % 6)] || v_suffix_num;
        
        v_email := lower(v_first) || '.' || lower(v_last) || '@' || email_domains[1 + (i % 6)];

        INSERT INTO suppliers (name, contact_person, phone, email, address, tin_inn)
        VALUES (
            'ОсОО ' || supplier_names[1 + (i % 8)] || ' ' || suffix[1 + (i % 5)] || ' ' || i,
            v_first || ' ' || v_last,
            v_phone,
            v_email,
            cities[1 + (i % 6)] || ', ' || streets[1 + (i % 10)] || ' ' || (i * 2),
            '0' || (1000000000000 + i)::text
        );
    END LOOP;
END $$;

DO $$ BEGIN RAISE NOTICE 'Seeding table: doctors (15 licensed clinicians)...'; END $$;
DO $$
DECLARE
    doc_first text[] := ARRAY['Elena', 'Ulan', 'Bakyt', 'Kanykei', 'Mirlan', 'Gulnara', 'Ruslan', 'Aisuluu', 'Daniyar', 'Dinara', 'Aibek', 'Cholpon', 'Erkin', 'Asel', 'Tilek'];
    doc_last text[] := ARRAY['Petrova', 'Saparov', 'Temirov', 'Asanova', 'Osmonov', 'Alieva', 'Kadyrov', 'Sadykova', 'Mambetov', 'Isaeva', 'Zhusupov', 'Abdykadyrova', 'Bakirov', 'Kenzhebaeva', 'Tashmatova'];
    clinics text[] := ARRAY['Miras Clinic Bishkek', 'National Hospital of the Kyrgyz Republic', 'City Hospital No. 1 Osh', 'Naryn Regional Hospital', 'Karakol Family Medicine Center', 'Jalal-Abad Cardiology Clinic'];
    phone_prefixes text[] := ARRAY['700', '555', '770', '500', '220', '705'];
    i int;
    v_suffix_num text;
    v_phone varchar(50);
BEGIN
    FOR i IN 1..15 LOOP
        v_suffix_num := ((i * 234567 + 54321) % 900000 + 100000)::text;
        v_phone := '+996' || phone_prefixes[1 + (i % 6)] || v_suffix_num;
        
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

DO $$ BEGIN RAISE NOTICE 'Seeding table: employees...'; END $$;
INSERT INTO employees (first_name, last_name, pin_inn, role, username, password_hash) VALUES
('System', 'Administrator', '22012198001122', 'admin', 'admin_user', '$2b$12$KGS1234adminhashedvalue'),
('Meerim', 'Kadyrova', '10403199501122', 'pharmacist', 'meerim_p', '$2b$12$KGS1234meerimhashedvalue'),
('Bakyt', 'Toktorov', '21212198801122', 'manager', 'bakyt_m', '$2b$12$KGS1234bakythashedvalue'),
('Cholpon', 'Isaeva', '10909199601122', 'pharmacist', 'cholpon_p', '$2b$12$KGS1234cholponhashedvalue'),
('Ulanbek', 'Mambetov', '20101199301122', 'pharmacist', 'ulan_p', '$2b$12$KGS1234ulanhashedvalue'),
('Kanykei', 'Asanova', '12512199001122', 'manager', 'kanykei_m', '$2b$12$KGS1234kanykeihashedvalue');

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

DO $$ BEGIN RAISE NOTICE 'Seeding table: patients (220 distinct records)...'; END $$;
DO $$
DECLARE
    male_first text[] := ARRAY['Azamat', 'Nursultan', 'Bakyt', 'Ulan', 'Tilek', 'Erkin', 'Aibek', 'Daniyar', 'Ruslan', 'Samat', 'Kanat', 'Temir', 'Arsen', 'Mirlan', 'Askar', 'Maksat'];
    male_last text[] := ARRAY['Aliev', 'Isaev', 'Osmonov', 'Sadykov', 'Mambetov', 'Toktogulov', 'Kadyrov', 'Asanov', 'Sultanov', 'Ibraimov', 'Zhusupov', 'Abdykadyrov', 'Bakirov', 'Kenzhebaev', 'Tashmatov'];
    female_first text[] := ARRAY['Aigul', 'Kanykei', 'Bermet', 'Cholpon', 'Meerim', 'Aisuluu', 'Zhyldyz', 'Dinara', 'Alina', 'Nurgul', 'Asel', 'Gulnara', 'Madina', 'Begimay', 'Saida', 'Aiperi'];
    female_last text[] := ARRAY['Alieva', 'Isaeva', 'Osmonova', 'Sadykova', 'Mambetova', 'Toktogulova', 'Kadyrova', 'Asanova', 'Sultanova', 'Ibraimova', 'Zhusupova', 'Abdykadyrova', 'Bakirova', 'Kenzhebaeva', 'Tashmatova'];
    phone_prefixes text[] := ARRAY['700', '555', '770', '500', '220', '705'];
    email_domains text[] := ARRAY['gmail.com', 'mail.ru', 'yandex.com', 'outlook.com', 'ucentralasia.org', 'yahoo.com'];
    i int;
    v_first_idx int;
    v_last_idx int;
    v_first varchar(100);
    v_last varchar(100);
    v_gender biological_gender;
    v_dob date;
    v_pin varchar(14);
    v_phone varchar(50);
    v_email varchar(100);
    v_suffix_num text;
BEGIN
    FOR i IN 1..220 LOOP
        v_dob := '1950-01-01'::date + ((i * 115) % 25000) * INTERVAL '1 day';
        
        v_first_idx := 1 + (i % 16);
        v_last_idx := 1 + ((i * 7 + 3) % 15);

        IF (i % 2) = 0 THEN
            v_first := male_first[v_first_idx];
            v_last := male_last[v_last_idx];
            v_gender := 'M'::biological_gender;
            v_pin := '2' || to_char(v_dob, 'DDMMYY') || lpad(i::text, 7, '0');
        ELSE
            v_first := female_first[v_first_idx];
            v_last := female_last[v_last_idx];
            v_gender := 'F'::biological_gender;
            v_pin := '1' || to_char(v_dob, 'DDMMYY') || lpad(i::text, 7, '0');
        END IF;
        
        v_suffix_num := ((i * 345678 + 98765) % 900000 + 100000)::text;
        v_phone := '+996' || phone_prefixes[1 + (i % 6)] || v_suffix_num;
        
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
            
            IF (i % 12) = 0 THEN
                v_exp := v_mfg + INTERVAL '1 year';
            ELSE
                v_exp := v_mfg + INTERVAL '3 years';
            END IF;
            
            v_buy := 15.00 + ((m * 17) % 150) + (b * 8.50);
            v_sell := ROUND(v_buy * (1.20 + (b * 0.05)), 2);
            v_init := 100 + ((m + b) % 5) * 50;
            
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
        
        IF v_issue < '2026-04-01'::date THEN
            v_exp := v_issue + INTERVAL '30 days';
            v_status := 'expired'::prescription_status;
        ELSE
            v_exp := v_issue + INTERVAL '60 days';
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
    FOR i IN 1..320 LOOP
        v_med1 := 1 + (i % 210);
        v_med2 := 1 + ((i + 47) % 210);
        
        SELECT status INTO v_rx_status FROM prescriptions WHERE id = i;
        
        v_qty1 := 10 + (i % 20);
        v_qty2 := 15 + ((i * 3) % 25);
        
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
        v_emp_id := 1 + (i % 6);
        
        IF (i % 3) = 0 THEN
            v_pay_method := 'mobile_qr'::payment_method;
        ELSIF (i % 3) = 1 THEN
            v_pay_method := 'card'::payment_method;
        ELSE
            v_pay_method := 'cash'::payment_method;
        END IF;
        
        IF (i % 10) = 0 THEN
            v_discount := 15.00;
        ELSIF (i % 15) = 0 THEN
            v_discount := 30.00;
        ELSE
            v_discount := 0.00;
        END IF;
        
        v_timestamp := CURRENT_TIMESTAMP - (i % 180) * INTERVAL '1 day' 
                                         - (8 + (i % 12)) * INTERVAL '1 hour' 
                                         - (i % 60) * INTERVAL '1 minute';
        
        IF (i % 3) = 0 AND i <= 320 THEN
            SELECT id INTO v_rx_id FROM prescriptions WHERE id = i AND status <> 'expired';
        ELSE
            v_rx_id := NULL;
        END IF;
        
        INSERT INTO sales (employee_id, prescription_id, payment_method, discount_amount, sale_timestamp)
        VALUES (v_emp_id, v_rx_id, v_pay_method, v_discount, v_timestamp)
        RETURNING id INTO v_sale_id;
        
        IF v_rx_id IS NOT NULL THEN
            SELECT medicine_id INTO v_med1 FROM prescription_items WHERE prescription_id = v_rx_id LIMIT 1;
            SELECT medicine_id INTO v_med2 FROM prescription_items WHERE prescription_id = v_rx_id OFFSET 1 LIMIT 1;
            
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

DO $$ BEGIN RAISE NOTICE 'Seeding table: inventory_adjustments (12 audit ledger records)...'; END $$;
INSERT INTO inventory_adjustments (batch_id, employee_id, quantity, adjustment_type, reason) VALUES
(1, 3, -2, 'breakage', 'Vial broken during shelf stocking (Разбита ампула при выкладке)'),
(15, 3, -5, 'spoilage', 'Storage temperature warning on batch (Испорчено из-за температурного режима)'),
(45, 6, -1, 'theft', 'Suspected retail theft from counter (Подозрение на кражу с витрины)'),
(112, 3, 5, 'reconciliation', 'Reconciliation count inventory surplus (Излишки при инвентаризации)'),
(181, 6, -3, 'return_to_supplier', 'Returned damaged packaging to supplier (Возврат поврежденной упаковки поставщику)'),
(202, 3, -1, 'breakage', 'Accidental drop by customer (Покупатель случайно разбил флакон)'),
(301, 3, -10, 'spoilage', 'Moisture exposure damage in storage (Повреждение влагой на складе)'),
(350, 6, 2, 'reconciliation', 'Found miscounted stock from previous shift (Обнаружены неучтенные единицы)'),
(401, 3, -1, 'breakage', 'Staff handling accident during intake (Неосторожность персонала при приемке)'),
(450, 6, -4, 'return_to_supplier', 'Defective caps returned to supplier (Заводской брак крышек)'),
(501, 3, -2, 'theft', 'Unaccounted loss during monthly review (Неучтенная недостача за месяц)'),
(520, 6, 8, 'reconciliation', 'Warehouse reconciliation surplus (Корректировка излишков склада)');

COMMIT;

DO $$ BEGIN RAISE NOTICE '--- [SUCCESS]: Algorithmic Database Seeding Completed Flawlessly! ---'; END $$;
