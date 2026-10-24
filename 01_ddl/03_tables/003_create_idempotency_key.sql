-- The key each Pago and each Reembolso was created with, as in 06-data/models.md.
-- Its foreign keys go in 04_alter. The Saga sends <sagaId>:cobrar and
-- <sagaId>:cobrar:compensar.
CREATE TABLE payment.idempotency_key (
  key         TEXT        PRIMARY KEY
              CONSTRAINT chk_idempotency_key_length CHECK (char_length(key) BETWEEN 8 AND 128),
  payment_id  UUID,
  refund_id   UUID,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- A key creates exactly one resource
  CONSTRAINT chk_idempotency_key_one_resource CHECK (num_nonnulls(payment_id, refund_id) = 1)
);
