/**
 * Pesaje / Cortes / Mermas — Fase 3.
 *
 * Registra una operación transaccional sobre un producto controlado_por_peso:
 *   - INSERT en `pesaje_operaciones` (encabezado con peso_procesado total).
 *   - INSERT en `pesaje_operacion_lineas` por cada destino.
 *   - Descuenta el peso_procesado del stock del producto origen y genera
 *     un movimiento SALIDA con origen='pesaje_corte'.
 *   - Por cada línea con destino='recorte_vendible', suma el peso al stock
 *     del producto derivado y genera un movimiento ENTRADA con
 *     origen='transformacion_derivado'.
 *   - Líneas 'merma' y 'consumo_interno' quedan como SALIDA definitiva
 *     (ya cubierta por la SALIDA del origen — no re-generamos movimiento).
 *   - 'resto_aprovechable' NO genera movimiento; representa el peso que
 *     sigue en el producto origen (por eso no se descuenta de más — el
 *     descuento total es exactamente `peso_procesado`, no la parte que
 *     "se fue"). Este es un detalle sutil pero importante: si el usuario
 *     dice "de 5 kg trabajé 4,7 kg, quedó 0,3 recorte + 0,1 merma + 4,3 de
 *     resto aprovechable", el sistema descuenta 4,7 y da entrada 0,3 al
 *     derivado. El resto aprovechable NO se descuenta del origen porque
 *     ya está ahí (el usuario simplemente lo dejó como estaba tras el
 *     corte físico). La operación queda registrada para auditoría.
 *
 * Todo dentro de una transacción PG con BEGIN/COMMIT (patrón compras-pg.ts).
 * Si cualquier paso falla, ROLLBACK deja la base como estaba.
 */
import { getChatPostgresPool, quoteSchemaTable } from "@/lib/supabase/chat-pg-pool";
import { assertAllowedChatDataSchema } from "@/lib/supabase/chat-data-schema";

export type PesajeDestino = "resto_aprovechable" | "recorte_vendible" | "merma" | "consumo_interno";

export interface PesajeLineaInput {
  destino: PesajeDestino;
  peso: number;
  /** Requerido solo cuando destino='recorte_vendible'. Debe ser otro producto
   *  que ya exista (con SKU/precio propio). */
  producto_derivado_id?: string | null;
  observacion?: string | null;
}

export interface PesajeInput {
  schema: string;
  empresaId: string;
  sucursalId: string;
  productoOrigenId: string;
  pesoProcesado: number;
  motivo: string | null;
  observaciones: string | null;
  createdBy: string | null;
  usuarioNombre: string | null;
  lineas: PesajeLineaInput[];
}

export interface PesajeResult {
  id: string;
  movimientosGenerados: number;
  stockOrigenResultante: number;
}

/** Tolerancia de conservación: igual que el trigger DB (0.5 g). */
const TOL_CONSERVACION_KG = 0.0005;

