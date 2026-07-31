"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { AlertTriangle, Trash2 } from "lucide-react";
import PageHeader from "@/components/ui/PageHeader";
import MontoInput from "@/components/ui/MontoInput";
import { apiFetch } from "@/lib/api/fetch-with-supabase-session";

type EstadoPago = "pendiente" | "parcial" | "pagado";

type Documento = {
  numero_control: string;
  proveedor_id: string | null;
  proveedor_nombre: string | null;
  fecha: string;
  tipo_pago: string;
  plazo_dias: number | null;
  total_documento: number;
  total_pagado: number;
  saldo_pendiente: number;
  items_count: number;
  dias_desde_fecha: number;
  dias_vencido: number;
  estado_pago: EstadoPago;
};

type Resumen = {
  documentos_con_saldo: number;
  total_deuda: number;
  vencidos: number;
  total_vencido: number;
  total_pagado_mes: number;
};

type Pago = {
  id: string;
  numero_control: string;
  proveedor_nombre: string | null;
  monto: number;
  metodo_pago: string;
  entidad_nombre: string | null;
  referencia: string | null;
  observaciones: string | null;
  fecha: string;
  usuario_nombre: string | null;
};

type EntidadBancaria = { id: string; codigo: string | null; nombre: string; tipo: string | null };

const METODOS = ["efectivo", "transferencia", "tarjeta", "cheque", "otro"] as const;
type Metodo = (typeof METODOS)[number];

function formatGs(v: number) {
  return `Gs. ${Math.round(v || 0).toLocaleString("es-PY")}`;
}
function formatFecha(iso: string) {
  try {
    return new Date(iso).toLocaleDateString("es-PY", { day: "2-digit", month: "2-digit", year: "numeric" });
  } catch {
    return iso;
  }
}

const inputClass =
  "w-full rounded-lg border border-slate-200 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-[#0EA5E9]";

