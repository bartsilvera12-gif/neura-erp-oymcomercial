import { NextRequest, NextResponse } from "next/server";
import { getTenantSupabaseFromAuth } from "@/lib/supabase/tenant-api";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { exigirSucursal, respuestaSucursalNoAsignada } from "@/lib/sucursales/filtro";

/**
 * GET /api/reportes/mermas
 *
 * Reporte de peso perdido / usado internamente durante operaciones de
 * pesaje/cortes. Consulta `pesaje_operacion_lineas` (JOIN a
 * `pesaje_operaciones` para fecha + usuario + motivo + origen, JOIN a
 * `productos` para nombre + SKU).
 *
 * Filtros por query string:
 *   - desde=YYYY-MM-DD  (default: hace 30 días)
 *   - hasta=YYYY-MM-DD  (default: hoy)
 *   - destino=merma|consumo_interno|ambos (default: ambos)
 *   - producto_id=uuid  (opcional)
 *
 * Devuelve:
 *   {
 *     rango: { desde, hasta },
 *     totales: {
 *       peso_merma, peso_consumo, peso_total,
 *       operaciones, lineas
 *     },
 *     top_productos: [{ producto_id, nombre, peso_merma, peso_consumo, peso_total }],
 *     detalle: [{ operacion_id, fecha, producto_id, nombre, sku, destino, peso, observacion, motivo, usuario_nombre }]
 *   }
 *
 * Solo se listan operaciones de la sucursal actual (misma regla que el
 * resto de reportes operativos). Multi-sucursal iría al consolidado.
 */

type Destino = "merma" | "consumo_interno";

interface OperacionRow {
  id: string;
  created_at: string;
  motivo: string | null;
  usuario_nombre: string | null;
  producto_origen_id: string;
}

interface LineaRow {
  operacion_id: string;
  destino: string;
  peso: string | number;
  observacion: string | null;
}

interface ProductoLite {
  id: string;
  nombre: string;
  sku: string | null;
}

function parseDate(s: string | null, fallback: Date): Date {
  if (!s) return fallback;
  const d = new Date(s);
  return isNaN(d.getTime()) ? fallback : d;
}

function toISODateEndOfDay(d: Date): string {
  const x = new Date(d);
  x.setHours(23, 59, 59, 999);
  return x.toISOString();
}

function toISODateStartOfDay(d: Date): string {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x.toISOString();
}

