import { NextResponse } from "next/server";
import { getServiceAuthUsuario } from "@/lib/auth/get-service-auth-usuario";
import { MAX_USUARIOS_ACTIVOS } from "@/lib/usuarios/limits";

/** Lista usuarios de la empresa del usuario autenticado (para /usuarios) */
export async function GET(request: Request) {
  try {
    const r = await getServiceAuthUsuario(request);
    if (!r.ok) {
      return NextResponse.json({ error: "No autenticado" }, { status: r.status });
    }
    const { supabaseSr, catalogUsuario } = r;
    if (!catalogUsuario) {
      return NextResponse.json({ error: "Perfil no encontrado" }, { status: 403 });
    }

    const empresaId = catalogUsuario.empresa_id ?? null;
    const rol = (catalogUsuario.rol ?? "").trim();
    if (!empresaId && rol !== "super_admin") {
      return NextResponse.json({ usuarios: [] });
    }

    let query = supabaseSr
      .from("usuarios")
      .select("id, nombre, email, telefono, fecha_nacimiento, rol, estado, created_at")
      .order("created_at", { ascending: false });

    if (rol !== "super_admin") {
      query = query.eq("empresa_id", empresaId as string);
    }

    const { data: usuarios, error } = await query;
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    // Conteo de activos + tope: el frontend lo usa para mostrar "X/N activos".
    // Se cuenta acá con los mismos criterios que el guard de alta (POST /nuevo)
    // para que el chip refleje exactamente lo que va a validar el server: el
    // admin logueado también cuenta.
    const activos = ((usuarios ?? []) as Array<{ estado: string | null }>).filter(
      (u) => (u.estado ?? "") === "activo"
    ).length;

    return NextResponse.json({
      usuarios: usuarios ?? [],
      activos,
      maxActivos: MAX_USUARIOS_ACTIVOS,
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Error";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
