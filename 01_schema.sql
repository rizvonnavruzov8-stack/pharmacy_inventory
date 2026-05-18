
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

DROP TYPE IF EXISTS employee_role CASCADE;
DROP TYPE IF EXISTS payment_method CASCADE;
DROP TYPE IF EXISTS adjustment_type CASCADE;
DROP TYPE IF EXISTS prescription_status CASCADE;
DROP TYPE IF EXISTS biological_gender CASCADE;


CREATE TYPE employee_role AS ENUM ('pharmacist', 'manager', 'admin');
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'mobile_qr');
CREATE TYPE adjustment_type AS ENUM ('breakage', 'spoilage', 'theft', 'reconciliation', 'return_to_supplier');
CREATE TYPE prescription_status AS ENUM ('pending', 'partially_filled', 'filled', 'expired');
CREATE TYPE biological_gender AS ENUM ('M', 'F');


CREATE TABLE categories (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    parent_category_id INT,
    description TEXT,
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_category_id) 
        REFERENCES categories(id) ON UPDATE CASCADE ON DELETE SET NULL
);

COMMENT ON TABLE categories IS 'Hierarchical classifications for pharmaceuticals (e.g. Antibiotics -> Penicillins)';
COMMENT ON COLUMN categories.parent_category_id IS 'Self-referencing foreign key creating a category hierarchy tree';