export async function createPesajePg(input: PesajeInput): Promise<PesajeResult> {
  const schema = assertAllowedChatDataSchema(input.schema);
  const poolMaybe = getChatPostgresPool();
  if (!poolMaybe) throw new Error("Pool PG no disponible.");
  const pool = poolMaybe;

  const tOps = quoteSchemaTable(schema, "pesaje_operaciones");
  const tLin = quoteSchemaTable(schema, "pesaje_operacion_lineas");
  const tP = quoteSchemaTable(schema, "productos");
  const tM = quoteSchemaTable(schema, "movimientos_inventario");

  // Validaciones pre-transacción (guard en app, además del CHECK DB).
  if (!(input.pesoProcesado > 0)) throw new Error("El peso procesado debe ser mayor a 0.");
  if (input.lineas.length === 0) throw new Error("La operación no tiene líneas.");

  let suma = 0;
  for (const l of input.lineas) {
    if (!(l.peso > 0)) throw new Error("Cada línea debe tener peso mayor a 0.");
    if (l.destino === "recorte_vendible" && !l.producto_derivado_id) {
      throw new Error("La línea 'recorte vendible' requiere un producto derivado.");
    }
    if (l.destino !== "recorte_vendible" && l.producto_derivado_id) {
      throw new Error("Solo 'recorte vendible' puede tener producto derivado.");
    }
    suma += l.peso;
  }
  if (Math.abs(suma - input.pesoProcesado) > TOL_CONSERVACION_KG) {
    throw new Error(
      `Conservación de peso violada: suma de líneas = ${suma.toFixed(3)} kg, peso procesado = ${input.pesoProcesado.toFixed(3)} kg.`
    );
  }

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    // 1) Validar origen: existe, es de la empresa y sucursal, y tiene stock suficiente
    //    para descontar el peso_procesado. Se hace `FOR UPDATE` para tomar lock
    //    del producto durante la transacción — otra venta/pesaje concurrente sobre
    //    el mismo producto espera hasta el COMMIT.
    const originRes = await client.query<{
      id: string;
      nombre: string;
      sku: string | null;
      stock_actual: string;
      controlado_por_peso: boolean;
      costo_promedio: string | null;
    }>(
      `SELECT id, nombre, sku, stock_actual, controlado_por_peso, costo_promedio
         FROM ${tP}
        WHERE id = $1::uuid AND empresa_id = $2::uuid AND sucursal_id = $3::uuid
        FOR UPDATE`,
      [input.productoOrigenId, input.empresaId, input.sucursalId]
    );
    if (originRes.rowCount === 0) {
      throw new Error("Producto de origen no encontrado en esta sucursal.");
    }
    const origen = originRes.rows[0];
    if (!origen.controlado_por_peso) {
      throw new Error("El producto de origen no está marcado como controlado por peso.");
    }
    const stockOrigen = Number(origen.stock_actual);
    if (input.pesoProcesado - stockOrigen > TOL_CONSERVACION_KG) {
      throw new Error(
        `Stock insuficiente: se procesan ${input.pesoProcesado.toFixed(3)} kg pero el stock actual es ${stockOrigen.toFixed(3)} kg.`
      );
    }
    const costoOrigen = origen.costo_promedio != null ? Number(origen.costo_promedio) : 0;

    // 2) Validar derivados: cada uno existe y pertenece a la empresa/sucursal.
    //    Bloqueamos también con FOR UPDATE para evitar carreras contra otro
    //    proceso que también les esté sumando/restando stock.
    const derivadoIds = [
      ...new Set(
        input.lineas
          .filter((l) => l.destino === "recorte_vendible" && l.producto_derivado_id)
          .map((l) => l.producto_derivado_id as string)
      ),
    ];
    const derivadosById = new Map<string, { costo: number; nombre: string; sku: string }>();
    if (derivadoIds.length > 0) {
      const derRes = await client.query<{
        id: string;
        nombre: string;
        sku: string | null;
        costo_promedio: string | null;
      }>(
        `SELECT id, nombre, sku, costo_promedio
           FROM ${tP}
          WHERE id = ANY($1::uuid[]) AND empresa_id = $2::uuid AND sucursal_id = $3::uuid
          FOR UPDATE`,
        [derivadoIds, input.empresaId, input.sucursalId]
      );
      const encontrados = new Set<string>();
      for (const r of derRes.rows) {
        encontrados.add(r.id);
        derivadosById.set(r.id, {
          costo: r.costo_promedio != null ? Number(r.costo_promedio) : 0,
          nombre: r.nombre,
          sku: r.sku ?? "",
        });
      }
      const faltantes = derivadoIds.filter((id) => !encontrados.has(id));
      if (faltantes.length > 0) {
        throw new Error(`Producto(s) derivado(s) no encontrados en esta sucursal: ${faltantes.join(", ")}`);
      }
    }

    // 3) INSERT encabezado
    const opRes = await client.query<{ id: string }>(
      `INSERT INTO ${tOps} (
         empresa_id, sucursal_id, producto_origen_id,
         peso_procesado, motivo, observaciones,
         created_by, usuario_nombre
       ) VALUES (
         $1::uuid, $2::uuid, $3::uuid,
         $4::numeric, $5, $6,
         $7::uuid, $8
       ) RETURNING id`,
      [
        input.empresaId, input.sucursalId, input.productoOrigenId,
        input.pesoProcesado, input.motivo, input.observaciones,
        input.createdBy, input.usuarioNombre,
      ]
    );
    const operacionId = opRes.rows[0].id;
    const referencia = `PESAJE-${operacionId}`;

    // 4) INSERT líneas (bulk con multi-VALUES). El trigger de conservación
    //    corre DEFERRABLE INITIALLY DEFERRED — se dispara al final de la
    //    transacción, así que el orden encabezado→líneas no importa.
    if (input.lineas.length > 0) {
      const values: string[] = [];
      const params: unknown[] = [];
      let n = 1;
      for (const l of input.lineas) {
        values.push(
          `($${n}::uuid, $${n + 1}, $${n + 2}::numeric, $${n + 3}::uuid, $${n + 4})`
        );
        n += 5;
        params.push(
          operacionId,
          l.destino,
          l.peso,
          l.producto_derivado_id ?? null,
          l.observacion ?? null,
        );
      }
      await client.query(
        `INSERT INTO ${tLin} (operacion_id, destino, peso, producto_derivado_id, observacion)
         VALUES ${values.join(",")}`,
        params
      );
    }

    // 5) Descontar del origen el peso_procesado y generar SALIDA
    //    (SET stock_actual = stock_actual - X en un único UPDATE, atómico).
    const updOrigen = await client.query<{ stock_actual: string }>(
      `UPDATE ${tP}
          SET stock_actual = GREATEST(stock_actual - $1::numeric, 0),
              updated_at = now()
        WHERE id = $2::uuid AND empresa_id = $3::uuid
        RETURNING stock_actual`,
      [input.pesoProcesado, input.productoOrigenId, input.empresaId]
    );
    const stockOrigenNuevo = Number(updOrigen.rows[0].stock_actual);

    await client.query(
      `INSERT INTO ${tM} (
         empresa_id, sucursal_id, producto_id, producto_nombre, producto_sku,
         tipo, cantidad, costo_unitario, origen, referencia, fecha,
         created_by, usuario_nombre
       ) VALUES (
         $1::uuid, $2::uuid, $3::uuid, $4, $5,
         'SALIDA', $6::numeric, $7::numeric, 'pesaje_corte', $8, now(),
         $9::uuid, $10
       )`,
      [
        input.empresaId, input.sucursalId, input.productoOrigenId,
        origen.nombre, origen.sku ?? "",
        input.pesoProcesado, costoOrigen, referencia,
        input.createdBy, input.usuarioNombre,
      ]
    );
    let movimientos = 1;

    // 6) Por cada línea 'recorte_vendible': sumar al derivado + ENTRADA.
    //    Las demás (merma, consumo_interno, resto_aprovechable) no generan
    //    otro movimiento — la salida ya está registrada arriba y su motivo
    //    granular vive en pesaje_operacion_lineas.
    for (const l of input.lineas) {
      if (l.destino !== "recorte_vendible") continue;
      const derivadoId = l.producto_derivado_id as string;
      const der = derivadosById.get(derivadoId)!;

      await client.query(
        `UPDATE ${tP}
            SET stock_actual = stock_actual + $1::numeric,
                updated_at = now()
          WHERE id = $2::uuid AND empresa_id = $3::uuid`,
        [l.peso, derivadoId, input.empresaId]
      );
      await client.query(
        `INSERT INTO ${tM} (
           empresa_id, sucursal_id, producto_id, producto_nombre, producto_sku,
           tipo, cantidad, costo_unitario, origen, referencia, fecha,
           created_by, usuario_nombre
         ) VALUES (
           $1::uuid, $2::uuid, $3::uuid, $4, $5,
           'ENTRADA', $6::numeric, $7::numeric, 'transformacion_derivado', $8, now(),
           $9::uuid, $10
         )`,
        [
          input.empresaId, input.sucursalId, derivadoId,
          der.nombre, der.sku,
          // Costo del derivado: hereda el costo del origen (la materia es la
          // misma). Si se quiere costear el corte con overhead, se ajusta
          // después manualmente — no lo inventamos acá.
          l.peso, costoOrigen, referencia,
          input.createdBy, input.usuarioNombre,
        ]
      );
      movimientos++;
    }

    await client.query("COMMIT");
    return {
      id: operacionId,
      movimientosGenerados: movimientos,
      stockOrigenResultante: stockOrigenNuevo,
    };
  } catch (err) {
    try {
      await client.query("ROLLBACK");
    } catch (rbErr) {
      console.error("[pesaje-pg] ROLLBACK falló", rbErr instanceof Error ? rbErr.message : rbErr);
    }
    throw err;
  } finally {
    client.release();
  }
}

