-- The Pago aggregate, as in 06-data/models.md: one immutable row per charge
-- attempt, already resolved.
CREATE TABLE payment.payment (
  id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Business fields
  reservation_id          UUID        NOT NULL,   -- owned by booking: referenced by id, no FK
  guest_id                UUID        NOT NULL,   -- owned by identity: who pays; no FK
  amount_cents            BIGINT      NOT NULL
                          CONSTRAINT chk_payment_amount_positive CHECK (amount_cents > 0),
  currency                TEXT        NOT NULL DEFAULT 'COP'
                          CONSTRAINT chk_payment_currency CHECK (char_length(currency) = 3),
  payment_method          TEXT        NOT NULL
                          CONSTRAINT chk_payment_method
                          CHECK (payment_method IN ('TARJETA_CREDITO', 'TARJETA_DEBITO')),
  status                  TEXT        NOT NULL
                          CONSTRAINT chk_payment_status CHECK (status IN ('APROBADO', 'RECHAZADO')),
  gateway_transaction_id  TEXT,       -- gateway reference, set if APROBADO
  rejection_reason        TEXT        -- set if RECHAZADO
                          CONSTRAINT chk_payment_rejection_reason
                          CHECK (rejection_reason IN ('FONDOS_INSUFICIENTES', 'TARJETA_RECHAZADA',
                                                      'TARJETA_VENCIDA', 'PASARELA_NO_DISPONIBLE')),

  -- Audit
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- No updated_at / deleted_at: Pago is immutable once created (AGGR-INV-004)

  -- One Saga charges one Reserva once
  CONSTRAINT uq_payment_reservation_id UNIQUE (reservation_id),

  CONSTRAINT chk_payment_outcome CHECK (
       (status = 'APROBADO'  AND gateway_transaction_id IS NOT NULL AND rejection_reason IS NULL)
    OR (status = 'RECHAZADO' AND rejection_reason IS NOT NULL AND gateway_transaction_id IS NULL)
  )
);