export async function GET(request: NextRequest) {
  try {
    const ctx = await getTenantSupabaseFromAuth(request);
    if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    const sucursalId = exigirSucursal(ctx.auth.sucursal_id);
    const empresaId = ctx.auth.empresa_id;

    const url = new URL(request.url);
    const ahora = new Date();
    const hace30 = new Date(ahora.getTime() - 30 * 24 * 60 * 60 * 1000);
    const desde = parseDate(url.searchParams.get("desde"), hace30);
    const hasta = parseDate(url.searchParams.get("hasta"), ahora);
    const desdeIso = toISODateStartOfDay(desde);
    const hastaIso = toISODateEndOfDay(hasta);

    const destinoParam = (url.searchParams.get("destino") ?? "ambos").toLowerCase();
    const destinos: Destino[] =
      destinoParam === "merma"
        ? ["merma"]
        : destinoParam === "consumo_interno"
        ? ["consumo_interno"]
        : ["merma", "consumo_interno"];

    const productoFiltro = url.searchParams.get("producto_id") || null;

    // 1) Traer las operaciones del rango + sucursal + (opcional) producto origen.
    let opsQ = ctx.supabase
      .from("pesaje_operaciones")
      .select("id, created_at, motivo, usuario_nombre, producto_origen_id")
      .eq("empresa_id", empresaId)
      .eq("sucursal_id", sucursalId)
      .gte("created_at", desdeIso)
      .lte("created_at", hastaIso)
      .order("created_at", { ascending: false });
    if (productoFiltro) {
      opsQ = opsQ.eq("producto_origen_id", productoFiltro);
    }
    const opsRes = await opsQ;
    if (opsRes.error) throw new Error(opsRes.error.message);
    const ops = (opsRes.data ?? []) as OperacionRow[];

    if (ops.length === 0) {
      return NextResponse.json(successResponse({
        rango: { desde: desdeIso, hasta: hastaIso },
        totales: { peso_merma: 0, peso_consumo: 0, peso_total: 0, operaciones: 0, lineas: 0 },
        top_productos: [],
        detalle: [],
      }));
    }

    const opsIds = ops.map((o) => o.id);
    const opsById = new Map(ops.map((o) => [o.id, o]));

    // 2) Traer solo las líneas de destino relevante para esas operaciones.
    const linRes = await ctx.supabase
      .from("pesaje_operacion_lineas")
      .select("operacion_id, destino, peso, observacion")
      .in("operacion_id", opsIds)
      .in("destino", destinos);
    if (linRes.error) throw new Error(linRes.error.message);
    const lineas = (linRes.data ?? []) as LineaRow[];

    if (lineas.length === 0) {
      // Puede haber operaciones sin mermas ni consumo interno (todo fue a
      // resto/recorte). Se devuelve rango + totales en 0.
      return NextResponse.json(successResponse({
        rango: { desde: desdeIso, hasta: hastaIso },
        totales: { peso_merma: 0, peso_consumo: 0, peso_total: 0, operaciones: 0, lineas: 0 },
        top_productos: [],
        detalle: [],
      }));
    }

    // 3) Hidratar nombres/SKU de los productos origen involucrados.
    const prodIds = [...new Set(ops.map((o) => o.producto_origen_id))];
    const prodRes = await ctx.supabase
      .from("productos")
      .select("id, nombre, sku")
      .in("id", prodIds);
    if (prodRes.error) throw new Error(prodRes.error.message);
    const prodById = new Map<string, ProductoLite>();
    for (const p of (prodRes.data ?? []) as ProductoLite[]) prodById.set(p.id, p);

    // 4) Armar detalle + totales + top productos.
    let pesoMerma = 0;
    let pesoConsumo = 0;
    const opsConLineas = new Set<string>();
    // acumulador por producto: { peso_merma, peso_consumo }
    const porProducto = new Map<string, { nombre: string; peso_merma: number; peso_consumo: number }>();

    const detalle = lineas.map((l) => {
      const op = opsById.get(l.operacion_id);
      const productoId = op?.producto_origen_id ?? "";
      const prod = prodById.get(productoId);
      const peso = Number(l.peso) || 0;
      opsConLineas.add(l.operacion_id);
      if (l.destino === "merma") pesoMerma += peso;
      else if (l.destino === "consumo_interno") pesoConsumo += peso;

      const acc = porProducto.get(productoId) ?? { nombre: prod?.nombre ?? "—", peso_merma: 0, peso_consumo: 0 };
      if (l.destino === "merma") acc.peso_merma += peso;
      else if (l.destino === "consumo_interno") acc.peso_consumo += peso;
      porProducto.set(productoId, acc);

      return {
        operacion_id: l.operacion_id,
        fecha: op?.created_at ?? null,
        producto_id: productoId,
        nombre: prod?.nombre ?? "—",
        sku: prod?.sku ?? null,
        destino: l.destino,
        peso,
        observacion: l.observacion,
        motivo: op?.motivo ?? null,
        usuario_nombre: op?.usuario_nombre ?? null,
      };
    });

    const topProductos = [...porProducto.entries()]
      .map(([id, v]) => ({
        producto_id: id,
        nombre: v.nombre,
        peso_merma: v.peso_merma,
        peso_consumo: v.peso_consumo,
        peso_total: v.peso_merma + v.peso_consumo,
      }))
      .sort((a, b) => b.peso_total - a.peso_total)
      .slice(0, 10);

    return NextResponse.json(successResponse({
      rango: { desde: desdeIso, hasta: hastaIso },
      totales: {
        peso_merma: pesoMerma,
        peso_consumo: pesoConsumo,
        peso_total: pesoMerma + pesoConsumo,
        operaciones: opsConLineas.size,
        lineas: detalle.length,
      },
      top_productos: topProductos,
      detalle,
    }));
  } catch (err) {
    const rSuc = respuestaSucursalNoAsignada(err);
    if (rSuc) return rSuc;
    console.error("[/api/reportes/mermas]", err instanceof Error ? err.message : err);
    return NextResponse.json(errorResponse("No se pudo generar el reporte."), { status: 500 });
  }
}
