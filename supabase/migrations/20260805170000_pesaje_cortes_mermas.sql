-- =============================================================================
-- Pesaje / Cortes / Mermas — Fase 3
--
-- Operación de "trabajar una pieza": se agarra una existencia (producto
-- controlado_por_peso) y se distribuye su peso entre destinos:
--   - resto_aprovechable  : peso que queda en el mismo producto de origen
--                           (no genera SALIDA — literalmente sigue ahí, la
--                           idea es solo dejar el reporte de qué se hizo).
--   - recorte_vendible    : se transforma en stock de OTRO producto (SKU
--                           propio, ya creado). SALIDA del origen + ENTRADA
--                           del derivado, todo en la misma transacción.
--   - merma               : desperdicio; sale del inventario y no vuelve.
--   - consumo_interno     : usado internamente; sale del inventario y no vuelve.
--
-- Conservación de peso (invariante): la suma de todas las líneas debe
-- coincidir exactamente con `pesaje_operaciones.peso_procesado`. Se enforce
-- con un trigger a nivel DB, además del guard cliente/server, para que
-- una fila mal formada no pueda persistir.
--
-- Trazabilidad: cada movimiento generado lleva referencia
-- `PESAJE-<operacion_id>` para poder auditar. `origen` extendido con
-- 'pesaje_corte' (salidas: mermas, consumo interno, salida por transformación)
-- y 'transformacion_derivado' (entrada del recorte vendible al producto derivado).
-- =============================================================================

BEGIN;

-- 1) Tabla de encabezado ------------------------------------------------------

CREATE TABLE IF NOT EXISTS oymcomercial.pesaje_operaciones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  sucursal_id uuid NOT NULL,
  producto_origen_id uuid NOT NULL REFERENCES oymcomercial.productos(id) ON DELETE RESTRICT,
  -- Peso total que se está procesando desde el origen (kg).
  -- 12,3 = hasta 999_999_999.999 kg con precisión al gramo, más que suficiente.
  peso_procesado numeric(12,3) NOT NULL CHECK (peso_procesado > 0),
  motivo text,
  observaciones text,
  created_by uuid,
  usuario_nombre text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_pesaje_op_empresa_sucursal_fecha
  ON oymcomercial.pesaje_operaciones (empresa_id, sucursal_id, created_at DESC);
CREATE INDEX IF NOT EXISTS ix_pesaje_op_producto
  ON oymcomercial.pesaje_operaciones (empresa_id, producto_origen_id, created_at DESC);

COMMENT ON TABLE oymcomercial.pesaje_operaciones IS
  'Encabezado de una operación de pesaje/cortes/mermas sobre una existencia de un producto controlado por peso.';

-- 2) Tabla de líneas ---------------------------------------------------------

CREATE TABLE IF NOT EXISTS oymcomercial.pesaje_operacion_lineas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  operacion_id uuid NOT NULL REFERENCES oymcomercial.pesaje_operaciones(id) ON DELETE CASCADE,
  destino text NOT NULL CHECK (destino IN ('resto_aprovechable', 'recorte_vendible', 'merma', 'consumo_interno')),
  peso numeric(12,3) NOT NULL CHECK (peso > 0),
  -- Solo se usa cuando destino='recorte_vendible': producto que recibe la
  -- ENTRADA. Para otros destinos queda NULL.
  producto_derivado_id uuid REFERENCES oymcomercial.productos(id) ON DELETE RESTRICT,
  observacion text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (
    (destino = 'recorte_vendible' AND producto_derivado_id IS NOT NULL)
    OR (destino <> 'recorte_vendible' AND producto_derivado_id IS NULL)
  )
);

CREATE INDEX IF NOT EXISTS ix_pesaje_lin_operacion
  ON oymcomercial.pesaje_operacion_lineas (operacion_id);
CREATE INDEX IF NOT EXISTS ix_pesaje_lin_derivado
  ON oymcomercial.pesaje_operacion_lineas (producto_derivado_id)
  WHERE producto_derivado_id IS NOT NULL;

