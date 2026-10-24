-- payment_app, through payment_writer, reads and inserts in payment, updates only
-- the outbox, and can neither edit the ledger, delete, nor change structure.
-- The check of Annex J.10: it writes only in its own schema.
-- Everything runs in one transaction that is rolled back.
BEGIN;
SET LOCAL ROLE payment_app;

INSERT INTO payment.payment (id, reservation_id, guest_id, amount_cents, payment_method, status,
                             gateway_transaction_id)
VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '55555555-5555-4555-8555-555555555555',
        '22222222-2222-4222-8222-222222222222', 450000, 'TARJETA_CREDITO', 'APROBADO', 'txn_0001');
INSERT INTO payment.idempotency_key (key, payment_id)
VALUES ('saga-0001:cobrar', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
INSERT INTO payment.outbox_event (id, aggregate_id, event_type, payload)
VALUES ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'PagoAprobado', '{}');
UPDATE payment.outbox_event SET published = TRUE, published_at = now()
WHERE id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
SELECT count(*) AS visible_payments FROM payment.payment;

DO $$
BEGIN
  UPDATE payment.payment SET amount_cents = 1;
  RAISE EXCEPTION 'payment_app could edit the ledger';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'payment_app cannot edit a Pago';
END
$$;

DO $$
BEGIN
  DELETE FROM payment.outbox_event;
  RAISE EXCEPTION 'payment_app could delete';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'payment_app cannot delete';
END
$$;

DO $$
BEGIN
  CREATE TABLE payment.not_allowed (id int);
  RAISE EXCEPTION 'payment_app could create a table';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'payment_app cannot change structure';
END
$$;

RESET ROLE;

-- Annex J.10: the schemas where payment_app can write.
DO $$
DECLARE
  schemas text;
BEGIN
  SELECT string_agg(DISTINCT n.nspname, ', ') INTO schemas
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.relkind = 'r'
    AND n.nspname NOT LIKE 'pg\_%' AND n.nspname <> 'information_schema'
    AND has_schema_privilege('payment_app', n.nspname, 'USAGE')
    AND (has_table_privilege('payment_app', c.oid, 'INSERT')
         OR has_table_privilege('payment_app', c.oid, 'UPDATE')
         OR has_table_privilege('payment_app', c.oid, 'DELETE'));
  IF schemas IS DISTINCT FROM 'payment' THEN
    RAISE EXCEPTION 'payment_app writes in: %', schemas;
  END IF;
  RAISE NOTICE 'Annex J.10: payment_app writes only in payment';
END
$$;

ROLLBACK;
