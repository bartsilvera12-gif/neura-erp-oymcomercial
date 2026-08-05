"use client";

/**
 * Campana de notificaciones. Por ahora solo alertas de stock bajo
 * (productos con `stock_actual <= stock_minimo` y `stock_minimo > 0`).
 *
 * Cálculo en vivo — no hay tabla de notificaciones persistente. Al abrir el
 * popover se refresca; en background se hace un fetch cada 60s para que el
 * badge se actualice sin tener que recargar la página. Cuando la pestaña
 * está oculta se pausa el refresh (visibilitychange) para no gastar batería.
 *
 * Si en el futuro se agregan más tipos de notificaciones, se puede extender
 * `TIPOS` sin tirar este componente: sumarle un segundo bloque en el popover.
 */
import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { Bell, AlertTriangle, PackageX } from "lucide-react";
import { fetchWithSupabaseSession } from "@/lib/api/fetch-with-supabase-session";

interface StockBajoItem {
  id: string;
  nombre: string;
  sku: string | null;
  stock_actual: number;
  stock_minimo: number;
  unidad_medida: string;
  controlado_por_peso: boolean;
}

interface StockBajoResp {
  count: number;
  items: StockBajoItem[];
}

/** Refresh en background (ms). 60s equilibra frescura con costo. */
const REFRESH_MS = 60_000;

function formatStock(n: number, unidad: string, porPeso: boolean): string {
  // Peso: hasta 3 decimales (0,350 kg). Unidad: entero.
  const opts = porPeso
    ? { minimumFractionDigits: 0, maximumFractionDigits: 3 }
    : { maximumFractionDigits: 0 };
  return `${n.toLocaleString("es-PY", opts)} ${unidad.toLowerCase()}`;
}

