"use client";

/**
 * Pesaje / Cortes / Mermas.
 *
 * Pantalla para registrar la operación de "trabajar una pieza": seleccionar
 * un producto controlado_por_peso, ingresar el peso procesado, y distribuirlo
 * entre destinos (resto, recorte vendible, merma, consumo interno).
 *
 * La conservación de peso se valida en vivo (chip verde/rojo) y también la
 * enforce el server + trigger DB. El botón "Registrar" queda deshabilitado
 * hasta que suma == peso procesado (tolerancia ±0,5 g).
 */
import { useCallback, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { fetchWithSupabaseSession } from "@/lib/api/fetch-with-supabase-session";
import SearchableSelect from "@/components/ui/SearchableSelect";
import { Trash2 } from "lucide-react";

type Destino = "resto_aprovechable" | "recorte_vendible" | "merma" | "consumo_interno";

const DESTINO_LABEL: Record<Destino, string> = {
  resto_aprovechable: "Resto aprovechable",
  recorte_vendible: "Recorte vendible",
  merma: "Merma",
  consumo_interno: "Consumo interno",
};

// Descripción corta que se muestra debajo del dropdown de destino según lo
// elegido. Ayuda al usuario a no confundirse en la operación (los 4 nombres
// son cercanos y el impacto contable es distinto).
const DESTINO_HELP: Record<Destino, string> = {
  resto_aprovechable: "Peso que queda en la pieza original. No genera movimiento adicional.",
  recorte_vendible: "El recorte separado se convierte en stock de OTRO producto que ya tenés cargado (con su propio SKU y precio). Ejemplo: de una pieza de queso, el recorte se pasa a 'Recorte de queso'.",
  merma: "Desperdicio. Sale del inventario y no vuelve.",
  consumo_interno: "Usado internamente (degustación, uso propio). Sale del inventario.",
};

interface Producto {
  id: string;
  nombre: string;
  sku: string;
  stock_actual: number;
  controlado_por_peso: boolean;
}

interface Linea {
  key: number;
  destino: Destino;
  peso: string;
  producto_derivado_id: string | null;
  observacion: string;
}

interface OperacionRow {
  id: string;
  producto_origen_id: string;
  producto_origen_nombre: string;
  peso_procesado: number;
  motivo: string | null;
  observaciones: string | null;
  usuario_nombre: string | null;
  created_at: string;
  lineas: Array<{
    destino: Destino;
    peso: number;
    producto_derivado_id: string | null;
    producto_derivado_nombre: string | null;
    observacion: string | null;
  }>;
}

// Counter simple para keys de líneas (no necesita crypto).
let lineaSeq = 0;
function nextLineaKey(): number { lineaSeq += 1; return lineaSeq; }

function nuevaLinea(): Linea {
  return {
    key: nextLineaKey(),
    destino: "resto_aprovechable",
    peso: "",
    producto_derivado_id: null,
    observacion: "",
  };
}

function toN(s: string): number {
  const n = parseFloat(s.replace(",", "."));
  return Number.isFinite(n) ? n : 0;
}

function formatKg(n: number): string {
  return `${n.toLocaleString("es-PY", { minimumFractionDigits: 0, maximumFractionDigits: 3 })} kg`;
}

function formatFecha(iso: string): string {
  try {
    const d = new Date(iso);
    const dd = String(d.getDate()).padStart(2, "0");
    const mm = String(d.getMonth() + 1).padStart(2, "0");
    return `${dd}/${mm}/${d.getFullYear()} ${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
  } catch { return iso; }
}

export default function PesajeCortesPage() {
  const [productos, setProductos] = useState<Producto[]>([]);
  const [cargandoProductos, setCargandoProductos] = useState(true);
  const [origenId, setOrigenId] = useState<string | null>(null);
  const [pesoProcesado, setPesoProcesado] = useState("");
  const [motivo, setMotivo] = useState("");
  const [observaciones, setObservaciones] = useState("");
  const [lineas, setLineas] = useState<Linea[]>(() => [nuevaLinea()]);
  const [enviando, setEnviando] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [ok, setOk] = useState<string | null>(null);
  const [historial, setHistorial] = useState<OperacionRow[]>([]);
  const [cargandoHistorial, setCargandoHistorial] = useState(true);

  /** Trae TODOS los productos (para tener candidatos de origen filtrados por
   *  controlado_por_peso y para el picker de derivado). El endpoint
   *  /api/productos ahora pagina server-side hasta agotar la tabla, así que
   *  no hay tope de 1000. */
  const recargarProductos = useCallback(async () => {
    setCargandoProductos(true);
    try {
      const r = await fetchWithSupabaseSession("/api/productos", { cache: "no-store" });
      const j = await r.json().catch(() => ({}));
      if (r.ok && j?.success) {
        const lista = ((j.data as { productos?: unknown[] }).productos ?? []) as Array<Record<string, unknown>>;
        setProductos(lista.map((p) => ({
          id: String(p.id),
          nombre: String(p.nombre ?? ""),
          sku: String(p.sku ?? ""),
          stock_actual: Number(p.stock_actual ?? 0),
          controlado_por_peso: p.controlado_por_peso === true,
        })));
      }
    } catch (e) {
      console.error("[pesaje] recargar productos", e);
    } finally {
      setCargandoProductos(false);
    }
  }, []);

  const recargarHistorial = useCallback(async () => {
    setCargandoHistorial(true);
    try {
      const r = await fetchWithSupabaseSession("/api/inventario/pesaje-cortes?limit=20", { cache: "no-store" });
      const j = await r.json().catch(() => ({}));
      if (r.ok && j?.success) {
        setHistorial(((j.data as { items?: OperacionRow[] }).items ?? []));
      }
    } catch (e) {
      console.error("[pesaje] recargar historial", e);
    } finally {
      setCargandoHistorial(false);
    }
  }, []);

  useEffect(() => {
    void recargarProductos();
    void recargarHistorial();
  }, [recargarProductos, recargarHistorial]);

  const productosPeso = useMemo(
    () => productos.filter((p) => p.controlado_por_peso),
    [productos]
  );

  const origen = useMemo(
    () => productos.find((p) => p.id === origenId) ?? null,
    [productos, origenId]
  );

  const pesoProcesadoN = toN(pesoProcesado);
  const sumaLineas = useMemo(
    () => lineas.reduce((s, l) => s + toN(l.peso), 0),
    [lineas]
  );
  const dif = sumaLineas - pesoProcesadoN;
  const conservado = Math.abs(dif) <= 0.0005 && pesoProcesadoN > 0;

  const stockDespues = origen ? origen.stock_actual - pesoProcesadoN : 0;
  const excedeStock = origen ? pesoProcesadoN > origen.stock_actual + 0.0005 : false;

  const puedeEnviar =
    !enviando &&
    !!origen &&
    pesoProcesadoN > 0 &&
    !excedeStock &&
    lineas.length > 0 &&
    lineas.every((l) => toN(l.peso) > 0 && (l.destino !== "recorte_vendible" || !!l.producto_derivado_id)) &&
    conservado;

  function updateLinea(key: number, patch: Partial<Linea>) {
    setLineas((prev) => prev.map((l) => (l.key === key ? { ...l, ...patch } : l)));
  }

  function addLinea() {
    setLineas((prev) => [...prev, nuevaLinea()]);
  }

  function removeLinea(key: number) {
    setLineas((prev) => (prev.length === 1 ? prev : prev.filter((l) => l.key !== key)));
  }

  function resetForm() {
    setOrigenId(null);
    setPesoProcesado("");
    setMotivo("");
    setObservaciones("");
    setLineas([nuevaLinea()]);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!puedeEnviar || !origen) return;
    setError(null);
    setOk(null);
    setEnviando(true);
    try {
      const body = {
        producto_origen_id: origen.id,
        peso_procesado: pesoProcesadoN,
        motivo: motivo.trim() || null,
        observaciones: observaciones.trim() || null,
        lineas: lineas.map((l) => ({
          destino: l.destino,
          peso: toN(l.peso),
          producto_derivado_id: l.destino === "recorte_vendible" ? l.producto_derivado_id : null,
          observacion: l.observacion.trim() || null,
        })),
      };
      const r = await fetchWithSupabaseSession("/api/inventario/pesaje-cortes", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      const j = await r.json().catch(() => ({}));
      if (!r.ok || !j?.success) {
        throw new Error((j as { error?: string })?.error ?? "No se pudo registrar la operación.");
      }
      const stockRes = Number((j.data as { stockOrigenResultante?: number })?.stockOrigenResultante ?? 0);
      setOk(`Operación registrada. Nuevo stock de ${origen.nombre}: ${formatKg(stockRes)}.`);
      resetForm();
      void recargarProductos();
      void recargarHistorial();
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo registrar la operación.");
    } finally {
      setEnviando(false);
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Pesaje / Cortes / Mermas</h1>
          <p className="text-sm text-gray-500 mt-0.5">
            Registrá la transformación de una pieza (queso, jamón) en resto aprovechable,
            recorte vendible, merma y consumo interno.
          </p>
        </div>
        <Link
          href="/inventario"
          className="rounded-md border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 hover:bg-slate-50"
        >
          Volver a Inventario
        </Link>
      </div>

      {productosPeso.length === 0 && !cargandoProductos && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          Todavía no configuraste ningún producto <strong>controlado por peso</strong>.
          Andá a <Link href="/inventario" className="underline">Inventario</Link>, editá el producto y activá
          la sección "Controlado por peso".
        </div>
      )}

      <form onSubmit={handleSubmit} className="rounded-xl border border-slate-200 bg-white shadow-sm p-5 space-y-5">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
          <div className="lg:col-span-6">
            <label className="block text-sm font-medium text-slate-700 mb-1.5">Producto de origen *</label>
            <SearchableSelect
              value={origenId}
              onChange={(id) => setOrigenId(id)}
              options={productosPeso.map((p) => ({
                id: p.id,
                label: p.nombre,
                hint: `${p.sku} · ${formatKg(p.stock_actual)}`,
              }))}
              placeholder={cargandoProductos ? "Cargando…" : "Elegí el producto"}
              disabled={cargandoProductos || productosPeso.length === 0}
            />
            {origen && (
              <p className="mt-1.5 text-xs text-slate-500">
                Stock actual: <span className="font-semibold tabular-nums text-slate-900">{formatKg(origen.stock_actual)}</span>
              </p>
            )}
          </div>
          <div className="lg:col-span-3">
            <label className="block text-sm font-medium text-slate-700 mb-1.5">Peso procesado (kg) *</label>
            <input
              type="text"
              inputMode="decimal"
              value={pesoProcesado}
              onChange={(e) => setPesoProcesado(e.target.value.replace(/[^\d.,]/g, ""))}
              placeholder="Ej: 4,700"
              className={`w-full rounded-lg border px-3 py-2 text-sm font-mono tabular-nums outline-none focus:ring-2 focus:ring-sky-400 ${
                excedeStock ? "border-rose-300 bg-rose-50" : "border-slate-200 bg-white"
              }`}
            />
            {excedeStock && (
              <p className="mt-1 text-xs text-rose-600">Supera el stock disponible.</p>
            )}
            {!excedeStock && pesoProcesadoN > 0 && origen && (
              <p className="mt-1 text-xs text-slate-500">
                Stock después: <span className="font-semibold tabular-nums">{formatKg(stockDespues)}</span>
              </p>
            )}
          </div>
          <div className="lg:col-span-3">
            <label className="block text-sm font-medium text-slate-700 mb-1.5">Motivo</label>
            <input
              type="text"
              value={motivo}
              onChange={(e) => setMotivo(e.target.value)}
              placeholder="Ej: Fraccionamiento diario"
              className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-sky-400"
              maxLength={120}
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1.5">Observaciones</label>
          <textarea
            value={observaciones}
            onChange={(e) => setObservaciones(e.target.value)}
            placeholder="Opcional"
            rows={2}
            className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-sky-400"
          />
        </div>

        {/* Grilla de líneas */}
        <div className="border-t border-slate-100 pt-4">
          <div className="flex items-center justify-between mb-3">
            <div>
              <p className="text-xs uppercase tracking-wide font-semibold text-slate-500">
                Distribución del peso
              </p>
              <p className="text-xs text-slate-500 mt-0.5">
                La suma tiene que coincidir con el peso procesado.
              </p>
            </div>
            <div
              className={`text-xs font-semibold rounded-full px-2.5 py-1 border ${
                conservado
                  ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                  : "bg-rose-50 text-rose-700 border-rose-200"
              }`}
              title="Peso conservado: suma de líneas == peso procesado (tolerancia ±0,5 g)"
            >
              {formatKg(sumaLineas)} / {formatKg(pesoProcesadoN)}
              {" · "}
              {conservado
                ? "conservado"
                : dif === 0 && pesoProcesadoN === 0
                ? "faltan datos"
                : `dif ${dif > 0 ? "+" : ""}${formatKg(dif)}`}
            </div>
          </div>

          <div className="space-y-2">
            {lineas.map((l) => (
              <div key={l.key} className="rounded-lg border border-slate-200 bg-slate-50/40 p-3">
                <div className="grid grid-cols-1 md:grid-cols-12 gap-3 items-start">
                  <div className="md:col-span-3">
                    <label className="block text-xs text-slate-600 mb-1">Destino</label>
                    <select
                      value={l.destino}
                      onChange={(e) => updateLinea(l.key, {
                        destino: e.target.value as Destino,
                        // Al cambiar de destino, limpiar derivado (si estaba).
                        producto_derivado_id: (e.target.value as Destino) === "recorte_vendible" ? l.producto_derivado_id : null,
                      })}
                      className="w-full rounded-md border border-slate-200 bg-white px-2 py-1.5 text-sm outline-none focus:ring-2 focus:ring-sky-400"
                    >
                      {(Object.keys(DESTINO_LABEL) as Destino[]).map((d) => (
                        <option key={d} value={d}>{DESTINO_LABEL[d]}</option>
                      ))}
                    </select>
                    <p className="mt-1 text-[11px] text-slate-500 leading-snug">{DESTINO_HELP[l.destino]}</p>
                  </div>

                  <div className="md:col-span-2">
                    <label className="block text-xs text-slate-600 mb-1">Peso (kg) *</label>
                    <input
                      type="text"
                      inputMode="decimal"
                      value={l.peso}
                      onChange={(e) => updateLinea(l.key, { peso: e.target.value.replace(/[^\d.,]/g, "") })}
                      placeholder="Ej: 0,300"
                      className="w-full rounded-md border border-slate-200 bg-white px-2 py-1.5 text-sm font-mono tabular-nums outline-none focus:ring-2 focus:ring-sky-400"
                    />
                  </div>

                  <div className="md:col-span-5">
                    {l.destino === "recorte_vendible" ? (
                      <>
                        <label className="block text-xs text-slate-600 mb-1">
                          ¿A qué producto se pasa este recorte? *
                        </label>
                        <SearchableSelect
                          value={l.producto_derivado_id}
                          onChange={(id) => updateLinea(l.key, { producto_derivado_id: id })}
                          options={productos
                            .filter((p) => p.id !== origen?.id)
                            .map((p) => ({
                              id: p.id,
                              label: p.nombre,
                              hint: p.sku,
                            }))}
                          placeholder="Elegí el producto donde entra el recorte"
                        />
                        <p className="mt-1 text-[11px] text-slate-500">
                          Tiene que estar creado en <span className="font-medium">Inventario</span> con su propio
                          SKU y precio (ej. "Recorte de queso").
                        </p>
                      </>
                    ) : (
                      <>
                        <label className="block text-xs text-slate-600 mb-1">Observación</label>
                        <input
                          type="text"
                          value={l.observacion}
                          onChange={(e) => updateLinea(l.key, { observacion: e.target.value })}
                          placeholder="Opcional"
                          className="w-full rounded-md border border-slate-200 bg-white px-2 py-1.5 text-sm outline-none focus:ring-2 focus:ring-sky-400"
                          maxLength={120}
                        />
                      </>
                    )}
                  </div>

                  <div className="md:col-span-2 flex md:justify-end">
                    <button
                      type="button"
                      onClick={() => removeLinea(l.key)}
                      disabled={lineas.length === 1}
                      className="inline-flex items-center gap-1 rounded-md border border-rose-200 bg-white px-2.5 py-1.5 text-xs font-medium text-rose-600 hover:bg-rose-50 disabled:opacity-40 disabled:cursor-not-allowed"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                      Quitar
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>

          <button
            type="button"
            onClick={addLinea}
            className="mt-3 rounded-md border border-slate-200 bg-white px-3 py-1.5 text-xs font-medium text-slate-700 hover:bg-slate-50"
          >
            + Agregar destino
          </button>
        </div>

        {error && (
          <div className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-700">
            {error}
          </div>
        )}
        {ok && (
          <div className="rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-700">
            {ok}
          </div>
        )}

        <div className="flex items-center justify-end gap-2 border-t border-slate-100 pt-4">
          <button
            type="button"
            onClick={resetForm}
            disabled={enviando}
            className="rounded-md border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 hover:bg-slate-50 disabled:opacity-50"
          >
            Vaciar
          </button>
          <button
            type="submit"
            disabled={!puedeEnviar}
            className="rounded-md bg-sky-600 px-4 py-2 text-sm font-semibold text-white hover:bg-sky-700 disabled:opacity-50"
          >
            {enviando ? "Registrando…" : "Registrar operación"}
          </button>
        </div>
      </form>

      {/* Historial */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm p-5">
        <div className="flex items-baseline justify-between mb-3">
          <h2 className="text-lg font-semibold text-slate-900">Últimas operaciones</h2>
          <span className="text-xs text-slate-500">
            {cargandoHistorial ? "Cargando…" : `${historial.length} registradas`}
          </span>
        </div>
        {historial.length === 0 && !cargandoHistorial ? (
          <p className="text-sm text-slate-500 py-6 text-center">No hay operaciones aún.</p>
        ) : (
          <ul className="divide-y divide-slate-100">
            {historial.map((op) => (
              <li key={op.id} className="py-3">
                <div className="flex items-baseline justify-between gap-3">
                  <div className="min-w-0">
                    <p className="text-sm font-semibold text-slate-900 truncate">{op.producto_origen_nombre}</p>
                    <p className="text-xs text-slate-500 mt-0.5">
                      {formatFecha(op.created_at)}
                      {op.usuario_nombre ? ` · ${op.usuario_nombre}` : ""}
                      {op.motivo ? ` · ${op.motivo}` : ""}
                    </p>
                  </div>
                  <span className="text-sm font-semibold tabular-nums text-slate-900">
                    {formatKg(op.peso_procesado)}
                  </span>
                </div>
                <div className="mt-2 flex flex-wrap gap-1.5">
                  {op.lineas.map((l, i) => (
                    <span
                      key={i}
                      className="inline-flex items-center gap-1 rounded-full border border-slate-200 bg-slate-50 px-2 py-0.5 text-[11px] text-slate-700"
                    >
                      <span className="font-semibold">{DESTINO_LABEL[l.destino]}</span>
                      <span className="text-slate-500">·</span>
                      <span className="tabular-nums">{formatKg(l.peso)}</span>
                      {l.producto_derivado_nombre && (
                        <>
                          <span className="text-slate-400">→</span>
                          <span className="text-slate-800">{l.producto_derivado_nombre}</span>
                        </>
                      )}
                    </span>
                  ))}
                </div>
                {op.observaciones && (
                  <p className="mt-1.5 text-xs text-slate-500 italic">{op.observaciones}</p>
                )}
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
