import { NextRequest, NextResponse } from "next/server";
import { getTenantSupabaseFromAuth } from "@/lib/supabase/tenant-api";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import { aplicarFiltroSucursal, exigirSucursal, respuestaSucursalNoAsignada } from "@/lib/sucursales/filtro";

/**
 * GET /api/notificaciones/stock-bajo
 *
 * Devuelve productos de la sucursal actual con stock por debajo del mínimo
 * configurado (`stock_actual <= stock_minimo` con `stock_minimo > 0`), más
 * el total. La campana del header usa `count` para el badge y la `items`
 * como lista de detalle en el popover.
 *
 * Cálculo en vivo, sin tabla de notificaciones persistente — el badge
 * refleja el stock real en tiempo real; no hay estado "leída" ni historial.
 * Si más adelante hace falta persistencia, se agrega encima sin romper este
 * endpoint (que quedaría como fallback / conteo).
 *
 * Se limita `items` a los 50 más críticos (peor ratio primero); el `count`
 * total incluye a los demás para no mentirle al usuario en el badge.
 */

const LIMITE_ITEMS = 50;

export async function GET(request: NextRequest) {
  try {
    const ctx = await getTenantSupabaseFromAuth(request);
    if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    const sucursalId = exigirSucursal(ctx.auth.sucursal_id);

    // Traemos SOLO productos con `stock_minimo > 0` (los que no tienen mínimo
    // configurado explícitamente no participan del alerta). Después
    // filtramos en JS `stock_actual <= stock_minimo` porque PostgREST no
    // soporta comparar columna vs columna en `.filter()`.
    //
    // El universo suele ser chico (solo los productos que el admin marcó como
    // "avísame si baja del mínimo"), así que el filtro en app no es un
    // problema de escala. Si algún día crece mucho, migrar a una vista SQL:
    //   CREATE VIEW oymcomercial.v_productos_stock_bajo AS
    //   SELECT ... FROM productos WHERE stock_minimo > 0 AND stock_actual <= stock_minimo;
    const { data, error } = await aplicarFiltroSucursal(
      ctx.supabase
        .from("productos")
        .select("id, nombre, sku, stock_actual, stock_minimo, unidad_medida, controlado_por_peso")
        .eq("empresa_id", ctx.auth.empresa_id)
        .eq("activo", true)
        .gt("stock_minimo", 0),
      sucursalId
    ).order("stock_actual", { ascending: true });

    if (error) throw new Error(error.message);
    const filas = ((data ?? []) as Array<{
      id: string;
      nombre: string;
      sku: string | null;
      stock_actual: number | string;
      stock_minimo: number | string;
      unidad_medida: string | null;
      controlado_por_peso: boolean | null;
    }>)
      .map((r) => ({
        id: String(r.id),
        nombre: String(r.nombre ?? ""),
        sku: r.sku ?? null,
        stock_actual: Number(r.stock_actual ?? 0),
        stock_minimo: Number(r.stock_minimo ?? 0),
        unidad_medida: (r.unidad_medida ?? "UNIDAD").toUpperCase(),
        controlado_por_peso: r.controlado_por_peso === true,
      }))
      .filter((p) => p.stock_actual <= p.stock_minimo);

    // Ordenamos por "más crítico": stock actual = 0 arriba, después por ratio
    // stock/mínimo (menor = peor). El .order de arriba ya ordena por
    // stock_actual ascendente, pero un producto con stock=5 y minimo=1000
    // debería mostrarse antes que uno con stock=5 y minimo=6.
    filas.sort((a, b) => {
      const ra = a.stock_minimo > 0 ? a.stock_actual / a.stock_minimo : 0;
      const rb = b.stock_minimo > 0 ? b.stock_actual / b.stock_minimo : 0;
      return ra - rb;
    });

    const items = filas.slice(0, LIMITE_ITEMS);

    return NextResponse.json(successResponse({ count: filas.length, items }));
  } catch (err) {
    const rSuc = respuestaSucursalNoAsignada(err);
    if (rSuc) return rSuc;
    console.error("[/api/notificaciones/stock-bajo]", err instanceof Error ? err.message : err);
    return NextResponse.json(errorResponse("No se pudieron cargar las notificaciones."), { status: 500 });
  }
}
