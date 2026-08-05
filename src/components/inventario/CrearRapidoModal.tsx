"use client";

import { useEffect, useRef, useState } from "react";

/**
 * Modal genérico "crear rápido" para dar de alta una entidad simple
 * (categoría, proveedor, etc.) desde otro flujo, sin salir de la pantalla.
 *
 * El caller pasa `onCreate` que resuelve al item creado; el modal muestra
 * cargando/error localmente y avisa al padre con `onCreated({id, nombre})`
 * para que lo seleccione automáticamente y refresque la lista.
 *
 * Se limita a nombre + descripción opcional a propósito: para completar el
 * resto de campos, el usuario abre la pantalla completa desde el link
 * "Ver todos / editar". Esto evita duplicar el formulario grande.
 */
export function CrearRapidoModal({
  open,
  titulo,
  placeholderNombre,
  onCancel,
  onCreate,
  onCreated,
  mostrarDescripcion = false,
}: {
  open: boolean;
  titulo: string;
  placeholderNombre: string;
  onCancel: () => void;
  onCreate: (payload: { nombre: string; descripcion: string | null }) => Promise<{ id: string; nombre: string }>;
  onCreated: (item: { id: string; nombre: string }) => void;
  mostrarDescripcion?: boolean;
}) {
  const [nombre, setNombre] = useState("");
  const [descripcion, setDescripcion] = useState("");
  const [guardando, setGuardando] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement | null>(null);

  useEffect(() => {
    if (open) {
      setNombre("");
      setDescripcion("");
      setError(null);
      setTimeout(() => inputRef.current?.focus(), 30);
    }
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
    if (!n) {
      setError("El nombre es obligatorio.");
      return;
    }
    setError(null);
    setGuardando(true);
    try {
      const item = await onCreate({
        nombre: n,
        descripcion: mostrarDescripcion ? (descripcion.trim() || null) : null,
      });
      onCreated(item);
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
        <div className="mb-4 flex items-start justify-between gap-2">
          <h3 className="text-base font-semibold text-slate-900">{titulo}</h3>
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

          {mostrarDescripcion && (
            <div>
              <label className="block text-xs font-medium text-slate-600 mb-1">Descripción</label>
              <textarea
                value={descripcion}
                onChange={(e) => setDescripcion(e.target.value)}
                placeholder="Opcional"
                rows={2}
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-sky-400"
                disabled={guardando}
              />
            </div>
          )}

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
              disabled={guardando || !nombre.trim()}
              className="rounded-md bg-sky-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-sky-700 disabled:opacity-50"
            >
              {guardando ? "Guardando…" : "Crear"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
