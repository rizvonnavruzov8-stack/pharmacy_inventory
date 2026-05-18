

BEGIN;

INSERT INTO sales (employee_id, prescription_id, payment_method, discount_amount)
VALUES (2, NULL, 'cash', 0.00);

INSERT INTO sale_items (sale_id, batch_id, quantity)
VALUES (currval('sales_id_seq'), 1, 2);

SELECT id, total_gross, tax_amount, total_net FROM sales WHERE id = currval('sales_id_seq');
SELECT id, current_quantity FROM batches WHERE id = 1;

COMMIT;


BEGIN;

UPDATE batches 
SET current_quantity = current_quantity + 100 
WHERE id = 4;

INSERT INTO inventory_adjustments (batch_id, employee_id, quantity, adjustment_type, reason)
VALUES (4, 3, 100, 'reconciliation', 'Restocked fresh supplier intake (Поступление новой партии товара)');

SELECT id, current_quantity, initial_quantity FROM batches WHERE id = 4;

COMMIT;


BEGIN;

INSERT INTO sales (employee_id, prescription_id, payment_method, discount_amount)
VALUES (2, NULL, 'mobile_qr', 0.00);

INSERT INTO sale_items (sale_id, batch_id, quantity)
VALUES (currval('sales_id_seq'), 2, 9999);

ROLLBACK;

SELECT * FROM sales WHERE id = currval('sales_id_seq'); -- Will return empty or error.


BEGIN;

INSERT INTO prescriptions (patient_id, doctor_id, serial_number, issue_date, expiry_date, status)
VALUES (15, 3, 'RX-889900-KG', CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', 'pending');

INSERT INTO prescription_items (prescription_id, medicine_id, prescribed_qty, dispensed_qty, dosage_instruction)
VALUES 
(currval('prescriptions_id_seq'), 1, 10, 0, 'Принимать по 1 таб 3 раза в день после еды / 1 tab tid pc'),
(currval('prescriptions_id_seq'), 8, 20, 0, 'Принимать по 1 капс перед сном / 1 cap hs');

COMMIT;
