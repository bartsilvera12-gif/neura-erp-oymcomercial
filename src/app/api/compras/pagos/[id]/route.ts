import { NextRequest, NextResponse } from "next/server";
import { getTenantSupabaseFromAuthWithRol } from "@/lib/supabase/tenant-api";
import { isAdmin } from "@/lib/middleware/auth";
import { exigirSucursal, respuestaSucursalNoAsignada } from "@/lib/sucursales/filtro";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";

/**
 * DELETE /api/compras/pagos/[id] — borra un pago mal cargado.
 *
 * Solo admin: borrar un pago aumenta la deuda con el proveedor, así que no es
 * una corrección que deba poder hacer cualquiera desde la pantalla.
 * El filtro por sucursal además impide borrar un pago de otro local.
 */
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const ctx = await getTenantSupabaseFromAuthWithRol(request);
    if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    if (!isAdmin(ctx.auth)) {
      return NextResponse.json(
        errorResponse("Solo un administrador puede eliminar un pago."),
        { status: 403 }
      );
    }
    const sucursalId = exigirSucursal(ctx.auth.sucursal_id);
    const { id } = await params;
    if (!id) return NextResponse.json(errorResponse("Falta el id del pago."), { status: 400 });

    const { data, error } = await ctx.supabase
      .from("compras_pagos")
      .delete()
      .eq("empresa_id", ctx.auth.empresa_id)
      .eq("sucursal_id", sucursalId)
      .eq("id", id)
      .select("id")
      .maybeSingle();
    if (error) throw new Error(error.message);
    if (!data) return NextResponse.json(errorResponse("Pago no encontrado."), { status: 404 });

    return NextResponse.json(successResponse({ id }));
  } catch (err) {
    const res = respuestaSucursalNoAsignada(err);
    if (res) return res;
    console.error("[/api/compras/pagos/[id] DELETE]", err instanceof Error ? err.message : err);
    return NextResponse.json(errorResponse("No se pudo eliminar el pago."), { status: 500 });
  }
}
