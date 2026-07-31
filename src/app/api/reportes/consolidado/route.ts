import { NextRequest, NextResponse } from "next/server";
import { getTenantSupabaseFromAuthWithRol } from "@/lib/supabase/tenant-api";
import { isAdmin } from "@/lib/middleware/auth";
import { fetchDataSchemaForEmpresaId } from "@/lib/supabase/empresa-data-schema";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { getReporteConsolidado } from "@/lib/reportes/server/consolidado-pg";
import { asuncionMesBoundsUtc, normalizarMes } from "@/lib/fechas/asuncion-bounds";

/**
 * GET /api/reportes/consolidado?mes=YYYY-MM — totales de TODAS las sucursales.
 *
 * Solo admin, y el chequeo es el único control que hay: a diferencia del resto
 * de los reportes, esta ruta no filtra por `auth.sucursal_id` a propósito (ver
 * el comentario de `consolidado-pg.ts`). Si el gate se cae, un encargado ve los
 * números del otro local.
 */
export async function GET(request: NextRequest) {
  try {
    const ctx = await getTenantSupabaseFromAuthWithRol(request);
    if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    if (!isAdmin(ctx.auth)) {
      return NextResponse.json(
        errorResponse("El consolidado de sucursales es solo para administradores."),
        { status: 403 }
      );
    }
    const schema = await fetchDataSchemaForEmpresaId(ctx.auth.empresa_id);
    const mes = normalizarMes(request.nextUrl.searchParams.get("mes"));
    const { start, end } = asuncionMesBoundsUtc(mes);
    const data = await getReporteConsolidado(schema, ctx.auth.empresa_id, { start, end });
    return NextResponse.json(successResponse({ ...data, mes }));
  } catch (err) {
    console.error("[/api/reportes/consolidado]", err instanceof Error ? err.message : err);
    return NextResponse.json(errorResponse("No se pudo cargar el consolidado."), { status: 500 });
  }
}
