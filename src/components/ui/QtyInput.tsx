"use client";

/**
 * Input numérico con "buffer local" para cantidades editables.
 *
 * Motivación: cuando `value` viene del estado del carrito (ej: `cantidad = 1`)
 * y usamos un <input value={cantidad}> controlado, borrar el "1" no funciona:
 * la próxima render restaura el "1" y no se puede tipear un número distinto
 * sin seleccionar todo primero. Este componente mantiene una copia del texto
 * como string mientras el input tiene foco, y sincroniza con `value` sólo
 * cuando cambia externamente y no está siendo editado. Al perder foco (o al
 * apretar Enter), si el texto es inválido, se restaura al `min`.
 */

import { useEffect, useRef, useState } from "react";

export function QtyInput({
  value,
  onChange,
  min = 1,
  step = 1,
  className = "",
  autoSelectOnFocus = true,
}: {
  value: number;
  onChange: (n: number) => void;
  min?: number;
  /** 1 → integer; usar "any" o 0.001 para decimales (kg). */
  step?: number | "any";
  className?: string;
  autoSelectOnFocus?: boolean;
}) {
  const [text, setText] = useState<string>(String(value));
  const [editing, setEditing] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  // Sincronizar con el valor externo cuando NO estamos editando
  // (ej: se presionó +/- o se sumó por buscador).
  useEffect(() => {
    if (!editing) setText(String(value));
  }, [value, editing]);

  return (
    <input
      ref={inputRef}
      type="number"
      min={min}
      step={step}
      value={text}
      onFocus={(e) => {
        setEditing(true);
        if (autoSelectOnFocus) e.currentTarget.select();
      }}
      onChange={(e) => {
        const raw = e.target.value;
        setText(raw);
        // Commit al carrito solo si el número es válido; el texto vacío
        // queda como buffer visual hasta que la persona termine de tipear.
        if (raw === "") return;
        const n = step === 1 ? parseInt(raw, 10) : Number(raw);
        if (Number.isFinite(n) && n >= min) onChange(n);
      }}
      onBlur={(e) => {
        setEditing(false);
        const raw = e.target.value;
        const n = step === 1 ? parseInt(raw, 10) : Number(raw);
        if (!Number.isFinite(n) || n < min) {
          onChange(min);
          setText(String(min));
        } else {
          setText(String(n));
        }
      }}
      onKeyDown={(e) => {
        if (e.key === "Enter") inputRef.current?.blur();
      }}
      className={className}
    />
  );
}
