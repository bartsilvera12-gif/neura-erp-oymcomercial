"use client";

/**
 * Bloque "Datos de la venta" para el POS de Caja. Versión simplificada:
 * NO tiene buscador de clientes — para facturar alcanza con escribir la
 * razón social y (opcionalmente) el RUC. No hace falta crear una ficha de
 * cliente por cada venta.
 *
 *   - Condición: Contado / Crédito. Crédito exige razón social + plazo ≥ 1
 *     día; en el cobro genera CxC identificada por la razón social.
 *   - Documento: Solo ticket / Factura. Factura exige razón social; RUC
 *     opcional (sin RUC se factura como consumidor final).
 *
 * Los datos ingresados viajan al server como snapshot (`cliente_razon_social`
 * y `cliente_ruc` de la venta). NO se crea ni se busca cliente en el
 * catálogo. Si más adelante quieren asociar con una ficha, se hace desde
 * /ventas/nueva o desde el módulo Clientes.
 */
import { useState } from "react";

export type CondicionVenta = "CONTADO" | "CREDITO";
export type TipoDocumento = "ticket" | "factura";

export interface DatosVentaState {
  condicion: CondicionVenta;
  plazoDias: string;
  documento: TipoDocumento;
  razonSocial: string;
  rucFactura: string;
}

export function emptyDatosVenta(): DatosVentaState {
  return {
    condicion: "CONTADO",
    plazoDias: "",
    documento: "ticket",
    razonSocial: "",
    rucFactura: "",
  };
}

/** Validación derivada del estado del bloque. Se usa antes de emitir la venta
 *  para bloquear con mensaje claro sin round-trip al server. */
export function datosVentaErrors(v: DatosVentaState): string | null {
  if (v.documento === "factura" && v.razonSocial.trim().length === 0) {
    return "Ingresá la razón social para poder facturar.";
  }
  if (v.condicion === "CREDITO") {
    if (v.razonSocial.trim().length === 0) {
      return "Ingresá la razón social del deudor para venta a crédito.";
    }
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
  // Mostrar los campos razón social/RUC cuando: factura O crédito. Contado +
  // ticket puede ir sin datos (venta al mostrador sin identificación).
  const necesitaDatosCliente = value.documento === "factura" || value.condicion === "CREDITO";
  const err = datosVentaErrors(value);
  const [dismissedErr, setDismissedErr] = useState(false);

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
        {/* Condición */}
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Condición</label>
          <div className="flex gap-1.5 rounded-lg border border-slate-200 bg-slate-100 p-1">
            <button
              type="button"
              onClick={() => { onChange({ ...value, condicion: "CONTADO", plazoDias: "" }); setDismissedErr(false); }}
              className={segCls(value.condicion === "CONTADO")}
            >
              Contado
            </button>
            <button
              type="button"
              onClick={() => { onChange({ ...value, condicion: "CREDITO" }); setDismissedErr(false); }}
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
                onChange={(e) => { onChange({ ...value, plazoDias: e.target.value }); setDismissedErr(false); }}
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
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Documento</label>
          <div className="flex gap-1.5 rounded-lg border border-slate-200 bg-slate-100 p-1">
            <button
              type="button"
              onClick={() => { onChange({ ...value, documento: "ticket" }); setDismissedErr(false); }}
              className={segCls(value.documento === "ticket")}
            >
              Solo ticket
            </button>
            <button
              type="button"
              onClick={() => { onChange({ ...value, documento: "factura" }); setDismissedErr(false); }}
              className={segCls(value.documento === "factura")}
            >
              Factura
            </button>
          </div>
        </div>

        {/* Razón social + RUC — visible cuando factura o crédito */}
        {necesitaDatosCliente && (
          <div className="lg:col-span-2 grid grid-cols-1 gap-3 sm:grid-cols-2 pt-1">
            <div>
              <label className="block text-xs font-medium text-slate-600 mb-1">
                Razón social <span className="text-rose-500">*</span>
              </label>
              <input
                type="text"
                value={value.razonSocial}
                onChange={(e) => { onChange({ ...value, razonSocial: e.target.value }); setDismissedErr(false); }}
                placeholder="Ej: Juan Pérez"
                className={inputCls}
                autoComplete="off"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-600 mb-1">
                N° de RUC / documento
              </label>
              <input
                type="text"
                value={value.rucFactura}
                onChange={(e) => { onChange({ ...value, rucFactura: e.target.value }); setDismissedErr(false); }}
                placeholder="Ej: 80012345-6"
                className={inputCls}
                autoComplete="off"
              />
            </div>
            <p className="text-[11px] text-slate-500 sm:col-span-2">
              Con la razón social alcanza para facturar — no hace falta crear ficha de cliente.
            </p>
          </div>
        )}
      </div>

      {err && !dismissedErr && (
        <p className="mt-3 rounded-md bg-rose-50 border border-rose-200 px-3 py-2 text-xs text-rose-700">
          {err}
        </p>
      )}
    </div>
  );
}
