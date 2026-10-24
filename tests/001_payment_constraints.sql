-- The constraints that defend the invariants of Payment
-- (02-domain/entities-and-rules.md, 06-data/models.md):
--   INV-004  a key creates one resource, once: the primary key of idempotency_key
--   one Pago per Reserva:                     uq_payment_reservation_id
--   outcome consistent with the status:       chk_payment_outcome
--   INV-006  at most one refund per Pago:     uq_refund_payment_id
-- Everything runs in one transaction that is rolled back.
BEGIN;

INSERT INTO payment.payment (id, reservation_id, guest_id, amount_cents, payment_method, status,
                             gateway_transaction_id)
VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '55555555-5555-4555-8555-555555555555',
        '22222222-2222-4222-8222-222222222222', 450000, 'TARJETA_CREDITO', 'APROBADO', 'txn_0001');
INSERT INTO payment.idempotency_key (key, payment_id)
VALUES ('saga-0001:cobrar', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
INSERT INTO payment.refund (id, payment_id, amount_cents, gateway_transaction_id)
VALUES ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 450000, 'txn_r_0001');
INSERT INTO payment.idempotency_key (key, refund_id)
VALUES ('saga-0001:cobrar:compensar', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');

-- Allowed: a RECHAZADO Pago of another Reserva, with its reason and no gateway reference.
INSERT INTO payment.payment (reservation_id, guest_id, amount_cents, payment_method, status, rejection_reason)
VALUES ('66666666-6666-4666-8666-666666666666', '22222222-2222-4222-8222-222222222222',
        180000, 'TARJETA_DEBITO', 'RECHAZADO', 'PASARELA_NO_DISPONIBLE');

-- INV-004: the same key cannot be stored twice.
DO $$
BEGIN
  INSERT INTO payment.idempotency_key (key, payment_id)
  VALUES ('saga-0001:cobrar', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
  RAISE EXCEPTION 'INV-004 not enforced: a repeated idempotency key was stored';
EXCEPTION WHEN unique_violation THEN
  RAISE NOTICE 'INV-004: repeated idempotency key rejected';
END
$$;

-- A key creates exactly one resource: neither none nor both.
DO $$
BEGIN
  INSERT INTO payment.idempotency_key (key) VALUES ('saga-0002:cobrar');
  RAISE EXCEPTION 'chk_idempotency_key_one_resource not enforced: a key with no resource was stored';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'chk_idempotency_key_one_resource: a key with no resource rejected';
END
$$;

-- One Pago per Reserva.
DO $$
BEGIN
  INSERT INTO payment.payment (reservation_id, guest_id, amount_cents, payment_method, status,
                               gateway_transaction_id)
  VALUES ('55555555-5555-4555-8555-555555555555', '22222222-2222-4222-8222-222222222222',
          450000, 'TARJETA_CREDITO', 'APROBADO', 'txn_0002');
  RAISE EXCEPTION 'uq_payment_reservation_id not enforced: a second Pago for a Reserva was stored';
EXCEPTION WHEN unique_violation THEN
  RAISE NOTICE 'uq_payment_reservation_id: a second Pago for the same Reserva rejected';
END
$$;

-- An APROBADO Pago without its gateway reference is inconsistent.
DO $$
BEGIN
  INSERT INTO payment.payment (reservation_id, guest_id, amount_cents, payment_method, status)
  VALUES ('77777777-7777-4777-8777-777777777777', '22222222-2222-4222-8222-222222222222',
          450000, 'TARJETA_CREDITO', 'APROBADO');
  RAISE EXCEPTION 'chk_payment_outcome not enforced: APROBADO without transaction id was stored';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'chk_payment_outcome: APROBADO without gateway reference rejected';
END
$$;

-- INV-006: at most one refund per Pago.
DO $$
BEGIN
  INSERT INTO payment.refund (payment_id, amount_cents, gateway_transaction_id)
  VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 450000, 'txn_r_0002');
  RAISE EXCEPTION 'INV-006 not enforced: a second refund for a Pago was stored';
EXCEPTION WHEN unique_violation THEN
  RAISE NOTICE 'INV-006: a second refund for the same Pago rejected';
END
$$;

ROLLBACK;
