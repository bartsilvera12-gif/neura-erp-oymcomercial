import { NextRequest, NextResponse } from "next/server";
import { getUserAndEmpresa } from "@/lib/middleware/auth";
import { fetchDataSchemaForEmpresaId } from "@/lib/supabase/empresa-data-schema";
import { exigirSucursal, respuestaSucursalNoAsignada } from "@/lib/sucursales/filtro";
import { listarCajasPg } from "@/lib/caja/server/caja-pg";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";

/** GET /api/caja/historial — turnos de la sucursal del usuario, con totales calculados. */
export async function GET(request: NextRequest) {
  try {
    const auth = await getUserAndEmpresa(request);
    if (!auth) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    const sucursalId = exigirSucursal(auth.sucursal_id);
    const schema = await fetchDataSchemaForEmpresaId(auth.empresa_id);

    const limitRaw = parseInt(request.nextUrl.searchParams.get("limit") ?? "100", 10);
    const limit = Number.isFinite(limitRaw) ? Math.min(Math.max(limitRaw, 1), 300) : 100;

    const cajas = await listarCajasPg(schema, auth.empresa_id, sucursalId, limit);
    return NextResponse.json(successResponse({ cajas }));
  } catch (err) {
    const res = respuestaSucursalNoAsignada(err);
    if (res) return res;
    console.error("[/api/caja/historial]", err instanceof Error ? err.message : err);
    return NextResponse.json(errorResponse("No se pudo cargar el historial."), { status: 500 });
  }
}