export default function PagosProveedoresPage() {
  const [tab, setTab] = useState<"pendientes" | "todos">("pendientes");
  const [docs, setDocs] = useState<Documento[]>([]);
  const [resumen, setResumen] = useState<Resumen | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [cargando, setCargando] = useState(true);
  const [busqueda, setBusqueda] = useState("");

  // Panel de pago
  const [docSel, setDocSel] = useState<Documento | null>(null);
  const [pagos, setPagos] = useState<Pago[]>([]);
  const [monto, setMonto] = useState("");
  const [metodo, setMetodo] = useState<Metodo>("efectivo");
  const [entidadId, setEntidadId] = useState("");
  const [referencia, setReferencia] = useState("");
  const [observaciones, setObservaciones] = useState("");
  const [guardando, setGuardando] = useState(false);
  const [pagoError, setPagoError] = useState<string | null>(null);
  const [entidades, setEntidades] = useState<EntidadBancaria[]>([]);

  const cargar = useCallback(async (t: "pendientes" | "todos") => {
    setCargando(true);
    setError(null);
    try {
      const url = t === "todos" ? "/api/compras/cuentas-por-pagar?incluir=pagados" : "/api/compras/cuentas-por-pagar";
      const r = await apiFetch(url, { cache: "no-store" });
      const j = await r.json().catch(() => ({}));
      if (!r.ok || !j?.success) throw new Error(j?.error ?? `Error ${r.status}`);
      setDocs(j.data?.items ?? []);
      setResumen(j.data?.summary ?? null);
    } catch (e) {
      setError(e instanceof Error ? e.message : "No se pudieron cargar las cuentas por pagar.");
      setDocs([]);
      setResumen(null);
    } finally {
      setCargando(false);
    }
  }, []);

  useEffect(() => { void cargar(tab); }, [cargar, tab]);

  useEffect(() => {
    apiFetch("/api/entidades-bancarias", { cache: "no-store" })
      .then((r) => r.json())
      .then((j) => { if (j?.success) setEntidades(j.data?.entidades ?? []); })
      .catch(() => { /* el select queda vacío */ });
  }, []);

  async function abrirDoc(d: Documento) {
    setDocSel(d);
    setPagoError(null);
    setMonto(String(Math.round(d.saldo_pendiente)));
    setMetodo("efectivo");
    setEntidadId("");
    setReferencia("");
    setObservaciones("");
    try {
      const r = await apiFetch(
        `/api/compras/pagos?numero_control=${encodeURIComponent(d.numero_control)}`,
        { cache: "no-store" }
      );
      const j = await r.json().catch(() => ({}));
      setPagos(j?.success ? j.data?.pagos ?? [] : []);
    } catch {
      setPagos([]);
    }
  }

  async function registrarPago() {
    if (!docSel) return;
    setPagoError(null);
    const m = Number(monto);
    if (!Number.isFinite(m) || m <= 0) { setPagoError("El monto debe ser mayor a 0."); return; }
    setGuardando(true);
    try {
      const entidad = entidades.find((e) => e.id === entidadId);
      const r = await apiFetch("/api/compras/pagos", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          numero_control: docSel.numero_control,
          monto: m,
          metodo_pago: metodo,
          entidad_id: entidadId || null,
          entidad_nombre: entidad?.nombre ?? null,
          referencia: referencia.trim() || null,
          observaciones: observaciones.trim() || null,
        }),
      });
      const j = await r.json().catch(() => ({}));
      if (!r.ok || !j?.success) throw new Error(j?.error ?? `Error ${r.status}`);
      setDocSel(null);
      await cargar(tab);
    } catch (e) {
      setPagoError(e instanceof Error ? e.message : "No se pudo registrar el pago.");
    } finally {
      setGuardando(false);
    }
  }

  async function eliminarPago(p: Pago) {
    setPagoError(null);
    try {
      const r = await apiFetch(`/api/compras/pagos/${p.id}`, { method: "DELETE" });
      const j = await r.json().catch(() => ({}));
      if (!r.ok || !j?.success) throw new Error(j?.error ?? `Error ${r.status}`);
      if (docSel) await abrirDoc(docSel);
      await cargar(tab);
    } catch (e) {
      setPagoError(e instanceof Error ? e.message : "No se pudo eliminar el pago.");
    }
  }

  const visibles = useMemo(() => {
    const q = busqueda.trim().toLowerCase();
    if (!q) return docs;
    return docs.filter(
      (d) =>
        d.numero_control.toLowerCase().includes(q) ||
        (d.proveedor_nombre ?? "").toLowerCase().includes(q)
    );
  }, [docs, busqueda]);

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Zentra · Compras"
        title="Pagos a proveedores"
        description="Deuda por documento, con su historial de pagos"
      />

      {resumen && (
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          <Stat label="Deuda total" value={formatGs(resumen.total_deuda)} sub={`${resumen.documentos_con_saldo} documento(s)`} accent />
          <Stat label="Vencido" value={formatGs(resumen.total_vencido)} sub={`${resumen.vencidos} documento(s)`} alerta={resumen.vencidos > 0} />
          <Stat label="Pagado este mes" value={formatGs(resumen.total_pagado_mes)} />
          <Stat label="Documentos" value={String(visibles.length)} sub={tab === "todos" ? "incluye pagados" : "con saldo"} />
        </div>
      )}

      <div className="flex flex-wrap items-center gap-3">
        <div className="flex gap-1 rounded-lg border border-slate-200 bg-slate-50 p-0.5">
          {(["pendientes", "todos"] as const).map((t) => (
            <button
              key={t}
              type="button"
              onClick={() => setTab(t)}
              className={`rounded px-3 py-1.5 text-xs font-medium transition ${
                tab === t ? "bg-white text-slate-900 shadow-sm" : "text-slate-500 hover:text-slate-700"
              }`}
            >
              {t === "pendientes" ? "Con saldo" : "Todos"}
            </button>
          ))}
        </div>
        <input
          value={busqueda}
          onChange={(e) => setBusqueda(e.target.value)}
          placeholder="Buscar por proveedor o N° de documento…"
          className={`${inputClass} max-w-sm`}
        />
      </div>

      {error && <p className="rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">{error}</p>}
      {cargando && docs.length === 0 && <p className="text-sm text-slate-400">Cargando…</p>}

      <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <table className="w-full min-w-[860px] text-left text-sm">
          <thead>
            <tr className="border-b border-slate-100 text-slate-600">
              <th className="py-3 pr-4 font-semibold">Documento</th>
              <th className="py-3 pr-4 font-semibold">Proveedor</th>
              <th className="py-3 pr-4 font-semibold">Fecha</th>
              <th className="py-3 pr-4 font-semibold">Condición</th>
              <th className="py-3 pr-4 text-right font-semibold">Total</th>
              <th className="py-3 pr-4 text-right font-semibold">Pagado</th>
              <th className="py-3 pr-4 text-right font-semibold">Saldo</th>
              <th className="py-3 font-semibold">Estado</th>
            </tr>
          </thead>
          <tbody>
            {visibles.map((d) => (
              <tr
                key={d.numero_control}
                onClick={() => void abrirDoc(d)}
                className="cursor-pointer border-b border-slate-50 last:border-0 hover:bg-slate-50"
              >
                <td className="py-3 pr-4 font-mono text-xs text-slate-700">
                  {d.numero_control}
                  <span className="ml-2 text-slate-400">{d.items_count} ítem(s)</span>
                </td>
                <td className="py-3 pr-4 font-medium text-slate-800">{d.proveedor_nombre ?? "—"}</td>
                <td className="py-3 pr-4 text-slate-600">{formatFecha(d.fecha)}</td>
                <td className="py-3 pr-4 text-slate-600">
                  {d.tipo_pago === "credito" ? `Crédito ${d.plazo_dias ?? 0}d` : "Contado"}
                  {d.dias_vencido > 0 && (
                    <span className="ml-2 inline-flex items-center gap-1 rounded-full bg-rose-50 px-2 py-0.5 text-[10px] font-semibold text-rose-700">
                      <AlertTriangle className="h-3 w-3" /> {d.dias_vencido}d vencido
                    </span>
                  )}
                </td>
                <td className="py-3 pr-4 text-right tabular-nums text-slate-600">{formatGs(d.total_documento)}</td>
                <td className="py-3 pr-4 text-right tabular-nums text-slate-600">{formatGs(d.total_pagado)}</td>
                <td className="py-3 pr-4 text-right font-semibold tabular-nums text-slate-900">{formatGs(d.saldo_pendiente)}</td>
                <td className="py-3">
                  <EstadoChip estado={d.estado_pago} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {!cargando && visibles.length === 0 && (
          <p className="py-8 text-center text-slate-400">
            {tab === "pendientes" ? "No hay deuda pendiente con proveedores." : "Sin documentos de compra."}
          </p>
        )}
      </div>

      {/* Panel de pago */}
      {docSel && (
        <div
          className="fixed inset-0 z-50 flex items-start justify-center bg-slate-900/50 p-4 pt-12 backdrop-blur-sm"
          onClick={() => { if (!guardando) setDocSel(null); }}
        >
          <div
            role="dialog"
            aria-modal="true"
            className="flex max-h-[85vh] w-full max-w-lg flex-col rounded-2xl border border-slate-200 bg-white shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="border-b border-slate-200 p-4">
              <h3 className="text-base font-semibold text-slate-900">
                Pagar {docSel.numero_control}
              </h3>
              <p className="mt-0.5 text-sm text-slate-500">
                {docSel.proveedor_nombre ?? "Sin proveedor"} · saldo{" "}
                <strong className="text-slate-900">{formatGs(docSel.saldo_pendiente)}</strong>
              </p>
            </div>

            <div className="space-y-3 overflow-y-auto p-4">
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-600">Monto (Gs.)</label>
                <MontoInput
                  value={monto}
                  onChange={(n) => setMonto(String(n))}
                  decimals={false}
                  className={inputClass}
                />
                <p className="mt-1 text-[11px] text-slate-400">
                  No se puede pagar más que el saldo. Para un pago parcial, bajá el monto.
                </p>
              </div>

              <div>
                <label className="mb-1 block text-xs font-medium text-slate-600">Método</label>
                <div className="grid grid-cols-5 gap-1">
                  {METODOS.map((m) => (
                    <button
                      key={m}
                      type="button"
                      onClick={() => setMetodo(m)}
                      className={`rounded-md border py-1.5 text-[11px] font-medium capitalize transition ${
                        metodo === m
                          ? "border-[#0EA5E9] bg-[#0EA5E9]/10 text-[#0284C7]"
                          : "border-slate-200 bg-white text-slate-600 hover:bg-slate-50"
                      }`}
                    >
                      {m}
                    </button>
                  ))}
                </div>
              </div>

              {metodo !== "efectivo" && (
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="mb-1 block text-xs font-medium text-slate-600">Entidad</label>
                    <select value={entidadId} onChange={(e) => setEntidadId(e.target.value)} className={inputClass}>
                      <option value="">— Seleccionar —</option>
                      {entidades.filter((e) => e.tipo !== "caja").map((e) => (
                        <option key={e.id} value={e.id}>{e.nombre}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="mb-1 block text-xs font-medium text-slate-600">Referencia</label>
                    <input value={referencia} onChange={(e) => setReferencia(e.target.value)} className={inputClass} placeholder="N° de operación / cheque" />
                  </div>
                </div>
              )}

              <div>
                <label className="mb-1 block text-xs font-medium text-slate-600">Observación (opcional)</label>
                <textarea value={observaciones} onChange={(e) => setObservaciones(e.target.value)} rows={2} className={inputClass} />
              </div>

              {pagoError && (
                <p className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">{pagoError}</p>
              )}

              {pagos.length > 0 && (
                <div>
                  <p className="mb-1.5 text-[11px] font-semibold uppercase tracking-wide text-slate-500">
                    Pagos registrados ({pagos.length})
                  </p>
                  <ul className="divide-y divide-slate-100 rounded-lg border border-slate-200">
                    {pagos.map((p) => (
                      <li key={p.id} className="flex items-center gap-2 px-3 py-2 text-xs">
                        <div className="min-w-0 flex-1">
                          <p className="font-medium text-slate-800">
                            {formatGs(p.monto)} <span className="font-normal capitalize text-slate-500">· {p.metodo_pago}</span>
                          </p>
                          <p className="text-slate-400">
                            {formatFecha(p.fecha)}
                            {p.entidad_nombre ? ` · ${p.entidad_nombre}` : ""}
                            {p.referencia ? ` · ${p.referencia}` : ""}
                          </p>
                        </div>
                        <button
                          type="button"
                          onClick={() => void eliminarPago(p)}
                          className="text-slate-400 hover:text-rose-600"
                          title="Eliminar pago (solo admin)"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </div>

            <div className="flex justify-end gap-2 border-t border-slate-200 p-4">
              <button
                type="button"
                onClick={() => setDocSel(null)}
                disabled={guardando}
                className="rounded-lg border border-slate-200 px-4 py-2 text-sm hover:bg-slate-50 disabled:opacity-50"
              >
                Cerrar
              </button>
              <button
                type="button"
                onClick={() => void registrarPago()}
                disabled={guardando || docSel.saldo_pendiente <= 0}
                className="rounded-lg bg-[#0EA5E9] px-4 py-2 text-sm font-medium text-white hover:bg-[#0284C7] disabled:opacity-50"
              >
                {guardando ? "Registrando…" : "Registrar pago"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function Stat({ label, value, sub, accent, alerta }: { label: string; value: string; sub?: string; accent?: boolean; alerta?: boolean }) {
  return (
    <div className={`rounded-xl border p-4 ${
      alerta ? "border-rose-200 bg-rose-50" : accent ? "border-sky-200 bg-sky-50" : "border-slate-200 bg-white"
    }`}>
      <p className="text-[11px] font-medium uppercase tracking-wide text-slate-500">{label}</p>
      <p className="mt-1 text-xl font-bold tabular-nums text-slate-900">{value}</p>
      {sub && <p className="text-[11px] text-slate-400">{sub}</p>}
    </div>
  );
}

function EstadoChip({ estado }: { estado: EstadoPago }) {
  const map = {
    pendiente: "bg-slate-100 text-slate-600",
    parcial: "bg-amber-50 text-amber-700",
    pagado: "bg-emerald-50 text-emerald-700",
  } as const;
  return (
    <span className={`rounded-full px-2 py-0.5 text-[11px] font-medium capitalize ${map[estado]}`}>
      {estado}
    </span>
  );
}
