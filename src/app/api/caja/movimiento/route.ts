import { NextRequest, NextResponse } from "next/server";
import { getUserAndEmpresa } from "@/lib/middleware/auth";
import { fetchDataSchemaForEmpresaId } from "@/lib/supabase/empresa-data-schema";
import { exigirSucursal, respuestaSucursalNoAsignada } from "@/lib/sucursales/filtro";
import { registrarMovimientoPg, getCajaAbiertaPg } from "@/lib/caja/server/caja-pg";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import type { MedioPagoCaja, TipoMovimientoCaja } from "@/lib/caja/types";

const TIPOS: TipoMovimientoCaja[] = ["ingreso", "egreso", "retiro", "ajuste"];
const MEDIOS: MedioPagoCaja[] = ["efectivo", "tarjeta", "transferencia", "otro"];

/** POST /api/caja/movimiento — ingreso/egreso/retiro/ajuste sobre la caja abierta. */
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

    const tipo = o.tipo as TipoMovimientoCaja;
    if (!TIPOS.includes(tipo)) {
      return NextResponse.json(errorResponse("Tipo de movimiento inválido."), { status: 400 });
    }
    const concepto = typeof o.concepto === "string" ? o.concepto.trim() : "";
    if (concepto.length === 0) {
      return NextResponse.json(errorResponse("El concepto es obligatorio."), { status: 400 });
    }
    const monto = Number(o.monto);
    if (!Number.isFinite(monto) || monto <= 0) {
      return NextResponse.json(errorResponse("El monto debe ser mayor a 0."), { status: 400 });
    }
    const medioPago: MedioPagoCaja = MEDIOS.includes(o.medio_pago as MedioPagoCaja)
      ? (o.medio_pago as MedioPagoCaja)
      : "efectivo";
    const observacion =
      o.observacion == null || o.observacion === "" ? null : String(o.observacion).slice(0, 2000);

    const schema = await fetchDataSchemaForEmpresaId(auth.empresa_id);

    let cajaId = o.caja_id == null || o.caja_id === "" ? null : String(o.caja_id);
    if (!cajaId) {
      const abierta = await getCajaAbiertaPg(schema, auth.empresa_id, sucursalId);
      if (!abierta) {
        return NextResponse.json(
          errorResponse("No hay caja abierta. Abrí la caja antes de registrar movimientos."),
          { status: 409 }
        );
      }
      cajaId = abierta.id;
    }

    const movimiento = await registrarMovimientoPg({
      schema,
      empresaId: auth.empresa_id,
      sucursalId,
      cajaId,
      tipo,
      concepto,
      monto,
      medioPago,
      observacion,
      usuarioId: auth.usuarioCatalogId ?? null,
    });
    return NextResponse.json(successResponse({ movimiento }), { status: 201 });
  } catch (err) {
    const res = respuestaSucursalNoAsignada(err);
    if (res) return res;
    const msg = err instanceof Error ? err.message : "No se pudo registrar el movimiento.";
    const status = msg.includes("no encontrada") || msg.includes("cerrada") ? 409 : 500;
    if (status === 500) console.error("[/api/caja/movimiento]", msg);
    return NextResponse.json(errorResponse(msg), { status });
  }
}
