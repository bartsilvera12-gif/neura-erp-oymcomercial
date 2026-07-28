-- Auditoría de cobros: quién registró el pago. Idempotente. Solo schema oymcomercial.
ALTER TABLE oymcomercial.cobros_clientes
  ADD COLUMN IF NOT EXISTS usuario_id uuid;
ALTER TABLE oymcomercial.cobros_clientes
  ADD COLUMN IF NOT EXISTS usuario_nombre text;
