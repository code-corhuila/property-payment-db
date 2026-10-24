-- Indexes of 06-data/models.md. refund.payment_id is already indexed by
-- uq_refund_payment_id.
-- "the payments of a guest":                         WHERE guest_id = ?
CREATE INDEX idx_payment_guest_id ON payment.payment (guest_id);
-- Foreign key columns.
CREATE INDEX idx_idempotency_key_payment_id ON payment.idempotency_key (payment_id);
CREATE INDEX idx_idempotency_key_refund_id ON payment.idempotency_key (refund_id);
-- "events the relay has not published yet", as in booking.outbox_event
CREATE INDEX idx_outbox_event_unpublished ON payment.outbox_event (created_at) WHERE published = FALSE;
