-- Amplía el CHECK de compras.metodo_pago para aceptar 'cheque'.
--
-- Motivación: la migración 20260710130000 dejó el enum en
-- ('efectivo','transferencia','tarjeta'). Los proveedores de O&M Comercial
-- suelen cobrar con cheque; el módulo Pagos-Proveedores ya lo soporta,
-- ahora también el alta de compra en /compras/nueva.
--
-- Idempotente: DROP IF EXISTS + ADD.

DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT n.nspname AS sch
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'compras'
      AND c.relkind = 'r'
      AND n.nspname = 'oymcomercial'
  LOOP
    EXECUTE format(
      'ALTER TABLE %I.compras DROP CONSTRAINT IF EXISTS compras_metodo_pago_check',
      r.sch
    );
    EXECUTE format(
      'ALTER TABLE %I.compras ADD CONSTRAINT compras_metodo_pago_check
         CHECK (metodo_pago IS NULL OR metodo_pago IN (''efectivo'', ''transferencia'', ''tarjeta'', ''cheque''))',
      r.sch
    );
  END LOOP;
END $$;
