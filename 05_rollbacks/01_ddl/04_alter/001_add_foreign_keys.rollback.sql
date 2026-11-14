ALTER TABLE payment.idempotency_key DROP CONSTRAINT IF EXISTS fk_idempotency_key_refund;
ALTER TABLE payment.idempotency_key DROP CONSTRAINT IF EXISTS fk_idempotency_key_payment;
ALTER TABLE payment.refund          DROP CONSTRAINT IF EXISTS fk_refund_payment;
