-- Conciliación de cobros: snapshot del nombre de la entidad bancaria en cobros_clientes
-- (mismo criterio que ventas_pagos_detalle). Idempotente. Solo schema oymcomercial.
ALTER TABLE oymcomercial.cobros_clientes
  ADD COLUMN IF NOT EXISTS entidad_nombre_snapshot text;
