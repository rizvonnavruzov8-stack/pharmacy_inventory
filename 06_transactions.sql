-- ============================================================================
-- PROJECT: Small Pharmacy Inventory & Prescription System (COMP2082 Final Project)
-- FILE: 06_transactions.sql
-- DESCRIPTION: High-Fidelity Transaction Demonstrations with ACID Analysis.
-- SYNTAX: PostgreSQL 15+ Standard
-- ============================================================================

-- ============================================================================
-- TRANSACTION 1: Successful Sales Checkout (OTC)
-- ACID FOCUS: ATOMICITY & DURABILITY
-- BUSINESS RULE: Pharmacist Meerim (Employee 2) registers a walk-in cash sale 
--                of 2 units of medicine from Batch 1 (Active and unexpired).
-- ============================================================================

-- Start the transaction block. Atomicity guarantees that either all steps succeed, 
-- or none do.
BEGIN;

-- Step 1: Create the Sales Receipt Header (staged)
-- Note: Financial totals (total_gross, tax_amount, total_net) start at 0.00. 
-- Our database automation triggers will automatically update these upon item inserts.
INSERT INTO sales (employee_id, prescription_id, payment_method, discount_amount)
VALUES (2, NULL, 'cash', 0.00);

-- Step 2: Add Sale Item using currval() to retrieve the auto-generated sales ID.
-- This insert fires "tg_deduct_inventory" which checks stock availability, 
-- locks the batch row, overrides unit price with the master shelf rate, 
-- deducts from batches.current_quantity, and updates the sales totals!
INSERT INTO sale_items (sale_id, batch_id, quantity)
VALUES (currval('sales_id_seq'), 1, 2);

-- Step 3: Verify the staged changes (Demonstrates ISOLATION)
-- Within this session, the sales invoice and batch deductions are visible, 
-- but other concurrent database sessions cannot see them until we commit.
SELECT id, total_gross, tax_amount, total_net FROM sales WHERE id = currval('sales_id_seq');
SELECT id, current_quantity FROM batches WHERE id = 1;

-- Step 4: Commit. All staged updates are permanently written to disk 
-- (DURABILITY) and become visible to all concurrent transactions.
COMMIT;


-- ============================================================================
-- TRANSACTION 2: Manual Inventory Stock Intake & Restock
-- ACID FOCUS: CONSISTENCY
-- BUSINESS RULE: A warehouse manager receives a bulk intake, updates stock counts,
--                and records a mandatory audit trail ledger in adjustments.
-- ============================================================================
BEGIN;

-- Step 1: Update batch stock count (adding 100 units to Batch 4)
UPDATE batches 
SET current_quantity = current_quantity + 100 
WHERE id = 4;

-- Step 2: Log a mandatory adjustment audit entry
-- Consistency ensures that if we restock inventory, a corresponding audit ledger 
-- entry is recorded, keeping the inventory counts and audit trails fully reconciled.
INSERT INTO inventory_adjustments (batch_id, employee_id, quantity, adjustment_type, reason)
VALUES (4, 3, 100, 'reconciliation', 'Restocked fresh supplier intake (Поступление новой партии товара)');

-- Step 3: Validate updated balance
SELECT id, current_quantity, initial_quantity FROM batches WHERE id = 4;

-- Step 4: Save updates
COMMIT;


-- ============================================================================
-- TRANSACTION 3: ACID Rollback on Stock-Out Trigger Blockade
-- ACID FOCUS: ATOMICITY & CONSISTENCY (All-or-Nothing Recovery)
-- BUSINESS RULE: A customer tries to buy 9,999 units of a drug. The database trigger
--                "tg_deduct_inventory" intercepts this, verifies insufficient quantity, 
--                and throws a custom SQLSTATE exception. The entire transaction rolls back.
-- ============================================================================
BEGIN;

-- Step 1: Create a Sales Receipt Header (staged within transaction block)
INSERT INTO sales (employee_id, prescription_id, payment_method, discount_amount)
VALUES (2, NULL, 'mobile_qr', 0.00);

-- Step 2: Attempt to insert a sale item exceeding available shelf quantity (e.g. 9999 units)
-- This insert fires the "tg_deduct_inventory" trigger, which raises an exception:
-- "EXCEPTION: Insufficient inventory quantity in selected batch."
-- This automatically invalidates the active transaction block!
INSERT INTO sale_items (sale_id, batch_id, quantity)
VALUES (currval('sales_id_seq'), 2, 9999);

-- Step 3: Since Step 2 threw an exception, the transaction is marked as ABORTED. 
-- Running any further SQL query will fail. We execute ROLLBACK to discard the staged 
-- receipt header (Step 1) and restore the database to its exact prior state.
ROLLBACK;

-- Verification: Verify that the receipt header was NEVER created and index remains pristine
-- (This mathematically proves ATOMICITY).
SELECT * FROM sales WHERE id = currval('sales_id_seq'); -- Will return empty or error.


-- ============================================================================
-- TRANSACTION 4: Atomic Prescription & Items Registration
-- ACID FOCUS: ATOMICITY & CLINICAL SAFETY CONSTRAINTS
-- BUSINESS RULE: A doctor prescribes 2 medications. We must insert the header slip 
--                and all items atomically. We can never have an empty prescription 
--                without items, as that violates clinical regulations.
-- ============================================================================
BEGIN;

-- Step 1: Insert the Prescription Header Slip
INSERT INTO prescriptions (patient_id, doctor_id, serial_number, issue_date, expiry_date, status)
VALUES (15, 3, 'RX-889900-KG', CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', 'pending');

-- Step 2: Insert the line items detailing medicine IDs and dosages 
-- using currval() to bind onto the prescription ID atomically.
INSERT INTO prescription_items (prescription_id, medicine_id, prescribed_qty, dispensed_qty, dosage_instruction)
VALUES 
(currval('prescriptions_id_seq'), 1, 10, 0, 'Принимать по 1 таб 3 раза в день после еды / 1 tab tid pc'),
(currval('prescriptions_id_seq'), 8, 20, 0, 'Принимать по 1 капс перед сном / 1 cap hs');

-- Step 3: Complete atomic block
COMMIT;
