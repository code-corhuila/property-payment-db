-- Outbox of the domain events of the Pago (ADR-005). models.md: same columns as
-- booking.outbox_event, in the schema payment; aggregate_type is Pago, and
-- chk_outbox_event_type allows PagoAprobado and PagoRechazado.
CREATE TABLE payment.outbox_event (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  aggregate_id      UUID        NOT NULL,               -- payment id
  aggregate_type    TEXT        NOT NULL DEFAULT 'Pago',
  event_type        TEXT        NOT NULL                -- wire-format name, as in domain-events.md
                    CONSTRAINT chk_outbox_event_type CHECK (event_type IN
                      ('PagoAprobado', 'PagoRechazado')),
  payload           JSONB       NOT NULL,               -- full event envelope
  published         BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  published_at      TIMESTAMPTZ
);
