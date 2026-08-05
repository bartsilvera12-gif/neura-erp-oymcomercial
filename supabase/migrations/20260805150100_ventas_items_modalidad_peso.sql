-- =============================================================================
-- ventas_items: modalidad, unidad de venta y precio unitario display para
-- soportar productos vendidos por peso (queso, jamón, etc.).
--
-- Todas las columnas son NULLABLE porque las ventas por unidad no las usan.
-- Cuando una línea proviene de un producto controlado_por_peso, se persiste:
--
--   - modalidad             ('entero' | 'recortado')
--   - unidad_venta          ('KG')  → el ticket la muestra como "0,350 KG"
--   - precio_unitario_display   → precio por kg que se pintó en el ticket
--                                  (== precio_venta unitario de la línea,
--                                  pero explícito para no adivinarlo al
--                                  regenerar tickets viejos si el catálogo
--                                  cambia después).
--
-- `cantidad` sigue guardando kg vendidos (numeric ya soporta decimales).
-- Idempotente.
-- =============================================================================

BEGIN;

ALTER TABLE oymcomercial.ventas_items
  ADD COLUMN IF NOT EXISTS modalidad text;

ALTER TABLE oymcomercial.ventas_items
  ADD COLUMN IF NOT EXISTS unidad_venta text;

ALTER TABLE oymcomercial.ventas_items
  ADD COLUMN IF NOT EXISTS precio_unitario_display numeric;

-- CHECK: modalidad, si viene, debe ser valor conocido.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chk_ventas_items_modalidad_valida' AND conrelid = 'oymcomercial.ventas_items'::regclass
  ) THEN
    ALTER TABLE oymcomercial.ventas_items
      ADD CONSTRAINT chk_ventas_items_modalidad_valida
      CHECK (modalidad IS NULL OR modalidad IN ('entero', 'recortado'));
  END IF;
END $$;

COMMENT ON COLUMN oymcomercial.ventas_items.modalidad IS
  'Modalidad de venta para productos por peso (entero|recortado). NULL en ventas por unidad.';
COMMENT ON COLUMN oymcomercial.ventas_items.unidad_venta IS
  'Unidad que se muestra en el ticket (KG para peso, sino se toma de productos.unidad_medida).';
COMMENT ON COLUMN oymcomercial.ventas_items.precio_unitario_display IS
  'Precio por unidad efectivo cuando se emitió el ticket (para regeneración fiel del comprobante).';

COMMIT;