/** Lista las últimas N operaciones de pesaje para una sucursal, incluyendo sus líneas. */
export interface PesajeListItem {
  id: string;
  producto_origen_id: string;
  producto_origen_nombre: string;
  peso_procesado: number;
  motivo: string | null;
  observaciones: string | null;
  usuario_nombre: string | null;
  created_at: string;
  lineas: Array<{
    destino: PesajeDestino;
    peso: number;
    producto_derivado_id: string | null;
    producto_derivado_nombre: string | null;
    observacion: string | null;
  }>;
}

export async function listPesajesPg(
  schemaRaw: string,
  empresaId: string,
  sucursalId: string,
  limit = 20
): Promise<PesajeListItem[]> {
  const schema = assertAllowedChatDataSchema(schemaRaw);
  const poolMaybe = getChatPostgresPool();
  if (!poolMaybe) throw new Error("Pool PG no disponible.");
  const pool = poolMaybe;

  const tOps = quoteSchemaTable(schema, "pesaje_operaciones");
  const tLin = quoteSchemaTable(schema, "pesaje_operacion_lineas");
  const tP = quoteSchemaTable(schema, "productos");

  const opsRes = await pool.query<{
    id: string;
    producto_origen_id: string;
    producto_origen_nombre: string;
    peso_procesado: string;
    motivo: string | null;
    observaciones: string | null;
    usuario_nombre: string | null;
    created_at: string;
  }>(
    `SELECT o.id, o.producto_origen_id, po.nombre AS producto_origen_nombre,
            o.peso_procesado, o.motivo, o.observaciones,
            o.usuario_nombre, o.created_at
       FROM ${tOps} o
       LEFT JOIN ${tP} po ON po.id = o.producto_origen_id
      WHERE o.empresa_id = $1::uuid AND o.sucursal_id = $2::uuid
      ORDER BY o.created_at DESC
      LIMIT $3`,
    [empresaId, sucursalId, limit]
  );
  if (opsRes.rowCount === 0) return [];

  const opIds = opsRes.rows.map((r) => r.id);
  const linRes = await pool.query<{
    operacion_id: string;
    destino: PesajeDestino;
    peso: string;
    producto_derivado_id: string | null;
    producto_derivado_nombre: string | null;
    observacion: string | null;
  }>(
    `SELECT l.operacion_id, l.destino, l.peso,
            l.producto_derivado_id, pd.nombre AS producto_derivado_nombre,
            l.observacion
       FROM ${tLin} l
       LEFT JOIN ${tP} pd ON pd.id = l.producto_derivado_id
      WHERE l.operacion_id = ANY($1::uuid[])
      ORDER BY l.operacion_id, l.created_at`,
    [opIds]
  );
  const linByOp = new Map<string, PesajeListItem["lineas"]>();
  for (const l of linRes.rows) {
    if (!linByOp.has(l.operacion_id)) linByOp.set(l.operacion_id, []);
    linByOp.get(l.operacion_id)!.push({
      destino: l.destino,
      peso: Number(l.peso),
      producto_derivado_id: l.producto_derivado_id,
      producto_derivado_nombre: l.producto_derivado_nombre,
      observacion: l.observacion,
    });
  }
  return opsRes.rows.map((r) => ({
    id: r.id,
    producto_origen_id: r.producto_origen_id,
    producto_origen_nombre: r.producto_origen_nombre,
    peso_procesado: Number(r.peso_procesado),
    motivo: r.motivo,
    observaciones: r.observaciones,
    usuario_nombre: r.usuario_nombre,
    created_at: r.created_at,
    lineas: linByOp.get(r.id) ?? [],
  }));
}
