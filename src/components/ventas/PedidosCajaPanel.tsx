"use client";

/**
 * Panel "Pedidos por cobrar" para el POS de Caja.
 *
 * Consume /api/pedidos-caja?estado=pendiente&en_cola=true y muestra la cola
 * de pedidos armados por los vendedores. Click en "Cobrar" toma el pedido
 * (POST /tomar → estado pendiente → en_caja) y avisa al padre para cargar
 * los items al carrito. El pedido queda vinculado al confirmar la venta
 * (server llama marcarPedidoFacturado con pedido_caja_id).
 *
 * Refresh: cada 45s en background + al montar + cuando la pestaña vuelve
 * a estar visible. Pausa cuando está oculta para no gastar bandwidth.
 */
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { fetchWithSupabaseSession } from "@/lib/api/fetch-with-supabase-session";
import { Package, ChevronDown, ChevronUp, RefreshCw, Loader2 } from "lucide-react";
import type { PedidoCaja } from "@/lib/pedidos-caja/types";

const REFRESH_MS = 45_000;

interface RespShape {
  success?: boolean;
  data?: { pedidos?: PedidoCaja[] };
  error?: string;
}

function formatGs(v: number): string {
  return `Gs. ${Math.round(v || 0).toLocaleString("es-PY")}`;
}
function formatFechaCorta(iso: string): string {
  try {
    const d = new Date(iso);
    return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
  } catch { return ""; }
}

