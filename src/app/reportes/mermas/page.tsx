"use client";

/**
 * Reporte de mermas y consumo interno.
 *
 * Lee /api/reportes/mermas y muestra: totales del período (peso perdido a
 * merma vs consumo interno + operaciones), ranking de productos con más
 * peso perdido, y el detalle línea a línea con fecha, producto, destino,
 * peso, motivo y usuario.
 *
 * Rango de fechas por defecto: últimos 30 días. Filtros de destino
 * (merma / consumo / ambos) y de producto opcional.
 */
import { useCallback, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import PageHeader from "@/components/ui/PageHeader";
import StatCard from "@/components/ui/StatCard";
import SearchableSelect from "@/components/ui/SearchableSelect";
import { fetchWithSupabaseSession } from "@/lib/api/fetch-with-supabase-session";
import { AlertTriangle, Coffee, Package as PackageIcon, PackageX } from "lucide-react";

type Destino = "merma" | "consumo_interno";
type DestinoFiltro = Destino | "ambos";

interface DetalleFila {
  operacion_id: string;
  fecha: string | null;
  producto_id: string;
  nombre: string;
  sku: string | null;
  destino: Destino;
  peso: number;
  observacion: string | null;
  motivo: string | null;
  usuario_nombre: string | null;
}

interface TopProducto {
  producto_id: string;
  nombre: string;
  peso_merma: number;
  peso_consumo: number;
  peso_total: number;
}

interface ReporteResp {
  rango: { desde: string; hasta: string };
  totales: {
    peso_merma: number;
    peso_consumo: number;
    peso_total: number;
    operaciones: number;
    lineas: number;
  };
  top_productos: TopProducto[];
  detalle: DetalleFila[];
}

interface ProductoOpt {
  id: string;
  nombre: string;
  sku: string;
}

function fmtKg(n: number): string {
  return `${n.toLocaleString("es-PY", { minimumFractionDigits: 0, maximumFractionDigits: 3 })} kg`;
}
function fmtFecha(iso: string | null): string {
  if (!iso) return "—";
  try {
    const d = new Date(iso);
    const dd = String(d.getDate()).padStart(2, "0");
    const mm = String(d.getMonth() + 1).padStart(2, "0");
    return `${dd}/${mm}/${d.getFullYear()} ${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
  } catch { return iso; }
}
function toInputDate(d: Date): string {
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}
function hoyIso(): string { return toInputDate(new Date()); }
function hace30Iso(): string {
  const d = new Date(); d.setDate(d.getDate() - 30);
  return toInputDate(d);
}

const DESTINO_LABEL: Record<Destino, string> = {
  merma: "Merma",
  consumo_interno: "Consumo interno",
};

export default function ReporteMermasPage() {
  const [desde, setDesde] = useState(hace30Iso());
  const [hasta, setHasta] = useState(hoyIso());
  const [destinoFiltro, setDestinoFiltro] = useState<DestinoFiltro>("ambos");
  const [productoFiltro, setProductoFiltro] = useState<string | null>(null);
  const [productos, setProductos] = useState<ProductoOpt[]>([]);
  const [data, setData] = useState<ReporteResp | null>(null);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Cargar catálogo de productos para el filtro (solo los controlados por peso —
  // son los únicos que pueden aparecer como origen de una operación de pesaje).
  useEffect(() => {
    let cancel = false;
    fetchWithSupabaseSession("/api/productos", { cache: "no-store" })
      .then((r) => r.json())
      .then((j) => {
        if (cancel || !j?.success) return;
        const raw = ((j.data as { productos?: Array<Record<string, unknown>> }).productos ?? []);
        const soloPeso = raw
          .filter((p) => p.controlado_por_peso === true)
          .map((p) => ({ id: String(p.id), nombre: String(p.nombre ?? ""), sku: String(p.sku ?? "") }));
        setProductos(soloPeso);
      })
      .catch(() => { /* no bloquea, el filtro queda vacío */ });
    return () => { cancel = true; };
  }, []);

  const cargar = useCallback(async () => {
    setCargando(true);
    setError(null);
    try {
      const params = new URLSearchParams({
        desde,
        hasta,
        destino: destinoFiltro,
      });
      if (productoFiltro) params.set("producto_id", productoFiltro);
      const r = await fetchWithSupabaseSession(`/api/reportes/mermas?${params.toString()}`, { cache: "no-store" });
      const j = await r.json().catch(() => ({}));
      if (!r.ok || !j?.success) throw new Error((j as { error?: string }).error ?? "No se pudo cargar el reporte.");
      setData(j.data as ReporteResp);
    } catch (e) {
      setError(e instanceof Error ? e.message : "No se pudo cargar el reporte.");
      setData(null);
    } finally {
      setCargando(false);
    }
  }, [desde, hasta, destinoFiltro, productoFiltro]);

  useEffect(() => { void cargar(); }, [cargar]);

  const totales = data?.totales ?? { peso_merma: 0, peso_consumo: 0, peso_total: 0, operaciones: 0, lineas: 0 };
  const topProductos = data?.top_productos ?? [];
  const detalle = data?.detalle ?? [];

  const maxPeso = useMemo(
    () => (topProductos.length > 0 ? Math.max(...topProductos.map((p) => p.peso_total)) : 0),
    [topProductos]
  );

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Zentra · Análisis"
        title="Mermas y consumo interno"
        description="Peso perdido a merma y usado internamente durante operaciones de pesaje / cortes."
      />

      {/* Filtros */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm p-4">
        <div className="grid grid-cols-1 md:grid-cols-12 gap-3 items-end">
          <div className="md:col-span-2">
            <label className="block text-xs font-medium text-slate-600 mb-1">Desde</label>
            <input
              type="date"
              value={desde}
              onChange={(e) => setDesde(e.target.value)}
              className="w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-sky-400"
            />
          </div>
          <div className="md:col-span-2">
            <label className="block text-xs font-medium text-slate-600 mb-1">Hasta</label>
            <input
              type="date"
              value={hasta}
              onChange={(e) => setHasta(e.target.value)}
              className="w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-sky-400"
            />
          </div>
          <div className="md:col-span-3">
            <label className="block text-xs font-medium text-slate-600 mb-1">Destino</label>
            <select
              value={destinoFiltro}
              onChange={(e) => setDestinoFiltro(e.target.value as DestinoFiltro)}
              className="w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-sky-400"
            >
              <option value="ambos">Merma + Consumo interno</option>
              <option value="merma">Solo merma</option>
              <option value="consumo_interno">Solo consumo interno</option>
            </select>
          </div>
          <div className="md:col-span-4">
            <label className="block text-xs font-medium text-slate-600 mb-1">Producto (opcional)</label>
            <SearchableSelect
              value={productoFiltro}
              onChange={(id) => setProductoFiltro(id)}
              options={productos.map((p) => ({ id: p.id, label: p.nombre, hint: p.sku }))}
              placeholder="Todos"
            />
          </div>
          <div className="md:col-span-1 flex md:justify-end">
            {productoFiltro && (
              <button
                type="button"
                onClick={() => setProductoFiltro(null)}
                className="text-xs text-slate-500 hover:text-slate-700 underline"
              >
                Limpiar
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Totales */}
      <div className="grid grid-cols-2 xl:grid-cols-4 gap-3">
        <StatCard compact label="Peso total" value={fmtKg(totales.peso_total)} hint={`${totales.lineas} líneas`} />
        <StatCard compact label="Merma" value={fmtKg(totales.peso_merma)} />
        <StatCard compact label="Consumo interno" value={fmtKg(totales.peso_consumo)} />
        <StatCard compact label="Operaciones" value={String(totales.operaciones)} hint="con líneas en el rango" />
      </div>

      {error && (
        <div className="rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">{error}</div>
      )}

      {/* Ranking */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm p-5">
        <h2 className="text-base font-semibold text-slate-900 mb-3">Productos con más peso perdido</h2>
        {topProductos.length === 0 && !cargando ? (
          <div className="py-10 text-center text-sm text-slate-500">
            <PackageX className="mx-auto h-8 w-8 text-slate-300" />
            <p className="mt-2">Sin mermas ni consumo interno en el período.</p>
          </div>
        ) : (
          <ul className="space-y-2">
            {topProductos.map((p) => {
              const pct = maxPeso > 0 ? (p.peso_total / maxPeso) * 100 : 0;
              return (
                <li key={p.producto_id} className="rounded-lg border border-slate-100 bg-slate-50/30 px-3 py-2">
                  <div className="flex items-baseline justify-between gap-2">
                    <p className="text-sm font-medium text-slate-900 truncate">{p.nombre}</p>
                    <span className="text-sm font-semibold tabular-nums text-slate-900 shrink-0">{fmtKg(p.peso_total)}</span>
                  </div>
                  <div className="mt-1.5 flex items-center gap-2">
                    <div className="flex-1 h-1.5 rounded-full bg-slate-200 overflow-hidden">
                      <div className="h-full bg-rose-500 rounded-full" style={{ width: `${pct}%` }} />
                    </div>
                    <span className="text-[11px] text-slate-500 tabular-nums shrink-0">
                      Merma {fmtKg(p.peso_merma)} · Consumo {fmtKg(p.peso_consumo)}
                    </span>
                  </div>
                </li>
              );
            })}
          </ul>
        )}
      </div>

      {/* Detalle */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm p-5">
        <div className="flex items-baseline justify-between mb-3">
          <h2 className="text-base font-semibold text-slate-900">Detalle</h2>
          <span className="text-xs text-slate-500">
            {cargando ? "Cargando…" : `${detalle.length} línea${detalle.length === 1 ? "" : "s"}`}
          </span>
        </div>
        {detalle.length === 0 && !cargando ? (
          <p className="text-sm text-slate-500 py-6 text-center">Nada para mostrar con estos filtros.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-xs uppercase tracking-wide text-slate-500 border-b border-slate-200">
                  <th className="py-2 pr-3">Fecha</th>
                  <th className="py-2 pr-3">Producto</th>
                  <th className="py-2 pr-3">Destino</th>
                  <th className="py-2 pr-3 text-right">Peso</th>
                  <th className="py-2 pr-3">Motivo / Observación</th>
                  <th className="py-2 pr-3">Usuario</th>
                </tr>
              </thead>
              <tbody>
                {detalle.map((d, i) => (
                  <tr key={`${d.operacion_id}-${i}`} className="border-b border-slate-100">
                    <td className="py-2 pr-3 tabular-nums text-slate-600 whitespace-nowrap">{fmtFecha(d.fecha)}</td>
                    <td className="py-2 pr-3">
                      <div className="font-medium text-slate-900 truncate max-w-[240px]">{d.nombre}</div>
                      <div className="text-[11px] font-mono text-slate-500">{d.sku ?? "—"}</div>
                    </td>
                    <td className="py-2 pr-3">
                      <span className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[11px] font-semibold ${
                        d.destino === "merma"
                          ? "bg-rose-50 text-rose-700 border border-rose-200"
                          : "bg-amber-50 text-amber-700 border border-amber-200"
                      }`}>
                        {d.destino === "merma" ? <AlertTriangle className="h-3 w-3" /> : <Coffee className="h-3 w-3" />}
                        {DESTINO_LABEL[d.destino]}
                      </span>
                    </td>
                    <td className="py-2 pr-3 text-right tabular-nums font-semibold text-slate-900">{fmtKg(d.peso)}</td>
                    <td className="py-2 pr-3 text-slate-600 max-w-[280px]">
                      {d.motivo && <span className="block truncate">{d.motivo}</span>}
                      {d.observacion && (
                        <span className={`block text-xs italic ${d.motivo ? "text-slate-500" : "text-slate-600"} truncate`}>
                          {d.observacion}
                        </span>
                      )}
                      {!d.motivo && !d.observacion && <span className="text-slate-400">—</span>}
                    </td>
                    <td className="py-2 pr-3 text-slate-600 truncate max-w-[140px]">{d.usuario_nombre ?? "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <div className="text-center text-xs text-slate-400">
        <Link href="/inventario/pesaje-cortes" className="hover:text-slate-600 underline">
          Registrar nueva operación de pesaje / cortes
        </Link>
        <span className="mx-2">·</span>
        <Link href="/reportes" className="hover:text-slate-600 underline">
          Volver a Reportes
        </Link>
        <span className="mx-2">·</span>
        <span className="inline-flex items-center gap-1">
          <PackageIcon className="h-3 w-3" /> Sucursal actual
        </span>
      </div>
    </div>
  );
}
