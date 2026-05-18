-- ============================================================================
-- PROJECT: Small Pharmacy Inventory & Prescription System (COMP2082 Final Project)
-- FILE: test_assertions.sql
-- DESCRIPTION: Automated Database Test Suite & Validation Assertions.
-- ============================================================================

-- Make sure notifications and notices are displayed in the query terminal
SET client_min_messages = NOTICE;

-- Ensure database is freshly seeded before running tests
\i seed.sql

-- ============================================================================
-- TEST 1: Attempt to sell more stock than exists
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '--- [TEST 1 START]: Attempting to sell 500 units of Ketonal Duo (Only 150 available) ---';
    
    -- Insert a dummy sale record (employee 2, no prescription)
    INSERT INTO sales (id, employee_id, prescription_id, payment_method)
    VALUES (999, 2, NULL, 'cash');

    -- Attempt to insert sale_item exceeding batch capacity (Batch 3 has current_quantity = 150)
    INSERT INTO sale_items (sale_id, batch_id, quantity)
    VALUES (999, 3, 500);

    -- If this line is reached, the trigger failed to raise an exception
    RAISE EXCEPTION 'TEST 1 FAILED: Trigger allowed selling non-existent stock.';
    
EXCEPTION
    WHEN raise_exception THEN
        IF SQLERRM LIKE '%Insufficient stock%' THEN
            RAISE NOTICE 'TEST 1 PASSED: Successfully caught expected stock exception: "%"', SQLERRM;
        ELSE
            RAISE EXCEPTION 'TEST 1 FAILED: Caught unexpected exception: %', SQLERRM;
        END IF;
END
$$;


-- ============================================================================
-- TEST 2: Attempt to sell medicine from an expired batch
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '--- [TEST 2 START]: Attempting to sell Amoxicillin from expired Batch 2 ---';
    
    INSERT INTO sales (id, employee_id, prescription_id, payment_method)
    VALUES (998, 2, 1, 'card'); -- Sales under valid Prescription 1

    -- Batch 2 expired on 2025-01-01
    INSERT INTO sale_items (sale_id, batch_id, quantity)
    VALUES (998, 2, 1);

    RAISE EXCEPTION 'TEST 2 FAILED: Trigger allowed selling expired medicine.';
    
EXCEPTION
    WHEN raise_exception THEN
        IF SQLERRM LIKE '%Cannot sell expired medication%' THEN
            RAISE NOTICE 'TEST 2 PASSED: Successfully caught expected expiration exception: "%"', SQLERRM;
        ELSE
            RAISE EXCEPTION 'TEST 2 FAILED: Caught unexpected exception: %', SQLERRM;
        END IF;
END
$$;


-- ============================================================================
-- TEST 3: Attempt to sell a prescription-only medicine without a prescription
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '--- [TEST 3 START]: Attempting to sell regulated Enalapril (Batch 4) without a prescription ---';
    
    INSERT INTO sales (id, employee_id, prescription_id, payment_method)
    VALUES (997, 2, NULL, 'mobile_qr'); -- prescription_id is explicitly NULL

    -- Enalapril requires prescription_required = TRUE
    INSERT INTO sale_items (sale_id, batch_id, quantity)
    VALUES (997, 4, 10);

    RAISE EXCEPTION 'TEST 3 FAILED: Trigger allowed selling regulated medicine without prescription.';
    
EXCEPTION
    WHEN raise_exception THEN
        IF SQLERRM LIKE '%regulated. A valid prescription is required%' THEN
            RAISE NOTICE 'TEST 3 PASSED: Successfully caught expected prescription check exception: "%"', SQLERRM;
        ELSE
            RAISE EXCEPTION 'TEST 3 FAILED: Caught unexpected exception: %', SQLERRM;
        END IF;
END
$$;


-- ============================================================================
-- TEST 4: Attempt to sell a prescription drug not listed in the prescription
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '--- [TEST 4 START]: Attempting to sell Ceftriaxone (Batch 6) under Prescription 1 (which does not list it) ---';
    
    INSERT INTO sales (id, employee_id, prescription_id, payment_method)
    VALUES (996, 2, 1, 'cash'); -- RX 1 specifies Amoxicillin and Bisoprolol, NOT Ceftriaxone

    -- Batch 6 contains Ceftriaxone
    INSERT INTO sale_items (sale_id, batch_id, quantity)
    VALUES (996, 6, 2);

    RAISE EXCEPTION 'TEST 4 FAILED: Trigger allowed selling unprescribed regulated medicine.';
    
EXCEPTION
    WHEN raise_exception THEN
        IF SQLERRM LIKE '%not authorized in prescription%' THEN
            RAISE NOTICE 'TEST 4 PASSED: Successfully caught expected unauthorized medicine exception: "%"', SQLERRM;
        ELSE
            RAISE EXCEPTION 'TEST 4 FAILED: Caught unexpected exception: %', SQLERRM;
        END IF;
END
$$;


-- ============================================================================
-- TEST 5: Attempt to exceed remaining prescribed limit
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '--- [TEST 5 START]: Attempting to purchase 25 capsules of Amoxicillin (Prescribed: 20) ---';
    
    INSERT INTO sales (id, employee_id, prescription_id, payment_method)
    VALUES (995, 2, 1, 'card'); -- RX 1 limits Amoxicillin to 20

    -- Batch 1 contains active Amoxicillin
    INSERT INTO sale_items (sale_id, batch_id, quantity)
    VALUES (995, 1, 25);

    RAISE EXCEPTION 'TEST 5 FAILED: Trigger allowed over-dispensing prescribed drug.';
    
