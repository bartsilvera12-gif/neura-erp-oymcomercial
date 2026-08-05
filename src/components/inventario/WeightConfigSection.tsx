"use client";

/**
 * Sección "Controlado por peso" para el form de producto (nuevo y editar).
 *
 * Cuando `controlado_por_peso` está activo:
 *  - La unidad de medida queda fijada a KG (regla que el backend enforce
 *    con un CHECK y a la que la API castea automáticamente).
 *  - Aparecen los checkboxes de modalidades y sus precios por kg.
 *  - Al menos una modalidad debe estar activa con precio > 0 antes de guardar.
 *
 * Al apagar el flag, se limpian los precios y las modalidades desde el
 * componente padre — así el reset queda alineado con lo que hace la API.
 */
import MontoInput from "@/components/ui/MontoInput";
import { MODALIDADES_PESO, MODALIDAD_LABEL, type ModalidadPeso } from "@/lib/inventario/types";

export interface WeightConfigValue {
  controlado_por_peso: boolean;
  precio_kg_entero: number | null;
  precio_kg_recortado: number | null;
  modalidades_activas: ModalidadPeso[];
}

export function emptyWeightConfig(): WeightConfigValue {
  return {
    controlado_por_peso: false,
    precio_kg_entero: null,
    precio_kg_recortado: null,
    modalidades_activas: [],
  };
}

export function WeightConfigSection({
  value,
  onChange,
  className = "",
}: {
  value: WeightConfigValue;
  onChange: (next: WeightConfigValue) => void;
  className?: string;
}) {
  const activo = value.controlado_por_peso;

  function toggleActivo(next: boolean) {
    if (!next) {
      // Apagar: limpiar todo para no dejar restos que confundan al guardar.
      onChange({
        controlado_por_peso: false,
        precio_kg_entero: null,
        precio_kg_recortado: null,
        modalidades_activas: [],
      });
      return;
    }
    onChange({
      ...value,
      controlado_por_peso: true,
      // Default útil: se prende "entero" para que el chip aparezca desde el primer click.
      modalidades_activas: value.modalidades_activas.length > 0 ? value.modalidades_activas : ["entero"],
    });
  }

  function toggleModalidad(m: ModalidadPeso, checked: boolean) {
    const set = new Set(value.modalidades_activas);
    if (checked) set.add(m);
    else set.delete(m);
    const modalidades = MODALIDADES_PESO.filter((x) => set.has(x));
    // Si sacan "entero" o "recortado", limpio el precio correspondiente
    // para no guardar un residuo que confunda al validador del server.
    onChange({
      ...value,
      modalidades_activas: modalidades,
      precio_kg_entero: modalidades.includes("entero") ? value.precio_kg_entero : null,
      precio_kg_recortado: modalidades.includes("recortado") ? value.precio_kg_recortado : null,
    });
  }

  const inputClass =
    "w-full border border-slate-200 rounded-lg px-3 py-2 outline-none focus:ring-2 focus:ring-[#0EA5E9] focus:outline-none bg-white text-sm";
  const labelClass = "block text-sm font-medium text-slate-700 mb-2";

  return (
    <div className={`rounded-xl border border-slate-200 bg-slate-50/40 p-5 ${className}`}>
      <label className="flex items-start gap-3 cursor-pointer">
        <input
          type="checkbox"
          checked={activo}
          onChange={(e) => toggleActivo(e.target.checked)}
          className="mt-0.5 h-4 w-4 rounded border-slate-300 text-sky-600 focus:ring-sky-500"
        />
        <div className="flex-1 min-w-0">
          <div className="text-sm font-semibold text-slate-900">
            Controlado por peso <span className="ml-1 text-xs font-normal text-slate-500">(KG)</span>
          </div>
          <p className="mt-0.5 text-xs text-slate-500 leading-snug">
            El producto se compra y se vende por kilogramos. La caja abre un modal
            de peso al agregar al carrito y permite elegir la modalidad de venta
            (entero o recortado/feteado), con precios por kg distintos sobre el
            mismo stock.
          </p>
        </div>
      </label>

      {activo && (
        <div className="mt-4 space-y-4 border-t border-slate-200 pt-4">
          <div>
            <p className="text-xs uppercase tracking-wide font-semibold text-slate-500 mb-2">
              Modalidades habilitadas
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {MODALIDADES_PESO.map((m) => {
                const checked = value.modalidades_activas.includes(m);
                return (
                  <label
                    key={m}
                    className={`flex items-center gap-2 rounded-lg border px-3 py-2 cursor-pointer transition-colors ${
                      checked ? "border-sky-300 bg-sky-50/60" : "border-slate-200 hover:border-slate-300"
                    }`}
                  >
                    <input
                      type="checkbox"
                      checked={checked}
                      onChange={(e) => toggleModalidad(m, e.target.checked)}
                      className="h-4 w-4 rounded border-slate-300 text-sky-600 focus:ring-sky-500"
                    />
                    <span className="text-sm font-medium text-slate-800">{MODALIDAD_LABEL[m]}</span>
                  </label>
                );
              })}
            </div>
            {value.modalidades_activas.length === 0 && (
              <p className="mt-2 text-xs text-rose-600">
                Marcá al menos una modalidad para poder guardar.
              </p>
            )}
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {value.modalidades_activas.includes("entero") && (
              <div>
                <label className={labelClass}>
                  Precio por kg — Entero <span className="text-rose-500">*</span>
                </label>
                <MontoInput
                  value={value.precio_kg_entero ?? 0}
                  onChange={(n) => onChange({ ...value, precio_kg_entero: n > 0 ? n : null })}
                  placeholder="Ej: 60.000"
                  className={inputClass}
                  decimals={false}
                />
              </div>
            )}
            {value.modalidades_activas.includes("recortado") && (
              <div>
                <label className={labelClass}>
                  Precio por kg — Recortado / feteado <span className="text-rose-500">*</span>
                </label>
                <MontoInput
                  value={value.precio_kg_recortado ?? 0}
                  onChange={(n) => onChange({ ...value, precio_kg_recortado: n > 0 ? n : null })}
                  placeholder="Ej: 48.000"
                  className={inputClass}
                  decimals={false}
                />
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
