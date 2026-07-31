import { NextRequest, NextResponse } from "next/server";
import { getUserAndEmpresa } from "@/lib/middleware/auth";
import { getTenantSupabaseFromAuth } from "@/lib/supabase/tenant-api";
import { fetchDataSchemaForEmpresaId } from "@/lib/supabase/empresa-data-schema";
import { exigirSucursal, respuestaSucursalNoAsignada } from "@/lib/sucursales/filtro";
import { getSaldoDocumento } from "@/lib/compras/server/cuentas-por-pagar-pg";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";

const COLS =
  "id, numero_control, proveedor_id, proveedor_nombre, monto, moneda, " +
  "metodo_pago, entidad_id, entidad_nombre, referencia, observaciones, " +
  "fecha, created_at, usuario_nombre";

const METODOS = new Set(["efectivo", "transferencia", "tarjeta", "cheque", "otro"]);

/**
 * GET /api/compras/pagos[?numero_control=…][?proveedor_id=…]
 * Historial de pagos de la sucursal. Sin filtros, los últimos 500.
 */
export async function GET(request: NextRequest) {
  try {
    const ctx = await getTenantSupabaseFromAuth(request);
    if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    const sucursalId = exigirSucursal(ctx.auth.sucursal_id);

    const numero = (request.nextUrl.searchParams.get("numero_control") ?? "").trim();
    const proveedorId = (request.nextUrl.searchParams.get("proveedor_id") ?? "").trim();

    let q = ctx.supabase
      .from("compras_pagos")
      .select(COLS)
      .eq("empresa_id", ctx.auth.empresa_id)
      .eq("sucursal_id", sucursalId)
      .order("fecha", { ascending: false });

    if (numero) q = q.eq("numero_control", numero);
    if (proveedorId) q = q.eq("proveedor_id", proveedorId);
    if (!numero && !proveedorId) q = q.range(0, 499);

    const { data, error } = await q;
    if (error) throw new Error(error.message);
    return NextResponse.json(successResponse({ pagos: data ?? [] }));
  } catch (err) {
    const res = respuestaSucursalNoAsignada(err);
    if (res) return res;
    console.error("[/api/compras/pagos GET]", err instanceof Error ? err.message : err);
    return NextResponse.json(errorResponse("No se pudieron cargar los pagos."), { status: 500 });
  }
}

/** POST /api/compras/pagos — registra un pago contra un documento de compra. */
export async function POST(request: NextRequest) {
  try {
    const auth = await getUserAndEmpresa(request);
    if (!auth) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    const sucursalId = exigirSucursal(auth.sucursal_id);
    const ctx = await getTenantSupabaseFromAuth(request);
    if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    const schema = await fetchDataSchemaForEmpresaId(auth.empresa_id);

    let body: Record<string, unknown>;
    try {
      body = (await request.json()) as Record<string, unknown>;
    } catch {
      return NextResponse.json(errorResponse("JSON inválido."), { status: 400 });
    }

    const numeroControl = typeof body.numero_control === "string" ? body.numero_control.trim() : "";
    if (!numeroControl) {
      return NextResponse.json(errorResponse("Falta el documento a pagar."), { status: 400 });
    }
    const monto = Number(body.monto);
    if (!Number.isFinite(monto) || monto <= 0) {
      return NextResponse.json(errorResponse("El monto debe ser mayor a 0."), { status: 400 });
    }
    const metodo = typeof body.metodo_pago === "string" ? body.metodo_pago.toLowerCase() : "";
    if (!METODOS.has(metodo)) {
      return NextResponse.json(errorResponse("Método de pago inválido."), { status: 400 });
    }

    // El documento tiene que existir en ESTA sucursal y no estar anulado.
    const doc = await getSaldoDocumento(schema, auth.empresa_id, sucursalId, numeroControl);
    if (!doc?.existe) {
      return NextResponse.json(
        errorResponse("No se encontró ese documento de compra en tu sucursal."),
        { status: 404 }
      );
    }
    // Se rechaza el sobrepago. El origen no validaba esto: cargar 10× el monto
    // de la factura pasaba sin chistar y dejaba la deuda del proveedor en un
    // número inventado, que después nadie sabe de dónde salió.
    if (doc.saldo <= 0) {
      return NextResponse.json(
        errorResponse("Ese documento ya está pagado por completo."),
        { status: 409 }
      );
    }
    if (monto > doc.saldo + 0.5) {
      return NextResponse.json(
        errorResponse(
          `El pago supera el saldo pendiente (Gs. ${Math.round(doc.saldo).toLocaleString("es-PY")}).`
        ),
        { status: 409 }
      );
    }

    // El proveedor se toma del documento salvo que venga explícito, para que el
    // pago no quede atribuido a otro por un dato mal mandado desde el front.
    const provQ = await ctx.supabase
      .from("compras")
      .select("proveedor_id, proveedor_nombre")
      .eq("empresa_id", auth.empresa_id)
      .eq("sucursal_id", sucursalId)
      .eq("numero_control", numeroControl)
      .neq("estado", "anulada")
      .limit(1)
      .maybeSingle();
    const docProv = (provQ.data ?? null) as
      | { proveedor_id: string | null; proveedor_nombre: string | null }
      | null;

    const ins = await ctx.supabase
      .from("compras_pagos")
      .insert({
        empresa_id: auth.empresa_id,
        sucursal_id: sucursalId,
        numero_control: numeroControl,
        proveedor_id: docProv?.proveedor_id ?? null,
        proveedor_nombre: docProv?.proveedor_nombre ?? null,
        monto: Math.round(monto),
        moneda: typeof body.moneda === "string" ? body.moneda : "PYG",
        metodo_pago: metodo,
        entidad_id: typeof body.entidad_id === "string" && body.entidad_id ? body.entidad_id : null,
        entidad_nombre:
          typeof body.entidad_nombre === "string" ? body.entidad_nombre.trim() || null : null,
        referencia: typeof body.referencia === "string" ? body.referencia.trim() || null : null,
        observaciones:
          typeof body.observaciones === "string" ? body.observaciones.trim() || null : null,
        fecha: typeof body.fecha === "string" && body.fecha ? body.fecha : new Date().toISOString(),
        usuario_nombre: auth.user?.email ?? null,
        created_by: auth.usuarioCatalogId ?? null,
      })
      .select(COLS)
      .single();

    if (ins.error) throw new Error(ins.error.message);
    return NextResponse.json(successResponse({ pago: ins.data }), { status: 201 });
  } catch (err) {
    const res = respuestaSucursalNoAsignada(err);
    if (res) return res;
    console.error("[/api/compras/pagos POST]", err instanceof Error ? err.message : err);
    return NextResponse.json(errorResponse("No se pudo registrar el pago."), { status: 500 });
  }
}
