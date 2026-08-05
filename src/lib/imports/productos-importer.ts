/**
 * Logica compartida del importador de Productos para preview y commit.
 */
import { getChatPostgresPool, quoteSchemaTable } from "@/lib/supabase/chat-pg-pool";
import { assertAllowedChatDataSchema } from "@/lib/supabase/chat-data-schema";
import { normalizeUpperText, normalizeUpperNullable } from "@/lib/text/normalize";
import type { PreviewRow, PreviewResponse } from "@/lib/excel/import-types";
import { pick, pickNumber, pickBool, chunked } from "./import-helpers";

interface ProductoExistente {
  id: string;
  sku: string;
  codigo_barras: string | null;
  stock_actual: number;
}

export interface ProductoParsed {
  row_number: number;
  nombre: string;
  sku: string;
  codigo_barras: string;
  categoria_nombre: string;
  proveedor_nombre: string;
  ubicacion_nombre: string;
  unidad_medida: string;
  costo_promedio: number;
  precio_venta: number;
  stock_actual: number;
  stock_minimo: number;
  metodo_valuacion: "CPP" | "FIFO" | "LIFO";
  activo: boolean;
  errors: string[];
  warnings: string[];
  match_id?: string | null;
}

const METODOS = new Set(["CPP", "FIFO", "LIFO"]);

export function parseProductosRows(rows: Record<string, string>[]): ProductoParsed[] {
  return rows.map((r, idx) => {
    const errors: string[] = [];
    const warnings: string[] = [];
    const nombre = normalizeUpperText(pick(r, "NOMBRE"));
    if (!nombre) errors.push("NOMBRE obligatorio.");
    const sku = normalizeUpperText(pick(r, "SKU"));
    const codigo_barras_raw = normalizeUpperText(pick(r, "CODIGO_BARRAS", "CODIGOBARRAS"));
    if (codigo_barras_raw && /^INT-/i.test(codigo_barras_raw)) {
      errors.push('Prefijo "INT-" reservado para códigos generados por el sistema.');
    }
    const mv = normalizeUpperText(pick(r, "METODO_VALUACION", "METODOVALUACION"));
    const metodo_valuacion = (METODOS.has(mv) ? mv : "CPP") as "CPP" | "FIFO" | "LIFO";
    return {
      row_number: idx + 2,
      nombre,
      sku,
      codigo_barras: codigo_barras_raw,
      categoria_nombre: normalizeUpperText(pick(r, "CATEGORIA", "CATEGORIA_PRINCIPAL")),
      proveedor_nombre: normalizeUpperText(pick(r, "PROVEEDOR_PRINCIPAL", "PROVEEDOR")),
      ubicacion_nombre: normalizeUpperText(pick(r, "UBICACION_PRINCIPAL", "UBICACION")),
      unidad_medida: normalizeUpperText(pick(r, "UNIDAD_MEDIDA", "UNIDADMEDIDA")) || "UNIDAD",
      costo_promedio: pickNumber(r, "COSTO_PROMEDIO"),
      precio_venta: pickNumber(r, "PRECIO_VENTA"),
      stock_actual: pickNumber(r, "STOCK_ACTUAL"),
      stock_minimo: pickNumber(r, "STOCK_MINIMO"),
      metodo_valuacion,
      activo: pickBool(r, "ACTIVO"),
      errors,
      warnings,
    };
  });
}

export interface ResolverMaps {
  productosBySku: Map<string, ProductoExistente>;
  productosByCodigo: Map<string, ProductoExistente>;
  /** Indice por id — usado en commit para leer stock anterior sin re-consultar. */
  productosById: Map<string, ProductoExistente>;
  categoriasByName: Map<string, string>;
  proveedoresByName: Map<string, string>;
  ubicacionesByName: Map<string, string>;
  ubicacionesByCodigo: Map<string, string>;
}

/**
 * `sucursalId` acota el match de productos existentes a la sucursal que importa.
 * Sin eso, un SKU repetido en otra sucursal haría que la fila del archivo se
 * resuelva como UPDATE del producto de esa otra sucursal: el importador le
 * pisaría stock y costo a un local que ni siquiera participa de la importación.
 */
