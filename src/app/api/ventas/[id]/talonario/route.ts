import { NextRequest, NextResponse } from "next/server";
import { getTenantSupabaseFromAuth } from "@/lib/supabase/tenant-api";
import { numeroALetras } from "@/lib/recibos/numero-a-letras";

/**
 * GET /api/ventas/[id]/talonario?auto=1
 *
 * Autocompletado sobre talonario pre-impreso (Comercial O&M) — el papel ya
 * trae el marco, timbrado, RUC del emisor y número de factura, y nosotros
 * pintamos SÓLO los datos variables en las posiciones exactas de cada celda.
 *
 * Papel: 21 cm × 19 cm (custom). Impresora: Epson matricial (LX-350) con
 * papel autocopiativo — imprime original + copia amarilla en una sola pasada.
 *
 * Calibración: el layout arranca con offsets estimados de la foto plana.
 * El operador ajusta con Alt+↑↓←→ (paso 1mm) y Alt+R para reset. Los offsets
 * quedan guardados en localStorage por PC bajo `neura.talonario.offset`.
 */

type ItemRow = {
  producto_nombre: string;
  sku: string;
  cantidad: number;
  precio_venta: number;
  total_linea: number;
  modalidad: string | null;
  unidad_venta: string | null;
  precio_unitario_display: number | null;
  tipo_iva: string | null;
};

type VentaRow = {
  id: string;
  numero_control: string;
  fecha: string;
  subtotal: number;
  monto_iva: number;
  total: number;
  tipo_venta: string;
  cliente_id: string | null;
  cliente_razon_social: string | null;
  cliente_ruc: string | null;
  nota_remision_numero: string | null;
  moneda: string;
};

