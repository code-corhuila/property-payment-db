-- Least privilege. The ledger is append-only: a Pago and a Reembolso are never
-- edited or deleted (AGGR-INV-004, data-dictionary.md), so the writer reads and
-- inserts. The only row that changes is an outbox event, when the relay marks it
-- published (ADR-005). The reader is granted to nobody: this project has no
-- cross-domain reads (ADR-008, rule 5).
GRANT USAGE ON SCHEMA payment TO payment_reader, payment_writer;
GRANT SELECT ON ALL TABLES IN SCHEMA payment TO payment_reader;
GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA payment TO payment_writer;
GRANT UPDATE ON payment.outbox_event TO payment_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA payment GRANT SELECT ON TABLES TO payment_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA payment GRANT SELECT, INSERT ON TABLES TO payment_writer;

-- The service connects as payment_app, which holds the writer role (Annex J.7).
GRANT payment_writer TO payment_app;