EXCEPTION
    WHEN raise_exception THEN
        IF SQLERRM LIKE '%Exceeded limit for%' THEN
            RAISE NOTICE 'TEST 5 PASSED: Successfully caught expected quantity limit exception: "%"', SQLERRM;
        ELSE
            RAISE EXCEPTION 'TEST 5 FAILED: Caught unexpected exception: %', SQLERRM;
        END IF;
END
$$;


-- ============================================================================
-- TEST 6: Attempt to buy under an expired prescription
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '--- [TEST 6 START]: Attempting to sell Ceftriaxone under expired Prescription 2 ---';
    
    INSERT INTO sales (id, employee_id, prescription_id, payment_method)
    VALUES (994, 2, 2, 'mobile_qr'); -- RX 2 expired on 2025-02-01

    -- Batch 6 contains Ceftriaxone
    INSERT INTO sale_items (sale_id, batch_id, quantity)
    VALUES (994, 6, 5);

    RAISE EXCEPTION 'TEST 6 FAILED: Trigger allowed transactions under expired prescriptions.';
    
EXCEPTION
    WHEN raise_exception THEN
        IF SQLERRM LIKE '%expired on%' THEN
            RAISE NOTICE 'TEST 6 PASSED: Successfully caught expected expired prescription exception: "%"', SQLERRM;
        ELSE
            RAISE EXCEPTION 'TEST 6 FAILED: Caught unexpected exception: %', SQLERRM;
        END IF;
END
$$;


-- ============================================================================
-- TEST 7: A successful transaction (OTC + regulated medicines within limits)
-- ============================================================================
DO $$
DECLARE
    v_gross NUMERIC(12, 2);
    v_tax NUMERIC(12, 2);
    v_net NUMERIC(12, 2);
    v_rx_status VARCHAR(20);
    v_dispensed INT;
    v_stock_amx INT;
    v_stock_vit INT;
BEGIN
    RAISE NOTICE '--- [TEST 7 START]: Processing a successful sale ---';
    RAISE NOTICE 'Purchasing 5 capsules of Amoxicillin (regulated, under RX 1) and 10 boxes of Vitamin C (OTC)';

    -- 1. Create sale record linked to valid Prescription 1 (with 10.00 KGS discount)
    INSERT INTO sales (id, employee_id, prescription_id, payment_method, discount_amount)
    VALUES (100, 2, 1, 'mobile_qr', 10.00);

    -- 2. Add 5 Amoxicillin (Batch 1 - Unit Price: 165.00)
    INSERT INTO sale_items (sale_id, batch_id, quantity) VALUES (100, 1, 5);

    -- 3. Add 10 Vitamin C (Batch 5 - Unit Price: 110.00)
    INSERT INTO sale_items (sale_id, batch_id, quantity) VALUES (100, 5, 10);

    -- 4. Assertions:
    -- Verify financial computations:
    -- gross = (5 * 165) + (10 * 110) = 825.00 + 1100.00 = 1925.00 KGS
    -- tax = 1925.00 - (1925.00 / 1.12) = 206.25 KGS (12% VAT included)
    -- net = 1925.00 - 10.00 = 1915.00 KGS
    SELECT total_gross, tax_amount, total_net INTO v_gross, v_tax, v_net FROM sales WHERE id = 100;
    IF v_gross <> 1925.00 OR v_tax <> 206.25 OR v_net <> 1915.00 THEN
        RAISE EXCEPTION 'TEST 7 FAILED: Financial math incorrect. Gross: %, Tax: %, Net: %', v_gross, v_tax, v_net;
    END IF;

    -- Verify stock deduction:
    -- Amoxicillin batch 1: 100 -> 95
    -- Vitamin C batch 5: 300 -> 290
    SELECT current_quantity INTO v_stock_amx FROM batches WHERE id = 1;
    SELECT current_quantity INTO v_stock_vit FROM batches WHERE id = 5;
    IF v_stock_amx <> 95 OR v_stock_vit <> 290 THEN
        RAISE EXCEPTION 'TEST 7 FAILED: Stock not deducted correctly. Amoxicillin: %, Vitamin C: %', v_stock_amx, v_stock_vit;
    END IF;

    -- Verify prescription tracking:
    -- Prescription 1 Amoxicillin dispensed_qty: 0 -> 5
    SELECT dispensed_qty INTO v_dispensed FROM prescription_items WHERE prescription_id = 1 AND medicine_id = 1;
    IF v_dispensed <> 5 THEN
        RAISE EXCEPTION 'TEST 7 FAILED: Prescription item dispensed qty not updated. Dispensed: %', v_dispensed;
    END IF;

    -- Verify prescription status transition:
    -- Prescription status: pending -> partially_filled
    SELECT status INTO v_rx_status FROM prescriptions WHERE id = 1;
    IF v_rx_status <> 'partially_filled' THEN
        RAISE EXCEPTION 'TEST 7 FAILED: Prescription status not updated to partially_filled. Status: %', v_rx_status;
    END IF;

    RAISE NOTICE 'TEST 7 PASSED: Sale completed successfully, inventory adjusted, prescription updated, and financial math matches!';
END
$$;
