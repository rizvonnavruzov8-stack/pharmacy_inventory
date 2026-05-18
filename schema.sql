-- ============================================================================
-- PROJECT: Small Pharmacy Inventory & Prescription System (COMP2082 Final Project)
-- ARCHITECT: PostgreSQL Senior Database Architect
-- REGION CONTEXT: Kyrgyzstan (KGS Currency, 14-digit PIN/INN, 12% VAT)
-- FILE: schema.sql
-- DESCRIPTION: Core Table Definitions, Constraints, and Primary/Foreign Keys.
-- ============================================================================

-- Clean up existing tables if any (for fresh deployments)
DROP TABLE IF EXISTS inventory_adjustments CASCADE;
DROP TABLE IF EXISTS sale_items CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS prescription_items CASCADE;
DROP TABLE IF EXISTS prescriptions CASCADE;
DROP TABLE IF EXISTS batches CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS doctors CASCADE;
DROP TABLE IF EXISTS patients CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS medicines CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

-- ============================================================================
-- 1. REFERENCE / LOOKUP TABLES
-- ============================================================================

-- 1.1 Category Hierarchy (Recursive Self-Reference)
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    parent_category_id INT REFERENCES categories(id) ON DELETE SET NULL,
    description TEXT
);

-- Index for parent categories to optimize hierarchical tree queries
CREATE INDEX idx_categories_parent ON categories(parent_category_id);

-- 1.2 Medicine Master Directory
CREATE TABLE medicines (
    id SERIAL PRIMARY KEY,
    trade_name VARCHAR(150) NOT NULL UNIQUE,
    generic_name VARCHAR(150) NOT NULL, -- International Nonproprietary Name (INN)
    category_id INT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    prescription_required BOOLEAN DEFAULT FALSE NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE NOT NULL
);

-- Index for searching medicines by category and generic name
CREATE INDEX idx_medicines_category ON medicines(category_id);
CREATE INDEX idx_medicines_generic_name ON medicines(generic_name);

-- 1.3 Suppliers Table
CREATE TABLE suppliers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    contact_person VARCHAR(100),
    phone VARCHAR(30) CHECK (phone ~ '^\+996\d{9}$'), -- Validates Kyrgyz format: +996770123456
    email VARCHAR(100) UNIQUE,
    address TEXT,
    tin_inn VARCHAR(14) UNIQUE NOT NULL CHECK (tin_inn ~ '^[012]\d{13}$') -- 14-digit corporate or individual INN in KG
);

-- 1.4 Patients Directory
CREATE TABLE patients (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    pin_inn VARCHAR(14) UNIQUE NOT NULL CHECK (pin_inn ~ '^[12]\d{13}$'), -- 14-digit Personal PIN in Kyrgyz ID Cards
    phone VARCHAR(30) CHECK (phone ~ '^\+996\d{9}$'),
    email VARCHAR(100) UNIQUE,
    date_of_birth DATE NOT NULL CHECK (date_of_birth <= CURRENT_DATE),
    gender CHAR(1) NOT NULL CHECK (gender IN ('M', 'F'))
);

CREATE INDEX idx_patients_pin ON patients(pin_inn);

-- 1.5 Doctors Registry
CREATE TABLE doctors (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    license_number VARCHAR(50) UNIQUE NOT NULL, -- MoH issued license number
    clinic_name VARCHAR(150) NOT NULL,
    phone VARCHAR(30) CHECK (phone ~ '^\+996\d{9}$')
);

CREATE INDEX idx_doctors_license ON doctors(license_number);

-- 1.6 Pharmacy Employees Registry
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    pin_inn VARCHAR(14) UNIQUE NOT NULL CHECK (pin_inn ~ '^[12]\d{13}$'),
    role VARCHAR(20) NOT NULL CHECK (role IN ('pharmacist', 'manager', 'admin')),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL
);

-- ============================================================================
-- 2. STATE / INVENTORY MANAGEMENT TABLES
-- ============================================================================