export async function buildResolverMaps(
  schemaRaw: string,
  empresaId: string,
  sucursalId: string
): Promise<ResolverMaps> {
  const schema = assertAllowedChatDataSchema(schemaRaw);
  const pool = getChatPostgresPool();
  if (!pool) throw new Error("Pool no disponible.");
  const tP = quoteSchemaTable(schema, "productos");
  const tC = quoteSchemaTable(schema, "categorias_productos");
  const tPr = quoteSchemaTable(schema, "proveedores");
  const tU = quoteSchemaTable(schema, "inventario_ubicaciones");

  const [prods, cats, provs, ubis] = await Promise.all([
    pool.query<ProductoExistente>(
      `SELECT id, sku, codigo_barras, stock_actual FROM ${tP} WHERE empresa_id=$1::uuid AND sucursal_id=$2::uuid`,
      [empresaId, sucursalId]
    ),
    pool.query<{ id: string; nombre: string }>(`SELECT id, nombre FROM ${tC} WHERE empresa_id=$1::uuid AND activo=true`, [empresaId]),
    pool.query<{ id: string; nombre: string }>(`SELECT id, nombre FROM ${tPr} WHERE empresa_id=$1::uuid`, [empresaId]),
    pool.query<{ id: string; nombre: string; codigo: string | null }>(`SELECT id, nombre, codigo FROM ${tU} WHERE empresa_id=$1::uuid AND activo=true`, [empresaId]),
  ]);

  const productosBySku = new Map<string, ProductoExistente>();
  const productosByCodigo = new Map<string, ProductoExistente>();
  const productosById = new Map<string, ProductoExistente>();
  for (const p of prods.rows) {
    const normalized: ProductoExistente = { id: p.id, sku: p.sku, codigo_barras: p.codigo_barras, stock_actual: Number(p.stock_actual) };
    if (p.sku) productosBySku.set(p.sku.toUpperCase(), normalized);
    if (p.codigo_barras) productosByCodigo.set(p.codigo_barras.toUpperCase(), normalized);
    productosById.set(p.id, normalized);
  }
  const categoriasByName = new Map<string, string>();
  for (const c of cats.rows) categoriasByName.set(c.nombre.trim().toUpperCase(), c.id);
  const proveedoresByName = new Map<string, string>();
  for (const p of provs.rows) proveedoresByName.set(p.nombre.trim().toUpperCase(), p.id);
  const ubicacionesByName = new Map<string, string>();
  const ubicacionesByCodigo = new Map<string, string>();
  for (const u of ubis.rows) {
    ubicacionesByName.set(u.nombre.trim().toUpperCase(), u.id);
    if (u.codigo) ubicacionesByCodigo.set(u.codigo.trim().toUpperCase(), u.id);
  }
  return { productosBySku, productosByCodigo, productosById, categoriasByName, proveedoresByName, ubicacionesByName, ubicacionesByCodigo };
}