COMMENT ON TABLE oymcomercial.pesaje_operacion_lineas IS
  'Distribución del peso procesado entre destinos (resto/recorte/merma/consumo). Suma = peso_procesado del encabezado.';

-- 3) Trigger: conservación de peso -------------------------------------------
--
-- Después de cualquier cambio en las líneas, verifica que SUM(peso) coincida
-- con peso_procesado del encabezado. Tolerancia 0.0005 kg para absorber
-- redondeos numéricos que TS/JS pueda producir (los kilos entran con hasta
-- 3 decimales, así que medio gramo es margen seguro sin permitir
-- discrepancias reales).

CREATE OR REPLACE FUNCTION oymcomercial.trg_pesaje_conservacion_peso()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_op_id uuid;
  v_esperado numeric(12,3);
  v_sumado numeric(12,3);
BEGIN
  v_op_id := COALESCE(NEW.operacion_id, OLD.operacion_id);

  SELECT peso_procesado INTO v_esperado
    FROM oymcomercial.pesaje_operaciones
   WHERE id = v_op_id;

  -- Si el encabezado ya no existe (ON DELETE CASCADE en curso), no validamos.
  IF v_esperado IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT COALESCE(SUM(peso), 0) INTO v_sumado
    FROM oymcomercial.pesaje_operacion_lineas
   WHERE operacion_id = v_op_id;

  IF ABS(v_sumado - v_esperado) > 0.0005 THEN
    RAISE EXCEPTION
      'Conservación de peso violada: suma de líneas = % kg, peso procesado = % kg (dif % kg)',
      v_sumado, v_esperado, (v_sumado - v_esperado)
      USING ERRCODE = '23514'; -- check_violation
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_pesaje_conservacion_peso ON oymcomercial.pesaje_operacion_lineas;
CREATE CONSTRAINT TRIGGER trg_pesaje_conservacion_peso
  AFTER INSERT OR UPDATE OR DELETE ON oymcomercial.pesaje_operacion_lineas
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION oymcomercial.trg_pesaje_conservacion_peso();

COMMENT ON FUNCTION oymcomercial.trg_pesaje_conservacion_peso() IS
  'Verifica al final de la transacción que SUM(lineas.peso) == pesaje_operaciones.peso_procesado. DEFERRABLE porque el INSERT del encabezado y las líneas viene por separado.';

-- 4) RLS y permisos ----------------------------------------------------------

ALTER TABLE oymcomercial.pesaje_operaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE oymcomercial.pesaje_operacion_lineas ENABLE ROW LEVEL SECURITY;

-- El backend usa service_role (pool PG directo), así que no hay policies
-- para authenticated/anon — el gate real vive en el endpoint. GRANT solo a
-- service_role para no exponer las tablas al front por accidente.
GRANT SELECT, INSERT, UPDATE, DELETE ON oymcomercial.pesaje_operaciones TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON oymcomercial.pesaje_operacion_lineas TO service_role;

-- 5) Extender CHECK de movimientos_inventario.origen -------------------------
--
-- Mismo patrón usado en 20260702180000_movimientos_origen_produccion.sql:
-- se dropean todas las CHECKs sobre `origen` (por si otra migración lo re-creó)
-- y se re-agrega con los dos valores nuevos.

DO $$
DECLARE
  cname text;
BEGIN
  FOR cname IN
    SELECT conname
      FROM pg_constraint
     WHERE conrelid = 'oymcomercial.movimientos_inventario'::regclass
       AND contype = 'c'
       AND pg_get_constraintdef(oid) ILIKE '%origen%'
  LOOP
    EXECUTE format('ALTER TABLE oymcomercial.movimientos_inventario DROP CONSTRAINT %I', cname);
  END LOOP;

  ALTER TABLE oymcomercial.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_origen_check
    CHECK (origen IN (
      'compra',
      'venta',
      'ajuste_manual',
      'inventario_inicial',
      'anulacion_venta',
      'anulacion_compra',
      'produccion',
      'pesaje_corte',
      'transformacion_derivado'
    ));
END $$;

COMMIT;
