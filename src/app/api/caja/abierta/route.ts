import { NextRequest, NextResponse } from "next/server";
import { getUserAndEmpresa } from "@/lib/middleware/auth";
import { fetchDataSchemaForEmpresaId } from "@/lib/supabase/empresa-data-schema";
import { exigirSucursal, respuestaSucursalNoAsignada } from "@/lib/sucursales/filtro";
import { getCajaAbiertaPg } from "@/lib/caja/server/caja-pg";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";

/** GET /api/caja/abierta — caja abierta de la sucursal del usuario (o null). */
export async function GET(request: NextRequest) {
  try {
    const auth = await getUserAndEmpresa(request);
    if (!auth) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    const sucursalId = exigirSucursal(auth.sucursal_id);
    const schema = await fetchDataSchemaForEmpresaId(auth.empresa_id);
    const caja = await getCajaAbiertaPg(schema, auth.empresa_id, sucursalId);
    return NextResponse.json(successResponse({ caja }));
  } catch (err) {
    const res = respuestaSucursalNoAsignada(err);
    if (res) return res;
    console.error("[/api/caja/abierta]", err instanceof Error ? err.message : err);
    return NextResponse.json(errorResponse("No se pudo obtener la caja."), { status: 500 });
  }
}
