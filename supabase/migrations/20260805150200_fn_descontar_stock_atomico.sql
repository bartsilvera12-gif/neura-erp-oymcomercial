-- =============================================================================
-- Función SQL atómica para descontar stock desde una venta.
--
-- Motivo: hoy `create-venta-pg.ts` calcula el nuevo stock en JavaScript
-- (SELECT stock → Math.max(0, stock - vendido) → UPDATE stock_actual = valor).
-- Sin transacción, dos ventas concurrentes del mismo producto pueden leer el
-- mismo stock inicial y cada una escribe su propio "nuevoStock", perdiendo
-- una de las salidas. Esta función encapsula el read-modify-write en un
-- único UPDATE con expresión — el `stock_actual` se lee y escribe en la
-- misma sentencia, sin ventana para el race.
--
-- Comportamiento preservado:
--   - El stock nunca baja de 0 (misma regla que Math.max(0, ...)).
--   - Si el nuevo stock sería < 0, se floora a 0. La cantidad real vendida
--     queda igualmente registrada en movimientos_inventario (el caller
--     inserta esa fila con la cantidad completa).
--   - Devuelve el stock resultante para que el caller lo cachee sin volver
--     a consultar.
--
-- La función es SECURITY DEFINER porque puede ser llamada vía PostgREST/RPC
-- con el rol del cliente; el owner (postgres/service_role) tiene los
-- permisos completos sobre oymcomercial.productos.
-- =============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION oymcomercial.fn_venta_descontar_stock(
  p_producto_id uuid,
  p_empresa_id uuid,
  p_cantidad numeric
) RETURNS numeric
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = oymcomercial, public
AS $$
DECLARE
  v_nuevo numeric;
BEGIN
  IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
    RAISE EXCEPTION 'cantidad inválida: %', p_cantidad USING ERRCODE = '22023';
  END IF;

  UPDATE oymcomercial.productos
     SET stock_actual = GREATEST(stock_actual - p_cantidad, 0),
         updated_at = now()
   WHERE id = p_producto_id
     AND empresa_id = p_empresa_id
   RETURNING stock_actual INTO v_nuevo;

  IF v_nuevo IS NULL THEN
    RAISE EXCEPTION 'producto no encontrado para empresa: id=% empresa=%',
      p_producto_id, p_empresa_id USING ERRCODE = 'P0002';
  END IF;

  RETURN v_nuevo;
END;
$$;

COMMENT ON FUNCTION oymcomercial.fn_venta_descontar_stock(uuid, uuid, numeric) IS
  'Descuenta stock de un producto de forma atómica y devuelve el stock resultante. Nunca baja de 0.';

-- Permitir invocarla desde PostgREST con service_role (los endpoints de venta
-- usan service role para escribir). authenticated queda excluido: no debería
-- llamar la función suelta desde el front, solo vía el endpoint /api/ventas.
GRANT EXECUTE ON FUNCTION oymcomercial.fn_venta_descontar_stock(uuid, uuid, numeric) TO service_role;

COMMIT;
