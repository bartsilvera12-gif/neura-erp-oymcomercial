-- Snapshot de razón social + RUC del receptor en la fila de venta.
--
-- Motivación: el POS de Caja permite facturar sin ficha de cliente en el
-- catálogo (razón social + RUC tipeados en el momento — "cliente ad-hoc").
-- Ese snapshot ya se guarda en `facturas` cuando se emite factura ERP,
-- pero cuando la venta es "solo ticket" o se imprime en talonario pre-impreso,
-- necesitamos los datos también en `ventas` para poder reimprimir / imprimir
-- talonario sin depender del puente factura.
--
-- Idempotente. Corre en el schema oymcomercial.

DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT n.nspname AS sch
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'ventas'
      AND c.relkind = 'r'
      AND n.nspname = 'oymcomercial'
  LOOP
    EXECUTE format(
      'ALTER TABLE %I.ventas ADD COLUMN IF NOT EXISTS cliente_razon_social text',
      r.sch
    );
    EXECUTE format(
      'ALTER TABLE %I.ventas ADD COLUMN IF NOT EXISTS cliente_ruc text',
      r.sch
    );
  END LOOP;
END $$;