export function buildPreview(parsed: ProductoParsed[], maps: ResolverMaps): PreviewResponse {
  const catsFaltantes = new Set<string>();
  const provsFaltantes = new Set<string>();
  const ubisFaltantes = new Set<string>();
  let insertar = 0, actualizar = 0, errores = 0, warnings = 0;
  let totalEntrada = 0, totalSalida = 0, movimientosGenerar = 0;
  const omitir = 0;
  const skuVistos = new Set<string>();
  const codbarVistos = new Set<string>();

  const rows: PreviewRow[] = parsed.map((p) => {
    // Errores fila
    if (p.sku && skuVistos.has(p.sku)) p.errors.push(`SKU "${p.sku}" duplicado en el archivo.`);
    if (p.sku) skuVistos.add(p.sku);
    if (p.codigo_barras && codbarVistos.has(p.codigo_barras)) p.errors.push(`Código de barras "${p.codigo_barras}" duplicado en el archivo.`);
    if (p.codigo_barras) codbarVistos.add(p.codigo_barras);

    // Match contra DB existente
    let matchId: string | null = null;
    let stockAnterior: number | null = null;
    if (p.codigo_barras && maps.productosByCodigo.has(p.codigo_barras)) {
      const ex = maps.productosByCodigo.get(p.codigo_barras)!;
      matchId = ex.id; stockAnterior = ex.stock_actual;
    } else if (p.sku && maps.productosBySku.has(p.sku)) {
      const ex = maps.productosBySku.get(p.sku)!;
      matchId = ex.id; stockAnterior = ex.stock_actual;
    }
    p.match_id = matchId;

    // Faltantes
    if (p.categoria_nombre && !maps.categoriasByName.has(p.categoria_nombre)) {
      p.warnings.push(`Categoría "${p.categoria_nombre}" no existe.`);
      catsFaltantes.add(p.categoria_nombre);
    }
    if (p.proveedor_nombre && !maps.proveedoresByName.has(p.proveedor_nombre)) {
      p.warnings.push(`Proveedor "${p.proveedor_nombre}" no existe.`);
      provsFaltantes.add(p.proveedor_nombre);
    }
    if (p.ubicacion_nombre && !maps.ubicacionesByName.has(p.ubicacion_nombre) && !maps.ubicacionesByCodigo.has(p.ubicacion_nombre)) {
      p.warnings.push(`Ubicación "${p.ubicacion_nombre}" no existe.`);
      ubisFaltantes.add(p.ubicacion_nombre);
    }

    const hasErr = p.errors.length > 0;
    const action = hasErr ? "ERROR" : matchId ? "UPDATE" : "INSERT";
    if (action === "INSERT") insertar++;
    else if (action === "UPDATE") actualizar++;
    else if (action === "ERROR") errores++;
    if (p.warnings.length > 0) warnings++;

    // Calcular impacto de stock que se generara
    let stockMov: string = "SIN MOVIMIENTO";
    if (!hasErr) {
      if (action === "INSERT" && p.stock_actual > 0) {
        stockMov = `ENTRADA +${p.stock_actual}`;
        totalEntrada += p.stock_actual;
        movimientosGenerar++;
      } else if (action === "UPDATE" && stockAnterior != null) {
        const delta = p.stock_actual - stockAnterior;
        if (delta > 0) {
          stockMov = `ENTRADA +${delta} (prev=${stockAnterior})`;
          totalEntrada += delta; movimientosGenerar++;
        } else if (delta < 0) {
          stockMov = `SALIDA ${delta} (prev=${stockAnterior})`;
          totalSalida += -delta; movimientosGenerar++;
        }
      }
    }

    return {
      row_number: p.row_number,
      action: action as "INSERT" | "UPDATE" | "ERROR" | "SKIP",
      warnings: p.warnings,
      errors: p.errors,
      data: {
        NOMBRE: p.nombre, SKU: p.sku, CODIGO_BARRAS: p.codigo_barras || "(auto)",
        CATEGORIA: p.categoria_nombre, PROVEEDOR: p.proveedor_nombre, UBICACION: p.ubicacion_nombre,
        COSTO: p.costo_promedio, PRECIO: p.precio_venta, STOCK: p.stock_actual,
        STOCK_ANTERIOR: stockAnterior ?? "",
        MOVIMIENTO: stockMov,
      },
    };
  });

  return {
    summary: {
      total: parsed.length,
      insertar, actualizar, omitir, errores, warnings,
      faltantes: {
        categorias: [...catsFaltantes],
        proveedores: [...provsFaltantes],
        ubicaciones: [...ubisFaltantes],
      },
      movimientos_a_generar: movimientosGenerar,
      unidades_entrada: totalEntrada,
      unidades_salida: totalSalida,
    },
    rows,
    headers: ["NOMBRE","SKU","CODIGO_BARRAS","CATEGORIA","PROVEEDOR_PRINCIPAL","UBICACION_PRINCIPAL","UNIDAD_MEDIDA","COSTO_PROMEDIO","PRECIO_VENTA","STOCK_ACTUAL","STOCK_MINIMO","METODO_VALUACION","ACTIVO"],
  };
}

