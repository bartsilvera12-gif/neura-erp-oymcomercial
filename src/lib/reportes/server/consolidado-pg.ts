import { getChatPostgresPool, quoteSchemaTable } from "@/lib/supabase/chat-pg-pool";
import { assertAllowedChatDataSchema } from "@/lib/supabase/chat-data-schema";

/**
 * Reporte consolidado por sucursal.
 *
 * ES LA ÚNICA LECTURA DEL SISTEMA QUE CRUZA SUCURSALES A PROPÓSITO.
 *
 * Todo el resto filtra con `aplicarFiltroSucursal` / `andSucursal` porque cada
 * usuario opera en una sola sucursal y no debe ver las otras (ver
 * `@/lib/sucursales/filtro`). Ese aislamiento es para la OPERACIÓN: quien
 * factura, mueve stock o cuenta la caja no tiene por qué ver otro local.
 *
 * La dueña del negocio sí necesita comparar. En vez de romper el aislamiento en
 * todas las pantallas —que dejaría al encargado de un local viendo el otro por
 * cualquier resquicio— se agrega esta lectura única, agregada y de solo lectura,
 * detrás de un chequeo de admin en la ruta. No devuelve documentos ni permite
 * abrir una venta: solo totales por sucursal.
 *
 * Por eso acá NO se usa `andSucursal`. Es deliberado, no un olvido.
 */

export interface FilaConsolidado {
  sucursal_id: string;
  sucursal_codigo: string;
  sucursal_nombre: string;
  ventas_cantidad: number;
  ventas_total: number;
  compras_total: number;
  gastos_total: number;
  /** ventas − compras − gastos del período. */
  resultado: number;
  /** Stock actual valorizado a costo promedio. Es una foto de HOY, no del período. */
  stock_valorizado: number;
  cajas_cerradas: number;
  /** Σ de las diferencias de arqueo de los turnos cerrados en el período. */
  caja_diferencias: number;
}

export interface ConsolidadoReporte {
  desde: string;
  hasta: string;
  filas: FilaConsolidado[];
  totales: Omit<FilaConsolidado, "sucursal_id" | "sucursal_codigo" | "sucursal_nombre">;
}

function pool() {
  const p = getChatPostgresPool();
  if (!p) throw new Error("Pool no disponible.");
  return p;
}

