REVOKE payment_writer FROM payment_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA payment REVOKE ALL ON TABLES FROM payment_reader, payment_writer;
REVOKE ALL ON ALL TABLES IN SCHEMA payment FROM payment_reader, payment_writer;
REVOKE USAGE ON SCHEMA payment FROM payment_reader, payment_writer;
