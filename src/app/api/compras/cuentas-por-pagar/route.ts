import { NextRequest, NextResponse } from "next/server";
import { getUserAndEmpresa } from "@/lib/middleware/auth";
import { fetchDataSchemaForEmpresaId } from "@/lib/supabase/empresa-data-schema";
import { exigirSucursal, respuestaSucursalNoAsignada } from "@/lib/sucursales/filtro";
import { getCuentasPorPagar } from "@/lib/compras/server/cuentas-por-pagar-pg";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";

/**
 * GET /api/compras/cuentas-por-pagar[?incluir=pagados]
 *
 * Deuda con proveedores de la sucursal del usuario, agrupada por documento.
 * Por defecto solo los que tienen saldo; con `incluir=pagados` también los
 * cancelados, para consultar el historial.
 */
export async function GET(request: NextRequest) {
  try {
    const auth = await getUserAndEmpresa(request);
    if (!auth) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    const sucursalId = exigirSucursal(auth.sucursal_id);
    const schema = await fetchDataSchemaForEmpresaId(auth.empresa_id);
    const incluirPagados = request.nextUrl.searchParams.get("incluir") === "pagados";

    const data = await getCuentasPorPagar(schema, auth.empresa_id, sucursalId, { incluirPagados });
    return NextResponse.json(successResponse(data));
  } catch (err) {
    const res = respuestaSucursalNoAsignada(err);
    if (res) return res;
    console.error("[/api/compras/cuentas-por-pagar]", err instanceof Error ? err.message : err);
    return NextResponse.json(errorResponse("No se pudieron calcular las cuentas por pagar."), { status: 500 });
  }
}
