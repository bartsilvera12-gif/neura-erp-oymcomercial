"use client";

/**
 * Modal de captura de peso + modalidad para productos controlados_por_peso.
 *
 * Se abre desde la caja cuando el usuario elige un producto por peso.
 * Muestra en vivo: stock disponible, peso ingresado, modalidad y su precio/kg,
 * subtotal y stock resultante después de confirmar.
 *
 * Reglas:
 *  - Peso > 0 con hasta 3 decimales.
 *  - No permite peso > stock (bloqueado por default; en el futuro puede
 *    reactivarse con permitir_sin_stock, ver flag opcional `permitirSobreventa`).
 *  - Al menos una modalidad activa: si solo hay una se pre-selecciona y el
 *    selector se oculta para no molestar.
 *  - Preparado para input via balanza / escáner: el input recibe focus al
 *    abrir y acepta paste + Enter para confirmar rápido.
 */
import { useEffect, useMemo, useRef, useState } from "react";
import { MODALIDAD_LABEL, type ModalidadPeso } from "@/lib/inventario/types";

export interface PesoModalProducto {
  id: string;
  sku: string;
  nombre: string;
  stock_actual: number;
  modalidades_activas: ModalidadPeso[];
  precio_kg_entero: number | null;
  precio_kg_recortado: number | null;
}

export interface PesoModalResult {
  peso: number;
  modalidad: ModalidadPeso;
  precioKg: number;
}

function formatKg(n: number): string {
  return `${n.toLocaleString("es-PY", { minimumFractionDigits: 0, maximumFractionDigits: 3 })} kg`;
}
function formatGs(n: number): string {
  return `Gs. ${Math.round(n).toLocaleString("es-PY")}`;
}

function precioPorModalidad(prod: PesoModalProducto, m: ModalidadPeso): number {
  if (m === "entero") return prod.precio_kg_entero ?? 0;
  return prod.precio_kg_recortado ?? 0;
}

export function PesoModal({
  producto,
  onCancel,
  onConfirm,
  permitirSobreventa = false,
}: {
  producto: PesoModalProducto | null;
  onCancel: () => void;
  onConfirm: (r: PesoModalResult) => void;
  permitirSobreventa?: boolean;
}) {
  const [modalidad, setModalidad] = useState<ModalidadPeso | null>(null);
  const [pesoStr, setPesoStr] = useState("");
  const inputRef = useRef<HTMLInputElement | null>(null);

  // Al abrir: default de modalidad = la primera activa. Reset peso.
  useEffect(() => {
    if (!producto) return;
    setModalidad(producto.modalidades_activas[0] ?? null);
    setPesoStr("");
    setTimeout(() => inputRef.current?.focus(), 30);
  }, [producto?.id]);

  // Escape para cerrar
  useEffect(() => {
    if (!producto) return;
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") onCancel();
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [producto, onCancel]);

  const peso = useMemo(() => {
    const n = parseFloat(pesoStr.replace(",", "."));
    return Number.isFinite(n) && n > 0 ? n : 0;
  }, [pesoStr]);

  const precioKg = producto && modalidad ? precioPorModalidad(producto, modalidad) : 0;
  const subtotal = peso * precioKg;
  const stockResultante = producto ? producto.stock_actual - peso : 0;
  const excedeStock = producto ? peso > producto.stock_actual + 0.0001 : false;
  const puedeConfirmar =
    !!producto && !!modalidad && peso > 0 && precioKg > 0 && (permitirSobreventa || !excedeStock);

  if (!producto) return null;

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!puedeConfirmar || !modalidad) return;
    onConfirm({ peso, modalidad, precioKg });
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/45 p-4"
      onClick={onCancel}
    >
      <div
        className="w-full max-w-md rounded-2xl bg-white p-5 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mb-3 flex items-start justify-between gap-2">
          <div className="min-w-0">
            <h3 className="text-base font-semibold text-slate-900 truncate">{producto.nombre}</h3>
            <p className="mt-0.5 text-xs font-mono text-slate-500">{producto.sku}</p>
          </div>
          <button
            type="button"
            onClick={onCancel}
            className="text-slate-400 hover:text-slate-600"
            aria-label="Cerrar"
          >
            ×
          </button>
        </div>

        <div className="mb-3 rounded-lg bg-slate-50 px-3 py-2 text-xs text-slate-600 flex items-center justify-between">
          <span>Stock disponible</span>
          <span className="font-semibold tabular-nums text-slate-900">{formatKg(producto.stock_actual)}</span>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {producto.modalidades_activas.length > 1 && (
            <div>
              <label className="block text-xs font-medium text-slate-600 mb-1.5">Modalidad</label>
              <div className="grid grid-cols-2 gap-2">
                {producto.modalidades_activas.map((m) => {
                  const p = precioPorModalidad(producto, m);
                  const activo = modalidad === m;
                  return (
                    <button
                      key={m}
                      type="button"
                      onClick={() => setModalidad(m)}
                      className={`rounded-lg border px-3 py-2 text-left transition-colors ${
                        activo ? "border-sky-400 bg-sky-50 shadow-sm" : "border-slate-200 hover:border-slate-300"
                      }`}
                    >
                      <div className="text-sm font-semibold text-slate-900">{MODALIDAD_LABEL[m]}</div>
                      <div className="text-xs text-slate-500 mt-0.5">{formatGs(p)} / kg</div>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          <div>
            <label className="block text-xs font-medium text-slate-600 mb-1.5">
              Peso (kg) <span className="text-rose-500">*</span>
            </label>
            <input
              ref={inputRef}
              type="text"
              inputMode="decimal"
              value={pesoStr}
              onChange={(e) => setPesoStr(e.target.value.replace(/[^\d.,]/g, ""))}
              placeholder="Ej: 0,350"
              className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-lg font-mono tabular-nums outline-none focus:ring-2 focus:ring-sky-400"
              autoComplete="off"
            />
            <p className="mt-1 text-[11px] text-slate-500">Hasta 3 decimales. Usá coma o punto.</p>
          </div>

          <div className="rounded-lg border border-slate-200 bg-slate-50/40 p-3 text-sm space-y-1.5">
            <div className="flex justify-between">
              <span className="text-slate-600">Precio / kg</span>
              <span className="font-semibold tabular-nums text-slate-900">{formatGs(precioKg)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-600">Peso</span>
              <span className="font-semibold tabular-nums text-slate-900">{peso > 0 ? formatKg(peso) : "—"}</span>
            </div>
            <div className="flex justify-between border-t border-slate-200 pt-1.5">
              <span className="text-slate-600">Subtotal</span>
              <span className="font-bold tabular-nums text-slate-900">{peso > 0 ? formatGs(subtotal) : "—"}</span>
            </div>
            <div className={`flex justify-between text-xs ${excedeStock ? "text-rose-600" : "text-slate-500"}`}>
              <span>Stock después</span>
              <span className="tabular-nums">{peso > 0 ? formatKg(stockResultante) : "—"}</span>
            </div>
          </div>

          {excedeStock && !permitirSobreventa && (
            <p className="rounded-md bg-rose-50 border border-rose-200 px-3 py-2 text-xs text-rose-700">
              El peso ingresado supera el stock disponible.
            </p>
          )}

          <div className="flex items-center justify-end gap-2">
            <button
              type="button"
              onClick={onCancel}
              className="rounded-md border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 hover:bg-slate-50"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={!puedeConfirmar}
              className="rounded-md bg-sky-600 px-4 py-2 text-sm font-semibold text-white hover:bg-sky-700 disabled:opacity-50"
            >
              Agregar al ticket
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
