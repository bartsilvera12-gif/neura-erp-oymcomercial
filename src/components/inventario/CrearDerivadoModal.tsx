"use client";

/**
 * Modal chico para crear un "producto derivado" desde la pantalla de
 * pesaje / cortes / mermas, sin salir del flujo.
 *
 * Un derivado es simplemente un producto CONTROLADO POR PESO más (KG,
 * precio por kg). No hace falta elegir modalidad porque en un recorte
 * suelto no aplica el par entero/recortado — se vende siempre al mismo
 * precio/kg. Como el schema exige `modalidades_activas` con al menos un
 * valor cuando controlado_por_peso=true, se persiste como ['entero'] y
 * `precio_kg_entero=<precio>`. En la caja el PesoModal detecta que hay
 * una sola modalidad y directamente la usa sin mostrar el selector.
 */
import { useEffect, useRef, useState } from "react";
import MontoInput from "@/components/ui/MontoInput";

export interface DerivadoCreado {
  id: string;
  nombre: string;
}

export function CrearDerivadoModal({
  open,
  onCancel,
  onCreated,
  placeholderNombre = "Ej: RECORTE DE QUESO",
}: {
  open: boolean;
  onCancel: () => void;
  onCreated: (d: DerivadoCreado) => void;
  placeholderNombre?: string;
}) {
  const [nombre, setNombre] = useState("");
  const [precio, setPrecio] = useState<number>(0);
  const [guardando, setGuardando] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement | null>(null);

  useEffect(() => {
    if (!open) return;
    setNombre("");
    setPrecio(0);
    setError(null);
    setTimeout(() => inputRef.current?.focus(), 30);
  }, [open]);

  useEffect(() => {
    if (!open) return;
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape" && !guardando) onCancel();
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, guardando, onCancel]);

  if (!open) return null;

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (guardando) return;
    const n = nombre.trim();
    if (!n) { setError("El nombre es obligatorio."); return; }
    if (!(precio > 0)) { setError("Cargá un precio por kg mayor a 0."); return; }
    setError(null);
    setGuardando(true);
    try {
      // Se usa el POST estándar de productos. El derivado hereda el patrón
      // "por peso" con una única modalidad (ver comentario del componente).
      // El backend fuerza unidad_medida='KG' cuando controlado_por_peso=true,
      // así que no hace falta enviarlo — pero lo mandamos para claridad.
      const res = await fetch("/api/productos", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          nombre: n.toUpperCase(),
          // SKU se genera del nombre (uppercase espacios→guiones). El importador
          // valida uniqueness; si choca, el server responde 409 y lo mostramos.
          sku: n.toUpperCase().replace(/\s+/g, "-").slice(0, 40),
          unidad_medida: "KG",
          metodo_valuacion: "CPP",
          stock_actual: 0,
          stock_minimo: 0,
          precio_venta: precio, // legacy: mismo valor por si alguna vista lo mira
          controlado_por_peso: true,
          modalidades_activas: ["entero"],
          precio_kg_entero: precio,
          precio_kg_recortado: null,
          tipo_iva: "10%",
        }),
      });
      const json = await res.json().catch(() => ({} as Record<string, unknown>));
      if (!res.ok || !json?.success) {
        throw new Error((json as { error?: string })?.error ?? "No se pudo crear el producto derivado.");
      }
      const prod = (json.data as { producto?: { id: string; nombre: string } }).producto;
      if (!prod?.id) throw new Error("Respuesta inválida del servidor.");
      onCreated({ id: prod.id, nombre: prod.nombre });
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo crear.");
    } finally {
      setGuardando(false);
    }
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4"
      onClick={() => { if (!guardando) onCancel(); }}
    >
      <div
        className="w-full max-w-md rounded-xl bg-white p-5 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mb-3 flex items-start justify-between gap-2">
          <div className="min-w-0">
            <h3 className="text-base font-semibold text-slate-900">Nuevo producto derivado</h3>
            <p className="mt-0.5 text-xs text-slate-500">
              Se crea como producto por peso (KG). Después la caja lo vende
              pesando cada porción.
            </p>
          </div>
          <button
            type="button"
            onClick={onCancel}
            disabled={guardando}
            className="text-slate-400 hover:text-slate-600"
            aria-label="Cerrar"
          >
            ×
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="block text-xs font-medium text-slate-600 mb-1">Nombre *</label>
            <input
              ref={inputRef}
              type="text"
              value={nombre}
              onChange={(e) => { setNombre(e.target.value); setError(null); }}
              placeholder={placeholderNombre}
              className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm uppercase outline-none focus:ring-2 focus:ring-sky-400"
              maxLength={120}
              disabled={guardando}
            />
          </div>

          <div>
            <label className="block text-xs font-medium text-slate-600 mb-1">Precio por kg (Gs.) *</label>
            <MontoInput
              value={precio}
              onChange={(n) => { setPrecio(n); setError(null); }}
              placeholder="Ej: 30.000"
              className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-sky-400"
              decimals={false}
            />
          </div>

          {error && (
            <p className="rounded-md bg-rose-50 border border-rose-200 px-3 py-2 text-xs text-rose-700">{error}</p>
          )}

          <div className="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={onCancel}
              disabled={guardando}
              className="rounded-md border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-700 hover:bg-slate-50 disabled:opacity-50"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={guardando || !nombre.trim() || !(precio > 0)}
              className="rounded-md bg-sky-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-sky-700 disabled:opacity-50"
            >
              {guardando ? "Creando…" : "Crear y usar"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
