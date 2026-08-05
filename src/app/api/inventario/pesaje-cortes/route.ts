import { NextRequest, NextResponse } from "next/server";
import { getTenantSupabaseFromAuth, getTenantSupabaseFromAuthWithRol } from "@/lib/supabase/tenant-api";
// getTenantSupabaseFromAuth se importa solo para el handler GET, que no
// necesita rol (cualquier usuario con acceso al slug inventario puede consultar).
import { fetchDataSchemaForEmpresaId } from "@/lib/supabase/empresa-data-schema";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { exigirSucursal, respuestaSucursalNoAsignada } from "@/lib/sucursales/filtro";
import { esRolAdminEmpresa } from "@/lib/modulos/resolve-effective-modules";
import {
  createPesajePg,
  listPesajesPg,
  type PesajeDestino,
  type PesajeLineaInput,
} from "@/lib/inventario/server/pesaje-pg";

/**
 * POST /api/inventario/pesaje-cortes
 * Crea una operación de pesaje/cortes/mermas. Solo admin de empresa (los
 * roles operativos no deberían transformar stock — es una operación
 * administrativa con impacto contable).
 *
 * GET /api/inventario/pesaje-cortes?limit=20
 * Últimas N operaciones de la sucursal actual, con sus líneas.
 *
 * Runtime Node.js + maxDuration 60 (pool PG directo, no edge; una operación
 * grande con muchas líneas puede tardar un par de segundos por el trigger
 * de conservación diferido).
 */
export const runtime = "nodejs";
export const maxDuration = 60;

const DESTINOS_VALIDOS: ReadonlySet<PesajeDestino> = new Set([
  "resto_aprovechable",
  "recorte_vendible",
  "merma",
  "consumo_interno",
]);

interface LineaInputRaw {
  destino?: unknown;
  peso?: unknown;
  producto_derivado_id?: unknown;
  observacion?: unknown;
}

/** Normaliza y valida el array de líneas del body. Devuelve tuple para poder
 *  ir con `if (err) return 400` sin mezclar los flujos. */
function parseLineas(raw: unknown): { lineas: PesajeLineaInput[]; error: string | null } {
  if (!Array.isArray(raw) || raw.length === 0) {
    return { lineas: [], error: "Cargá al menos una línea de destino." };
  }
  const lineas: PesajeLineaInput[] = [];
  for (const r of raw as LineaInputRaw[]) {
    const destino = typeof r.destino === "string" ? r.destino : "";
    if (!DESTINOS_VALIDOS.has(destino as PesajeDestino)) {
      return { lineas: [], error: `Destino inválido: "${destino}"` };
    }
    const peso = Number(r.peso);
    if (!Number.isFinite(peso) || peso <= 0) {
      return { lineas: [], error: "Cada línea debe tener un peso mayor a 0." };
    }
    const derivadoId = r.producto_derivado_id ? String(r.producto_derivado_id) : null;
    if (destino === "recorte_vendible" && !derivadoId) {
      return { lineas: [], error: "La línea 'recorte vendible' requiere un producto derivado." };
    }
    if (destino !== "recorte_vendible" && derivadoId) {
      return { lineas: [], error: "Solo 'recorte vendible' puede tener producto derivado." };
    }
    lineas.push({
      destino: destino as PesajeDestino,
      peso,
      producto_derivado_id: derivadoId,
      observacion: typeof r.observacion === "string" ? r.observacion.trim() || null : null,
    });
  }
  return { lineas, error: null };
}

