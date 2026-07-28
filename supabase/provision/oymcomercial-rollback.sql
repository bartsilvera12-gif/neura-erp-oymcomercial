-- =====================================================================
-- ROLLBACK del aprovisionamiento de 'oymcomercial'.
-- Alcance LIMITADO exclusivamente al schema nuevo. No toca ningún otro
-- schema (reservacaacupe, zentra_erp, public, auth, otros clientes).
-- DROP ... CASCADE elimina objetos de oymcomercial y sus FKs internas
-- (incluidas las FKs oymcomercial.* -> auth.users, que viven DENTRO de
-- oymcomercial); las filas de auth.users NO se ven afectadas.
-- =====================================================================
BEGIN;
DROP SCHEMA IF EXISTS "oymcomercial" CASCADE;
COMMIT;