export default function NotificacionesPopover() {
  const [count, setCount] = useState(0);
  const [items, setItems] = useState<StockBajoItem[]>([]);
  const [cargando, setCargando] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [open, setOpen] = useState(false);
  const wrapperRef = useRef<HTMLDivElement>(null);

  const cargar = useCallback(async () => {
    setCargando(true);
    setError(null);
    try {
      const r = await fetchWithSupabaseSession("/api/notificaciones/stock-bajo", { cache: "no-store" });
      const j = await r.json().catch(() => ({}));
      if (!r.ok || !j?.success) {
        throw new Error((j as { error?: string })?.error ?? "No se pudo cargar.");
      }
      const data = (j.data as StockBajoResp) ?? { count: 0, items: [] };
      setCount(Number(data.count) || 0);
      setItems(Array.isArray(data.items) ? data.items : []);
    } catch (e) {
      setError(e instanceof Error ? e.message : "No se pudo cargar.");
    } finally {
      setCargando(false);
    }
  }, []);

  // Fetch inicial + polling. El polling se pausa cuando la pestaña está
  // oculta para no gastar bandwidth ni pegarle a Supabase sin motivo.
  useEffect(() => {
    void cargar();
    let intervalId: ReturnType<typeof setInterval> | null = null;
    function start() {
      if (intervalId != null) return;
      intervalId = setInterval(() => { void cargar(); }, REFRESH_MS);
    }
    function stop() {
      if (intervalId != null) {
        clearInterval(intervalId);
        intervalId = null;
      }
    }
    function handleVis() {
      if (document.visibilityState === "visible") { void cargar(); start(); }
      else stop();
    }
    start();
    document.addEventListener("visibilitychange", handleVis);
    return () => {
      stop();
      document.removeEventListener("visibilitychange", handleVis);
    };
  }, [cargar]);

  // Cerrar al clickear afuera.
  useEffect(() => {
    if (!open) return;
    function onDoc(e: MouseEvent) {
      if (!wrapperRef.current) return;
      if (!wrapperRef.current.contains(e.target as Node)) setOpen(false);
    }
    function onEsc(e: KeyboardEvent) {
      if (e.key === "Escape") setOpen(false);
    }
    document.addEventListener("mousedown", onDoc);
    document.addEventListener("keydown", onEsc);
    return () => {
      document.removeEventListener("mousedown", onDoc);
      document.removeEventListener("keydown", onEsc);
    };
  }, [open]);

  const badgeText = count > 99 ? "99+" : String(count);
  const tieneAlertas = count > 0;

  return (
    <div className="relative" ref={wrapperRef}>
      <button
        type="button"
        onClick={() => {
          setOpen((v) => !v);
          // Al abrir, refresca por si hubo cambios desde el último poll.
          if (!open) void cargar();
        }}
        className="relative rounded-lg p-2 text-slate-500 transition-colors hover:bg-slate-50 hover:text-[#3F8E91]"
        aria-label={`Notificaciones${tieneAlertas ? ` (${count})` : ""}`}
      >
        <Bell className="h-5 w-5" />
        <span
          className={`absolute -right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full px-1 text-[10px] font-bold text-white ${
            tieneAlertas ? "bg-rose-500" : "bg-[#4FAEB2]"
          }`}
        >
          {badgeText}
        </span>
      </button>

      {open && (
        <div className="absolute right-0 top-full z-50 mt-2 w-[22rem] max-w-[calc(100vw-2rem)] rounded-xl border border-slate-200 bg-white shadow-lg">
          <div className="flex items-center justify-between border-b border-slate-100 px-4 py-3">
            <div>
              <p className="text-sm font-semibold text-slate-900">Notificaciones</p>
              <p className="text-xs text-slate-500 mt-0.5">
                {tieneAlertas
                  ? `${count} producto${count === 1 ? "" : "s"} con stock bajo`
                  : "Sin alertas"}
              </p>
            </div>
            {cargando && <span className="text-[11px] text-slate-400">Actualizando…</span>}
          </div>

          {error && (
            <div className="mx-3 mt-3 rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-xs text-rose-700">
              {error}
            </div>
          )}

          {!error && items.length === 0 && !cargando && (
            <div className="px-4 py-8 text-center text-sm text-slate-500">
              <PackageX className="mx-auto h-8 w-8 text-slate-300" />
              <p className="mt-2">Todo en orden — no hay productos por debajo del mínimo.</p>
              <p className="mt-1 text-[11px] text-slate-400">
                Configurá <span className="font-medium text-slate-500">Stock mínimo</span> en la ficha de cada producto para activar el aviso.
              </p>
            </div>
          )}

          {items.length > 0 && (
            <ul className="max-h-[22rem] overflow-y-auto divide-y divide-slate-100">
              {items.map((p) => {
                const sinStock = p.stock_actual <= 0;
                return (
                  <li key={p.id}>
                    <Link
                      href={`/inventario/${p.id}/editar`}
                      onClick={() => setOpen(false)}
                      className="block px-4 py-2.5 hover:bg-slate-50 transition-colors"
                    >
                      <div className="flex items-start gap-3">
                        <div
                          className={`mt-0.5 shrink-0 rounded-full p-1.5 ${
                            sinStock ? "bg-rose-100 text-rose-600" : "bg-amber-100 text-amber-600"
                          }`}
                        >
                          <AlertTriangle className="h-3.5 w-3.5" />
                        </div>
                        <div className="min-w-0 flex-1">
                          <p className="truncate text-sm font-medium text-slate-900">{p.nombre}</p>
                          <p className="mt-0.5 font-mono text-[11px] text-slate-500">
                            {p.sku ?? "—"}
                          </p>
                          <p className="mt-1 text-xs">
                            <span className={`font-semibold ${sinStock ? "text-rose-600" : "text-amber-700"}`}>
                              {sinStock ? "Sin stock" : formatStock(p.stock_actual, p.unidad_medida, p.controlado_por_peso)}
                            </span>
                            <span className="text-slate-400"> · mínimo {formatStock(p.stock_minimo, p.unidad_medida, p.controlado_por_peso)}</span>
                          </p>
                        </div>
                      </div>
                    </Link>
                  </li>
                );
              })}
            </ul>
          )}

          {items.length > 0 && (
            <div className="border-t border-slate-100 px-4 py-2.5 text-center">
              <Link
                href="/inventario?stockBajo=1"
                onClick={() => setOpen(false)}
                className="text-xs font-medium text-sky-700 hover:text-sky-900"
              >
                Ver todos en Inventario →
              </Link>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
