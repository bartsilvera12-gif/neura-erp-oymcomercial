import { NextRequest, NextResponse } from "next/server";
import { getTenantSupabaseFromAuth } from "@/lib/supabase/tenant-api";
import { errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { exigirSucursal, respuestaSucursalNoAsignada } from "@/lib/sucursales/filtro";
import { buildXlsxBufferSheets, sheetFromRows, xlsxResponseHeaders } from "@/lib/excel/export";

/**
 * GET /api/reportes/mermas/export
 *
 * Exporta el reporte de mermas/consumo interno a Excel. Comparte los mismos
 * filtros que /api/reportes/mermas (desde, hasta, destino, producto_id).
 *
 * Genera un libro con dos hojas:
 *   1. "Resumen"   → totales + top productos (peso perdido).
 *   2. "Detalle"   → una fila por línea de merma/consumo con fecha, producto,
 *                    destino, peso, motivo, observación, usuario.
 *
 * Se re-usa la misma lógica de query que el endpoint JSON — se copia el
 * shape porque los reportes en este ERP no tienen aún una capa "storage"
 * server compartida; extraer un helper acá agregaría acoplamiento sin
 * mucho beneficio. Si aparece un tercer consumidor se refactoriza.
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

const DESTINO_LABEL: Record<Destino, string> = {
  merma: "Merma",
  consumo_interno: "Consumo interno",
};

function parseDate(s: string | null, fallback: Date): Date {
  if (!s) return fallback;
  const d = new Date(s);
  return isNaN(d.getTime()) ? fallback : d;
}
function toISOStart(d: Date): string { const x = new Date(d); x.setHours(0, 0, 0, 0); return x.toISOString(); }
function toISOEnd(d: Date): string { const x = new Date(d); x.setHours(23, 59, 59, 999); return x.toISOString(); }
function fmtFecha(iso: string | null): string {
  if (!iso) return "";
  try {
    const d = new Date(iso);
    return `${String(d.getDate()).padStart(2, "0")}/${String(d.getMonth() + 1).padStart(2, "0")}/${d.getFullYear()} ${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
  } catch { return iso; }
}
function fmtRangoParaTitulo(iso: string): string {
  try {
    const d = new Date(iso);
    return `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, "0")}${String(d.getDate()).padStart(2, "0")}`;
  } catch { return "x"; }
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
    const desdeIso = toISOStart(desde);
    const hastaIso = toISOEnd(hasta);
    const destinoParam = (url.searchParams.get("destino") ?? "ambos").toLowerCase();
    const destinos: Destino[] =
      destinoParam === "merma" ? ["merma"]
      : destinoParam === "consumo_interno" ? ["consumo_interno"]
      : ["merma", "consumo_interno"];
    const productoFiltro = url.searchParams.get("producto_id") || null;

    // 1) Operaciones del rango
    let opsQ = ctx.supabase
      .from("pesaje_operaciones")
      .select("id, created_at, motivo, usuario_nombre, producto_origen_id")
      .eq("empresa_id", empresaId)
      .eq("sucursal_id", sucursalId)
      .gte("created_at", desdeIso)
      .lte("created_at", hastaIso)
      .order("created_at", { ascending: false });
    if (productoFiltro) opsQ = opsQ.eq("producto_origen_id", productoFiltro);
    const opsRes = await opsQ;
    if (opsRes.error) throw new Error(opsRes.error.message);
    const ops = (opsRes.data ?? []) as OperacionRow[];
    const opsById = new Map(ops.map((o) => [o.id, o]));

    // 2) Líneas con destino filtrado
    let lineas: LineaRow[] = [];
    if (ops.length > 0) {
      const linRes = await ctx.supabase
        .from("pesaje_operacion_lineas")
        .select("operacion_id, destino, peso, observacion")
        .in("operacion_id", ops.map((o) => o.id))
        .in("destino", destinos);
      if (linRes.error) throw new Error(linRes.error.message);
      lineas = (linRes.data ?? []) as LineaRow[];
    }

    // 3) Productos
    const prodIds = [...new Set(ops.map((o) => o.producto_origen_id))];
    const prodById = new Map<string, ProductoLite>();
    if (prodIds.length > 0) {
      const prodRes = await ctx.supabase
        .from("productos")
        .select("id, nombre, sku")
        .in("id", prodIds);
      if (prodRes.error) throw new Error(prodRes.error.message);
      for (const p of (prodRes.data ?? []) as ProductoLite[]) prodById.set(p.id, p);
    }

    // 4) Armar detalle + agregados
    let pesoMerma = 0;
    let pesoConsumo = 0;
    const porProducto = new Map<string, { nombre: string; sku: string; peso_merma: number; peso_consumo: number }>();

    interface DetalleFilaExport {
      fecha: string;
      producto: string;
      sku: string;
      destino: string;
      peso: number;
      motivo: string;
      observacion: string;
      usuario: string;
    }
    const detalle: DetalleFilaExport[] = lineas.map((l) => {
      const op = opsById.get(l.operacion_id);
      const productoId = op?.producto_origen_id ?? "";
      const prod = prodById.get(productoId);
      const peso = Number(l.peso) || 0;
      if (l.destino === "merma") pesoMerma += peso;
      else if (l.destino === "consumo_interno") pesoConsumo += peso;
      const acc = porProducto.get(productoId) ?? {
        nombre: prod?.nombre ?? "—",
        sku: prod?.sku ?? "",
        peso_merma: 0,
        peso_consumo: 0,
      };
      if (l.destino === "merma") acc.peso_merma += peso;
      else if (l.destino === "consumo_interno") acc.peso_consumo += peso;
      porProducto.set(productoId, acc);
      return {
        fecha: fmtFecha(op?.created_at ?? null),
        producto: prod?.nombre ?? "—",
        sku: prod?.sku ?? "",
        destino: DESTINO_LABEL[l.destino as Destino] ?? l.destino,
        peso,
        motivo: op?.motivo ?? "",
        observacion: l.observacion ?? "",
        usuario: op?.usuario_nombre ?? "",
      };
    });

    interface TopFilaExport {
      producto: string;
      sku: string;
      peso_merma: number;
      peso_consumo: number;
      peso_total: number;
    }
    const topProductos: TopFilaExport[] = [...porProducto.values()]
      .map((v) => ({
        producto: v.nombre,
        sku: v.sku,
        peso_merma: v.peso_merma,
        peso_consumo: v.peso_consumo,
        peso_total: v.peso_merma + v.peso_consumo,
      }))
      .sort((a, b) => b.peso_total - a.peso_total);

    // 5) Armar workbook
    const resumenAoa: (string | number)[][] = [
      ["Reporte de mermas y consumo interno"],
      [`Desde ${fmtFecha(desdeIso)}`, `Hasta ${fmtFecha(hastaIso)}`],
      [`Destino: ${destinoParam}`, productoFiltro ? `Producto: ${productoFiltro}` : "Producto: (todos)"],
      [],
      ["Totales"],
      ["Peso merma (kg)", pesoMerma],
      ["Peso consumo interno (kg)", pesoConsumo],
      ["Peso total (kg)", pesoMerma + pesoConsumo],
      ["Operaciones", new Set(lineas.map((l) => l.operacion_id)).size],
      ["Líneas", lineas.length],
    ];
    const resumenSheet = {
      sheetName: "Resumen",
      aoa: resumenAoa,
      colWidths: [30, 20, 20, 20, 20],
    };

    const topSheet = sheetFromRows(
      "Top productos",
      topProductos,
      [
        { header: "Producto", value: (r) => r.producto, width: 32 },
        { header: "SKU", value: (r) => r.sku, width: 16 },
        { header: "Merma (kg)", value: (r) => r.peso_merma, width: 14 },
        { header: "Consumo (kg)", value: (r) => r.peso_consumo, width: 14 },
        { header: "Total (kg)", value: (r) => r.peso_total, width: 14 },
      ]
    );

    const detalleSheet = sheetFromRows(
      "Detalle",
      detalle,
      [
        { header: "Fecha", value: (r) => r.fecha, width: 18 },
        { header: "Producto", value: (r) => r.producto, width: 32 },
        { header: "SKU", value: (r) => r.sku, width: 16 },
        { header: "Destino", value: (r) => r.destino, width: 16 },
        { header: "Peso (kg)", value: (r) => r.peso, width: 12 },
        { header: "Motivo", value: (r) => r.motivo, width: 28 },
        { header: "Observación", value: (r) => r.observacion, width: 28 },
        { header: "Usuario", value: (r) => r.usuario, width: 22 },
      ]
    );

    const buf = buildXlsxBufferSheets([resumenSheet, topSheet, detalleSheet]);
    const filename = `mermas_${fmtRangoParaTitulo(desdeIso)}_${fmtRangoParaTitulo(hastaIso)}`;
    // Body-init acepta Buffer en Node runtime; TS/Next types no lo saben.
    return new Response(buf as unknown as BodyInit, {
      status: 200,
      headers: xlsxResponseHeaders(filename),
    });
  } catch (err) {
    const rSuc = respuestaSucursalNoAsignada(err);
    if (rSuc) return rSuc;
    console.error("[/api/reportes/mermas/export]", err instanceof Error ? err.message : err);
    return NextResponse.json(errorResponse("No se pudo generar el export."), { status: 500 });
  }
}