export async function getReporteConsolidado(
  schemaRaw: string,
  empresaId: string,
  b: { start: string; end: string }
): Promise<ConsolidadoReporte> {
  const schema = assertAllowedChatDataSchema(schemaRaw);
  const tSuc = quoteSchemaTable(schema, "sucursales");
  const tVentas = quoteSchemaTable(schema, "ventas");
  const tCompras = quoteSchemaTable(schema, "compras");
  const tGastos = quoteSchemaTable(schema, "gastos");
  const tProd = quoteSchemaTable(schema, "productos");
  const tCajas = quoteSchemaTable(schema, "cajas");
  const p = pool();

  // Una consulta por métrica, agrupada por sucursal. Se hace así y no con un
  // solo JOIN gigante porque unir cinco tablas de detalle por sucursal
  // multiplica filas y las sumas salen infladas.
  const [sucs, ventas, compras, gastos, stock, cajas] = await Promise.all([
    p.query<{ id: string; codigo: string; nombre: string }>(
      `SELECT id, codigo, nombre FROM ${tSuc}
        WHERE empresa_id=$1::uuid AND activa=true
        ORDER BY es_principal DESC, nombre`,
      [empresaId]
    ),
    p.query<{ sucursal_id: string; cantidad: number; total: number }>(
      `SELECT sucursal_id, COUNT(*)::int AS cantidad, COALESCE(SUM(total),0)::float8 AS total
         FROM ${tVentas}
        WHERE empresa_id=$1::uuid AND estado <> 'anulada'
          AND fecha>=$2::timestamptz AND fecha<=$3::timestamptz
        GROUP BY sucursal_id`,
      [empresaId, b.start, b.end]
    ),
    p.query<{ sucursal_id: string; total: number }>(
      `SELECT sucursal_id, COALESCE(SUM(total),0)::float8 AS total
         FROM ${tCompras}
        WHERE empresa_id=$1::uuid AND estado <> 'anulada'
          AND fecha>=$2::timestamptz AND fecha<=$3::timestamptz
        GROUP BY sucursal_id`,
      [empresaId, b.start, b.end]
    ),
    p.query<{ sucursal_id: string; total: number }>(
      `SELECT sucursal_id, COALESCE(SUM(monto),0)::float8 AS total
         FROM ${tGastos}
        WHERE empresa_id=$1::uuid
          AND fecha>=$2::timestamptz AND fecha<=$3::timestamptz
        GROUP BY sucursal_id`,
      [empresaId, b.start, b.end]
    ),
    // Stock: foto de hoy. No tiene rango de fechas porque `productos.stock_actual`
    // es el saldo vivo; reconstruir el stock histórico exigiría recorrer
    // movimientos_inventario y no es lo que se está preguntando acá.
    p.query<{ sucursal_id: string; total: number }>(
      `SELECT sucursal_id, COALESCE(SUM(stock_actual * costo_promedio),0)::float8 AS total
         FROM ${tProd}
        WHERE empresa_id=$1::uuid AND activo=true
        GROUP BY sucursal_id`,
      [empresaId]
    ),
    p.query<{ sucursal_id: string; cerradas: number; diferencias: number }>(
      `SELECT sucursal_id, COUNT(*)::int AS cerradas,
              COALESCE(SUM(diferencia),0)::float8 AS diferencias
         FROM ${tCajas}
        WHERE empresa_id=$1::uuid AND estado='cerrada'
          AND fecha_cierre>=$2::timestamptz AND fecha_cierre<=$3::timestamptz
        GROUP BY sucursal_id`,
      [empresaId, b.start, b.end]
    ),
  ]);

  const byId = <T extends { sucursal_id: string }>(rows: T[]) =>
    new Map(rows.map((r) => [r.sucursal_id, r]));
  const mVentas = byId(ventas.rows);
  const mCompras = byId(compras.rows);
  const mGastos = byId(gastos.rows);
  const mStock = byId(stock.rows);
  const mCajas = byId(cajas.rows);

  const filas: FilaConsolidado[] = sucs.rows.map((s) => {
    const ventasTotal = mVentas.get(s.id)?.total ?? 0;
    const comprasTotal = mCompras.get(s.id)?.total ?? 0;
    const gastosTotal = mGastos.get(s.id)?.total ?? 0;
    return {
      sucursal_id: s.id,
      sucursal_codigo: s.codigo,
      sucursal_nombre: s.nombre,
      ventas_cantidad: mVentas.get(s.id)?.cantidad ?? 0,
      ventas_total: ventasTotal,
      compras_total: comprasTotal,
      gastos_total: gastosTotal,
      resultado: ventasTotal - comprasTotal - gastosTotal,
      stock_valorizado: mStock.get(s.id)?.total ?? 0,
      cajas_cerradas: mCajas.get(s.id)?.cerradas ?? 0,
      caja_diferencias: mCajas.get(s.id)?.diferencias ?? 0,
    };
  });

  const suma = (f: (x: FilaConsolidado) => number) => filas.reduce((a, x) => a + f(x), 0);

  return {
    desde: b.start,
    hasta: b.end,
    filas,
    totales: {
      ventas_cantidad: suma((x) => x.ventas_cantidad),
      ventas_total: suma((x) => x.ventas_total),
      compras_total: suma((x) => x.compras_total),
      gastos_total: suma((x) => x.gastos_total),
      resultado: suma((x) => x.resultado),
      stock_valorizado: suma((x) => x.stock_valorizado),
      cajas_cerradas: suma((x) => x.cajas_cerradas),
      caja_diferencias: suma((x) => x.caja_diferencias),
    },
  };
}
