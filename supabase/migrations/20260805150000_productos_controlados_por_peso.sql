-- =============================================================================
-- Productos controlados por peso (queso, jamón, fraccionables).
--
-- Agrega a `oymcomercial.productos` la configuración necesaria para vender
-- un mismo producto por peso con dos modalidades sobre EL MISMO stock:
--   - entero          → precio_kg_entero
--   - recortado/feteado → precio_kg_recortado
--
-- El "recorte vendible" (recorte físicamente separado durante el
-- procesamiento de una pieza) queda para Fase 3 como producto derivado con
-- SKU/precio/stock propio; NO se modela como tercera modalidad.
--
-- Todo el stock vive en `productos.stock_actual` (numeric, ya soporta
-- decimales). Elegir modalidad al vender solo cambia el precio/kg — no
-- duplica ni bifurca el stock.
--
-- Los productos vendidos por unidad no cambian: los nuevos flags son
-- opcionales y su default es "no controlado por peso".
-- =============================================================================

BEGIN;

-- 1) Columnas nuevas ---------------------------------------------------------

ALTER TABLE oymcomercial.productos
  ADD COLUMN IF NOT EXISTS controlado_por_peso boolean NOT NULL DEFAULT false;

ALTER TABLE oymcomercial.productos
  ADD COLUMN IF NOT EXISTS precio_kg_entero numeric;

ALTER TABLE oymcomercial.productos
  ADD COLUMN IF NOT EXISTS precio_kg_recortado numeric;

-- Modalidades activas del producto. Subset de {entero, recortado}. Se guarda
-- como text[] (misma estrategia que otras columnas configurables del ERP) y
-- se valida por CHECK. Default en NULL (no aplica) para productos por unidad.
ALTER TABLE oymcomercial.productos
  ADD COLUMN IF NOT EXISTS modalidades_activas text[];

-- 2) CHECKs -----------------------------------------------------------------
--
-- Regla: si controlado_por_peso = true, entonces:
--   - unidad_medida debe ser 'KG' (evita mezclar UNIDAD con precio/kg)
--   - modalidades_activas debe tener al menos un elemento válido
--   - cada modalidad activa debe tener su precio/kg > 0
--
-- Si controlado_por_peso = false los tres campos nuevos son ignorados
-- (pueden quedar NULL). Los CHECKS solo aplican cuando el flag está en true.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chk_productos_peso_unidad_kg' AND conrelid = 'oymcomercial.productos'::regclass
  ) THEN
    ALTER TABLE oymcomercial.productos
      ADD CONSTRAINT chk_productos_peso_unidad_kg
      CHECK (
        controlado_por_peso = false
        OR upper(coalesce(unidad_medida, '')) = 'KG'
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chk_productos_modalidades_validas' AND conrelid = 'oymcomercial.productos'::regclass
  ) THEN
    ALTER TABLE oymcomercial.productos
      ADD CONSTRAINT chk_productos_modalidades_validas
      CHECK (
        modalidades_activas IS NULL
        OR modalidades_activas <@ ARRAY['entero', 'recortado']::text[]
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chk_productos_peso_modalidades_no_vacio' AND conrelid = 'oymcomercial.productos'::regclass
  ) THEN
    ALTER TABLE oymcomercial.productos
      ADD CONSTRAINT chk_productos_peso_modalidades_no_vacio
      CHECK (
        controlado_por_peso = false
        OR (modalidades_activas IS NOT NULL AND array_length(modalidades_activas, 1) >= 1)
      );
  END IF;

  -- Coherencia precio/modalidad: si "entero" está activa, precio_kg_entero
  -- debe ser > 0. Idem "recortado".
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chk_productos_peso_precios_coherentes' AND conrelid = 'oymcomercial.productos'::regclass
  ) THEN
    ALTER TABLE oymcomercial.productos
      ADD CONSTRAINT chk_productos_peso_precios_coherentes
      CHECK (
        controlado_por_peso = false
        OR (
          (NOT ('entero' = ANY(modalidades_activas)) OR (precio_kg_entero IS NOT NULL AND precio_kg_entero > 0))
          AND
          (NOT ('recortado' = ANY(modalidades_activas)) OR (precio_kg_recortado IS NOT NULL AND precio_kg_recortado > 0))
        )
      );
  END IF;
END $$;

-- 3) Comentarios -------------------------------------------------------------

COMMENT ON COLUMN oymcomercial.productos.controlado_por_peso IS
  'Si true, el producto se compra y se vende por peso en KG. El POS abre modal de peso al agregar al carrito.';
COMMENT ON COLUMN oymcomercial.productos.precio_kg_entero IS
  'Precio por kg cuando la venta es pieza entera (modalidad = entero). Obligatorio si "entero" está en modalidades_activas.';
COMMENT ON COLUMN oymcomercial.productos.precio_kg_recortado IS
  'Precio por kg cuando la venta es recortada/feteada (modalidad = recortado). Obligatorio si "recortado" está en modalidades_activas.';
COMMENT ON COLUMN oymcomercial.productos.modalidades_activas IS
  'Modalidades habilitadas en el POS. Subset de {entero, recortado}. NULL para productos vendidos por unidad.';

COMMIT;