export async function POST(request: NextRequest) {
  try {
    // WithRol: pesaje es operación administrativa (afecta stock + costeo).
    // Los usuarios operativos pueden vender por peso desde la caja pero no
    // procesar piezas.
    const ctx = await getTenantSupabaseFromAuthWithRol(request);
    if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    const sucursalId = exigirSucursal(ctx.auth.sucursal_id);
    const empresaId = ctx.auth.empresa_id;

    if (!esRolAdminEmpresa(ctx.auth.rol ?? "")) {
      return NextResponse.json(errorResponse("Solo el administrador puede registrar pesaje/cortes."), { status: 403 });
    }

    let body: Record<string, unknown>;
    try {
      body = (await request.json()) as Record<string, unknown>;
    } catch {
      return NextResponse.json(errorResponse("JSON inválido."), { status: 400 });
    }

    const productoOrigenId = typeof body.producto_origen_id === "string" ? body.producto_origen_id : "";
    if (!productoOrigenId) {
      return NextResponse.json(errorResponse("Seleccioná un producto de origen."), { status: 400 });
    }
    const pesoProcesado = Number(body.peso_procesado);
    if (!Number.isFinite(pesoProcesado) || pesoProcesado <= 0) {
      return NextResponse.json(errorResponse("El peso procesado debe ser mayor a 0."), { status: 400 });
    }
    const motivo = typeof body.motivo === "string" ? body.motivo.trim() || null : null;
    const observaciones = typeof body.observaciones === "string" ? body.observaciones.trim() || null : null;

    const parsed = parseLineas(body.lineas);
    if (parsed.error) return NextResponse.json(errorResponse(parsed.error), { status: 400 });

    // La conservación de peso también la enforce el trigger DB — este check
    // es solo para dar el 400 rápido sin pegarle a Postgres.
    const suma = parsed.lineas.reduce((s, l) => s + l.peso, 0);
    if (Math.abs(suma - pesoProcesado) > 0.0005) {
      return NextResponse.json(
        errorResponse(
          `La suma de las líneas (${suma.toFixed(3)} kg) no coincide con el peso procesado (${pesoProcesado.toFixed(3)} kg).`
        ),
        { status: 400 }
      );
    }

    const schema = await fetchDataSchemaForEmpresaId(empresaId);
    const result = await createPesajePg({
      schema,
      empresaId,
      sucursalId,
      productoOrigenId,
      pesoProcesado,
      motivo,
      observaciones,
      createdBy: ctx.auth.usuarioCatalogId ?? null,
      usuarioNombre: ctx.auth.nombre ?? null,
      lineas: parsed.lineas,
    });

    return NextResponse.json(successResponse(result));
  } catch (err) {
    const rSuc = respuestaSucursalNoAsignada(err);
    if (rSuc) return rSuc;
    const msg = err instanceof Error ? err.message : "No se pudo registrar la operación.";
    console.error("[/api/inventario/pesaje-cortes POST]", msg);
    // Errores esperados del lib (peso, stock, conservación) llegan como 400.
    const esUserError =
      msg.startsWith("La suma") ||
      msg.startsWith("Conservación") ||
      msg.startsWith("Stock insuficiente") ||
      msg.startsWith("Producto de origen") ||
      msg.startsWith("El producto de origen") ||
      msg.startsWith("El peso") ||
      msg.startsWith("Cada línea") ||
      msg.startsWith("La línea") ||
      msg.startsWith("Solo 'recorte") ||
      msg.startsWith("Producto(s) derivado");
    return NextResponse.json(errorResponse(msg), { status: esUserError ? 400 : 500 });
  }
}

export async function GET(request: NextRequest) {
  try {
    const ctx = await getTenantSupabaseFromAuth(request);
    if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    const sucursalId = exigirSucursal(ctx.auth.sucursal_id);
    const empresaId = ctx.auth.empresa_id;

    const url = new URL(request.url);
    const limitParam = Number(url.searchParams.get("limit") ?? "20");
    const limit = Math.max(1, Math.min(100, Number.isFinite(limitParam) ? limitParam : 20));

    const schema = await fetchDataSchemaForEmpresaId(empresaId);
    const items = await listPesajesPg(schema, empresaId, sucursalId, limit);
    return NextResponse.json(successResponse({ items, count: items.length }));
  } catch (err) {
    const rSuc = respuestaSucursalNoAsignada(err);
    if (rSuc) return rSuc;
    console.error("[/api/inventario/pesaje-cortes GET]", err instanceof Error ? err.message : err);
    return NextResponse.json(errorResponse("No se pudo listar las operaciones."), { status: 500 });
  }
}
