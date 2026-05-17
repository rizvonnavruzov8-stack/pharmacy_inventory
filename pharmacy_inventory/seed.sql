-- ============================================================================
-- PROJECT: Small Pharmacy Inventory & Prescription System (COMP2082 Final Project)
-- FILE: seed.sql
-- DESCRIPTION: Realistic Seed Data tailored for Kyrgyzstan Community Pharmacy.
-- ============================================================================

-- Clean up any existing data in correct topological order
TRUNCATE TABLE inventory_adjustments CASCADE;
TRUNCATE TABLE sale_items CASCADE;
TRUNCATE TABLE sales CASCADE;
TRUNCATE TABLE prescription_items CASCADE;
TRUNCATE TABLE prescriptions CASCADE;
TRUNCATE TABLE batches CASCADE;
TRUNCATE TABLE employees CASCADE;
TRUNCATE TABLE doctors CASCADE;
TRUNCATE TABLE patients CASCADE;
TRUNCATE TABLE suppliers CASCADE;
TRUNCATE TABLE medicines CASCADE;
TRUNCATE TABLE categories CASCADE;

-- ============================================================================
-- 1. SEED: categories (Recursive Self-Reference Hierarchy)
-- ============================================================================
INSERT INTO categories (id, name, parent_category_id, description) VALUES
(1, 'Anti-infectives & Antibiotics', NULL, 'Medications to prevent or treat bacterial, fungal, and viral infections'),
(2, 'Penicillins', 1, 'Beta-lactam antibiotics used to treat bacterial infections'),
(3, 'Cephalosporins', 1, 'Broad-spectrum beta-lactam antibiotics grouped in generations'),
(4, 'Analgesics & Pain Relievers', NULL, 'Medications designed to reduce pain, inflammation, and fever'),
(5, 'Non-Steroidal Anti-Inflammatory Drugs (NSAIDs)', 4, 'Analgesics that provide anti-inflammatory and fever-reducing effects'),
(6, 'Cardiovascular System', NULL, 'Medications acting on the heart and blood circulation system'),
(7, 'Beta-blockers', 6, 'Beta-adrenergic blocking agents to regulate blood pressure and heart rate'),
(8, 'Vitamins & Dietary Supplements', NULL, 'Nutritional supplements, essential vitamins, and organic health products');

-- Sync the ID sequence
ALTER SEQUENCE categories_id_seq RESTART WITH 9;

-- ============================================================================
-- 2. SEED: medicines (Reference Catalog)
-- ============================================================================
INSERT INTO medicines (id, trade_name, generic_name, category_id, prescription_required, description) VALUES
(1, 'Amoxicillin-Neman 500mg', 'Amoxicillin', 2, TRUE, 'Broad-spectrum penicillin antibiotic capsules'),
(2, 'Ceftriaxone-Euro 1g Injection', 'Ceftriaxone', 3, TRUE, 'Third-generation cephalosporin antibiotic injection vial'),
(3, 'Ketonal Duo 150mg', 'Ketoprofen', 5, FALSE, 'Fast-acting, long-lasting non-steroidal anti-inflammatory capsules'),
(4, 'Enalapril-Farmamir 10mg', 'Enalapril', 6, TRUE, 'ACE inhibitor to treat hypertension and congestive heart failure'),
(5, 'Bisoprolol-Acre 5mg', 'Bisoprolol', 7, TRUE, 'Selective beta-1 blocker for hypertension management'),
(6, 'Aspirin Cardio 100mg', 'Acetylsalicylic Acid', 6, FALSE, 'Low-dose aspirin for platelet aggregation inhibition (heart health)'),
(7, 'Vitamin C chewable 500mg', 'Ascorbic Acid', 8, FALSE, 'Antioxidant supplement to boost immunity and wellness');

ALTER SEQUENCE medicines_id_seq RESTART WITH 8;

-- ============================================================================
-- 3. SEED: suppliers (Local Kyrgyzstan Wholesalers)
-- ============================================================================
INSERT INTO suppliers (id, name, contact_person, phone, email, address, tin_inn) VALUES
(1, 'ОсОО Неман-Фарм (Neman-Pharm)', 'Tilek Asanov', '+996700123456', 'sales@neman.kg', 'Bishkek, Gorky Str 1A', '01203200510123'),
(2, 'ОсОО Еврофарм (Europharm)', 'Adilet Mambetov', '+996555998877', 'info@europharm.kg', 'Bishkek, Togolok Moldo 40', '00908199710111'),
(3, 'ОсОО Фармамир (Farmamir)', 'Zarina Kenzhebaeva', '+996772445566', 'dist@farmamir.kg', 'Bishkek, Chuy Ave 115', '02511201010199');

ALTER SEQUENCE suppliers_id_seq RESTART WITH 4;