CREATE TABLE medicines (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trade_name VARCHAR(150) NOT NULL UNIQUE,
    generic_name VARCHAR(150) NOT NULL, -- INN name
    category_id INT NOT NULL,
    prescription_required BOOLEAN DEFAULT FALSE NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    CONSTRAINT fk_medicines_category FOREIGN KEY (category_id) 
        REFERENCES categories(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

COMMENT ON TABLE medicines IS 'Master catalogue of medicines registered in the system';
COMMENT ON COLUMN medicines.generic_name IS 'International Nonproprietary Name (INN) representing the active chemical agent';
COMMENT ON COLUMN medicines.prescription_required IS 'System flag forcing pharmacist to scan a valid doctor prescription';

CREATE TABLE suppliers (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    contact_person VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(100) UNIQUE,
    address TEXT,
    tin_inn VARCHAR(14) NOT NULL UNIQUE,
    CONSTRAINT chk_suppliers_phone CHECK (phone ~ '^\+996\d{9}$'),
    CONSTRAINT chk_suppliers_tin_inn CHECK (tin_inn ~ '^[012]\d{13}$')
);

COMMENT ON TABLE suppliers IS 'Wholesale pharmaceutical distributors supplying inventory stocks';
COMMENT ON COLUMN suppliers.tin_inn IS 'Standard 14-digit corporate or personal Tax Identification Number in Kyrgyzstan';

CREATE TABLE patients (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    pin_inn VARCHAR(14) NOT NULL UNIQUE,
    phone VARCHAR(30),
    email VARCHAR(100) UNIQUE,
    date_of_birth DATE NOT NULL,
    gender biological_gender NOT NULL,
    CONSTRAINT chk_patients_phone CHECK (phone ~ '^\+996\d{9}$'),
    CONSTRAINT chk_patients_pin_inn CHECK (pin_inn ~ '^[12]\d{13}$'),
    CONSTRAINT chk_patients_dob CHECK (date_of_birth <= CURRENT_DATE)
);

COMMENT ON TABLE patients IS 'Patient registry containing biological and standard identifier records';
COMMENT ON COLUMN patients.pin_inn IS 'Mandatory 14-digit Personal Identification Number on Kyrgyz ID cards';

CREATE TABLE doctors (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    license_number VARCHAR(50) NOT NULL UNIQUE,
    clinic_name VARCHAR(150) NOT NULL,
    phone VARCHAR(30),
    CONSTRAINT chk_doctors_phone CHECK (phone ~ '^\+996\d{9}$')
);

COMMENT ON TABLE doctors IS 'Clinicians and licensed practitioners authorized to prescribe regulated drugs';
COMMENT ON COLUMN doctors.license_number IS 'Official Ministry of Health (MoH) professional medical license index';

CREATE TABLE employees (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    pin_inn VARCHAR(14) NOT NULL UNIQUE,
    role employee_role NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    CONSTRAINT chk_employees_pin_inn CHECK (pin_inn ~ '^[12]\d{13}$')
);

COMMENT ON TABLE employees IS 'Pharmacy staff member registry with mapped system access roles';

CREATE TABLE batches (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    medicine_id INT NOT NULL,
    supplier_id INT NOT NULL,
    batch_number VARCHAR(50) NOT NULL,
    manufacturing_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    purchase_price NUMERIC(12, 2) NOT NULL,
    selling_price NUMERIC(12, 2) NOT NULL,
    initial_quantity INT NOT NULL,
    current_quantity INT NOT NULL,
    CONSTRAINT uq_medicine_batch UNIQUE (medicine_id, batch_number),
    CONSTRAINT fk_batches_medicine FOREIGN KEY (medicine_id) 
        REFERENCES medicines(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_batches_supplier FOREIGN KEY (supplier_id) 
        REFERENCES suppliers(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_batches_dates CHECK (expiry_date > manufacturing_date),
    CONSTRAINT chk_batches_purchase_price CHECK (purchase_price > 0),
    CONSTRAINT chk_batches_selling_price CHECK (selling_price > purchase_price),
    CONSTRAINT chk_batches_initial_qty CHECK (initial_quantity > 0),
    CONSTRAINT chk_batches_current_qty CHECK (current_quantity >= 0)
);

COMMENT ON TABLE batches IS 'Physical blocks of medicine in inventory, tracking specific manufacturing and expiry schedules';
COMMENT ON COLUMN batches.batch_number IS 'Manufacturer physical print batch number';
COMMENT ON COLUMN batches.selling_price IS 'Retail customer shelf price. Must be higher than wholesale purchase price to verify margins';

CREATE TABLE prescriptions (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    serial_number VARCHAR(50) NOT NULL UNIQUE,
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE NOT NULL,
    status prescription_status DEFAULT 'pending' NOT NULL,
    CONSTRAINT fk_prescriptions_patient FOREIGN KEY (patient_id) 
        REFERENCES patients(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_prescriptions_doctor FOREIGN KEY (doctor_id) 
        REFERENCES doctors(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_prescriptions_dates CHECK (expiry_date >= issue_date)
);

COMMENT ON TABLE prescriptions IS 'Medical prescriptions issued to patients by registered doctors';
COMMENT ON COLUMN prescriptions.serial_number IS 'Unique serialized barcode index printed on paper slip or QR code';

CREATE TABLE prescription_items (
    prescription_id INT NOT NULL,
    medicine_id INT NOT NULL,
    prescribed_qty INT NOT NULL,
    dispensed_qty INT DEFAULT 0 NOT NULL,
    dosage_instruction VARCHAR(255) NOT NULL,
    PRIMARY KEY (prescription_id, medicine_id),
    CONSTRAINT fk_prescription_items_prescription FOREIGN KEY (prescription_id) 
        REFERENCES prescriptions(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_prescription_items_medicine FOREIGN KEY (medicine_id) 
        REFERENCES medicines(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_prescription_items_prescribed CHECK (prescribed_qty > 0),
    CONSTRAINT chk_prescription_items_dispensed CHECK (dispensed_qty >= 0 AND dispensed_qty <= prescribed_qty)
);

COMMENT ON TABLE prescription_items IS 'Junction catalog connecting prescriptions to specific medicines with authorized quantities';

CREATE TABLE sales (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id INT NOT NULL,
    prescription_id INT,
    sale_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    payment_method payment_method NOT NULL,
    total_gross NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    tax_amount NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    discount_amount NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    total_net NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    CONSTRAINT fk_sales_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_sales_prescription FOREIGN KEY (prescription_id) 
        REFERENCES prescriptions(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_sales_gross CHECK (total_gross >= 0),
    CONSTRAINT chk_sales_tax CHECK (tax_amount >= 0),
    CONSTRAINT chk_sales_discount CHECK (discount_amount >= 0),
    CONSTRAINT chk_sales_net CHECK (total_net >= 0)
);

COMMENT ON TABLE sales IS 'Sales receipt summaries and cumulative financial tax records';
COMMENT ON COLUMN sales.prescription_id IS 'Optional link to a prescription if checkout includes prescription-only medication';
COMMENT ON COLUMN sales.tax_amount IS 'Calculated 12% standard Kyrgyzstan VAT included in total_gross';

CREATE TABLE sale_items (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sale_id INT NOT NULL,
    batch_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price NUMERIC(12, 2) NOT NULL,
    subtotal NUMERIC(12, 2) NOT NULL,
    CONSTRAINT uq_sale_batch UNIQUE (sale_id, batch_id),
    CONSTRAINT fk_sale_items_sale FOREIGN KEY (sale_id) 
        REFERENCES sales(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_sale_items_batch FOREIGN KEY (batch_id) 
        REFERENCES batches(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_sale_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_sale_items_unit_price CHECK (unit_price > 0),
    CONSTRAINT chk_sale_items_subtotal CHECK (subtotal > 0)
);

COMMENT ON TABLE sale_items IS 'Junction catalog capturing transaction details of items checked out';

CREATE TABLE inventory_adjustments (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id INT NOT NULL,
    employee_id INT NOT NULL,
    quantity INT NOT NULL,
    adjustment_type adjustment_type NOT NULL,
    adjustment_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reason TEXT NOT NULL,
    CONSTRAINT fk_adjustments_batch FOREIGN KEY (batch_id) 
        REFERENCES batches(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_adjustments_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

COMMENT ON TABLE inventory_adjustments IS 'Audit ledger containing manual batch stock delta adjustments (wastage, theft, counts)';


CREATE INDEX idx_prescriptions_lookup 
ON prescriptions (serial_number, patient_id);

CREATE INDEX idx_sales_reporting 
ON sales (sale_timestamp, employee_id);

CREATE INDEX idx_batches_expiry_tracking 
ON batches (expiry_date, medicine_id) 
WHERE (current_quantity > 0);

CREATE INDEX idx_medicines_search 
ON medicines (trade_name, generic_name);
