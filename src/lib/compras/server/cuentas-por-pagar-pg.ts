import { getChatPostgresPool, quoteSchemaTable } from "@/lib/supabase/chat-pg-pool";
import { assertAllowedChatDataSchema } from "@/lib/supabase/chat-data-schema";

/**
 * Cuentas por pagar: deuda con proveedores, agrupada por documento.
 *
 * `compras` tiene una fila por producto y todas las líneas de una misma factura
 * recibida comparten `numero_control`. Se le debe al proveedor el documento
 * entero, así que el saldo se calcula por `numero_control`:
 *   SUM(compras.total) − SUM(compras_pagos.monto)
 *
 * La agregación va en SQL y no en memoria. El origen de este módulo traía todas
 * las compras y todos los pagos al servidor (hasta 50.000 filas, paginando de a
 * 1.000) para sumarlos en JavaScript. Con el catálogo importado eso son muchas
 * filas para responder una pantalla, y Postgres agrupa esto sin despeinarse.
 */

export type EstadoPagoDoc = "pendiente" | "parcial" | "pagado";

export interface DocumentoPorPagar {
  numero_control: string;
  proveedor_id: string | null;
  proveedor_nombre: string | null;
  /** Fecha más antigua entre las líneas del documento. */
  fecha: string;
  tipo_pago: string;
  plazo_dias: number | null;
  total_documento: number;
  total_pagado: number;
  saldo_pendiente: number;
  items_count: number;
  /** Días transcurridos desde la fecha del documento. */
  dias_desde_fecha: number;
  /** Días pasados del vencimiento (fecha + plazo). 0 si no venció o es contado. */
  dias_vencido: number;
  estado_pago: EstadoPagoDoc;
}

export interface ResumenPorPagar {
  documentos_con_saldo: number;
  total_deuda: number;
  vencidos: number;
  total_vencido: number;
  total_pagado_mes: number;
}

function pool() {
  const p = getChatPostgresPool();
  if (!p) throw new Error("Pool no disponible.");
  return p;
}

