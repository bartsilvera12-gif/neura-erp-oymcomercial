"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { apiFetch } from "@/lib/api/fetch-with-supabase-session";
import { esRolAdminEmpresaOGlobal } from "@/lib/auth/rol-empresa";
import {
  getSucursales,
  createSucursal,
  updateSucursal,
  type Sucursal,
} from "@/lib/sucursales/storage";

const inputClass =
  "w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-[#0EA5E9] outline-none";

export default function SucursalesPage() {
  const [lista, setLista] = useState<Sucursal[]>([]);
  const [esAdmin, setEsAdmin] = useState<boolean | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [guardando, setGuardando] = useState(false);

  // Form crear
  const [codigo, setCodigo] = useState("");
  const [nombre, setNombre] = useState("");
  const [establecimiento, setEstablecimiento] = useState("");
  const [puntoExpedicion, setPuntoExpedicion] = useState("");

  // Edición inline
  const [editId, setEditId] = useState<string | null>(null);
  const [eCodigo, setECodigo] = useState("");
  const [eNombre, setENombre] = useState("");
  const [eEstablecimiento, setEEstablecimiento] = useState("");
  const [ePunto, setEPunto] = useState("");

  const reload = useCallback(async () => {
    setLista(await getSucursales({ todas: true }));
  }, []);

  useEffect(() => {
    // El rol decide si la pantalla es operable: la API rechaza a los no-admin
    // con 403, y sin este chequeo la tabla se vería vacía sin explicación.
    (async () => {
      try {
        const r = await apiFetch("/api/usuarios/me", { cache: "no-store" });
        const j = await r.json().catch(() => ({}));
        const admin = esRolAdminEmpresaOGlobal(j?.usuario?.rol ?? null);
        setEsAdmin(admin);
        if (admin) await reload();
      } catch {
        setEsAdmin(false);
      }
    })();
  }, [reload]);

  async function handleCrear(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    if (!nombre.trim()) return;
    setGuardando(true);
    const res = await createSucursal({
      codigo: codigo.trim() || undefined,
      nombre: nombre.trim(),
      establecimiento: establecimiento.trim() || null,
      punto_expedicion: puntoExpedicion.trim() || null,
    });
    setGuardando(false);
    if (!res.ok) {
      setError(res.error);
      return;
    }
    setCodigo("");
    setNombre("");
    setEstablecimiento("");
    setPuntoExpedicion("");
    await reload();
  }

  function startEdit(s: Sucursal) {
    setEditId(s.id);
    setECodigo(s.codigo);
    setENombre(s.nombre);
    setEEstablecimiento(s.establecimiento ?? "");
    setEPunto(s.punto_expedicion ?? "");
    setError(null);
  }

  async function saveEdit() {
    if (!editId) return;
    setError(null);
    const res = await updateSucursal(editId, {
      codigo: eCodigo.trim(),
      nombre: eNombre.trim(),
      establecimiento: eEstablecimiento.trim() || null,
      punto_expedicion: ePunto.trim() || null,
    });
    if (!res.ok) {
      setError(res.error);
      return;
    }
    setEditId(null);
    await reload();
  }

  async function toggleActiva(s: Sucursal) {
    setError(null);
    const res = await updateSucursal(s.id, { activa: !s.activa });
    if (!res.ok) setError(res.error);
    else await reload();
  }

  async function marcarPrincipal(s: Sucursal) {
    setError(null);
    const res = await updateSucursal(s.id, { es_principal: true });
    if (!res.ok) setError(res.error);
    else await reload();
  }

  return (
    <div className="mx-auto w-full max-w-5xl space-y-8 px-4 pb-10 sm:px-6 lg:px-8">
      <div>
        <Link href="/configuracion" className="text-sm text-sky-600 hover:underline">
          ← Configuración
        </Link>
        <h1 className="mt-2 text-2xl font-bold text-slate-900">Sucursales</h1>
        <p className="text-sm text-slate-600">
          Locales donde opera la empresa. Cada usuario pertenece a una sola sucursal y ve únicamente los
          datos de esa — ventas, stock, caja y facturación quedan separados. La asignación se hace desde{" "}
          <Link href="/usuarios" className="text-sky-600 hover:underline">
            Usuarios
          </Link>
          .
        </p>
      </div>

      {esAdmin === false && (
        <p className="rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800">
          Solo un administrador puede ver y editar las sucursales.
        </p>
      )}

      {esAdmin && (
        <>
          <form
            onSubmit={handleCrear}
            className="max-w-2xl space-y-3 rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
          >
            <h2 className="text-sm font-semibold text-slate-800">Nueva sucursal</h2>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-600">Código</label>
                <input
                  className={`${inputClass} uppercase`}
                  value={codigo}
                  onChange={(e) => setCodigo(e.target.value)}
                  placeholder="Ej: MATRIZ"
                  maxLength={20}
                />
                <p className="mt-1 text-xs text-slate-400">Si lo dejás vacío se deriva del nombre.</p>
              </div>
              <div className="sm:col-span-2">
                <label className="mb-1 block text-xs font-medium text-slate-600">Nombre *</label>
                <input
                  className={inputClass}
                  value={nombre}
                  onChange={(e) => setNombre(e.target.value)}
                  placeholder="Ej: Casa Matriz"
                  required
                />
              </div>
            </div>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-600">Establecimiento</label>
                <input
                  className={inputClass}
                  value={establecimiento}
                  onChange={(e) => setEstablecimiento(e.target.value)}
                  placeholder="001"
                  inputMode="numeric"
                  maxLength={3}
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-600">Punto de expedición</label>
                <input
                  className={inputClass}
                  value={puntoExpedicion}
                  onChange={(e) => setPuntoExpedicion(e.target.value)}
                  placeholder="002"
                  inputMode="numeric"
                  maxLength={3}
                />
              </div>
            </div>
            <p className="text-xs text-slate-400">
              Establecimiento y punto de expedición son los datos SIFEN con los que se numeran las facturas
              emitidas en esta sucursal. Si quedan vacíos se usa la configuración de la empresa.
            </p>
            {error && <p className="text-sm text-red-600">{error}</p>}
            <button
              type="submit"
              disabled={guardando}
              className="rounded-lg bg-[#0EA5E9] px-4 py-2 text-sm font-medium text-white hover:bg-[#0284C7] disabled:opacity-60"
            >
              {guardando ? "Creando…" : "Crear sucursal"}
            </button>
          </form>

          <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-slate-100 text-slate-600">
                  <th className="py-3 pr-4 font-semibold">Código</th>
                  <th className="py-3 pr-4 font-semibold">Nombre</th>
                  <th className="py-3 pr-4 font-semibold">Est. / Punto</th>
                  <th className="py-3 pr-4 font-semibold">Principal</th>
                  <th className="py-3 pr-4 font-semibold">Activa</th>
                  <th className="py-3 font-semibold">Acciones</th>
                </tr>
              </thead>
              <tbody>
                {lista.map((s) => (
                  <tr key={s.id} className="border-b border-slate-50 last:border-0">
                    <td className="py-3 pr-4 font-mono text-xs">
                      {editId === s.id ? (
                        <input
                          className={`${inputClass} uppercase`}
                          value={eCodigo}
                          onChange={(e) => setECodigo(e.target.value)}
                          maxLength={20}
                        />
                      ) : (
                        s.codigo
                      )}
                    </td>
                    <td className="py-3 pr-4">
                      {editId === s.id ? (
                        <input
                          className={inputClass}
                          value={eNombre}
                          onChange={(e) => setENombre(e.target.value)}
                        />
                      ) : (
                        <span className="font-medium text-slate-800">{s.nombre}</span>
                      )}
                    </td>
                    <td className="py-3 pr-4 font-mono text-xs text-slate-600">
                      {editId === s.id ? (
                        <div className="flex gap-2">
                          <input
                            className={inputClass}
                            value={eEstablecimiento}
                            onChange={(e) => setEEstablecimiento(e.target.value)}
                            placeholder="001"
                            inputMode="numeric"
                            maxLength={3}
                          />
                          <input
                            className={inputClass}
                            value={ePunto}
                            onChange={(e) => setEPunto(e.target.value)}
                            placeholder="002"
                            inputMode="numeric"
                            maxLength={3}
                          />
                        </div>
                      ) : s.establecimiento || s.punto_expedicion ? (
                        `${s.establecimiento ?? "—"} / ${s.punto_expedicion ?? "—"}`
                      ) : (
                        "—"
                      )}
                    </td>
                    <td className="py-3 pr-4">
                      {s.es_principal ? (
                        <span className="rounded-full bg-sky-50 px-2 py-0.5 text-xs font-medium text-sky-700">
                          Principal
                        </span>
                      ) : (
                        <button
                          type="button"
                          onClick={() => void marcarPrincipal(s)}
                          className="text-xs text-slate-500 hover:text-sky-600 hover:underline"
                        >
                          Marcar
                        </button>
                      )}
                    </td>
                    <td className="py-3 pr-4">
                      <button
                        type="button"
                        onClick={() => void toggleActiva(s)}
                        className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                          s.activa ? "bg-emerald-50 text-emerald-700" : "bg-slate-100 text-slate-500"
                        }`}
                      >
                        {s.activa ? "Sí" : "No"}
                      </button>
                    </td>
                    <td className="py-3">
                      {editId === s.id ? (
                        <div className="flex gap-2">
                          <button
                            type="button"
                            onClick={() => void saveEdit()}
                            className="font-medium text-sky-600 hover:underline"
                          >
                            Guardar
                          </button>
                          <button
                            type="button"
                            onClick={() => setEditId(null)}
                            className="text-slate-500 hover:underline"
                          >
                            Cancelar
                          </button>
                        </div>
                      ) : (
                        <button
                          type="button"
                          onClick={() => startEdit(s)}
                          className="font-medium text-sky-600 hover:underline"
                        >
                          Editar
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {lista.length === 0 && (
              <p className="py-8 text-center text-slate-400">
                Sin sucursales cargadas. La primera que crees queda como principal.
              </p>
            )}
          </div>
        </>
      )}
    </div>
  );
}
