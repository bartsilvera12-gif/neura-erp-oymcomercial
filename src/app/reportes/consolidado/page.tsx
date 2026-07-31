"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { apiFetch } from "@/lib/api/fetch-with-supabase-session";

type Fila = {
  sucursal_id: string;
  sucursal_codigo: string;
  sucursal_nombre: string;
  ventas_cantidad: number;
  ventas_total: number;
  compras_total: number;
  gastos_total: number;
  resultado: number;
  stock_valorizado: number;
  cajas_cerradas: number;
  caja_diferencias: number;
};
type Totales = Omit<Fila, "sucursal_id" | "sucursal_codigo" | "sucursal_nombre">;
type Reporte = { mes: string; filas: Fila[]; totales: Totales };

function formatGs(v: number) {
  return `Gs. ${Math.round(v || 0).toLocaleString("es-PY")}`;
}

function mesActual() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

export default function ConsolidadoPage() {
  const [mes, setMes] = useState(mesActual);
  const [data, setData] = useState<Reporte | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [cargando, setCargando] = useState(true);

  const cargar = useCallback(async (m: string) => {
    setCargando(true);
    setError(null);
    try {
      const res = await apiFetch(`/api/reportes/consolidado?mes=${encodeURIComponent(m)}`, {
        cache: "no-store",
      });
      const j = await res.json().catch(() => ({}));
      if (!res.ok || !j?.success) throw new Error(j?.error ?? `Error ${res.status}`);
      setData(j.data as Reporte);
    } catch (e) {
      setError(e instanceof Error ? e.message : "No se pudo cargar el consolidado.");
      setData(null);
    } finally {
      setCargando(false);
    }
  }, []);

  useEffect(() => {
    void cargar(mes);
  }, [cargar, mes]);

  return (
    <div className="space-y-6">
      <div>
        <Link href="/reportes" className="text-sm text-sky-600 hover:underline">
          ← Reportes
        </Link>
        <h1 className="mt-2 text-2xl font-bold text-slate-900">Consolidado por sucursal</h1>
        <p className="text-sm text-slate-600">
          Comparación de todas las sucursales activas en el mes. Es la única pantalla que cruza
          sucursales: el resto del sistema muestra solo la tuya.
        </p>
      </div>

      <div className="flex flex-wrap items-center gap-3">
        <label className="text-sm font-medium text-slate-700" htmlFor="mes">
          Mes
        </label>
        <input
          id="mes"
          type="month"
          value={mes}
          onChange={(e) => setMes(e.target.value || mesActual())}
          className="rounded-lg border border-slate-200 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-[#0EA5E9]"
        />
      </div>

      {error && (
        <p className="rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">{error}</p>
      )}

      {cargando && !data && <p className="text-sm text-slate-400">Cargando…</p>}

      {data && (
        <>
          <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <table className="w-full min-w-[820px] text-left text-sm">
              <thead>
                <tr className="border-b border-slate-100 text-slate-600">
                  <th className="py-3 pr-4 font-semibold">Sucursal</th>
                  <th className="py-3 pr-4 text-right font-semibold">Ventas</th>
                  <th className="py-3 pr-4 text-right font-semibold">Facturado</th>
                  <th className="py-3 pr-4 text-right font-semibold">Compras</th>
                  <th className="py-3 pr-4 text-right font-semibold">Gastos</th>
                  <th className="py-3 pr-4 text-right font-semibold">Resultado</th>
                  <th className="py-3 pr-4 text-right font-semibold">Stock valorizado</th>
                  <th className="py-3 pr-4 text-right font-semibold">Cierres</th>
                  <th className="py-3 text-right font-semibold">Dif. de caja</th>
                </tr>
              </thead>
              <tbody>
                {data.filas.map((f) => (
                  <tr key={f.sucursal_id} className="border-b border-slate-50 last:border-0">
                    <td className="py-3 pr-4">
                      <span className="font-medium text-slate-800">{f.sucursal_nombre}</span>
                      <span className="ml-2 font-mono text-xs text-slate-400">{f.sucursal_codigo}</span>
                    </td>
                    <td className="py-3 pr-4 text-right tabular-nums text-slate-600">{f.ventas_cantidad}</td>
                    <td className="py-3 pr-4 text-right tabular-nums font-medium text-slate-800">{formatGs(f.ventas_total)}</td>
                    <td className="py-3 pr-4 text-right tabular-nums text-slate-600">{formatGs(f.compras_total)}</td>
                    <td className="py-3 pr-4 text-right tabular-nums text-slate-600">{formatGs(f.gastos_total)}</td>
                    <td className={`py-3 pr-4 text-right font-semibold tabular-nums ${f.resultado < 0 ? "text-rose-600" : "text-emerald-700"}`}>
                      {formatGs(f.resultado)}
                    </td>
                    <td className="py-3 pr-4 text-right tabular-nums text-slate-600">{formatGs(f.stock_valorizado)}</td>
                    <td className="py-3 pr-4 text-right tabular-nums text-slate-600">{f.cajas_cerradas}</td>
                    <td className={`py-3 text-right tabular-nums ${f.caja_diferencias === 0 ? "text-slate-400" : f.caja_diferencias < 0 ? "text-rose-600" : "text-sky-600"}`}>
                      {formatGs(f.caja_diferencias)}
                    </td>
                  </tr>
                ))}
              </tbody>
              {data.filas.length > 1 && (
                <tfoot>
                  <tr className="border-t-2 border-slate-200 font-bold text-slate-900">
                    <td className="py-3 pr-4">Total</td>
                    <td className="py-3 pr-4 text-right tabular-nums">{data.totales.ventas_cantidad}</td>
                    <td className="py-3 pr-4 text-right tabular-nums">{formatGs(data.totales.ventas_total)}</td>
                    <td className="py-3 pr-4 text-right tabular-nums">{formatGs(data.totales.compras_total)}</td>
                    <td className="py-3 pr-4 text-right tabular-nums">{formatGs(data.totales.gastos_total)}</td>
                    <td className={`py-3 pr-4 text-right tabular-nums ${data.totales.resultado < 0 ? "text-rose-600" : "text-emerald-700"}`}>
                      {formatGs(data.totales.resultado)}
                    </td>
                    <td className="py-3 pr-4 text-right tabular-nums">{formatGs(data.totales.stock_valorizado)}</td>
                    <td className="py-3 pr-4 text-right tabular-nums">{data.totales.cajas_cerradas}</td>
                    <td className="py-3 text-right tabular-nums">{formatGs(data.totales.caja_diferencias)}</td>
                  </tr>
                </tfoot>
              )}
            </table>
            {data.filas.length === 0 && (
              <p className="py-8 text-center text-slate-400">No hay sucursales activas.</p>
            )}
          </div>

          <p className="text-xs leading-relaxed text-slate-400">
            <strong>Resultado</strong> es ventas − compras − gastos del mes; es una aproximación de
            caja, no un estado contable. <strong>Stock valorizado</strong> es el saldo de hoy a costo
            promedio, no el del cierre del mes. <strong>Dif. de caja</strong> suma las diferencias de
            arqueo de los turnos cerrados: positivo sobró, negativo faltó.
          </p>
        </>
      )}
    </div>
  );
}
