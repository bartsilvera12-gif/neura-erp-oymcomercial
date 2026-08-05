"use client";

/**
 * Bloque "Datos de la venta" para el POS de Caja. Réplica compacta del
 * bloque que ya vive en /ventas/nueva/page.tsx pero pensada para la caja
 * rápida:
 *
 *   - Cliente: buscador con dropdown (carga el catálogo una vez al foco;
 *     el POS de una sucursal chica no tiene decenas de miles de clientes).
 *   - Condición: Contado / Crédito. Crédito exige cliente + plazo ≥ 1 día
 *     y en el cobro genera CxC.
 *   - Documento: Solo ticket / Factura. Factura exige razón social; el RUC
 *     es opcional (sin RUC se factura como consumidor final).
 *
 * NO se replicó nota de remisión ni facturación electrónica avanzada — si
 * el vendedor necesita eso, va a /ventas/nueva (flujo completo).
 *
 * El componente es "controlado": el padre pasa `value` y `onChange`. Todo
 * el estado vive arriba (para que confirmarCobro pueda leerlo).
 */
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { fetchWithSupabaseSession } from "@/lib/api/fetch-with-supabase-session";

export type CondicionVenta = "CONTADO" | "CREDITO";
export type TipoDocumento = "ticket" | "factura";

export interface DatosVentaState {
  clienteId: string | null;
  clienteLabel: string | null;
  condicion: CondicionVenta;
  plazoDias: string;
  documento: TipoDocumento;
  razonSocial: string;
  rucFactura: string;
}

export function emptyDatosVenta(): DatosVentaState {
  return {
    clienteId: null,
    clienteLabel: null,
    condicion: "CONTADO",
    plazoDias: "",
    documento: "ticket",
    razonSocial: "",
    rucFactura: "",
  };
}

interface ClienteOpt {
  id: string;
  label: string;
  ruc: string | null;
  razon_social: string | null;
}

function foldTxt(s: string): string {
  return s.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
}

/** Deriva estados de validación que el POS también necesita ver (deshabilitar
 *  botón Cobrar, mostrar alertas). Mismo criterio que /ventas/nueva:
 *   - Factura → cliente_id obligatorio (SIFEN necesita receptor).
 *   - Crédito → cliente_id obligatorio + plazo ≥ 1 día (para CxC).
 *   - Solo ticket + contado → cliente opcional.
 */
export function datosVentaErrors(v: DatosVentaState): string | null {
  if (v.documento === "factura" && !v.clienteId) {
    return "Seleccioná un cliente para poder facturar.";
  }
  if (v.condicion === "CREDITO") {
    if (!v.clienteId) return "La venta a crédito requiere un cliente seleccionado.";
    const p = Number(v.plazoDias);
    if (!Number.isFinite(p) || p < 1) return "Ingresá el plazo de crédito (días).";
  }
  return null;
}

