import { NextRequest, NextResponse } from "next/server";
import { getTenantSupabaseFromAuthWithRol } from "@/lib/supabase/tenant-api";
import { isAdmin } from "@/lib/middleware/auth";
import { successResponse, errorResponse } from "@/lib/api/response";
import { API_ERRORS } from "@/lib/api/errors";
import type { AppSupabaseClient } from "@/lib/supabase/schema";

/** Error de validación de payload; el handler lo traduce a 400. */
class ValidacionError extends Error {}

function cleanNombre(v: unknown): string {
  return typeof v === "string" ? v.trim().slice(0, 120) : "";
}

/**
 * El código es NOT NULL y único por empresa. Va en mayúsculas y sin espacios
 * porque se usa como identificador corto en listados y búsquedas.
 */
function cleanCodigo(v: unknown): string {
  const s = typeof v === "string" ? v.trim().toUpperCase().replace(/\s+/g, "_") : "";
  return s.slice(0, 20);
}

/**
 * Establecimiento y punto de expedición SIFEN: tres dígitos ("001"). Se acepta
 * "1" y se completa con ceros, porque es como lo dicta el usuario y un "1"
 * guardado tal cual rompería el CDC más adelante, en silencio.
 */
function normSifen3(v: unknown, campo: string): string | null {
  if (v === null || v === undefined) return null;
  const s = String(v).trim();
  if (!s) return null;
  if (!/^\d{1,3}$/.test(s)) {
    throw new ValidacionError(`${campo} debe ser numérico de hasta 3 dígitos (ej: 001).`);
  }
  return s.padStart(3, "0");
}

/** Mensaje claro cuando choca `sucursales_codigo_uq` (empresa_id, codigo). */
function esCodigoDuplicado(msg: string): boolean {
  return /duplicate key|unique|23505/i.test(msg);
}

/**
 * Deja `id` como única principal de la empresa. Se limpia la anterior primero
 * (mismo orden que productos/[id]): si algo falla en el medio queda una empresa
 * sin principal, que solo afecta la preselección de destino en reposición —
 * mientras que dos principales confundiría a todas las pantallas que buscan una.
 */
async function marcarComoPrincipal(
  supabase: AppSupabaseClient,
  empresaId: string,
  id: string
): Promise<void> {
  await supabase
    .from("sucursales")
    .update({ es_principal: false })
    .eq("empresa_id", empresaId)
    .eq("es_principal", true);
  await supabase
    .from("sucursales")
    .update({ es_principal: true })
    .eq("empresa_id", empresaId)
    .eq("id", id);
}

/**
 * GET /api/sucursales[?todas=1]
 *
 * Sin parámetros: sucursales activas de la empresa con id/código/nombre. Se usa
 * para el selector del alta de usuarios, así que NO filtra por la sucursal del
 * usuario — para asignarle una sucursal a alguien hay que ver la lista completa.
 *
 * Con `todas=1`: fila completa, incluidas las inactivas y los datos SIFEN, para
 * la pantalla de administración. Solo admin, porque establecimiento y punto de
 * expedición son datos fiscales.
 */
export async function GET(request: NextRequest) {
  try {
    const ctx = await getTenantSupabaseFromAuthWithRol(request);
    if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });

    const todas = request.nextUrl.searchParams.get("todas") === "1";
    if (todas && !isAdmin(ctx.auth)) {
      return NextResponse.json(errorResponse("Sólo administradores"), { status: 403 });
    }

    let query = ctx.supabase
      .from("sucursales")
      .select(
        todas
          ? "id, codigo, nombre, es_principal, activa, establecimiento, punto_expedicion"
          : "id, codigo, nombre, es_principal"
      )
      .eq("empresa_id", ctx.auth.empresa_id);
    if (!todas) query = query.eq("activa", true);

    const { data, error } = await query
      .order("es_principal", { ascending: false })
      .order("nombre");
    if (error) throw new Error(error.message);

    return NextResponse.json(successResponse({ sucursales: data ?? [] }));
  } catch (err) {
    console.error("[/api/sucursales GET]", err instanceof Error ? err.message : err);
    return NextResponse.json(errorResponse("No se pudieron cargar las sucursales."), { status: 500 });
  }
}