export interface CommitOutcome {
  inserted: number;
  updated: number;
  skipped: number;
  errors: number;
  warnings: number;
  movimientos_generados: number;
  unidades_entrada: number;
  unidades_salida: number;
  errorMessages: string[];
  warningMessages: string[];
}

export interface CommitContext {
  filename?: string | null;
  createdBy?: string | null;
  usuarioNombre?: string | null;
}

export async function commitProductos(
  schemaRaw: string,
  empresaId: string,
  /** Sucursal destino: todo lo que se inserte queda acá (productos y movimientos). */
  sucursalId: string,
  parsed: ProductoParsed[],
  maps: ResolverMaps,
  crearFaltantes: boolean,
  ctx: CommitContext = {}
): Promise<CommitOutcome> {
  const schema = assertAllowedChatDataSchema(schemaRaw);
  const poolMaybe = getChatPostgresPool();
  if (!poolMaybe) throw new Error("Pool no disponible.");
  const pool = poolMaybe;
  const tP = quoteSchemaTable(schema, "productos");
  const tC = quoteSchemaTable(schema, "categorias_productos");
  const tPr = quoteSchemaTable(schema, "proveedores");
  const tU = quoteSchemaTable(schema, "inventario_ubicaciones");
  const tM = quoteSchemaTable(schema, "movimientos_inventario");
  const tSec = `"${schema.replace(/"/g, '""')}".incrementar_secuencia_producto`;
  const refImport = `IMPORT_EXCEL:${(ctx.filename ?? "").slice(0, 80)}`;

  const out: CommitOutcome = {
    inserted: 0, updated: 0, skipped: 0, errors: 0, warnings: 0,
    movimientos_generados: 0, unidades_entrada: 0, unidades_salida: 0,
    errorMessages: [], warningMessages: [],
  };

  // Movimientos encolados: se insertan en bloque al final para ahorrar
  // ~1 round-trip por producto (con 1000+ filas el tiempo total baja de >60s
  // a segundos; sin esto el proxy corta la request con 524).
  interface PendingMov {
    producto_id: string;
    producto_nombre: string;
    producto_sku: string;
    tipo: "ENTRADA" | "SALIDA";
    origen: "inventario_inicial" | "ajuste_manual";
    cantidad: number;
    costo_unitario: number;
    refExtra?: string;
  }
  const pendingMovs: PendingMov[] = [];
  function encolarMovimiento(m: PendingMov): void {
    if (m.cantidad <= 0) return;
    pendingMovs.push(m);
  }

  // Crear faltantes (categorias/proveedores/ubicaciones) si corresponde
  if (crearFaltantes) {
    const cats = new Set<string>();
    const provs = new Set<string>();
    const ubis = new Set<string>();
    for (const p of parsed) {
      if (p.categoria_nombre && !maps.categoriasByName.has(p.categoria_nombre)) cats.add(p.categoria_nombre);
      if (p.proveedor_nombre && !maps.proveedoresByName.has(p.proveedor_nombre)) provs.add(p.proveedor_nombre);
      if (p.ubicacion_nombre && !maps.ubicacionesByName.has(p.ubicacion_nombre) && !maps.ubicacionesByCodigo.has(p.ubicacion_nombre)) ubis.add(p.ubicacion_nombre);
    }
    for (const nombre of cats) {
      try {
        const r = await pool.query<{ id: string }>(`INSERT INTO ${tC} (empresa_id, nombre, activo) VALUES ($1::uuid,$2,true) RETURNING id`, [empresaId, nombre]);
        maps.categoriasByName.set(nombre, r.rows[0].id);
        out.warningMessages.push(`Categoría creada: ${nombre}`);
      } catch (e) { out.errorMessages.push(`No se pudo crear categoría ${nombre}: ${(e as Error).message}`); }
    }
    for (const nombre of provs) {
      try {
        const r = await pool.query<{ id: string }>(`INSERT INTO ${tPr} (empresa_id, nombre, estado) VALUES ($1::uuid,$2,'activo') RETURNING id`, [empresaId, nombre]);
        maps.proveedoresByName.set(nombre, r.rows[0].id);
        out.warningMessages.push(`Proveedor creado: ${nombre}`);
      } catch (e) { out.errorMessages.push(`No se pudo crear proveedor ${nombre}: ${(e as Error).message}`); }
    }
    for (const nombre of ubis) {
      try {
        const r = await pool.query<{ id: string }>(`INSERT INTO ${tU} (empresa_id, nombre, tipo, activo) VALUES ($1::uuid,$2,'otro',true) RETURNING id`, [empresaId, nombre]);
        maps.ubicacionesByName.set(nombre, r.rows[0].id);
        out.warningMessages.push(`Ubicación creada: ${nombre} (tipo: otro)`);
      } catch (e) { out.errorMessages.push(`No se pudo crear ubicación ${nombre}: ${(e as Error).message}`); }
    }
  }

  /**
   * Las filas se escriben en tandas CONCURRENTES.
   *
   * Antes esto era un for anidado con `await` por fila: los "chunks" de 200 no
   * hacían nada, la ejecución seguía siendo estrictamente secuencial. Cada fila
   * cuesta 2 o 3 viajes a la base (secuencia, insert, movimiento), así que un
   * catálogo de 1.149 productos son más de 2.500 consultas en fila india. Con
   * la latencia de Supabase eso pasa los dos minutos y el proxy corta la
   * request: el navegador recibe la página de error en HTML y el importador
   * muere con "Unexpected token '<'" después de haber escrito una parte.
   *
   * El tamaño de tanda acompaña al pool (PG_POOL_MAX, 10 por defecto): más
   * concurrencia que conexiones solo agrega cola.
   *
   * Es seguro en paralelo: los contadores de `out` se tocan entre awaits, y
   * Node no ejecuta dos de esos tramos a la vez; el código de barras interno
   * sale de `incrementar_secuencia_producto`, que es un upsert atómico con
   * ON CONFLICT ... RETURNING, no un SELECT MAX.
   *
   * Efecto visible: los mensajes de error dejan de salir ordenados por fila.
   * Cada uno dice a qué fila pertenece, así que se ordenan al final.
   */
  const CONCURRENCIA = 10;
  for (const chunk of chunked(parsed, CONCURRENCIA)) {
    await Promise.all(chunk.map(async (p) => {
      if (p.errors.length > 0) { out.errors++; out.errorMessages.push(`Fila ${p.row_number}: ${p.errors.join("; ")}`); return; }
      const categoriaId = p.categoria_nombre ? maps.categoriasByName.get(p.categoria_nombre) ?? null : null;
      const proveedorId = p.proveedor_nombre ? maps.proveedoresByName.get(p.proveedor_nombre) ?? null : null;
      const ubicacionId = p.ubicacion_nombre
        ? (maps.ubicacionesByName.get(p.ubicacion_nombre) ?? maps.ubicacionesByCodigo.get(p.ubicacion_nombre) ?? null)
        : null;

      try {
        if (p.match_id) {
          // UPDATE — el stock anterior sale del cache que ya cargo
          // buildResolverMaps (productosById). Antes esto pegaba un SELECT
          // por fila y era casi la mitad del tiempo del commit.
          const stockAnterior = Number(maps.productosById.get(p.match_id)?.stock_actual ?? 0);
          await pool.query(
            `UPDATE ${tP} SET
               nombre=$1, sku=$2, codigo_barras=NULLIF($3,''),
               unidad_medida=$4, costo_promedio=$5::numeric, precio_venta=$6::numeric,
               stock_actual=$7::numeric, stock_minimo=$8::numeric,
               metodo_valuacion=$9, activo=$10::boolean,
               categoria_principal_id=$11::uuid, proveedor_principal_id=$12::uuid, ubicacion_principal_id=$13::uuid,
               updated_at=now()
             WHERE id=$14::uuid AND empresa_id=$15::uuid`,
            [p.nombre, p.sku, p.codigo_barras, p.unidad_medida, p.costo_promedio, p.precio_venta,
             p.stock_actual, p.stock_minimo, p.metodo_valuacion, p.activo,
             categoriaId, proveedorId, ubicacionId, p.match_id, empresaId]
          );
          out.updated++;
          // Movimiento por delta (ajuste_manual + ENTRADA/SALIDA segun signo)
          const delta = p.stock_actual - stockAnterior;
          if (delta !== 0) {
            encolarMovimiento({
              producto_id: p.match_id,
              producto_nombre: p.nombre,
              producto_sku: p.sku,
              tipo: delta > 0 ? "ENTRADA" : "SALIDA",
              origen: "ajuste_manual",
              cantidad: Math.abs(delta),
              costo_unitario: p.costo_promedio,
              refExtra: `Δ ${delta > 0 ? "+" : ""}${delta} (prev=${stockAnterior} new=${p.stock_actual})`,
            });
          }
        } else {
          // Generar codigo_barras_interno si no vino
          let codigoBarras = p.codigo_barras;
          let codigoInterno = false;
          if (!codigoBarras) {
            try {
              const r = await pool.query<{ v: string }>(`SELECT ${tSec}($1::uuid) AS v`, [empresaId]);
              const seq = Number(r.rows[0]?.v ?? 0);
              if (seq > 0) {
                codigoBarras = `INT-${String(seq).padStart(6, "0")}`;
                codigoInterno = true;
              }
            } catch (e) { out.warningMessages.push(`Fila ${p.row_number}: no se pudo generar código interno (${(e as Error).message})`); }
          }
          const inserted = await pool.query<{ id: string }>(
            `INSERT INTO ${tP} (
               empresa_id, sucursal_id, nombre, sku, codigo_barras, codigo_barras_interno,
               unidad_medida, costo_promedio, precio_venta, stock_actual, stock_minimo,
               metodo_valuacion, activo, categoria_principal_id, proveedor_principal_id, ubicacion_principal_id
             ) VALUES (
               $1::uuid, $2::uuid, $3, NULLIF($4,''), NULLIF($5,''), $6::boolean,
               $7, $8::numeric, $9::numeric, $10::numeric, $11::numeric,
               $12, $13::boolean, $14::uuid, $15::uuid, $16::uuid
             ) RETURNING id`,
            [empresaId, sucursalId, p.nombre, p.sku, codigoBarras, codigoInterno,
             p.unidad_medida, p.costo_promedio, p.precio_venta, p.stock_actual, p.stock_minimo,
             p.metodo_valuacion, p.activo, categoriaId, proveedorId, ubicacionId]
          );
          out.inserted++;
          // Movimiento de inventario inicial si stock > 0
          if (p.stock_actual > 0 && inserted.rows[0]?.id) {
            encolarMovimiento({
              producto_id: inserted.rows[0].id,
              producto_nombre: p.nombre,
              producto_sku: p.sku,
              tipo: "ENTRADA",
              origen: "inventario_inicial",
              cantidad: p.stock_actual,
              costo_unitario: p.costo_promedio,
            });
          }
        }
        if (p.warnings.length > 0) out.warnings++;
      } catch (e) {
        out.errors++;
        const msg = (e as Error).message;
        const code = (e as { code?: string })?.code;
        if (code === "23505") {
          out.errorMessages.push(`Fila ${p.row_number}: SKU/Código duplicado (${msg.slice(0, 80)})`);
        } else {
          out.errorMessages.push(`Fila ${p.row_number}: ${msg.slice(0, 200)}`);
        }
      }
    }));
  }

  // Flush bulk de movimientos en tandas de 500. Antes esto era un INSERT por
  // fila (1000+ round-trips); con 500-row VALUES cae a 2-3 requests. Si una
  // tanda falla, degradamos a INSERT individual para no perder el resto.
  const MOV_CHUNK = 500;
  const MOV_COLS = 13; // debe coincidir con la cantidad de placeholders por fila
  for (const chunk of chunked(pendingMovs, MOV_CHUNK)) {
    const values: string[] = [];
    const params: unknown[] = [];
    let n = 1;
    for (const m of chunk) {
      const refFinal = m.refExtra ? `${refImport} ${m.refExtra}` : refImport;
      values.push(
        `($${n}::uuid,$${n + 1}::uuid,$${n + 2}::uuid,$${n + 3},$${n + 4},$${n + 5},$${n + 6}::numeric,$${n + 7}::numeric,$${n + 8},$${n + 9},now(),$${n + 10}::uuid,$${n + 11})`
      );
      n += MOV_COLS - 1; // fecha es now(), no cuenta como placeholder
      params.push(
        empresaId, sucursalId, m.producto_id, m.producto_nombre, m.producto_sku,
        m.tipo, m.cantidad, m.costo_unitario, m.origen, refFinal,
        ctx.createdBy ?? null, ctx.usuarioNombre ?? null,
      );
    }
    const sql = `INSERT INTO ${tM} (
      empresa_id, sucursal_id, producto_id, producto_nombre, producto_sku,
      tipo, cantidad, costo_unitario, origen, referencia, fecha, created_by, usuario_nombre
    ) VALUES ${values.join(",")}`;
    try {
      await pool.query(sql, params);
      out.movimientos_generados += chunk.length;
      for (const m of chunk) {
        if (m.tipo === "ENTRADA") out.unidades_entrada += m.cantidad;
        else out.unidades_salida += m.cantidad;
      }
    } catch (e) {
      // Fallback: la tanda entera fallo; probamos uno a uno para no perder
      // los que si eran validos y para reportar el motivo concreto.
      out.warningMessages.push(`Tanda de ${chunk.length} movimientos fallo en bloque, reintentando individualmente: ${(e as Error).message.slice(0, 120)}`);
      for (const m of chunk) {
        try {
          const refFinal = m.refExtra ? `${refImport} ${m.refExtra}` : refImport;
          await pool.query(
            `INSERT INTO ${tM} (empresa_id, sucursal_id, producto_id, producto_nombre, producto_sku,
              tipo, cantidad, costo_unitario, origen, referencia, fecha, created_by, usuario_nombre)
             VALUES ($1::uuid,$2::uuid,$3::uuid,$4,$5,$6,$7::numeric,$8::numeric,$9,$10,now(),$11::uuid,$12)`,
            [empresaId, sucursalId, m.producto_id, m.producto_nombre, m.producto_sku,
             m.tipo, m.cantidad, m.costo_unitario, m.origen, refFinal,
             ctx.createdBy ?? null, ctx.usuarioNombre ?? null]
          );
          out.movimientos_generados++;
          if (m.tipo === "ENTRADA") out.unidades_entrada += m.cantidad;
          else out.unidades_salida += m.cantidad;
        } catch (e2) {
          out.warningMessages.push(`No se pudo registrar movimiento para ${m.producto_nombre}: ${(e2 as Error).message.slice(0, 120)}`);
        }
      }
    }
  }

  // Con las tandas concurrentes los mensajes llegan en el orden en que
  // respondió la base, no en el del archivo. Se reordenan por número de fila
  // para que el reporte de errores se pueda seguir contra el Excel.
  const porFila = (a: string, b: string) => {
    const n = (s: string) => Number(/^Fila (\d+):/.exec(s)?.[1] ?? Number.MAX_SAFE_INTEGER);
    return n(a) - n(b);
  };
  out.errorMessages.sort(porFila);
  out.warningMessages.sort(porFila);

  return out;
}

/** Helper sin uso directo aqui pero util al exponer en templates */
export const PRODUCTOS_TEMPLATE_ROW = {
  NOMBRE: "EJEMPLO PRODUCTO",
  SKU: "EJ-001",
  CODIGO_BARRAS: "",
  CATEGORIA: "ELECTRICIDAD",
  PROVEEDOR_PRINCIPAL: "DON HERRAMIENTAS SA",
  UBICACION_PRINCIPAL: "DEPOSITO CENTRAL",
  UNIDAD_MEDIDA: "UNIDAD",
  COSTO_PROMEDIO: 10000,
  PRECIO_VENTA: 15000,
  STOCK_ACTUAL: 10,
  STOCK_MINIMO: 2,
  METODO_VALUACION: "CPP",
  ACTIVO: "SI",
};
// Util para detectar uso por linter
export const _unused = normalizeUpperNullable;
