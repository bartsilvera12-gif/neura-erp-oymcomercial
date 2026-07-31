-- ============================================================================
-- Pagos a proveedores (cuentas por pagar)
-- ============================================================================
--
-- Portado desde cotillon-erp. `compras` ya guarda `tipo_pago` y `plazo_dias`,
-- así que la compra a crédito se podía registrar, pero no había dónde anotar
-- los pagos: la deuda con el proveedor quedaba sin cancelar nunca.
--
-- MODELO: el pago se ata al DOCUMENTO del proveedor, no a la línea de compra.
-- `compras` tiene una fila por producto y todas comparten `numero_control` (la
-- factura recibida). Se paga la factura entera, no el renglón de un producto,
-- así que la deuda se agrupa por `numero_control` y el saldo sale de
-- SUM(compras.total) − SUM(compras_pagos.monto).
--
-- No hay FK contra `compras`: la referencia es el `numero_control`, que no es
-- clave única ahí (se repite por cada línea). El chequeo de que el documento
-- existe y no está anulado lo hace la API antes de insertar.
--
-- POR SUCURSAL, igual que la caja: la deuda es del local que compró, y quien
-- paga desde Luque no tiene por qué ver ni cancelar facturas de San Lorenzo.
-- ============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS oymcomercial.compras_pagos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  sucursal_id uuid NOT NULL,
  -- Documento del proveedor que se está pagando. Coincide con
  -- compras.numero_control.
  numero_control text NOT NULL,
  -- Snapshot del proveedor: si mañana se renombra, el pago sigue diciendo a
  -- quién se le pagó ese día.
  proveedor_id uuid,
  proveedor_nombre text,
  monto numeric(14,2) NOT NULL CHECK (monto > 0),
  moneda text NOT NULL DEFAULT 'PYG',
  metodo_pago text NOT NULL
    CHECK (metodo_pago IN ('efectivo','transferencia','tarjeta','cheque','otro')),
  -- Conciliación bancaria: con qué entidad y bajo qué referencia se pagó.
  entidad_id uuid,
  entidad_nombre text,
  referencia text,
  observaciones text,
  fecha timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  usuario_nombre text
);

ALTER TABLE oymcomercial.compras_pagos
  DROP CONSTRAINT IF EXISTS compras_pagos_sucursal_id_fkey;
ALTER TABLE oymcomercial.compras_pagos
  ADD CONSTRAINT compras_pagos_sucursal_id_fkey FOREIGN KEY (sucursal_id)
  REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;

ALTER TABLE oymcomercial.compras_pagos
  DROP CONSTRAINT IF EXISTS compras_pagos_proveedor_id_fkey;
ALTER TABLE oymcomercial.compras_pagos
  ADD CONSTRAINT compras_pagos_proveedor_id_fkey FOREIGN KEY (proveedor_id)
  REFERENCES oymcomercial.proveedores(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS compras_pagos_sucursal_fecha_ix
  ON oymcomercial.compras_pagos (empresa_id, sucursal_id, fecha DESC);

CREATE INDEX IF NOT EXISTS compras_pagos_numero_control_ix
  ON oymcomercial.compras_pagos (empresa_id, sucursal_id, numero_control);

CREATE INDEX IF NOT EXISTS compras_pagos_proveedor_ix
  ON oymcomercial.compras_pagos (empresa_id, proveedor_id)
  WHERE proveedor_id IS NOT NULL;

-- Privilegios: solo service_role, igual que las tablas de caja. Esta tabla no
-- la toca nunca el navegador — todo pasa por /api/compras/pagos, que corre con
-- service role. RLS habilitada sin políticas: deny by default para el resto.
-- (service_role tiene BYPASSRLS, así que no se ve afectado.)
GRANT SELECT, INSERT, UPDATE, DELETE ON oymcomercial.compras_pagos TO service_role;
ALTER TABLE oymcomercial.compras_pagos ENABLE ROW LEVEL SECURITY;

COMMIT;