function escapeHtml(s: string | number | null | undefined): string {
  return String(s ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function formatNumero(n: number): string {
  return Math.round(Number(n) || 0).toLocaleString("es-PY");
}

function formatCantidad(n: number, esPeso: boolean): string {
  const v = Number(n) || 0;
  if (esPeso) return v.toFixed(3).replace(/\.?0+$/, "");
  return String(Math.round(v));
}

/** Divide los items en 3 columnas según tipo_iva (EXENTA / 5% / 10%).
 *  El talonario tiene columnas separadas — cada línea va en UNA sola. */
function montoPorColumna(it: ItemRow): { exentas: number; iva5: number; iva10: number } {
  const total = Number(it.total_linea) || 0;
  const tipo = (it.tipo_iva ?? "").toUpperCase();
  if (tipo === "EXENTA") return { exentas: total, iva5: 0, iva10: 0 };
  if (tipo === "5%") return { exentas: 0, iva5: total, iva10: 0 };
  return { exentas: 0, iva5: 0, iva10: total };
}

function renderTalonario(venta: VentaRow, items: ItemRow[]): string {
  const fecha = new Date(venta.fecha);
  const dd = String(fecha.getDate()).padStart(2, "0");
  const mm = String(fecha.getMonth() + 1).padStart(2, "0");
  const yy = String(fecha.getFullYear()).slice(-2);

  const esContado = String(venta.tipo_venta).toUpperCase() === "CONTADO";
  const razonSocial = venta.cliente_razon_social ?? "";
  const ruc = venta.cliente_ruc ?? "";
  const notaRem = venta.nota_remision_numero ?? "";

  // Totales por columna (mientras corremos el detalle)
  let subExentas = 0, sub5 = 0, sub10 = 0;
  const filasHtml: string[] = [];
  const MAX_FILAS = 12;

  for (let i = 0; i < Math.min(items.length, MAX_FILAS); i++) {
    const it = items[i]!;
    const esPeso = (it.modalidad ?? "") !== "" || (it.unidad_venta ?? "").toUpperCase() === "KG";
    const cant = formatCantidad(Number(it.cantidad), esPeso);
    const unidad = esPeso ? " KG" : "";
    const precio = Number(it.precio_unitario_display ?? it.precio_venta) || 0;
    const mm = montoPorColumna(it);
    subExentas += mm.exentas; sub5 += mm.iva5; sub10 += mm.iva10;
    filasHtml.push(`
      <div class="row row-${i}">
        <span class="c-cant">${escapeHtml(cant)}${escapeHtml(unidad)}</span>
        <span class="c-desc">${escapeHtml(it.producto_nombre)}</span>
        <span class="c-precio">${formatNumero(precio)}</span>
        <span class="c-exentas">${mm.exentas > 0 ? formatNumero(mm.exentas) : ""}</span>
        <span class="c-iva5">${mm.iva5 > 0 ? formatNumero(mm.iva5) : ""}</span>
        <span class="c-iva10">${mm.iva10 > 0 ? formatNumero(mm.iva10) : ""}</span>
      </div>`);
  }

  const totalPagar = Number(venta.total) || 0;
  // Liquidación del IVA: monto contenido dentro del precio con IVA.
  //   IVA 10% incluido → monto/11
  //   IVA 5%  incluido → monto/21
  const liq5 = Math.round(sub5 / 21);
  const liq10 = Math.round(sub10 / 11);
  const totalIva = liq5 + liq10;
  const letras = numeroALetras(totalPagar) + " GUARANÍES";

  // Layout absoluto en mm. Coordenadas iniciales estimadas de la foto plana
  // (21×19cm). Se calibran con el modo ajuste. Todos los top/left son mm.
  const html = `<!DOCTYPE html>
<html lang="es"><head>
<meta charset="utf-8" />
<title>Talonario · ${escapeHtml(venta.numero_control)}</title>
<style>
  @page { size: 210mm 190mm; margin: 0; }
  html, body { margin: 0; padding: 0; background: #fff; }
  body { font-family: "Consolas", "Courier New", monospace; color: #000; font-size: 10.5pt; }

  /* Contenedor: 210×190mm. Todo lo que va sobre el papel se posiciona en mm
     absolutos dentro de este contenedor. */
  .sheet {
    position: relative;
    width: 210mm;
    height: 190mm;
    box-sizing: border-box;
    /* Offset global aplicado por JS para calibrar (translate en mm). */
    transform: translate(0, 0);
    transform-origin: top left;
  }

  .f { position: absolute; white-space: nowrap; }
  .bold { font-weight: 700; }

  /* — Fecha (San Lorenzo, __/__/__ del 20__) — */
  .f-fecha-dd { top: 57mm; left: 32mm; }
  .f-fecha-mm { top: 57mm; left: 41mm; }
  .f-fecha-yy { top: 57mm; left: 66mm; }

  /* — Cond de Venta: X sobre CONTADO o CREDITO — */
  .f-contado { top: 57mm; left: 147mm; }
  .f-credito { top: 57mm; left: 165mm; }

  /* — Nombre / Razón Social — */
  .f-razon { top: 68mm; left: 42mm; max-width: 90mm; overflow: hidden; }

  /* — Nota de Remisión Nº — */
  .f-nrem { top: 68mm; left: 165mm; max-width: 35mm; overflow: hidden; }

  /* — RUC del cliente — */
  .f-ruc { top: 78mm; left: 30mm; max-width: 90mm; overflow: hidden; }

  /* — Tabla de items —
     El primer row arranca en y=97mm. Cada fila mide 5.4mm. Columnas:
       CANT      x=8mm    (10mm ancho, alineado izq)
       DESC      x=22mm   (85mm ancho)
       PRECIO    x=112mm  (16mm, alineado der)
       EXENTAS   x=133mm  (14mm, alineado der)
       5%        x=155mm  (14mm, alineado der)
       10%       x=178mm  (18mm, alineado der)
  */
  .items { position: absolute; top: 97mm; left: 0; right: 0; }
  .row { position: relative; height: 5.4mm; }
  .row > span { position: absolute; top: 0; font-size: 10pt; }
  .c-cant    { left: 8mm; }
  .c-desc    { left: 22mm; max-width: 85mm; overflow: hidden; }
  .c-precio  { left: 112mm; width: 18mm; text-align: right; }
  .c-exentas { left: 133mm; width: 17mm; text-align: right; }
  .c-iva5    { left: 155mm; width: 17mm; text-align: right; }
  .c-iva10   { left: 178mm; width: 22mm; text-align: right; }

  /* — SUB-TOTALES (fila) — */
  .f-sub-exentas { top: 163mm; left: 133mm; width: 17mm; text-align: right; }
  .f-sub-5       { top: 163mm; left: 155mm; width: 17mm; text-align: right; }
  .f-sub-10      { top: 163mm; left: 178mm; width: 22mm; text-align: right; }

  /* — TOTAL A PAGAR (importe en letras + número) — */
  .f-letras      { top: 170mm; left: 42mm; max-width: 130mm; overflow: hidden; font-size: 9.5pt; }
  .f-total       { top: 170mm; left: 178mm; width: 22mm; text-align: right; font-weight: 700; }

  /* — LIQUIDACIÓN DEL IVA (5% / 10% / Total IVA) — */
  .f-liq5     { top: 178mm; left: 47mm; width: 20mm; text-align: right; }
  .f-liq10    { top: 178mm; left: 85mm; width: 20mm; text-align: right; }
  .f-totiva   { top: 178mm; left: 178mm; width: 22mm; text-align: right; font-weight: 700; }

  /* — Panel de calibración (solo pantalla) — */
  #cal {
    position: fixed; top: 8px; right: 8px; z-index: 9999;
    background: #111; color: #fff; padding: 8px 10px; border-radius: 6px;
    font: 11px/1.4 -apple-system, Segoe UI, Roboto, sans-serif;
    box-shadow: 0 2px 10px rgba(0,0,0,.3); user-select: none;
    max-width: 260px;
  }
  #cal b { color: #4FAEB2; }
  #cal button { background:#333; color:#fff; border:1px solid #555; border-radius:4px; padding:2px 6px; margin: 2px 2px 0 0; cursor:pointer; font-size:11px;}
  #cal button:hover { background:#444; }
  @media print { #cal { display: none !important; } }
</style>
</head>
<body>
  <div id="cal">
    <div><b>Calibración talonario</b></div>
    <div>Alt+↑↓←→ mueve todo 1mm · Alt+Shift+flecha 0.2mm · Alt+R reset · Alt+P imprimir</div>
    <div style="margin-top:4px">Offset: <span id="calXY">0, 0</span> mm</div>
    <div style="margin-top:4px">
      <button id="calDec">−1mm ↑</button>
      <button id="calInc">+1mm ↓</button>
      <button id="calReset">Reset</button>
      <button id="calPrint">Imprimir</button>
    </div>
  </div>

  <div class="sheet" id="sheet">
    <div class="f f-fecha-dd">${escapeHtml(dd)}</div>
    <div class="f f-fecha-mm">${escapeHtml(mm)}</div>
    <div class="f f-fecha-yy">${escapeHtml(yy)}</div>

    ${esContado ? '<div class="f f-contado bold">X</div>' : ''}
    ${!esContado ? '<div class="f f-credito bold">X</div>' : ''}

    <div class="f f-razon">${escapeHtml(razonSocial)}</div>
    <div class="f f-nrem">${escapeHtml(notaRem)}</div>
    <div class="f f-ruc">${escapeHtml(ruc)}</div>

    <div class="items">${filasHtml.join("")}</div>

    <div class="f f-sub-exentas">${subExentas > 0 ? formatNumero(subExentas) : "0"}</div>
    <div class="f f-sub-5">${sub5 > 0 ? formatNumero(sub5) : "0"}</div>
    <div class="f f-sub-10">${sub10 > 0 ? formatNumero(sub10) : "0"}</div>

    <div class="f f-letras">${escapeHtml(letras)}</div>
    <div class="f f-total">${formatNumero(totalPagar)}</div>

    <div class="f f-liq5">${liq5 > 0 ? formatNumero(liq5) : "0"}</div>
    <div class="f f-liq10">${liq10 > 0 ? formatNumero(liq10) : "0"}</div>
    <div class="f f-totiva">${formatNumero(totalIva)}</div>
  </div>

<script>
(function(){
  var KEY = "neura.talonario.offset";
  var el = document.getElementById("sheet");
  var out = document.getElementById("calXY");
  var stored = (function(){
    try { return JSON.parse(localStorage.getItem(KEY) || "{}"); } catch(e) { return {}; }
  })();
  var x = Number(stored.x) || 0;
  var y = Number(stored.y) || 0;
  function apply(){
    el.style.transform = "translate(" + x + "mm, " + y + "mm)";
    out.textContent = x.toFixed(1) + ", " + y.toFixed(1);
    try { localStorage.setItem(KEY, JSON.stringify({x: x, y: y})); } catch(e){}
  }
  function nudge(dx, dy){ x += dx; y += dy; apply(); }
  document.addEventListener("keydown", function(e){
    if (!e.altKey) return;
    var step = e.shiftKey ? 0.2 : 1;
    if (e.key === "ArrowLeft")  { nudge(-step, 0); e.preventDefault(); }
    else if (e.key === "ArrowRight") { nudge(step, 0); e.preventDefault(); }
    else if (e.key === "ArrowUp")    { nudge(0, -step); e.preventDefault(); }
    else if (e.key === "ArrowDown")  { nudge(0, step);  e.preventDefault(); }
    else if (e.key === "r" || e.key === "R") { x = 0; y = 0; apply(); e.preventDefault(); }
    else if (e.key === "p" || e.key === "P") { window.print(); e.preventDefault(); }
  });
  document.getElementById("calInc").onclick = function(){ nudge(0, 1); };
  document.getElementById("calDec").onclick = function(){ nudge(0, -1); };
  document.getElementById("calReset").onclick = function(){ x=0; y=0; apply(); };
  document.getElementById("calPrint").onclick = function(){ window.print(); };
  apply();
  try {
    if (new URL(location.href).searchParams.get("auto") === "1") setTimeout(function(){ window.print(); }, 300);
  } catch(e){}
})();
</script>
</body></html>`;
  return html;
}

export async function GET(request: NextRequest, ctxParams: { params: Promise<{ id: string }> }) {
  const { id } = await ctxParams.params;
  const ctx = await getTenantSupabaseFromAuth(request);
  if (!ctx) return new NextResponse("No autorizado", { status: 401 });
  const empresaId = ctx.auth.empresa_id;

  const vQ = await ctx.supabase
    .from("ventas")
    .select("id, numero_control, fecha, subtotal, monto_iva, total, tipo_venta, cliente_id, cliente_razon_social, cliente_ruc, nota_remision_numero, moneda")
    .eq("id", id)
    .eq("empresa_id", empresaId)
    .maybeSingle();
  if (vQ.error) return new NextResponse(`Error: ${vQ.error.message}`, { status: 500 });
  if (!vQ.data) return new NextResponse("Venta no encontrada", { status: 404 });
  const venta = vQ.data as unknown as VentaRow;

  // Fallback: si la venta no tiene snapshot (ventas anteriores a la migración),
  // busca la razón social / RUC en la factura ERP o en la ficha del cliente.
  if (!venta.cliente_razon_social || !venta.cliente_ruc) {
    if (venta.cliente_id) {
      const cQ = await ctx.supabase
        .from("clientes")
        .select("empresa, nombre, nombre_contacto, nombre_facturacion, ruc")
        .eq("id", venta.cliente_id)
        .eq("empresa_id", empresaId)
        .maybeSingle();
      const c = cQ.data as Record<string, string | null> | null;
      if (c) {
        const s = (v: string | null | undefined) =>
          typeof v === "string" && v.trim() ? v.trim() : null;
        venta.cliente_razon_social = venta.cliente_razon_social ??
          (s(c.nombre_facturacion) || s(c.empresa) || s(c.nombre_contacto) || s(c.nombre));
        venta.cliente_ruc = venta.cliente_ruc ?? s(c.ruc);
      }
    }
    if (!venta.cliente_razon_social || !venta.cliente_ruc) {
      const fQ = await ctx.supabase
        .from("facturas")
        .select("cliente_razon_social, cliente_ruc")
        .eq("origen_venta_id", id)
        .eq("empresa_id", empresaId)
        .limit(1)
        .maybeSingle();
      const f = fQ.data as { cliente_razon_social: string | null; cliente_ruc: string | null } | null;
      if (f) {
        venta.cliente_razon_social = venta.cliente_razon_social ?? f.cliente_razon_social;
        venta.cliente_ruc = venta.cliente_ruc ?? f.cliente_ruc;
      }
    }
  }

  const iQ = await ctx.supabase
    .from("ventas_items")
    .select("producto_nombre, sku, cantidad, precio_venta, total_linea, modalidad, unidad_venta, precio_unitario_display, tipo_iva")
    .eq("venta_id", id)
    .eq("empresa_id", empresaId);
  if (iQ.error) return new NextResponse(`Error items: ${iQ.error.message}`, { status: 500 });
  const items = (iQ.data ?? []) as unknown as ItemRow[];

  const html = renderTalonario(venta, items);
  return new NextResponse(html, {
    status: 200,
    headers: { "Content-Type": "text/html; charset=utf-8" },
  });
}