/** POST /api/sucursales — crea una sucursal. Solo admin. */
export async function POST(request: NextRequest) {
  try {
    const ctx = await getTenantSupabaseFromAuthWithRol(request);
    if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    if (!isAdmin(ctx.auth)) {
      return NextResponse.json(errorResponse("Sólo administradores"), { status: 403 });
    }
    const { supabase, auth } = ctx;
    const b = (await request.json().catch(() => ({}))) as Record<string, unknown>;

    const nombre = cleanNombre(b.nombre);
    if (!nombre) {
      return NextResponse.json(errorResponse("El nombre es obligatorio."), { status: 400 });
    }
    // Si no lo cargan, se deriva del nombre: el código es NOT NULL y pedirlo
    // aparte solo agrega fricción a un dato que casi siempre es el nombre corto.
    const codigo = cleanCodigo(b.codigo) || cleanCodigo(nombre);
    if (!codigo) {
      return NextResponse.json(errorResponse("El código es obligatorio."), { status: 400 });
    }
    const establecimiento = normSifen3(b.establecimiento, "El establecimiento");
    const puntoExpedicion = normSifen3(b.punto_expedicion, "El punto de expedición");

    // La primera sucursal de la empresa es principal sí o sí: sin una principal
    // no hay destino por defecto en reposición ni orden estable en el selector.
    const { count } = await supabase
      .from("sucursales")
      .select("id", { count: "exact", head: true })
      .eq("empresa_id", auth.empresa_id);
    const esPrimera = (count ?? 0) === 0;
    const principalPedida = b.es_principal === true || esPrimera;
    const activa = b.activa === false ? false : true;
    // Misma regla que en PATCH: la principal tiene que estar activa, si no
    // desaparece de todos los selectores siendo la sucursal de referencia.
    if (principalPedida && !activa) {
      return NextResponse.json(
        errorResponse("Una sucursal inactiva no puede ser la principal."),
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from("sucursales")
      .insert([
        {
          empresa_id: auth.empresa_id,
          codigo,
          nombre,
          es_principal: esPrimera,
          activa,
          establecimiento,
          punto_expedicion: puntoExpedicion,
        },
      ])
      .select("id, codigo, nombre, es_principal, activa, establecimiento, punto_expedicion")
      .single();

    if (error) {
      if (esCodigoDuplicado(error.message)) {
        return NextResponse.json(errorResponse("Ya existe una sucursal con ese código."), { status: 409 });
      }
      throw new Error(error.message);
    }

    if (principalPedida && !esPrimera) {
      await marcarComoPrincipal(supabase, auth.empresa_id, data.id);
      data.es_principal = true;
    }

    return NextResponse.json(successResponse({ sucursal: data }), { status: 201 });
  } catch (err) {
    if (err instanceof ValidacionError) {
      return NextResponse.json(errorResponse(err.message), { status: 400 });
    }
    console.error("[/api/sucursales POST]", err instanceof Error ? err.message : err);
    return NextResponse.json(errorResponse("No se pudo crear la sucursal."), { status: 500 });
  }
}

/** PATCH /api/sucursales — actualiza una sucursal (body.id requerido). Solo admin. */
export async function PATCH(request: NextRequest) {
  try {
    const ctx = await getTenantSupabaseFromAuthWithRol(request);
    if (!ctx) return NextResponse.json(errorResponse(API_ERRORS.UNAUTHORIZED), { status: 401 });
    if (!isAdmin(ctx.auth)) {
      return NextResponse.json(errorResponse("Sólo administradores"), { status: 403 });
    }
    const { supabase, auth } = ctx;
    const b = (await request.json().catch(() => ({}))) as Record<string, unknown>;
    const id = typeof b.id === "string" ? b.id : "";
    if (!id) return NextResponse.json(errorResponse("Falta el id de la sucursal."), { status: 400 });

    const { data: actual, error: errActual } = await supabase
      .from("sucursales")
      .select("id, es_principal, activa")
      .eq("empresa_id", auth.empresa_id)
      .eq("id", id)
      .maybeSingle();
    if (errActual) throw new Error(errActual.message);
    if (!actual) return NextResponse.json(errorResponse("Sucursal no encontrada."), { status: 404 });

    const patch: Record<string, unknown> = {};
    if (b.nombre !== undefined) {
      const nombre = cleanNombre(b.nombre);
      if (!nombre) return NextResponse.json(errorResponse("El nombre es obligatorio."), { status: 400 });
      patch.nombre = nombre;
    }
    if (b.codigo !== undefined) {
      const codigo = cleanCodigo(b.codigo);
      if (!codigo) return NextResponse.json(errorResponse("El código es obligatorio."), { status: 400 });
      patch.codigo = codigo;
    }
    if (b.establecimiento !== undefined) {
      patch.establecimiento = normSifen3(b.establecimiento, "El establecimiento");
    }
    if (b.punto_expedicion !== undefined) {
      patch.punto_expedicion = normSifen3(b.punto_expedicion, "El punto de expedición");
    }
    if (b.activa !== undefined) {
      const activa = b.activa === true;
      // La principal no se desactiva: quedaría una empresa cuya sucursal de
      // referencia no aparece en ningún selector. Primero se promueve otra.
      if (!activa && actual.es_principal) {
        return NextResponse.json(
          errorResponse("No se puede desactivar la sucursal principal. Marcá otra como principal primero."),
          { status: 409 }
        );
      }
      patch.activa = activa;
    }

    // `es_principal` no se escribe en el patch: se resuelve aparte porque hay que
    // limpiar la anterior en la misma operación.
    const promover = b.es_principal === true && !actual.es_principal;
    if (b.es_principal === false && actual.es_principal) {
      return NextResponse.json(
        errorResponse("Para dejar de ser principal, marcá otra sucursal como principal."),
        { status: 409 }
      );
    }
    // Una sucursal inactiva no puede ser la principal (misma razón que arriba).
    if (promover && patch.activa === false) {
      return NextResponse.json(
        errorResponse("Una sucursal inactiva no puede ser la principal."),
        { status: 409 }
      );
    }
    if (promover && !actual.activa && patch.activa === undefined) {
      return NextResponse.json(
        errorResponse("Activá la sucursal antes de marcarla como principal."),
        { status: 409 }
      );
    }

    if (Object.keys(patch).length > 0) {
      const { error } = await supabase
        .from("sucursales")
        .update({ ...patch, updated_at: new Date().toISOString() })
        .eq("empresa_id", auth.empresa_id)
        .eq("id", id);
      if (error) {
        if (esCodigoDuplicado(error.message)) {
          return NextResponse.json(errorResponse("Ya existe una sucursal con ese código."), { status: 409 });
        }
        throw new Error(error.message);
      }
    }

    if (promover) await marcarComoPrincipal(supabase, auth.empresa_id, id);

    const { data, error: errFinal } = await supabase
      .from("sucursales")
      .select("id, codigo, nombre, es_principal, activa, establecimiento, punto_expedicion")
      .eq("empresa_id", auth.empresa_id)
      .eq("id", id)
      .single();
    if (errFinal) throw new Error(errFinal.message);

    return NextResponse.json(successResponse({ sucursal: data }));
  } catch (err) {
    if (err instanceof ValidacionError) {
      return NextResponse.json(errorResponse(err.message), { status: 400 });
    }
    console.error("[/api/sucursales PATCH]", err instanceof Error ? err.message : err);
    return NextResponse.json(errorResponse("No se pudo actualizar la sucursal."), { status: 500 });
  }
}
