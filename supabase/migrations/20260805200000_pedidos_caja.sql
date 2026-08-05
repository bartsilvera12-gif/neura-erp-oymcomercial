-- =============================================================================
-- Pedidos a Caja — módulo Pedidos portado desde stzautopartes-erp.
--
-- El vendedor arma un pedido desde /pedidos/nuevo y lo envía a la Caja. El
-- cajero lo ve en "Pedidos por cobrar", lo abre y cobra desde el POS. Cuando
-- se cobra queda vinculado a la venta como 'facturado'.
--
-- Modelo consolidado (fusiona las 2 migraciones del otro repo en una sola):
--   - Tabla pedidos_caja con items JSONB (snapshot del pedido).
--   - Numero PED-XXXXXX por empresa, único parcial.
--   - Estado: pendiente | en_caja | facturado | cancelado.
--   - Columna en_cola_caja: si false, el pedido volvió al vendedor y NO
--     aparece en Caja hasta que lo re-envíen.
--   - Sucursal: obligatoria (mismo criterio que el resto de tablas
--     transaccionales de esta instancia).
--   - RLS por empresa (puede_acceder_empresa) + GRANT service_role.
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS oymcomercial.pedidos_caja (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id           uuid NOT NULL,
  sucursal_id          uuid NOT NULL,
  numero               text NULL,
  titulo               text NOT NULL,

  cliente_id           uuid NULL,
  cliente_nombre       text NULL,
  cliente_telefono     text NULL,
  observacion          text NULL,

  items                jsonb NOT NULL DEFAULT '[]'::jsonb,
  total_estimado       numeric NOT NULL DEFAULT 0,

  estado               text NOT NULL DEFAULT 'pendiente'
                       CHECK (estado IN ('pendiente','en_caja','facturado','cancelado')),
  en_cola_caja         boolean NOT NULL DEFAULT true,

  armado_por_id        uuid NULL,
  armado_por_email     text NULL,
  abierto_por_id       uuid NULL,
  abierto_por_email    text NULL,
  abierto_at           timestamptz NULL,

  venta_id             uuid NULL,
  venta_numero         text NULL,
  facturado_at         timestamptz NULL,

  cancelado_por_id     uuid NULL,
  cancelado_motivo     text NULL,
  cancelado_at         timestamptz NULL,

  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now()
);

-- Índices ------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS pedidos_caja_empresa_estado_idx
  ON oymcomercial.pedidos_caja (empresa_id, sucursal_id, estado, created_at DESC);

CREATE INDEX IF NOT EXISTS pedidos_caja_armado_por_idx
  ON oymcomercial.pedidos_caja (empresa_id, armado_por_id, created_at DESC);

CREATE INDEX IF NOT EXISTS pedidos_caja_venta_idx
  ON oymcomercial.pedidos_caja (empresa_id, venta_id)
  WHERE venta_id IS NOT NULL;

-- Único parcial: PED-XXXXXX es único por empresa (NULLs no cuentan).
CREATE UNIQUE INDEX IF NOT EXISTS pedidos_caja_numero_uniq
  ON oymcomercial.pedidos_caja (empresa_id, numero)
  WHERE numero IS NOT NULL;

-- Trigger touch updated_at ------------------------------------------------

CREATE OR REPLACE FUNCTION oymcomercial.touch_pedidos_caja_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS pedidos_caja_touch ON oymcomercial.pedidos_caja;
CREATE TRIGGER pedidos_caja_touch
  BEFORE UPDATE ON oymcomercial.pedidos_caja
  FOR EACH ROW
  EXECUTE FUNCTION oymcomercial.touch_pedidos_caja_updated_at();

-- RLS + GRANT --------------------------------------------------------------

ALTER TABLE oymcomercial.pedidos_caja ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pedidos_caja_select ON oymcomercial.pedidos_caja;
DROP POLICY IF EXISTS pedidos_caja_insert ON oymcomercial.pedidos_caja;
DROP POLICY IF EXISTS pedidos_caja_update ON oymcomercial.pedidos_caja;
DROP POLICY IF EXISTS pedidos_caja_delete ON oymcomercial.pedidos_caja;

CREATE POLICY pedidos_caja_select ON oymcomercial.pedidos_caja
  FOR SELECT USING (public.puede_acceder_empresa(empresa_id));
CREATE POLICY pedidos_caja_insert ON oymcomercial.pedidos_caja
  FOR INSERT WITH CHECK (public.puede_acceder_empresa(empresa_id));
CREATE POLICY pedidos_caja_update ON oymcomercial.pedidos_caja
  FOR UPDATE USING (public.puede_acceder_empresa(empresa_id))
  WITH CHECK (public.puede_acceder_empresa(empresa_id));
CREATE POLICY pedidos_caja_delete ON oymcomercial.pedidos_caja
  FOR DELETE USING (public.puede_acceder_empresa(empresa_id));

GRANT SELECT, INSERT, UPDATE, DELETE ON oymcomercial.pedidos_caja TO service_role;

-- Módulo en el catálogo + activación por empresa (mismo patrón que otros
-- módulos: idempotente, no toca usuario_modulos para no romper el "0 filas
-- = ve todo" de los usuarios existentes).

INSERT INTO oymcomercial.modulos (slug, nombre)
SELECT 'pedidos', 'Pedidos'
WHERE NOT EXISTS (SELECT 1 FROM oymcomercial.modulos WHERE slug = 'pedidos');

INSERT INTO oymcomercial.empresa_modulos (empresa_id, modulo_id, activo)
SELECT e.id, m.id, true
  FROM oymcomercial.empresas e
 CROSS JOIN oymcomercial.modulos m
 WHERE m.slug = 'pedidos'
   AND NOT EXISTS (
     SELECT 1 FROM oymcomercial.empresa_modulos em
      WHERE em.empresa_id = e.id AND em.modulo_id = m.id
   );

COMMIT;
