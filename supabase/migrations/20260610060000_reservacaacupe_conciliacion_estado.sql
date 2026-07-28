-- Conciliación bancaria con estado por movimiento: pendiente | aprobado | rechazado.
-- Se guarda en la fuente del movimiento (detalle de cobro de venta y cobro de CxC).
-- Idempotente. Solo schema oymcomercial. NO toca stock/deuda/ventas.

-- ventas_pagos_detalle ------------------------------------------------------
ALTER TABLE oymcomercial.ventas_pagos_detalle
  ADD COLUMN IF NOT EXISTS conciliacion_estado text NOT NULL DEFAULT 'pendiente';
ALTER TABLE oymcomercial.ventas_pagos_detalle
  ADD COLUMN IF NOT EXISTS conciliado_at timestamptz;
ALTER TABLE oymcomercial.ventas_pagos_detalle
  ADD COLUMN IF NOT EXISTS conciliado_por text;
ALTER TABLE oymcomercial.ventas_pagos_detalle
  DROP CONSTRAINT IF EXISTS vpd_conciliacion_estado_check;
ALTER TABLE oymcomercial.ventas_pagos_detalle
  ADD CONSTRAINT vpd_conciliacion_estado_check
  CHECK (conciliacion_estado = ANY (ARRAY['pendiente'::text, 'aprobado'::text, 'rechazado'::text]));

-- cobros_clientes -----------------------------------------------------------
ALTER TABLE oymcomercial.cobros_clientes
  ADD COLUMN IF NOT EXISTS conciliacion_estado text NOT NULL DEFAULT 'pendiente';
ALTER TABLE oymcomercial.cobros_clientes
  ADD COLUMN IF NOT EXISTS conciliado_at timestamptz;
ALTER TABLE oymcomercial.cobros_clientes
  ADD COLUMN IF NOT EXISTS conciliado_por text;
ALTER TABLE oymcomercial.cobros_clientes
  DROP CONSTRAINT IF EXISTS cc_conciliacion_estado_check;
ALTER TABLE oymcomercial.cobros_clientes
  ADD CONSTRAINT cc_conciliacion_estado_check
  CHECK (conciliacion_estado = ANY (ARRAY['pendiente'::text, 'aprobado'::text, 'rechazado'::text]));
