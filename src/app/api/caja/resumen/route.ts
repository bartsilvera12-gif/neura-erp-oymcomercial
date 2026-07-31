import { NextRequest, NextResponse } from "next/server";
import { getUserAndEmpresa } from "@/lib/middleware/auth";
import { fetchDataSchemaForEmpresaId } from "@/lib/supabase/empresa-data-schema";
import { exigirSucursal, respuestaSucursalNoAsignada } from "@/lib/sucursales/filtro";
import { getResumenCajaPg, getCajaAbiertaPg } from "@/lib/caja/server/caja-pg";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";

/**
 * GET /api/caja/resumen?caja_id=… — arqueo de una caja.
 * Sin `caja_id` devuelve el de la caja abierta de la sucursal (o null).
 */
export async function GET(request: NextRequest) {
  try {
    const auth = await getUserAndEmpresa(request);
    if (!auth) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    const sucursalId = exigirSucursal(auth.sucursal_id);
    const schema = await fetchDataSchemaForEmpresaId(auth.empresa_id);

    let cajaId = request.nextUrl.searchParams.get("caja_id");
    if (!cajaId) {
      const abierta = await getCajaAbiertaPg(schema, auth.empresa_id, sucursalId);
      if (!abierta) return NextResponse.json(successResponse({ resumen: null }));
      cajaId = abierta.id;
    }

    const resumen = await getResumenCajaPg(schema, auth.empresa_id, sucursalId, cajaId);
    if (!resumen) return NextResponse.json(errorResponse("Caja no encontrada."), { status: 404 });
    return NextResponse.json(successResponse({ resumen }));
  } catch (err) {
    const res = respuestaSucursalNoAsignada(err);
    if (res) return res;
    console.error("[/api/caja/resumen]", err instanceof Error ? err.message : err);
    return NextResponse.json(errorResponse("No se pudo obtener el resumen."), { status: 500 });
  }
}
