
DROP TRIGGER IF EXISTS trg_sale_items_deduct ON sale_items;
DROP TRIGGER IF EXISTS trg_sale_items_prescription ON sale_items;
DROP TRIGGER IF EXISTS trg_sale_items_totals ON sale_items;
DROP TRIGGER IF EXISTS trg_inventory_adjustment_sync ON inventory_adjustments;

DROP FUNCTION IF EXISTS fn_deduct_inventory();
DROP FUNCTION IF EXISTS fn_validate_prescription();
DROP FUNCTION IF EXISTS fn_update_sale_totals();
DROP FUNCTION IF EXISTS fn_sync_inventory_adjustment();

CREATE OR REPLACE FUNCTION fn_deduct_inventory()
RETURNS TRIGGER AS $$
DECLARE
    v_batch_qty INT;
    v_expiry_date DATE;
    v_selling_price NUMERIC(12, 2);
    v_med_name VARCHAR(150);
    v_sale_date DATE;
BEGIN
    SELECT b.current_quantity, b.expiry_date, b.selling_price, m.trade_name
    INTO v_batch_qty, v_expiry_date, v_selling_price, v_med_name
    FROM batches b
    JOIN medicines m ON b.medicine_id = m.id
    WHERE b.id = NEW.batch_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Inventory Error: Batch ID % does not exist.', NEW.batch_id;
    END IF;

    SELECT sale_timestamp::date INTO v_sale_date FROM sales WHERE id = NEW.sale_id;

    IF v_expiry_date <= COALESCE(v_sale_date, CURRENT_DATE) THEN
        RAISE EXCEPTION 'Safety Violation: Cannot sell expired medication. Batch % for "%" expired on %.', 
            NEW.batch_id, v_med_name, v_expiry_date;
    END IF;

    IF v_batch_qty < NEW.quantity THEN
        RAISE EXCEPTION 'Inventory Error: Insufficient stock for "%" in Batch %. Requested %, but only % in stock.', 
            v_med_name, NEW.batch_id, NEW.quantity, v_batch_qty;
    END IF;

    NEW.unit_price := v_selling_price;
    NEW.subtotal := v_selling_price * NEW.quantity;

    UPDATE batches
    SET current_quantity = current_quantity - NEW.quantity
    WHERE id = NEW.batch_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sale_items_deduct
BEFORE INSERT ON sale_items
FOR EACH ROW
EXECUTE FUNCTION fn_deduct_inventory();


CREATE OR REPLACE FUNCTION fn_validate_prescription()
RETURNS TRIGGER AS $$
DECLARE
    v_medicine_id INT;
    v_med_name VARCHAR(150);
    v_rx_required BOOLEAN;
    v_prescription_id INT;
    v_rx_serial VARCHAR(50);
    v_rx_expiry DATE;
    v_prescribed_qty INT;
    v_dispensed_qty INT;
    v_remaining_qty INT;
    v_total_prescribed_items INT;
    v_fully_dispensed_items INT;
    v_sale_date DATE;
BEGIN
    SELECT b.medicine_id, m.trade_name, m.prescription_required
    INTO v_medicine_id, v_med_name, v_rx_required
    FROM batches b
    JOIN medicines m ON b.medicine_id = m.id
    WHERE b.id = NEW.batch_id;

    SELECT prescription_id, sale_timestamp::date 
    INTO v_prescription_id, v_sale_date 
    FROM sales 
    WHERE id = NEW.sale_id;

    IF v_rx_required THEN
        IF v_prescription_id IS NULL THEN
            RAISE EXCEPTION 'Prescription Violation: Medicine "%" is regulated. A valid prescription is required.', 
                v_med_name;
        END IF;

        SELECT serial_number, expiry_date 
        INTO v_rx_serial, v_rx_expiry
        FROM prescriptions 
        WHERE id = v_prescription_id;

        IF v_rx_expiry < COALESCE(v_sale_date, CURRENT_DATE) THEN
            RAISE EXCEPTION 'Prescription Violation: Prescription serial % expired on %.', 
                v_rx_serial, v_rx_expiry;
        END IF;

        SELECT prescribed_qty, dispensed_qty
        INTO v_prescribed_qty, v_dispensed_qty
        FROM prescription_items
        WHERE prescription_id = v_prescription_id AND medicine_id = v_medicine_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Prescription Violation: Regulated medicine "%" is not authorized in prescription serial %.', 
                v_med_name, v_rx_serial;
        END IF;

        v_remaining_qty := v_prescribed_qty - v_dispensed_qty;

        IF NEW.quantity > v_remaining_qty THEN
            RAISE EXCEPTION 'Prescription Violation: Exceeded limit for "%". Prescribed: %, Already dispensed: %, Remaining: %, Requested: %.',
                v_med_name, v_prescribed_qty, v_dispensed_qty, v_remaining_qty, NEW.quantity;
        END IF;

        UPDATE prescription_items
        SET dispensed_qty = dispensed_qty + NEW.quantity
        WHERE prescription_id = v_prescription_id AND medicine_id = v_medicine_id;

        SELECT COUNT(*), SUM(CASE WHEN prescribed_qty = dispensed_qty THEN 1 ELSE 0 END)
        INTO v_total_prescribed_items, v_fully_dispensed_items
        FROM prescription_items
        WHERE prescription_id = v_prescription_id;

        IF v_fully_dispensed_items = v_total_prescribed_items THEN
            UPDATE prescriptions SET status = 'filled' WHERE id = v_prescription_id;
        ELSE
            UPDATE prescriptions SET status = 'partially_filled' WHERE id = v_prescription_id;
        END IF;

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sale_items_prescription
BEFORE INSERT ON sale_items
FOR EACH ROW
EXECUTE FUNCTION fn_validate_prescription();


CREATE OR REPLACE FUNCTION fn_update_sale_totals()
RETURNS TRIGGER AS $$
DECLARE
    v_sale_id INT;
    v_total_gross NUMERIC(12, 2);
    v_discount NUMERIC(12, 2);
    v_tax_amount NUMERIC(12, 2);
    v_total_net NUMERIC(12, 2);
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_sale_id := OLD.sale_id;
    ELSE
        v_sale_id := NEW.sale_id;
    END IF;

    SELECT COALESCE(SUM(subtotal), 0.00) INTO v_total_gross
    FROM sale_items
    WHERE sale_id = v_sale_id;

    SELECT discount_amount INTO v_discount
    FROM sales
    WHERE id = v_sale_id;

    v_tax_amount := ROUND(v_total_gross - (v_total_gross / 1.12), 2);
    
    v_total_net := v_total_gross - COALESCE(v_discount, 0.00);

    IF v_total_net < 0 THEN
        v_total_net := 0.00;
    END IF;

    UPDATE sales
    SET total_gross = v_total_gross,
        tax_amount = v_tax_amount,
        total_net = v_total_net
    WHERE id = v_sale_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sale_items_totals
AFTER INSERT OR UPDATE OR DELETE ON sale_items
FOR EACH ROW
EXECUTE FUNCTION fn_update_sale_totals();


CREATE OR REPLACE FUNCTION fn_sync_inventory_adjustment()
RETURNS TRIGGER AS $$
DECLARE
    v_batch_number VARCHAR(50);
BEGIN
    UPDATE batches
    SET current_quantity = current_quantity + NEW.quantity
    WHERE id = NEW.batch_id;


    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_inventory_adjustment_sync
AFTER INSERT ON inventory_adjustments
FOR EACH ROW
EXECUTE FUNCTION fn_sync_inventory_adjustment();
