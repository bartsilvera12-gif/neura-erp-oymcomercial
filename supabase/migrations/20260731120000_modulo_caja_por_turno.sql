-- ============================================================================
-- Módulo Caja por turno
-- ============================================================================
--
-- Portado desde cotillon-erp (schema enlodemari / autorepuestosfelix). Mismo
-- modelo: una "caja" es un TURNO, no un día calendario. Se abre con un monto
-- inicial, se le asocian ventas y movimientos manuales mientras está abierta, y
-- se cierra contando el efectivo físico. Las ventas pertenecen a la caja por
-- `caja_id`, no por fecha — el turno puede cruzar la medianoche.
--
-- Aditivo: crea dos tablas nuevas y una columna en ventas. No toca compras,
-- facturas, SIFEN, CxC ni contabilidad.
--
-- DIFERENCIA CON EL ORIGEN — la caja es POR SUCURSAL, no por empresa.
-- En el origen el índice único era `(empresa_id) WHERE estado='abierta'`: una
-- sola caja abierta en toda la empresa. Acá cada usuario pertenece a una única
-- sucursal y ve solo lo de esa (ver src/lib/sucursales/filtro.ts), así que con
-- el modelo del origen la segunda sucursal en abrir su turno recibiría "ya hay
-- una caja abierta" por un turno que su gente no puede ni ver. El único que se
-- traslada tal cual es el invariante: una caja abierta a la vez POR SUCURSAL.
--
-- El catálogo de usuarios vive en este mismo schema (instancia monocliente), así
-- que abierta_por / cerrada_por referencian oymcomercial.usuarios y no hay
-- consulta cross-schema como en el origen.
--
-- OJO: esta migración NO otorga privilegios. Los GRANT van en
-- 20260731160000_caja_grants_y_rls.sql, que hay que aplicar junto con esta o el
-- módulo falla con "permission denied for table cajas".
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1) cajas — el turno: apertura, cierre y arqueo
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS oymcomercial.cajas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  sucursal_id uuid NOT NULL,
  numero_caja bigint NOT NULL,
  estado text NOT NULL DEFAULT 'abierta' CHECK (estado IN ('abierta','cerrada')),
  abierta_por uuid,
  cerrada_por uuid,
  fecha_apertura timestamptz NOT NULL DEFAULT now(),
  fecha_cierre timestamptz,
  monto_apertura numeric(14,2) NOT NULL DEFAULT 0,
  monto_cierre_contado numeric(14,2),
  monto_esperado_efectivo numeric(14,2),
  diferencia numeric(14,2),
  observacion_apertura text,
  observacion_cierre text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  -- La numeración corre por sucursal: cada local lleva su propia serie de
  -- turnos, como su propio talonario. Numerar por empresa haría que Casa Matriz
  -- viera saltos de número por turnos de otra sucursal que no puede consultar.
  CONSTRAINT uq_cajas_sucursal_numero UNIQUE (empresa_id, sucursal_id, numero_caja)
);

ALTER TABLE oymcomercial.cajas
  DROP CONSTRAINT IF EXISTS cajas_sucursal_id_fkey;
ALTER TABLE oymcomercial.cajas
  ADD CONSTRAINT cajas_sucursal_id_fkey FOREIGN KEY (sucursal_id)
  REFERENCES oymcomercial.sucursales(id) ON DELETE RESTRICT;

CREATE INDEX IF NOT EXISTS ix_cajas_sucursal_estado
  ON oymcomercial.cajas (empresa_id, sucursal_id, estado);
CREATE INDEX IF NOT EXISTS ix_cajas_sucursal_apertura
  ON oymcomercial.cajas (empresa_id, sucursal_id, fecha_apertura DESC);

-- El invariante del módulo: una sola caja abierta por sucursal.
CREATE UNIQUE INDEX IF NOT EXISTS uq_cajas_una_abierta_por_sucursal
  ON oymcomercial.cajas (empresa_id, sucursal_id) WHERE estado = 'abierta';

-- ---------------------------------------------------------------------------
-- 2) caja_movimientos — ingresos / egresos / retiros / ajustes manuales
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS oymcomercial.caja_movimientos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  caja_id uuid NOT NULL REFERENCES oymcomercial.cajas(id) ON DELETE CASCADE,
  tipo text NOT NULL CHECK (tipo IN ('ingreso','egreso','retiro','ajuste')),
  concepto text NOT NULL,
  monto numeric(14,2) NOT NULL,
  medio_pago text NOT NULL DEFAULT 'efectivo'
    CHECK (medio_pago IN ('efectivo','tarjeta','transferencia','otro')),
  usuario_id uuid,
  observacion text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_caja_mov_concepto_non_empty CHECK (length(trim(concepto)) > 0)
);

-- No lleva sucursal_id propio: cuelga de la caja, que ya la tiene. Duplicarla
-- abriría la puerta a un movimiento cuya sucursal no sea la de su caja.
CREATE INDEX IF NOT EXISTS ix_caja_mov_caja
  ON oymcomercial.caja_movimientos (empresa_id, caja_id, created_at);

-- ---------------------------------------------------------------------------
-- 3) ventas.caja_id — asocia la venta al turno
-- ---------------------------------------------------------------------------
-- No reasigna ventas históricas: en las previas queda NULL, que es lo correcto
-- (no pertenecieron a ningún turno).
ALTER TABLE oymcomercial.ventas ADD COLUMN IF NOT EXISTS caja_id uuid;

CREATE INDEX IF NOT EXISTS ix_ventas_caja
  ON oymcomercial.ventas (empresa_id, caja_id);

ALTER TABLE oymcomercial.ventas
  DROP CONSTRAINT IF EXISTS ventas_caja_id_fkey;
ALTER TABLE oymcomercial.ventas
  ADD CONSTRAINT ventas_caja_id_fkey FOREIGN KEY (caja_id)
  REFERENCES oymcomercial.cajas(id) ON DELETE SET NULL;

COMMIT;
