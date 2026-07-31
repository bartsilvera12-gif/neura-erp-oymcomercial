/** Sucursales — cliente browser sobre `/api/sucursales`. */

import { apiFetch } from "@/lib/api/fetch-with-supabase-session";

export interface Sucursal {
  id: string;
  codigo: string;
  nombre: string;
  es_principal: boolean;
  activa: boolean;
  establecimiento: string | null;
  punto_expedicion: string | null;
}

/** Fila reducida que devuelve el listado sin `todas=1` (selector de usuarios). */
export type SucursalOpcion = Pick<Sucursal, "id" | "codigo" | "nombre" | "es_principal">;

export interface SucursalInput {
  codigo?: string;
  nombre: string;
  es_principal?: boolean;
  activa?: boolean;
  establecimiento?: string | null;
  punto_expedicion?: string | null;
}

type Res<T> = { ok: true; data: T } | { ok: false; error: string };

/** `todas` trae inactivas y datos SIFEN; requiere admin en el servidor. */
export async function getSucursales(opts?: { todas?: boolean }): Promise<Sucursal[]> {
  try {
    const url = opts?.todas ? "/api/sucursales?todas=1" : "/api/sucursales";
    const r = await apiFetch(url, { cache: "no-store" });
    const j = await r.json().catch(() => ({}));
    if (!r.ok || !j?.success) return [];
    return (j.data?.sucursales ?? []) as Sucursal[];
  } catch {
    return [];
  }
}

export async function createSucursal(input: SucursalInput): Promise<Res<Sucursal>> {
  try {
    const r = await apiFetch("/api/sucursales", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(input),
    });
    const j = await r.json().catch(() => ({}));
    if (!r.ok || !j?.success) return { ok: false, error: j?.error ?? `Error ${r.status}` };
    return { ok: true, data: j.data.sucursal as Sucursal };
  } catch (e) {
    return { ok: false, error: e instanceof Error ? e.message : "Error de red" };
  }
}

export async function updateSucursal(
  id: string,
  patch: Partial<SucursalInput>
): Promise<Res<Sucursal>> {
  try {
    const r = await apiFetch("/api/sucursales", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id, ...patch }),
    });
    const j = await r.json().catch(() => ({}));
    if (!r.ok || !j?.success) return { ok: false, error: j?.error ?? `Error ${r.status}` };
    return { ok: true, data: j.data.sucursal as Sucursal };
  } catch (e) {
    return { ok: false, error: e instanceof Error ? e.message : "Error de red" };
  }
}
