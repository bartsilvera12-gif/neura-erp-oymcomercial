import { NextRequest, NextResponse } from "next/server";
import { getUserAndEmpresa } from "@/lib/middleware/auth";
import { fetchDataSchemaForEmpresaId } from "@/lib/supabase/empresa-data-schema";
import { exigirSucursal, respuestaSucursalNoAsignada } from "@/lib/sucursales/filtro";
import { abrirCajaPg } from "@/lib/caja/server/caja-pg";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";

/** POST /api/caja/abrir — abre el turno de la sucursal del usuario con un monto inicial. */
export async function POST(request: NextRequest) {
  try {
    const auth = await getUserAndEmpresa(request);
    if (!auth) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    const sucursalId = exigirSucursal(auth.sucursal_id);

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return NextResponse.json(errorResponse("JSON inválido."), { status: 400 });
    }
    const o = (body ?? {}) as Record<string, unknown>;
    const montoApertura = Number(o.monto_apertura);
    if (!Number.isFinite(montoApertura) || montoApertura < 0) {
      return NextResponse.json(errorResponse("Monto de apertura inválido."), { status: 400 });
    }
    const observacion =
      o.observacion == null || o.observacion === "" ? null : String(o.observacion).slice(0, 2000);

    const schema = await fetchDataSchemaForEmpresaId(auth.empresa_id);
    const caja = await abrirCajaPg({
      schema,
      empresaId: auth.empresa_id,
      sucursalId,
      montoApertura,
      observacion,
      usuarioId: auth.usuarioCatalogId ?? null,
    });
    return NextResponse.json(successResponse({ caja }), { status: 201 });
  } catch (err) {
    const res = respuestaSucursalNoAsignada(err);
    if (res) return res;
    const msg = err instanceof Error ? err.message : "No se pudo abrir la caja.";
    const status = msg.includes("Ya hay una caja abierta") ? 409 : 500;
    if (status === 500) console.error("[/api/caja/abrir]", msg);
    return NextResponse.json(errorResponse(msg), { status });
  }
}