-- ============================================================================
-- 4. SEED: patients (Kyrgyz Citizen Registration with 14-Digit PINs)
-- ============================================================================
-- Kyrgyz PINs (ПИН/ИНН) encode details like century, DOB, and unique indexes
INSERT INTO patients (id, first_name, last_name, pin_inn, phone, email, date_of_birth, gender) VALUES
(1, 'Bakyt', 'Aliev', '20101198501234', '+996705112233', 'bakyt.aliev@gmail.com', '1985-01-01', 'M'),
(2, 'Aigul', 'Sadykova', '11505199201234', '+996550998877', 'aigul.sadykova@mail.ru', '1992-05-15', 'F'),
(3, 'Bermet', 'Asanova', '12308200004321', '+996770445566', 'bermet.asanova@yandex.ru', '2000-08-23', 'F');

ALTER SEQUENCE patients_id_seq RESTART WITH 4;

-- ============================================================================
-- 5. SEED: doctors (Ministry of Health Licensed Doctors)
-- ============================================================================
INSERT INTO doctors (id, first_name, last_name, license_number, clinic_name, phone) VALUES
(1, 'Elena', 'Petrova', 'MoH-KG-88392', 'Miras Clinic Bishkek', '+996500123456'),
(2, 'Ulan', 'Saparov', 'MoH-KG-55421', 'National Hospital of the Kyrgyz Republic', '+996705778899');

ALTER SEQUENCE doctors_id_seq RESTART WITH 3;

-- ============================================================================
-- 6. SEED: employees (Pharmacy Staff Registry)
-- ============================================================================
INSERT INTO employees (id, first_name, last_name, pin_inn, role, username, password_hash) VALUES
(1, 'Admin', 'User', '22012198001122', 'admin', 'admin_user', '$2b$12$KGS1234adminhashedvalue'),
(2, 'Meerim', 'Kadyrova', '10403199501122', 'pharmacist', 'meerim_p', '$2b$12$KGS1234meerimhashedvalue'),
(3, 'Bakyt', 'Toktorov', '21212198801122', 'manager', 'bakyt_m', '$2b$12$KGS1234bakythashedvalue');

ALTER SEQUENCE employees_id_seq RESTART WITH 4;

-- ============================================================================
-- 7. SEED: batches (Active & Historical Expired Batches)
-- ============================================================================
-- Note: Includes standard active unexpired batches, and specifically ONE 
-- expired batch of Amoxicillin to prove our database trigger successfully 
-- blocks sales of expired medicines.
INSERT INTO batches (id, medicine_id, supplier_id, batch_number, expiry_date, purchase_price, selling_price, initial_quantity, current_quantity) VALUES
-- Amoxicillin: Active batch
(1, 1, 1, 'AMX-2026-01', '2028-12-31', 120.00, 165.00, 100, 100),
-- Amoxicillin: EXPIRED batch (for validation testing)
(2, 1, 1, 'AMX-2023-09', '2025-01-01', 100.00, 140.00, 50, 12),
-- Ketonal Duo: Active batch (OTC)
(3, 3, 2, 'KET-773', '2028-06-30', 240.00, 310.00, 150, 150),
-- Enalapril: Active batch
(4, 4, 3, 'ENP-099', '2027-03-15', 45.00, 68.00, 200, 200),
-- Vitamin C: Active batch (OTC)
(5, 7, 1, 'VITC-112', '2026-08-01', 80.00, 110.00, 300, 300),
-- Ceftriaxone: Active batch
(6, 2, 3, 'CEF-990', '2027-09-01', 150.00, 210.00, 120, 120),
-- Bisoprolol: Active batch
(7, 5, 2, 'BIS-02', '2027-10-31', 90.00, 135.00, 80, 80);

ALTER SEQUENCE batches_id_seq RESTART WITH 8;

-- ============================================================================
-- 8. SEED: prescriptions (Valid & Expired Test Registrations)
-- ============================================================================
INSERT INTO prescriptions (id, patient_id, doctor_id, serial_number, issue_date, expiry_date, status) VALUES
-- RX 1: Valid prescription for Patient 1 (Bakyt Aliev) issued by Doctor 2 (Ulan Saparov)
(1, 1, 2, 'RX-99827-KG', CURRENT_DATE - INTERVAL '5 days', CURRENT_DATE + INTERVAL '25 days', 'pending'),
-- RX 2: EXPIRED prescription for Patient 2 (Aigul Sadykova) issued by Doctor 1 (Elena Petrova)
(2, 2, 1, 'RX-44219-KG', '2025-01-01', '2025-02-01', 'expired');

ALTER SEQUENCE prescriptions_id_seq RESTART WITH 3;

-- ============================================================================
-- 9. SEED: prescription_items (Regulated items tied to Prescriptions)
-- ============================================================================
INSERT INTO prescription_items (prescription_id, medicine_id, prescribed_qty, dispensed_qty, dosage_instruction) VALUES
-- RX 1 requires Amoxicillin (20 capsules) and Bisoprolol (30 tablets)
(1, 1, 20, 0, 'Take 1 tablet every 8 hours for 7 days'),
(1, 5, 30, 0, 'Take 1 tablet daily in the morning'),
-- RX 2 required Ceftriaxone (10 vials) - already expired
(2, 2, 10, 0, 'Intramuscular injection twice daily for 5 days');
