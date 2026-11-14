-- Foreign keys inside the schema, as in 06-data/models.md. The ledger is
-- append-only: nothing referenced can be deleted.
ALTER TABLE payment.refund
  ADD CONSTRAINT fk_refund_payment
  FOREIGN KEY (payment_id) REFERENCES payment.payment (id) ON DELETE RESTRICT;

ALTER TABLE payment.idempotency_key
  ADD CONSTRAINT fk_idempotency_key_payment
  FOREIGN KEY (payment_id) REFERENCES payment.payment (id) ON DELETE RESTRICT;
ALTER TABLE payment.idempotency_key
  ADD CONSTRAINT fk_idempotency_key_refund
  FOREIGN KEY (refund_id) REFERENCES payment.refund (id) ON DELETE RESTRICT;