-- 2.1 Medicine Inventory Batches (Granular Stock Tracker)
CREATE TABLE batches (
    id SERIAL PRIMARY KEY,
    medicine_id INT NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
    supplier_id INT NOT NULL REFERENCES suppliers(id) ON DELETE RESTRICT,
    batch_number VARCHAR(50) NOT NULL,
    expiry_date DATE NOT NULL, -- System triggers block sale if expired
    purchase_price NUMERIC(12, 2) NOT NULL CHECK (purchase_price > 0),
    selling_price NUMERIC(12, 2) NOT NULL CHECK (selling_price > purchase_price), -- Assures profitability
    initial_quantity INT NOT NULL CHECK (initial_quantity > 0),
    current_quantity INT NOT NULL CHECK (current_quantity >= 0),
    UNIQUE (medicine_id, batch_number)
);

-- Index optimization for active unexpired batches (Partial Indexing)
CREATE INDEX idx_active_unexpired_batches 
ON batches (medicine_id) 
WHERE (current_quantity > 0 AND expiry_date > CURRENT_DATE);

-- ============================================================================
-- 3. TRANSACTION / JUNCTION / EVENT TABLES
-- ============================================================================

-- 3.1 Prescriptions Registry
CREATE TABLE prescriptions (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
    doctor_id INT NOT NULL REFERENCES doctors(id) ON DELETE RESTRICT,
    serial_number VARCHAR(50) UNIQUE NOT NULL, -- QR code or paper slip number
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE NOT NULL CHECK (expiry_date >= issue_date),
    status VARCHAR(20) DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'partially_filled', 'filled', 'expired'))
);

CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id);
CREATE INDEX idx_prescriptions_serial ON prescriptions(serial_number);

-- 3.2 Prescription Items (Junction Table: Many-to-Many - Prescriptions & Medicines)
CREATE TABLE prescription_items (
    prescription_id INT NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    medicine_id INT NOT NULL REFERENCES medicines(id) ON DELETE RESTRICT,
    prescribed_qty INT NOT NULL CHECK (prescribed_qty > 0),
    dispensed_qty INT NOT NULL DEFAULT 0 CHECK (dispensed_qty >= 0 AND dispensed_qty <= prescribed_qty),
    dosage_instruction VARCHAR(255) NOT NULL,
    PRIMARY KEY (prescription_id, medicine_id)
);

-- 3.3 Sales Transaction Log
CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
    prescription_id INT REFERENCES prescriptions(id) ON DELETE RESTRICT, -- Nullable for OTC sales
    sale_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('cash', 'card', 'mobile_qr')),
    total_gross NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (total_gross >= 0),
    tax_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0), -- 12% standard Kyrgyz VAT
    discount_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    total_net NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (total_net >= 0)
);

CREATE INDEX idx_sales_timestamp ON sales(sale_timestamp);

-- 3.4 Sale Items (Junction Table: Many-to-Many - Sales & Batches)
CREATE TABLE sale_items (
    id SERIAL PRIMARY KEY,
    sale_id INT NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    batch_id INT NOT NULL REFERENCES batches(id) ON DELETE RESTRICT,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price > 0),
    subtotal NUMERIC(12, 2) NOT NULL CHECK (subtotal > 0),
    UNIQUE (sale_id, batch_id)
);

-- 3.5 Inventory Adjustments Log (Shrinkage, Breakage, Auditing)
CREATE TABLE inventory_adjustments (
    id SERIAL PRIMARY KEY,
    batch_id INT NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    employee_id INT NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
    quantity INT NOT NULL, -- Negative for break/shrink, positive for reconciliation
    adjustment_type VARCHAR(30) NOT NULL CHECK (adjustment_type IN ('breakage', 'spoilage', 'theft', 'reconciliation', 'return_to_supplier')),
    adjustment_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reason TEXT NOT NULL
);

-- Index for adjustment reporting
CREATE INDEX idx_adjustments_batch ON inventory_adjustments(batch_id);