export function PedidosCajaPanel({
  onCobrar,
  pedidoActivoId,
}: {
  /** Se llama cuando el cajero elige un pedido. El padre debe cargar los
   *  items al carrito y setear pedido_caja_id para el confirmarCobro. */
  onCobrar: (p: PedidoCaja) => Promise<void> | void;
  /** Si hay un pedido siendo cobrado, este id se resalta en la lista. */
  pedidoActivoId: string | null;
}) {
  const [pedidos, setPedidos] = useState<PedidoCaja[]>([]);
  const [cargando, setCargando] = useState(false);
  const [tomandoId, setTomandoId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [expandido, setExpandido] = useState(true);
  const mountedRef = useRef(true);

  const cargar = useCallback(async () => {
    setCargando(true);
    try {
      const r = await fetchWithSupabaseSession(
        "/api/pedidos-caja?estado=pendiente&en_cola=true&limit=100",
        { cache: "no-store" }
      );
      const j = (await r.json().catch(() => ({}))) as RespShape;
      if (!mountedRef.current) return;
      if (!r.ok || !j?.success) {
        throw new Error(j?.error ?? "No se pudieron cargar los pedidos.");
      }
      setPedidos(j.data?.pedidos ?? []);
      setError(null);
    } catch (e) {
      if (mountedRef.current) setError(e instanceof Error ? e.message : "Error al cargar.");
    } finally {
      if (mountedRef.current) setCargando(false);
    }
  }, []);

  useEffect(() => {
    mountedRef.current = true;
    void cargar();
    let intervalId: ReturnType<typeof setInterval> | null = null;
    function start() {
      if (intervalId != null) return;
      intervalId = setInterval(() => { void cargar(); }, REFRESH_MS);
    }
    function stop() {
      if (intervalId != null) { clearInterval(intervalId); intervalId = null; }
    }
    function onVis() {
      if (document.visibilityState === "visible") { void cargar(); start(); }
      else stop();
    }
    start();
    document.addEventListener("visibilitychange", onVis);
    return () => {
      mountedRef.current = false;
      stop();
      document.removeEventListener("visibilitychange", onVis);
    };
  }, [cargar]);

  async function handleCobrar(p: PedidoCaja) {
    if (tomandoId) return;
    setTomandoId(p.id);
    try {
      // "Tomar" transiciona pendiente → en_caja atomicamente. Si otro cajero
      // ya lo tomó el server igual devuelve OK (idempotente) — el padre carga
      // igual los items, y la venta al confirmar detecta la carrera si hay.
      await fetchWithSupabaseSession(`/api/pedidos-caja/${p.id}/tomar`, { method: "POST" });
      await onCobrar(p);
      // Refresh para reflejar el cambio de estado en la lista de otros cajeros.
      void cargar();
    } catch (e) {
      setError(e instanceof Error ? e.message : "No se pudo tomar el pedido.");
    } finally {
      setTomandoId(null);
    }
  }

  const total = pedidos.length;
  const totalRotulo = useMemo(() => (total === 0 ? "vacía" : `${total} pedido${total === 1 ? "" : "s"}`), [total]);

  return (
    <div className="rounded-2xl border border-slate-200 bg-white shadow-sm">
      <button
        type="button"
        onClick={() => setExpandido((v) => !v)}
        className="flex w-full items-center justify-between gap-3 px-4 py-3 text-left"
      >
        <div className="flex items-center gap-2 min-w-0">
          <Package className="h-4 w-4 shrink-0 text-[#4FAEB2]" />
          <span className="text-sm font-semibold text-slate-800">Pedidos por cobrar</span>
          <span
            className={`shrink-0 rounded-full px-2 py-0.5 text-[11px] font-semibold ${
              total > 0 ? "bg-[#4FAEB2]/10 text-[#3F8E91]" : "bg-slate-100 text-slate-500"
            }`}
          >
            {totalRotulo}
          </span>
          {cargando && <Loader2 className="h-3.5 w-3.5 animate-spin text-slate-400" />}
        </div>
        <div className="flex items-center gap-1.5">
          <button
            type="button"
            onClick={(e) => { e.stopPropagation(); void cargar(); }}
            className="rounded-md p-1 text-slate-400 hover:text-slate-600"
            aria-label="Refrescar"
            title="Refrescar ahora"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${cargando ? "animate-spin" : ""}`} />
          </button>
          {expandido ? <ChevronUp className="h-4 w-4 text-slate-400" /> : <ChevronDown className="h-4 w-4 text-slate-400" />}
        </div>
      </button>

      {expandido && (
        <div className="border-t border-slate-100">
          {error && (
            <div className="m-3 rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-xs text-rose-700">
              {error}
            </div>
          )}
          {total === 0 && !cargando && !error && (
            <div className="px-4 py-6 text-center text-xs text-slate-500">
              Cuando los vendedores armen pedidos, aparecerán acá para cobrar.
            </div>
          )}
          {total > 0 && (
            <ul className="max-h-[280px] overflow-y-auto divide-y divide-slate-100">
              {pedidos.map((p) => {
                const activo = pedidoActivoId === p.id;
                const tomando = tomandoId === p.id;
                const enCaja = p.estado === "en_caja";
                return (
                  <li
                    key={p.id}
                    className={`px-4 py-2.5 ${activo ? "bg-[#4FAEB2]/[0.08]" : "hover:bg-slate-50"}`}
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0 flex-1">
                        <div className="flex items-baseline gap-2 flex-wrap">
                          <span className="text-sm font-semibold text-slate-900 truncate">
                            {p.numero ?? "—"}
                          </span>
                          {p.cliente_nombre && (
                            <span className="text-xs text-slate-600 truncate">· {p.cliente_nombre}</span>
                          )}
                          {enCaja && (
                            <span className="rounded-full border border-amber-200 bg-amber-50 px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-amber-700">
                              En caja
                            </span>
                          )}
                        </div>
                        <div className="mt-0.5 flex items-center gap-2 text-[11px] text-slate-500">
                          <span>{p.items.length} ítem{p.items.length === 1 ? "" : "s"}</span>
                          <span>·</span>
                          <span className="tabular-nums">{formatGs(p.total_estimado)}</span>
                          {p.armado_por_email && (
                            <>
                              <span>·</span>
                              <span className="truncate max-w-[140px]">{p.armado_por_email}</span>
                            </>
                          )}
                          <span>·</span>
                          <span>{formatFechaCorta(p.created_at)}</span>
                        </div>
                      </div>
                      <button
                        type="button"
                        onClick={() => void handleCobrar(p)}
                        disabled={tomando || activo}
                        className={`shrink-0 rounded-md px-3 py-1.5 text-xs font-semibold transition-colors ${
                          activo
                            ? "bg-[#4FAEB2]/20 text-[#3F8E91] cursor-default"
                            : tomando
                            ? "bg-slate-100 text-slate-400 cursor-wait"
                            : "bg-[#4FAEB2] text-white hover:bg-[#3F8E91]"
                        }`}
                      >
                        {activo ? "En caja" : tomando ? "Tomando…" : "Cobrar"}
                      </button>
                    </div>
                  </li>
                );
              })}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}
