import { NextRequest, NextResponse } from "next/server";
import { PDFDocument, StandardFonts, rgb, type PDFFont, type PDFPage } from "pdf-lib";
import { getTenantSupabaseFromAuth } from "@/lib/supabase/tenant-api";
import { numeroALetras } from "@/lib/recibos/numero-a-letras";

/**
 * GET /api/ventas/[id]/talonario?dx=0&dy=0
 *
 * Autocompletado sobre talonario pre-impreso Comercial O&M (21×19cm) —
 * el papel ya trae el marco / timbrado / RUC del emisor / Nº de factura;
 * este endpoint pinta SÓLO los datos variables (fecha, razón social,
 * RUC del cliente, marca CONTADO/CRÉDITO, filas de items separadas por
 * IVA, sub-totales, total, liquidación IVA, importe en letras).
 *
 * Se genera un **PDF binario de 210×190mm** con pdf-lib en vez de HTML.
 * Motivación: el HTML+window.print() dependía del usuario configurando
 * "Márgenes: Ninguno" y desactivando encabezados en Chrome. Con PDF, el
 * visor imprime "Tamaño real" por defecto y no hay margen que corrompa
 * la posición. El operador solo apreta el icono de impresora del visor.
 *
 * Calibración: query params `dx` y `dy` (en mm, admite decimales y
 * negativos) desplazan TODO el layout. Ej: `?dx=2&dy=-1` corre 2mm a
 * la derecha y 1mm arriba. Se pueden guardar como bookmark.
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
  total: number;
  tipo_venta: string;
  cliente_id: string | null;
  cliente_razon_social: string | null;
  cliente_ruc: string | null;
  nota_remision_numero: string | null;
};

// ── Layout (mm desde el borde superior-izquierdo del papel) ────────────
// El driver de la Epson LX-350 en serveroym está configurado con papel
// tamaño CARTA (216×279mm portrait) — así lo dejó el facturador viejo que
// venían usando. Chrome PDF viewer imprime "Tamaño real" solo si el PDF
// coincide con el papel del driver; si no coincide, rota/escala/centra
// y descoloca todo. Por eso el PDF también es Carta portrait: el layout
// del talonario ocupa los primeros 190mm de altura y 210mm de ancho
// (arriba a la izquierda), que es donde cae el papel físico del talonario
// cuando se carga alineado al margen superior-izquierdo. La Epson
// imprime esos 190mm y avanza el resto en vacío (comportamiento normal
// con carta + hoja suelta más corta).
const PAGE_W_MM = 216;  // Carta portrait: ancho
const PAGE_H_MM = 279;  // Carta portrait: alto (el talonario ocupa solo los primeros 190mm)

// Fecha "San Lorenzo, DD  MM  del 20 YY"
const FECHA_Y = 47;
const FECHA_DD_X = 52;
const FECHA_MM_X = 66;
const FECHA_YY_X = 92;

// Cond. de Venta (X sobre CONTADO o CREDITO)
const CONTADO_X = 149;
const CREDITO_X = 176;
const COND_Y = 47;

// Nota de Remisión Nº
const NREM_X = 168;
const NREM_Y = 58;

// Nombre o Razón Social
const RAZON_X = 55;
const RAZON_Y = 64;

// RUC del cliente
const RUC_X = 30;
const RUC_Y = 74;

// Tabla de items — primer row + fila
const TABLE_Y_FIRST = 91;
const ROW_H = 7;
const MAX_ROWS = 6;

// Columnas (X del texto; c-precio / c-* alineados a la derecha del X_END)
const COL_CANT_X = 12; // izquierda
const COL_DESC_X = 30; // izquierda
const COL_PRECIO_X_END = 131; // derecha
const COL_EXENTAS_X_END = 150; // derecha
const COL_IVA5_X_END = 171; // derecha
const COL_IVA10_X_END = 205; // derecha

// SUB-TOTALES (fila)
const SUB_Y = 143;
const SUB_EXENTAS_X_END = COL_EXENTAS_X_END;
const SUB_IVA5_X_END = COL_IVA5_X_END;
const SUB_IVA10_X_END = COL_IVA10_X_END;

// TOTAL A PAGAR (importe en letras + número)
const TOTAL_Y = 152;
const LETRAS_X = 42;
const TOTAL_X_END = COL_IVA10_X_END;

// LIQUIDACIÓN DEL IVA (5% / 10% / TOTAL IVA)
const LIQ_Y = 162;
const LIQ5_X_END = 82;
const LIQ10_X_END = 122;
const TOTIVA_X_END = COL_IVA10_X_END;

const MM_TO_PT = 2.834645669;
const mm = (v: number) => v * MM_TO_PT;

function formatNumero(n: number): string {
  return Math.round(Number(n) || 0).toLocaleString("es-PY");
}
function formatCantidad(n: number, esPeso: boolean): string {
  const v = Number(n) || 0;
  if (esPeso) return v.toFixed(3).replace(/\.?0+$/, "");
  return String(Math.round(v));
}
function truncate(s: string, max: number): string {
  return s.length > max ? s.slice(0, max - 1) + "…" : s;
}

function montoPorColumna(it: ItemRow): { exentas: number; iva5: number; iva10: number } {
  const total = Number(it.total_linea) || 0;
  const tipo = (it.tipo_iva ?? "").toUpperCase();
  if (tipo === "EXENTA") return { exentas: total, iva5: 0, iva10: 0 };
  if (tipo === "5%") return { exentas: 0, iva5: total, iva10: 0 };
  return { exentas: 0, iva5: 0, iva10: total };
}

// ── Helpers de dibujo (origen top-left en mm) ───────────────────────────
function drawText(
  page: PDFPage,
  text: string,
  xMm: number,
  yMmFromTop: number,
  font: PDFFont,
  size = 9
) {
  if (!text) return;
  page.drawText(text, {
    x: mm(xMm),
    y: mm(PAGE_H_MM - yMmFromTop) - size * 0.35, // baseline compensada
    size,
    font,
    color: rgb(0, 0, 0),
  });
}
function drawTextRight(
  page: PDFPage,
  text: string,
  xMmRightEdge: number,
  yMmFromTop: number,
  font: PDFFont,
  size = 9
) {
  if (!text) return;
  const w = font.widthOfTextAtSize(text, size);
  page.drawText(text, {
    x: mm(xMmRightEdge) - w,
    y: mm(PAGE_H_MM - yMmFromTop) - size * 0.35,
    size,
    font,
    color: rgb(0, 0, 0),
  });
}

async function buildTalonarioPdf(venta: VentaRow, items: ItemRow[], dxMm: number, dyMm: number): Promise<Uint8Array> {
  const pdfDoc = await PDFDocument.create();
  const page = pdfDoc.addPage([mm(PAGE_W_MM), mm(PAGE_H_MM)]);
  const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
  const fontBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

  // Ajuste global
  const OX = dxMm;
  const OY = dyMm;
  const t = (page: PDFPage, txt: string, x: number, y: number, f = font, s = 9) =>
    drawText(page, txt, x + OX, y + OY, f, s);
  const tR = (page: PDFPage, txt: string, xEnd: number, y: number, f = font, s = 9) =>
    drawTextRight(page, txt, xEnd + OX, y + OY, f, s);

  // Fecha
  const fecha = new Date(venta.fecha);
  const dd = String(fecha.getDate()).padStart(2, "0");
  const mmStr = String(fecha.getMonth() + 1).padStart(2, "0");
  const yy = String(fecha.getFullYear()).slice(-2);
  t(page, dd, FECHA_DD_X, FECHA_Y);
  t(page, mmStr, FECHA_MM_X, FECHA_Y);
  t(page, yy, FECHA_YY_X, FECHA_Y);

  // Cond. de Venta
  const esContado = String(venta.tipo_venta).toUpperCase() === "CONTADO";
  t(page, "X", esContado ? CONTADO_X : CREDITO_X, COND_Y, fontBold, 11);

  // Nota Remisión Nº
  if (venta.nota_remision_numero) t(page, venta.nota_remision_numero, NREM_X, NREM_Y);

  // Nombre o Razón Social
  t(page, truncate(venta.cliente_razon_social ?? "", 60), RAZON_X, RAZON_Y);

  // RUC
  t(page, venta.cliente_ruc ?? "", RUC_X, RUC_Y);

  // Filas de items
  let subExentas = 0, sub5 = 0, sub10 = 0;
  const N = Math.min(items.length, MAX_ROWS);
  for (let i = 0; i < N; i++) {
    const it = items[i]!;
    const rowY = TABLE_Y_FIRST + i * ROW_H;
    const esPeso = (it.modalidad ?? "") !== "" || (it.unidad_venta ?? "").toUpperCase() === "KG";
    const cant = formatCantidad(Number(it.cantidad), esPeso);
    const unidad = esPeso ? " KG" : "";
    const precio = Number(it.precio_unitario_display ?? it.precio_venta) || 0;
    const mmCol = montoPorColumna(it);
    subExentas += mmCol.exentas; sub5 += mmCol.iva5; sub10 += mmCol.iva10;

    t(page, `${cant}${unidad}`, COL_CANT_X, rowY);
    t(page, truncate(it.producto_nombre, 38), COL_DESC_X, rowY);
    tR(page, formatNumero(precio), COL_PRECIO_X_END, rowY);
    if (mmCol.exentas > 0) tR(page, formatNumero(mmCol.exentas), COL_EXENTAS_X_END, rowY);
    if (mmCol.iva5 > 0) tR(page, formatNumero(mmCol.iva5), COL_IVA5_X_END, rowY);
    if (mmCol.iva10 > 0) tR(page, formatNumero(mmCol.iva10), COL_IVA10_X_END, rowY);
  }

  // Sub-totales
  tR(page, formatNumero(subExentas), SUB_EXENTAS_X_END, SUB_Y);
  tR(page, formatNumero(sub5), SUB_IVA5_X_END, SUB_Y);
  tR(page, formatNumero(sub10), SUB_IVA10_X_END, SUB_Y);

  // Total a pagar
  const totalPagar = Number(venta.total) || 0;
  t(page, truncate(numeroALetras(totalPagar) + " GUARANÍES", 65), LETRAS_X, TOTAL_Y, font, 8.5);
  tR(page, formatNumero(totalPagar), TOTAL_X_END, TOTAL_Y, fontBold, 10);

  // Liquidación IVA (contenido: 5% inc. = /21, 10% inc. = /11)
  const liq5 = Math.round(sub5 / 21);
  const liq10 = Math.round(sub10 / 11);
  const totalIva = liq5 + liq10;
  tR(page, formatNumero(liq5), LIQ5_X_END, LIQ_Y);
  tR(page, formatNumero(liq10), LIQ10_X_END, LIQ_Y);
  tR(page, formatNumero(totalIva), TOTIVA_X_END, LIQ_Y, fontBold);

  return pdfDoc.save();
}

export async function GET(request: NextRequest, ctxParams: { params: Promise<{ id: string }> }) {
  const { id } = await ctxParams.params;
  const url = new URL(request.url);
  const dx = Number(url.searchParams.get("dx") ?? 0) || 0;
  const dy = Number(url.searchParams.get("dy") ?? 0) || 0;

  const ctx = await getTenantSupabaseFromAuth(request);
  if (!ctx) return new NextResponse("No autorizado", { status: 401 });
  const empresaId = ctx.auth.empresa_id;

  const vQ = await ctx.supabase
    .from("ventas")
    .select("id, numero_control, fecha, total, tipo_venta, cliente_id, cliente_razon_social, cliente_ruc, nota_remision_numero")
    .eq("id", id)
    .eq("empresa_id", empresaId)
    .maybeSingle();
  if (vQ.error) return new NextResponse(`Error: ${vQ.error.message}`, { status: 500 });
  if (!vQ.data) return new NextResponse("Venta no encontrada", { status: 404 });
  const venta = vQ.data as unknown as VentaRow;

  // Fallback: si la venta no tiene snapshot, buscar en ficha del cliente o
  // en la factura ERP (ventas anteriores a la migración de snapshot).
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

  const pdfBytes = await buildTalonarioPdf(venta, items, dx, dy);
  // Response con el buffer del PDF. inline → se abre en el visor del navegador
  // (Chrome/Edge/Firefox tienen visor propio). El operador imprime desde ahí:
  // el visor usa "Tamaño real" por defecto, no depende de márgenes del sitio.
  return new NextResponse(pdfBytes as unknown as BodyInit, {
    status: 200,
    headers: {
      "Content-Type": "application/pdf",
      "Content-Disposition": `inline; filename="talonario-${venta.numero_control}.pdf"`,
      "Cache-Control": "no-store",
    },
  });
}