export function DatosVentaHeader({
  value,
  onChange,
}: {
  value: DatosVentaState;
  onChange: (next: DatosVentaState) => void;
}) {
  const [clientes, setClientes] = useState<ClienteOpt[]>([]);
  const [cargandoClientes, setCargandoClientes] = useState(false);
  const [queryCli, setQueryCli] = useState("");
  const [openDrop, setOpenDrop] = useState(false);
  const wrapRef = useRef<HTMLDivElement | null>(null);

  const cargarClientes = useCallback(async () => {
    if (clientes.length > 0) return; // cache simple: 1 vez por vida del componente
    setCargandoClientes(true);
    try {
      const r = await fetchWithSupabaseSession("/api/clientes", { cache: "no-store" });
      const j = await r.json().catch(() => ({}));
      const lista = ((j?.clientes ?? j?.data?.clientes ?? []) as Array<Record<string, unknown>>);
      const opts: ClienteOpt[] = lista.map((c) => {
        const nombre = String(c.nombre_contacto ?? c.nombre ?? c.empresa ?? "");
        const empresa = String(c.empresa ?? "");
        const label = empresa && empresa !== nombre ? `${empresa}${nombre ? ` — ${nombre}` : ""}` : (nombre || empresa || "—");
        return {
          id: String(c.id),
          label,
          ruc: (c.ruc as string | null) ?? null,
          razon_social: (c.nombre_facturacion as string | null) ?? empresa ?? nombre ?? null,
        };
      });
      setClientes(opts);
    } catch (e) {
      console.error("[DatosVentaHeader] cargar clientes", e);
    } finally {
      setCargandoClientes(false);
    }
  }, [clientes.length]);

  // Click afuera cierra el dropdown.
  useEffect(() => {
    if (!openDrop) return;
    function onDoc(e: MouseEvent) {
      if (!wrapRef.current) return;
      if (!wrapRef.current.contains(e.target as Node)) setOpenDrop(false);
    }
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, [openDrop]);

  const filtrados = useMemo(() => {
    const q = foldTxt(queryCli.trim());
    if (!q) return clientes.slice(0, 30);
    return clientes
      .filter((c) => foldTxt(c.label).includes(q) || (c.ruc && c.ruc.includes(q)))
      .slice(0, 30);
  }, [clientes, queryCli]);

  function seleccionarCliente(c: ClienteOpt | null) {
    onChange({
      ...value,
      clienteId: c?.id ?? null,
      clienteLabel: c?.label ?? null,
      // Autocompletar razón social/RUC con lo del cliente si están vacíos —
      // el vendedor puede editarlos igual (algunos clientes facturan a otro
      // nombre puntual, ej. "para mi señora").
      razonSocial: c?.razon_social && !value.razonSocial ? c.razon_social : value.razonSocial,
      rucFactura: c?.ruc && !value.rucFactura ? c.ruc : value.rucFactura,
    });
    setQueryCli("");
    setOpenDrop(false);
  }

  const err = datosVentaErrors(value);
  const inputCls =
    "w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-[#4FAEB2]/30 focus:border-[#4FAEB2]";
  const segCls = (activo: boolean) =>
    `flex-1 rounded-md py-2 text-sm font-medium transition-colors ${
      activo ? "bg-[#4FAEB2] text-white shadow-sm" : "bg-white text-slate-600 hover:bg-slate-50"
    }`;

  return (
    <div className="rounded-2xl border border-slate-200 bg-white shadow-sm p-4">
      <p className="mb-3 text-xs font-semibold uppercase tracking-wider text-slate-500">
        Datos de la venta
      </p>

      <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
        {/* Cliente */}
        <div ref={wrapRef} className="relative">
          <label className="block text-sm font-medium text-slate-700 mb-1">
            Cliente <span className="text-xs font-normal text-slate-400">(opcional)</span>
          </label>
          <div className="flex gap-2">
            <input
              type="text"
              value={value.clienteId ? (value.clienteLabel ?? "") : queryCli}
              onChange={(e) => { seleccionarCliente(null); setQueryCli(e.target.value); setOpenDrop(true); }}
              onFocus={() => { void cargarClientes(); setOpenDrop(true); }}
              placeholder="Buscar por nombre o RUC…"
              className={inputCls}
            />
            {value.clienteId && (
              <button
                type="button"
                onClick={() => seleccionarCliente(null)}
                className="shrink-0 rounded-lg border border-slate-200 px-3 text-xs text-slate-500 hover:bg-slate-50"
              >
                Quitar
              </button>
            )}
          </div>
          {openDrop && !value.clienteId && (
            <div className="absolute z-30 mt-1 w-full max-h-64 overflow-auto rounded-lg border border-slate-200 bg-white shadow-lg">
              {cargandoClientes ? (
                <p className="px-3 py-2 text-xs text-slate-400">Cargando…</p>
              ) : filtrados.length === 0 ? (
                <p className="px-3 py-2 text-xs text-slate-400">Sin clientes que coincidan.</p>
              ) : (
                filtrados.map((c) => (
                  <button
                    key={c.id}
                    type="button"
                    onClick={() => seleccionarCliente(c)}
                    className="block w-full text-left px-3 py-2 text-sm hover:bg-slate-50"
                  >
                    <span className="font-medium text-slate-800">{c.label}</span>
                    {c.ruc && <span className="ml-2 text-xs text-slate-400">RUC {c.ruc}</span>}
                  </button>
                ))
              )}
            </div>
          )}
          <p className="mt-1 text-[11px] text-slate-400">
            Si no seleccionás cliente, la venta se registra sin cliente.
          </p>
        </div>

        {/* Condición */}
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Condición</label>
          <div className="flex gap-1.5 rounded-lg border border-slate-200 bg-slate-100 p-1">
            <button
              type="button"
              onClick={() => onChange({ ...value, condicion: "CONTADO", plazoDias: "" })}
              className={segCls(value.condicion === "CONTADO")}
            >
              Contado
            </button>
            <button
              type="button"
              onClick={() => onChange({ ...value, condicion: "CREDITO" })}
              className={segCls(value.condicion === "CREDITO")}
            >
              Crédito
            </button>
          </div>
          {value.condicion === "CREDITO" && (
            <div className="mt-2">
              <label className="block text-xs font-medium text-slate-600 mb-1">Plazo (días) *</label>
              <input
                type="number"
                min={1}
                value={value.plazoDias}
                onChange={(e) => onChange({ ...value, plazoDias: e.target.value })}
                placeholder="Ej: 30"
                className={inputCls}
              />
              <p className="mt-1 text-[11px] text-slate-500">
                Al confirmar se genera una cuenta por cobrar por el total.
              </p>
            </div>
          )}
        </div>

        {/* Documento */}
        <div className="lg:col-span-2">
          <label className="block text-sm font-medium text-slate-700 mb-1">Documento</label>
          <div className="flex gap-1.5 rounded-lg border border-slate-200 bg-slate-100 p-1">
            <button
              type="button"
              onClick={() => onChange({ ...value, documento: "ticket" })}
              className={segCls(value.documento === "ticket")}
            >
              Solo ticket
            </button>
            <button
              type="button"
              onClick={() => onChange({ ...value, documento: "factura" })}
              className={segCls(value.documento === "factura")}
            >
              Factura
            </button>
          </div>
          {value.documento === "factura" && (
            <div className="mt-3 grid grid-cols-1 gap-3 sm:grid-cols-2">
              <div>
                <label className="block text-xs font-medium text-slate-600 mb-1">
                  Razón social *
                </label>
                <input
                  type="text"
                  value={value.razonSocial}
                  onChange={(e) => onChange({ ...value, razonSocial: e.target.value })}
                  placeholder="Ej: Juan Pérez"
                  className={inputCls}
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-slate-600 mb-1">N° de RUC</label>
                <input
                  type="text"
                  value={value.rucFactura}
                  onChange={(e) => onChange({ ...value, rucFactura: e.target.value })}
                  placeholder="Ej: 80012345-6"
                  className={inputCls}
                />
              </div>
              <p className="text-[11px] text-slate-500 sm:col-span-2">
                No hace falta ficha de cliente: con la razón social alcanza para facturar.
              </p>
            </div>
          )}
        </div>
      </div>

      {err && (
        <p className="mt-3 rounded-md bg-rose-50 border border-rose-200 px-3 py-2 text-xs text-rose-700">
          {err}
        </p>
      )}
    </div>
  );
}
