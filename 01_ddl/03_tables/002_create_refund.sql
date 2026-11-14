-- The Reembolso entity, as in 06-data/models.md: a ledger entry that reverses an
-- approved Pago. Its foreign key goes in 04_alter.
CREATE TABLE payment.refund (
  id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id              UUID        NOT NULL,
  amount_cents            BIGINT      NOT NULL
                          CONSTRAINT chk_refund_amount_positive CHECK (amount_cents > 0),
  currency                TEXT        NOT NULL DEFAULT 'COP'
                          CONSTRAINT chk_refund_currency CHECK (char_length(currency) = 3),
  gateway_transaction_id  TEXT        NOT NULL,   -- gateway reference of the refund
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- INV-006: at most one refund per Pago
  CONSTRAINT uq_refund_payment_id UNIQUE (payment_id)
);