export async function getCuentasPorPagar(
  schemaRaw: string,
  empresaId: string,
  sucursalId: string,
  opts: { incluirPagados: boolean }
): Promise<{ items: DocumentoPorPagar[]; summary: ResumenPorPagar }> {
  const schema = assertAllowedChatDataSchema(schemaRaw);
  const tCompras = quoteSchemaTable(schema, "compras");
  const tPagos = quoteSchemaTable(schema, "compras_pagos");
  const p = pool();

  // Los pagos se agregan en una subconsulta aparte y no con un JOIN directo:
  // unir el detalle de compras (una fila por producto) contra el detalle de
  // pagos multiplicaría las filas y ambas sumas saldrían infladas.
  const q = await p.query<{
    numero_control: string;
    proveedor_id: string | null;
    proveedor_nombre: string | null;
    fecha: string;
    tipo_pago: string;
    plazo_dias: number | null;
    total_documento: number;
    total_pagado: number;
    items_count: number;
  }>(
    `WITH docs AS (
       SELECT numero_control,
              MIN(proveedor_id::text)::uuid   AS proveedor_id,
              MIN(proveedor_nombre)           AS proveedor_nombre,
              MIN(fecha)                      AS fecha,
              MIN(tipo_pago)                  AS tipo_pago,
              MAX(plazo_dias)                 AS plazo_dias,
              COALESCE(SUM(total),0)::float8  AS total_documento,
              COUNT(*)::int                   AS items_count
         FROM ${tCompras}
        WHERE empresa_id=$1::uuid AND sucursal_id=$2::uuid AND estado <> 'anulada'
        GROUP BY numero_control
     ),
     pagos AS (
       SELECT numero_control, COALESCE(SUM(monto),0)::float8 AS total_pagado
         FROM ${tPagos}
        WHERE empresa_id=$1::uuid AND sucursal_id=$2::uuid
        GROUP BY numero_control
     )
     SELECT d.numero_control, d.proveedor_id, d.proveedor_nombre, d.fecha,
            d.tipo_pago, d.plazo_dias, d.total_documento, d.items_count,
            COALESCE(pg.total_pagado,0)::float8 AS total_pagado
       FROM docs d
       LEFT JOIN pagos pg ON pg.numero_control = d.numero_control
      ORDER BY d.fecha ASC`,
    [empresaId, sucursalId]
  );

  const ahora = Date.now();
  const todos: DocumentoPorPagar[] = q.rows.map((r) => {
    const totalPagado = Number(r.total_pagado) || 0;
    const totalDoc = Number(r.total_documento) || 0;
    const saldo = Math.max(totalDoc - totalPagado, 0);
    const dias = Math.floor((ahora - new Date(r.fecha).getTime()) / 86400000);
    // Contado vence el mismo día; a crédito, a los `plazo_dias`.
    const plazo = r.tipo_pago === "credito" ? (r.plazo_dias ?? 0) : 0;
    return {
      numero_control: r.numero_control,
      proveedor_id: r.proveedor_id,
      proveedor_nombre: r.proveedor_nombre,
      fecha: r.fecha,
      tipo_pago: r.tipo_pago,
      plazo_dias: r.plazo_dias,
      total_documento: totalDoc,
      total_pagado: totalPagado,
      saldo_pendiente: saldo,
      items_count: r.items_count,
      dias_desde_fecha: dias,
      dias_vencido: saldo > 0 ? Math.max(dias - plazo, 0) : 0,
      estado_pago: saldo <= 0 ? "pagado" : totalPagado > 0 ? "parcial" : "pendiente",
    };
  });

  const conSaldo = todos.filter((d) => d.saldo_pendiente > 0);
  const vencidos = conSaldo.filter((d) => d.dias_vencido > 0);

  // Pagado en el mes en curso. El origen dejaba este número en 0 con un
  // reduce que nunca sumaba nada; acá se consulta de verdad.
  const mesQ = await p.query<{ total: number }>(
    `SELECT COALESCE(SUM(monto),0)::float8 AS total FROM ${tPagos}
      WHERE empresa_id=$1::uuid AND sucursal_id=$2::uuid
        AND fecha >= date_trunc('month', now() AT TIME ZONE 'America/Asuncion')`,
    [empresaId, sucursalId]
  );

  return {
    items: opts.incluirPagados ? todos : conSaldo,
    summary: {
      documentos_con_saldo: conSaldo.length,
      total_deuda: conSaldo.reduce((s, d) => s + d.saldo_pendiente, 0),
      vencidos: vencidos.length,
      total_vencido: vencidos.reduce((s, d) => s + d.saldo_pendiente, 0),
      total_pagado_mes: Number(mesQ.rows[0]?.total) || 0,
    },
  };
}

/** Saldo pendiente de un documento puntual. Se usa para no aceptar sobrepagos. */
export async function getSaldoDocumento(
  schemaRaw: string,
  empresaId: string,
  sucursalId: string,
  numeroControl: string
): Promise<{ existe: boolean; total: number; pagado: number; saldo: number } | null> {
  const schema = assertAllowedChatDataSchema(schemaRaw);
  const tCompras = quoteSchemaTable(schema, "compras");
  const tPagos = quoteSchemaTable(schema, "compras_pagos");
  const p = pool();

  const [doc, pagos] = await Promise.all([
    p.query<{ total: number; n: number }>(
      `SELECT COALESCE(SUM(total),0)::float8 AS total, COUNT(*)::int AS n
         FROM ${tCompras}
        WHERE empresa_id=$1::uuid AND sucursal_id=$2::uuid
          AND numero_control=$3 AND estado <> 'anulada'`,
      [empresaId, sucursalId, numeroControl]
    ),
    p.query<{ total: number }>(
      `SELECT COALESCE(SUM(monto),0)::float8 AS total FROM ${tPagos}
        WHERE empresa_id=$1::uuid AND sucursal_id=$2::uuid AND numero_control=$3`,
      [empresaId, sucursalId, numeroControl]
    ),
  ]);

  const n = Number(doc.rows[0]?.n) || 0;
  if (n === 0) return { existe: false, total: 0, pagado: 0, saldo: 0 };
  const total = Number(doc.rows[0]?.total) || 0;
  const pagado = Number(pagos.rows[0]?.total) || 0;
  return { existe: true, total, pagado, saldo: Math.max(total - pagado, 0) };
}
