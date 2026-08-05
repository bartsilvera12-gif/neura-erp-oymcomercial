"use client";

import Link from "next/link";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { CheckCircle2, Loader2, Package, Search, Trash2 } from "lucide-react";
import CajaControlPanel from "@/components/caja/CajaControlPanel";
import MontoInput, { parseMontoInput } from "@/components/ui/MontoInput";
import { fetchWithSupabaseSession } from "@/lib/api/fetch-with-supabase-session";
import { saveVenta } from "@/lib/ventas/storage";
import type { LineaVenta, MetodoPago, TipoIvaVenta } from "@/lib/ventas/types";
import { MODALIDAD_LABEL, type ModalidadPeso } from "@/lib/inventario/types";
import { PesoModal, type PesoModalProducto, type PesoModalResult } from "@/components/ventas/PesoModal";
import { DatosVentaHeader, datosVentaErrors, emptyDatosVenta, type DatosVentaState } from "@/components/ventas/DatosVentaHeader";
import { PedidosCajaPanel } from "@/components/ventas/PedidosCajaPanel";
import type { PedidoCaja } from "@/lib/pedidos-caja/types";

type EntidadBancaria = { id: string; codigo: string | null; nombre: string; tipo: string | null };

// ── Tipos POS ───────────────────────────────────────────────────────────────

type ProductoHit = {
  id: string;
  nombre: string;
  sku: string;
  codigo_barras: string | null;
  precio_venta: number;
  precio_mayorista: number;
  cantidad_minima_mayorista: number | null;
  stock_actual: number;
  imagen_url: string | null;
  tipo_iva: TipoIvaVenta;
  // Peso: si controlado_por_peso=true, al agregar al carrito se abre PesoModal
  // y la línea se marca con modalidad + precio_kg_display + unidad='KG'.
  controlado_por_peso: boolean;
  modalidades_activas: ModalidadPeso[];
  precio_kg_entero: number | null;
  precio_kg_recortado: number | null;
};

type CartItem = {
  /** Key única de fila en el carrito (para React y para permitir varias pesadas
   *  del mismo producto sin agruparse). NO se envía al server. */
  cart_line_id: string;
  producto_id: string;
  producto_nombre: string;
  sku: string;
  imagen_url: string | null;
  stock_actual: number;
  cantidad: number;
  precio_venta: number;         // precio unitario minorista base
  precio_mayorista: number;     // precio unitario mayorista (0 si no aplica)
  cantidad_minima_mayorista: number | null;
  tipo_iva: TipoIvaVenta;
  // Peso — undefined en items por unidad. Cuando modalidad viene, precio_venta
  // guarda directamente el precio/kg elegido y unidad_venta = 'KG'.
  modalidad?: ModalidadPeso;
  unidad_venta?: string;
  controlado_por_peso?: boolean;
};

/** Contador simple para cart_line_id (no necesita crypto para uniqueness dentro de la sesión). */
let cartLineSeq = 0;
function nextCartLineId(): string {
  cartLineSeq += 1;
  return `cli_${cartLineSeq}`;
}

/** Mapea la fila que devuelve /api/productos/search a un hit del POS. */
function toHit(p: Record<string, unknown>): ProductoHit {
  const iva = p.tipo_iva;
  const modalidadesRaw = Array.isArray(p.modalidades_activas) ? p.modalidades_activas : [];
  const modalidades = modalidadesRaw.filter((m): m is ModalidadPeso => m === "entero" || m === "recortado");
  return {
    id: String(p.id),
    nombre: String(p.nombre ?? ""),
    sku: String(p.sku ?? ""),
    codigo_barras: (p.codigo_barras as string | null) ?? null,
    precio_venta: Number(p.precio_venta) || 0,
    precio_mayorista: Number(p.precio_mayorista) || 0,
    cantidad_minima_mayorista:
      p.cantidad_minima_mayorista != null ? Number(p.cantidad_minima_mayorista) : null,
    stock_actual: Number(p.stock_actual) || 0,
    imagen_url: (p.imagen_url as string | null) ?? null,
    tipo_iva: (iva === "EXENTA" || iva === "5%" ? iva : "10%") as TipoIvaVenta,
    controlado_por_peso: p.controlado_por_peso === true,
    modalidades_activas: modalidades,
    precio_kg_entero: p.precio_kg_entero != null ? Number(p.precio_kg_entero) : null,
    precio_kg_recortado: p.precio_kg_recortado != null ? Number(p.precio_kg_recortado) : null,
  };
}

/** Precio unitario efectivo según la cantidad y el umbral mayorista del producto. */
function precioEfectivo(
  it: Pick<CartItem, "cantidad" | "precio_venta" | "precio_mayorista" | "cantidad_minima_mayorista">
): number {
  if (
    it.precio_mayorista > 0 &&
    it.cantidad_minima_mayorista != null &&
    it.cantidad_minima_mayorista > 0 &&
    it.cantidad >= it.cantidad_minima_mayorista
  ) {
    return it.precio_mayorista;
  }
  return it.precio_venta;
}

function esMayoristaAplicado(
  it: Pick<CartItem, "cantidad" | "precio_venta" | "precio_mayorista" | "cantidad_minima_mayorista">
): boolean {
  return (
    precioEfectivo(it) === it.precio_mayorista &&
    it.precio_mayorista > 0 &&
    it.precio_mayorista !== it.precio_venta
  );
}

/**
 * IVA contenido en un total. Los precios se cargan CON IVA incluido, así que el
 * impuesto se despeja hacia atrás — misma fórmula que usa /ventas/nueva.
 *
 * El origen de este POS mandaba siempre `tipo_iva: "EXENTA"` y `monto_iva: 0`.
 * Acá no sirve: el servidor recalcula los totales por ítem y rechaza la venta
 * con "Totales no coinciden" si no cuadran, y además la factura electrónica
 * necesita el IVA real de cada producto.
 */
function calcIva(tipo: TipoIvaVenta, total: number): number {
  if (tipo === "EXENTA") return 0;
  if (tipo === "5%") return total - total / 1.05;
  return total - total / 1.1;
}

function formatGs(v: number) {
  return `Gs. ${Math.round(v || 0).toLocaleString("es-PY")}`;
}

// ── Página principal ───────────────────────────────────────────────────────

export default function CajaPage() {
  // Estado de caja abierta: sin turno abierto no se cobra.
  const [cajaAbierta, setCajaAbierta] = useState(false);
  // Tick para que el CajaControlPanel refresque su arqueo después de cobrar,
  // sin recargar la página.
  const [refreshCajaTick, setRefreshCajaTick] = useState(0);

  // Búsqueda de productos (izquierda)
  const [q, setQ] = useState("");
  const [hits, setHits] = useState<ProductoHit[]>([]);
  const [buscando, setBuscando] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const searchCacheRef = useRef<Map<string, { hits: ProductoHit[]; ts: number }>>(new Map());
  const abortRef = useRef<AbortController | null>(null);

  // Carrito + producto destacado (derecha)
  const [cart, setCart] = useState<CartItem[]>([]);
  const [ultimoAgregado, setUltimoAgregado] = useState<CartItem | null>(null);

  // Modal cobro
  const [cobroOpen, setCobroOpen] = useState(false);
  const [metodo, setMetodo] = useState<MetodoPago>("efectivo");
  const [efectivoRecibido, setEfectivoRecibido] = useState("");
  const [referencia, setReferencia] = useState("");
  const [titular, setTitular] = useState("");
  const [entidadId, setEntidadId] = useState("");
  const [fechaAcreditacion, setFechaAcreditacion] = useState("");
  const [entidades, setEntidades] = useState<EntidadBancaria[]>([]);
  const [cobrando, setCobrando] = useState(false);
  const [cobroError, setCobroError] = useState<string | null>(null);
  const [ventaOk, setVentaOk] = useState<string | null>(null);

  // Modal "asociar código de barras a un producto"
  const [asociarOpen, setAsociarOpen] = useState(false);
  const [asociarCode, setAsociarCode] = useState("");
  const [asociarQuery, setAsociarQuery] = useState("");
  const [asociarHits, setAsociarHits] = useState<ProductoHit[]>([]);
  const [asociarBuscando, setAsociarBuscando] = useState(false);
  const [asociarGuardando, setAsociarGuardando] = useState(false);
  const [asociarError, setAsociarError] = useState<string | null>(null);

  // Búsqueda dentro del modal de asociar
  useEffect(() => {
    if (!asociarOpen) return;
    const trimmed = asociarQuery.trim();
    if (trimmed.length < 2) { setAsociarHits([]); return; }
    let cancel = false;
    const t = setTimeout(async () => {
      setAsociarBuscando(true);
      try {
        const res = await fetchWithSupabaseSession(
          `/api/productos/search?q=${encodeURIComponent(trimmed)}&limit=15`,
          { cache: "no-store" }
        );
        const j = await res.json();
        if (cancel) return;
        setAsociarHits(((j?.data?.items ?? []) as Record<string, unknown>[]).map(toHit));
      } finally {
        if (!cancel) setAsociarBuscando(false);
      }
    }, 220);
    return () => { cancel = true; clearTimeout(t); };
  }, [asociarQuery, asociarOpen]);

  function abrirAsociarCodigo(code: string) {
    setAsociarCode(code);
    setAsociarQuery("");
    setAsociarHits([]);
    setAsociarError(null);
    setAsociarOpen(true);
  }

  // Cargar entidades bancarias (para transferencia/tarjeta)
  useEffect(() => {
    let cancel = false;
    fetchWithSupabaseSession("/api/entidades-bancarias", { cache: "no-store" })
      .then((r) => r.json())
      .then((j) => { if (!cancel && j?.success) setEntidades(j.data?.entidades ?? []); })
      .catch(() => { /* opcional: sin entidades el select queda vacío */ });
    return () => { cancel = true; };
  }, []);

  // Entidades disponibles según método (excluye tipo "caja" para trans/tarjeta).
  const entidadesFiltradas = useMemo(() => {
    if (metodo === "efectivo") return [];
    if (metodo === "tarjeta") return entidades.filter((e) => e.tipo === "tarjeta" || e.tipo === "banco");
    return entidades.filter((e) => e.tipo !== "caja"); // transferencia
  }, [entidades, metodo]);

  // Búsqueda con debounce + cache en memoria + AbortController.
  // - Cache: las mismas letras dos veces (typo+backspace, volver a buscar algo
  //   que ya viste) devuelven resultado sin fetch. TTL 50 min, por debajo de la
  //   ~1 h de vida de las signed URLs de imagen, así nunca mostramos link roto.
  // - Abort: al tipear la próxima letra se cancela el fetch viejo, para que una
  //   respuesta lenta no pise a otra más nueva.
  useEffect(() => {
    const trimmed = q.trim();
    if (trimmed.length < 2) { setHits([]); return; }
    const key = trimmed.toLowerCase();

    const cached = searchCacheRef.current.get(key);
    if (cached && Date.now() - cached.ts < 50 * 60 * 1000) {
      setHits(cached.hits);
      setBuscando(false);
      return;
    }

    let cancel = false;
    const t = setTimeout(async () => {
      abortRef.current?.abort();
      const controller = new AbortController();
      abortRef.current = controller;

      setBuscando(true);
      try {
        const res = await fetchWithSupabaseSession(
          `/api/productos/search?q=${encodeURIComponent(trimmed)}&limit=15`,
          { cache: "no-store", signal: controller.signal }
        );
        const j = await res.json();
        if (cancel || controller.signal.aborted) return;
        const items = ((j?.data?.items ?? []) as Record<string, unknown>[]).map(toHit);
        searchCacheRef.current.set(key, { hits: items, ts: Date.now() });
        // Techo defensivo: pasadas las 200 entradas, se tiran las más viejas.
        if (searchCacheRef.current.size > 200) {
          const oldest = Array.from(searchCacheRef.current.entries())
            .sort((a, b) => a[1].ts - b[1].ts)
            .slice(0, 50)
            .map(([k]) => k);
          for (const k of oldest) searchCacheRef.current.delete(k);
        }
        setHits(items);
      } catch (e) {
        if ((e as { name?: string })?.name === "AbortError") return;
        throw e;
      } finally {
        if (!cancel && !controller.signal.aborted) setBuscando(false);
      }
    }, 180);
    return () => { cancel = true; clearTimeout(t); };
  }, [q]);

  // Estado del modal de peso: se abre cuando addToCart recibe un hit
  // controlado_por_peso, y se cierra al confirmar o cancelar.
  const [pesoProducto, setPesoProducto] = useState<PesoModalProducto | null>(null);

  // Datos de la venta (cliente + condición + documento) — bloque arriba del POS.
  // Se resetea después de cada cobro exitoso para que la próxima venta arranque
  // limpia (contado + solo ticket, sin cliente).
  const [datosVenta, setDatosVenta] = useState<DatosVentaState>(emptyDatosVenta());

  // Pedido de la cola de Caja que se está cobrando actualmente (si el cajero
  // eligió uno del panel "Pedidos por cobrar"). Al confirmar la venta, el
  // server lo marca como facturado usando este id.
  const [pedidoCajaActivo, setPedidoCajaActivo] = useState<PedidoCaja | null>(null);

  const addToCart = useCallback((p: ProductoHit) => {
    // Productos por peso: no se puede agregar con cantidad=1 (no tiene sentido).
    // Se abre el modal, y la confirmación del modal cablea agregarConPeso().
    if (p.controlado_por_peso) {
      if (p.modalidades_activas.length === 0) {
        // Producto mal configurado: activó controlado_por_peso pero no tiene
        // ninguna modalidad. Se ignora silenciosamente en vez de romper la caja.
        console.warn("[POS] producto por peso sin modalidades activas", p.id);
        return;
      }
      setPesoProducto({
        id: p.id,
        sku: p.sku,
        nombre: p.nombre,
        stock_actual: p.stock_actual,
        modalidades_activas: p.modalidades_activas,
        precio_kg_entero: p.precio_kg_entero,
        precio_kg_recortado: p.precio_kg_recortado,
      });
      setQ("");
      setHits([]);
      return;
    }
    const item: CartItem = {
      cart_line_id: nextCartLineId(),
      producto_id: p.id,
      producto_nombre: p.nombre,
      sku: p.sku,
      imagen_url: p.imagen_url,
      stock_actual: p.stock_actual,
      cantidad: 1,
      precio_venta: p.precio_venta,
      precio_mayorista: p.precio_mayorista,
      cantidad_minima_mayorista: p.cantidad_minima_mayorista,
      tipo_iva: p.tipo_iva,
    };
    setCart((prev) => {
      // Solo agrupar items por unidad (mismo producto_id sin modalidad).
      const ex = prev.find((x) => x.producto_id === p.id && !x.controlado_por_peso);
      if (ex) return prev.map((x) => x.cart_line_id === ex.cart_line_id ? { ...x, cantidad: x.cantidad + 1 } : x);
      return [...prev, item];
    });
    setUltimoAgregado(item);
    setQ("");
    setHits([]);
    inputRef.current?.focus();
  }, []);

  const agregarConPeso = useCallback((result: PesoModalResult) => {
    if (!pesoProducto) return;
    const item: CartItem = {
      cart_line_id: nextCartLineId(),
      producto_id: pesoProducto.id,
      producto_nombre: pesoProducto.nombre,
      sku: pesoProducto.sku,
      imagen_url: null,
      stock_actual: pesoProducto.stock_actual,
      // Para productos por peso: cantidad = peso en kg, precio_venta = precio/kg.
      // NO hay mayorista (no aplica al modelo por peso).
      cantidad: result.peso,
      precio_venta: result.precioKg,
      precio_mayorista: 0,
      cantidad_minima_mayorista: null,
      tipo_iva: "10%",
      modalidad: result.modalidad,
      unidad_venta: "KG",
      controlado_por_peso: true,
    };
    // Cada pesada es una línea distinta (no se agrupan) para que el ticket
    // muestre exactamente lo que se pesó. Al no compartir cart_line_id, el
    // agrupador de addToCart no las une. El server las suma correctamente
    // en el descuento de stock atómico.
    setCart((prev) => [...prev, item]);
    setUltimoAgregado(item);
    setPesoProducto(null);
    inputRef.current?.focus();
  }, [pesoProducto]);

  async function asociarYAgregar(prod: ProductoHit) {
    setAsociarGuardando(true);
    setAsociarError(null);
    try {
      const res = await fetchWithSupabaseSession(`/api/productos/${prod.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ codigo_barras: asociarCode }),
      });
      const j = await res.json().catch(() => ({}));
      if (!res.ok || !j?.success) throw new Error(j?.error ?? "No se pudo guardar el código.");
      addToCart({ ...prod, codigo_barras: asociarCode });
      setAsociarOpen(false);
    } catch (e) {
      setAsociarError(e instanceof Error ? e.message : "No se pudo guardar el código.");
    } finally {
      setAsociarGuardando(false);
    }
  }

  // Scanner: el lector tipea el código y manda Enter. Se busca primero un match
  // exacto entre los hits que ya están en pantalla; si no hay, se consulta.
  const onKeyDownBuscar = useCallback(async (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key !== "Enter") return;
    e.preventDefault();
    const term = q.trim();
    if (!term) return;
    const exact = hits.find(
      (h) => h.codigo_barras === term || h.sku.toLowerCase() === term.toLowerCase()
    );
    if (exact) { addToCart(exact); return; }
    try {
      const res = await fetchWithSupabaseSession(
        `/api/productos/search?q=${encodeURIComponent(term)}&limit=1`,
        { cache: "no-store" }
      );
      const j = await res.json();
      const first = (j?.data?.items ?? [])[0] as Record<string, unknown> | undefined;
      if (first) addToCart(toHit(first));
    } catch {
      /* si falla la red, el usuario ve el buscador sin resultados */
    }
  }, [q, hits, addToCart]);

  const updateCant = (cartLineId: string, cant: number) => {
    // Items por unidad: mínimo 1 y enteros (parseInt del caller).
    // Items por peso: se editan desde el PesoModal (no desde el carrito) —
    // este handler solo se usa para +/-/input numérico de unidades.
    setCart((prev) => prev.map((x) => x.cart_line_id === cartLineId ? { ...x, cantidad: Math.max(1, cant) } : x));
  };
  const removeFromCart = (cartLineId: string) => {
    setCart((prev) => prev.filter((x) => x.cart_line_id !== cartLineId));
    setUltimoAgregado((u) => (u && u.cart_line_id === cartLineId ? null : u));
  };
  const vaciarCarrito = () => { setCart([]); setUltimoAgregado(null); setPedidoCajaActivo(null); };

  /** Toma un pedido de la cola y lo carga como carrito del POS. Si ya había
   *  items en el carrito, se reemplazan (el pedido es el nuevo contexto).
   *  Autocompleta razón social / RUC del pedido si vienen. */
  const cargarPedidoAlCarrito = useCallback(async (p: PedidoCaja) => {
    // Los items del pedido no traen stock_actual ni cantidad_minima_mayorista
    // ni imagen_url — se rehidratan en el momento del cobro con las mejores
    // estimaciones (mayorista queda desactivado; el precio ya es el que el
    // vendedor pactó). Si el vendedor puso una modalidad de peso, se preserva.
    const nuevosItems: CartItem[] = p.items.map((it) => {
      const cantNum = Number(it.cantidad) || 0;
      const precioNum = Number(it.precio_venta) || 0;
      const tipoIva: TipoIvaVenta =
        it.tipo_iva === "EXENTA" || it.tipo_iva === "5%" ? it.tipo_iva : "10%";
      return {
        cart_line_id: nextCartLineId(),
        producto_id: it.producto_id,
        producto_nombre: it.producto_nombre,
        sku: it.sku ?? "",
        imagen_url: null,
        stock_actual: 0,
        cantidad: cantNum,
        precio_venta: precioNum,
        precio_mayorista: 0,
        cantidad_minima_mayorista: null,
        tipo_iva: tipoIva,
      };
    });
    setCart(nuevosItems);
    setPedidoCajaActivo(p);
    setUltimoAgregado(nuevosItems[nuevosItems.length - 1] ?? null);
    // Autocompletar datos de venta con los del pedido — sin sobrescribir lo
    // que ya haya tipeado el cajero.
    setDatosVenta((prev) => ({
      ...prev,
      razonSocial: prev.razonSocial || p.cliente_nombre || "",
    }));
    inputRef.current?.focus();
  }, []);

  /** Libera el pedido activo (vuelve al vendedor, sale de la cola). Se llama
   *  cuando el cajero decide cancelar el cobro sin facturarlo. */
  const liberarPedidoActivo = useCallback(async () => {
    if (!pedidoCajaActivo) return;
    try {
      await fetchWithSupabaseSession(`/api/pedidos-caja/${pedidoCajaActivo.id}/liberar`, { method: "POST" });
    } catch (e) {
      console.error("[POS] liberar pedido fallo:", e);
    }
    setPedidoCajaActivo(null);
    vaciarCarrito();
  }, [pedidoCajaActivo]);

  const total = useMemo(() => cart.reduce((s, it) => s + it.cantidad * precioEfectivo(it), 0), [cart]);
  const cantTotal = useMemo(() => cart.reduce((s, it) => s + it.cantidad, 0), [cart]);

  function abrirCobro() {
    if (cart.length === 0) return;
    setCobroError(null);
    setMetodo("efectivo");
    setEfectivoRecibido("");
    setReferencia("");
    setTitular("");
    setEntidadId("");
    setFechaAcreditacion(new Date().toISOString().slice(0, 10));
    setCobroOpen(true);
  }

  // Confirmar cobro → crear venta + abrir ticket
  async function confirmarCobro() {
    if (cart.length === 0) return;
    setCobrando(true);
    setCobroError(null);
    try {
      const items: LineaVenta[] = cart.map((it) => {
        const precio = precioEfectivo(it);
        const totalLinea = it.cantidad * precio;
        const montoIva = calcIva(it.tipo_iva, totalLinea);
        const esPeso = it.controlado_por_peso === true && !!it.modalidad;
        return {
          producto_id: it.producto_id,
          producto_nombre: it.producto_nombre,
          sku: it.sku,
          cantidad: it.cantidad,
          precio_venta_original: precio,
          precio_venta: precio,
          tipo_iva: it.tipo_iva,
          // Peso: no aplica el toggle mayorista (esMayoristaAplicado devuelve
          // false porque precio_mayorista=0), pero blindamos con la guarda.
          tipo_precio: !esPeso && esMayoristaAplicado(it) ? "mayorista" : "minorista",
          subtotal: totalLinea - montoIva,
          monto_iva: montoIva,
          total_linea: totalLinea,
          // Metadatos de peso — llegan a ventas_items via /api/ventas/create.
          modalidad: esPeso ? it.modalidad : undefined,
          unidad_venta: esPeso ? (it.unidad_venta ?? "KG") : undefined,
          precio_unitario_display: esPeso ? precio : undefined,
        };
      });
      const totalVenta = items.reduce((s, it) => s + it.total_linea, 0);
      const ivaVenta = items.reduce((s, it) => s + it.monto_iva, 0);
      const entidadSel = entidades.find((e) => e.id === entidadId);
      const pagoDetalle = metodo === "efectivo"
        ? null
        : {
            entidad_bancaria_id: entidadId || null,
            entidad_nombre_snapshot: entidadSel?.nombre ?? null,
            referencia: referencia.trim() || null,
            titular: metodo === "transferencia" ? (titular.trim() || null) : null,
            fecha_acreditacion: fechaAcreditacion || null,
          };

      // Guard cliente-side: si la selección arriba no es válida, no llegamos
      // al server (que rechazaría). Muestra el mismo mensaje que el header.
      const dvErr = datosVentaErrors(datosVenta);
      if (dvErr) {
        setCobroError(dvErr);
        return;
      }
      const plazoDiasNum = datosVenta.condicion === "CREDITO"
        ? Math.max(1, Number(datosVenta.plazoDias) || 1)
        : 0;
      const res = await saveVenta({
        items,
        moneda: "GS",
        tipo_cambio: 1,
        subtotal: totalVenta - ivaVenta,
        monto_iva: ivaVenta,
        total: totalVenta,
        tipo_venta: datosVenta.condicion,
        plazo_dias: plazoDiasNum,
        metodo_pago: metodo,
        cliente_id: null,
        // Cliente ad-hoc: sin ficha en el catálogo. Alcanza con la razón
        // social (obligatoria en factura y crédito) y el RUC opcional.
        razon_social_ad_hoc: datosVenta.razonSocial.trim() || null,
        ruc_ad_hoc: datosVenta.rucFactura.trim() || null,
        // 'Factura' arriba dispara el puente venta→factura ERP + SIFEN.
        // 'Solo ticket' registra la venta e imprime comanda, sin factura.
        emitir_factura: datosVenta.documento === "factura",
      }, undefined, pagoDetalle, {
        // Si el cajero eligió cobrar desde el panel Pedidos por cobrar, el
        // server marca el pedido como facturado post-venta (idempotente).
        pedidoCajaId: pedidoCajaActivo?.id ?? null,
      });
      if (!res.success) {
        setCobroError(res.error);
        return;
      }
      const v = res.venta;
      // Cuando el cajero eligió "Factura", abrimos la vista de talonario
      // (autocompletado sobre el papel físico pre-impreso Epson matricial).
      // "Solo ticket" sigue abriendo el ticket térmico como comprobante interno.
      const rutaImpresion = datosVenta.documento === "factura"
        ? `/api/ventas/${v.id}/talonario?auto=1`
        : `/api/ventas/${v.id}/ticket?auto=1`;
      try { window.open(rutaImpresion, "_blank", "noopener"); } catch {}
      setVentaOk(v.numero_control);
      setCobroOpen(false);
      vaciarCarrito();
      // vaciarCarrito ya limpia pedidoCajaActivo, pero por explicitud —
      // si el flujo cambia mañana, este set queda como documentación de que
      // el pedido termina "consumido" al facturar.
      setPedidoCajaActivo(null);
      // Volver a defaults (contado + solo ticket + sin cliente) para no
      // arrastrar los datos de la venta anterior a la próxima.
      setDatosVenta(emptyDatosVenta());
      setRefreshCajaTick((n) => n + 1);
      setTimeout(() => setVentaOk(null), 3500);
      inputRef.current?.focus();
    } catch (e) {
      setCobroError(e instanceof Error ? e.message : "No se pudo registrar la venta.");
    } finally {
      setCobrando(false);
    }
  }

  const diferenciaEfectivo = useMemo(() => {
    if (metodo !== "efectivo") return 0;
    const r = parseMontoInput(efectivoRecibido);
    if (!Number.isFinite(r) || r <= 0) return -total;
    return r - total;
  }, [efectivoRecibido, total, metodo]);
  const vuelto = diferenciaEfectivo > 0 ? diferenciaEfectivo : 0;
  const faltaEfectivo = diferenciaEfectivo < 0 ? -diferenciaEfectivo : 0;
  const efectivoIngresado = parseMontoInput(efectivoRecibido) > 0;

  // Foco en el buscador cuando la caja se abre: el cajero escanea sin tocar nada.
  useEffect(() => {
    if (cajaAbierta) inputRef.current?.focus();
  }, [cajaAbierta]);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-[11px] font-semibold uppercase tracking-[0.18em] text-[#4FAEB2]">
            <span
              aria-hidden="true"
              className="inline-block h-1.5 w-1.5 rounded-full bg-[#4FAEB2]"
              style={{ boxShadow: "0 0 0 3px rgba(79,174,178,0.18)" }}
            />
            Zentra · Operaciones
          </div>
          <h1 className="mt-1 text-lg font-semibold tracking-tight text-slate-900">Caja</h1>
          <p className="mt-0.5 text-xs text-slate-500">Escaneá o buscá un producto y cobrálo directo.</p>
        </div>
        <Link
          href="/ventas/ordenes"
          className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50"
        >
          Ver órdenes del día →
        </Link>
      </div>

      <CajaControlPanel onStateChange={setCajaAbierta} defaultCollapsed refreshTick={refreshCajaTick} />

      {ventaOk && (
        <div className="flex items-center gap-2 rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-medium text-emerald-800 shadow-sm">
          <CheckCircle2 className="h-5 w-5" /> Venta <strong>{ventaOk}</strong> registrada. Ticket enviado a imprimir.
        </div>
      )}

      {/* Split POS */}
      {!cajaAbierta ? (
        <div className="rounded-2xl border border-dashed border-slate-300 bg-white p-10 text-center text-sm text-slate-500 shadow-sm">
          Abrí la caja para empezar a cobrar.
        </div>
      ) : (
        <>
        {/* Datos de la venta arriba (cliente / condicion / documento).
            Se muestran siempre para que el vendedor pueda dejar el flag de
            factura o crédito seteado antes de escanear el primer producto. */}
        <DatosVentaHeader value={datosVenta} onChange={setDatosVenta} />

        {/* Cola de pedidos armados por vendedores. Al elegir "Cobrar" carga
            los items al carrito y marca el pedido como en_caja. */}
        <PedidosCajaPanel
          onCobrar={cargarPedidoAlCarrito}
          pedidoActivoId={pedidoCajaActivo?.id ?? null}
        />

        {/* Aviso persistente cuando hay un pedido siendo cobrado: le da al
            cajero forma de identificar el contexto y liberar si eligió mal. */}
        {pedidoCajaActivo && (
          <div className="flex items-center justify-between gap-3 rounded-xl border border-[#4FAEB2]/40 bg-[#4FAEB2]/[0.08] px-4 py-2.5">
            <div className="min-w-0 text-sm text-slate-800">
              Estás cobrando el pedido{" "}
              <span className="font-semibold">{pedidoCajaActivo.numero ?? "sin número"}</span>
              {pedidoCajaActivo.cliente_nombre && (
                <span className="text-slate-600"> · {pedidoCajaActivo.cliente_nombre}</span>
              )}
              . Al confirmar la venta se marca como facturado.
            </div>
            <button
              type="button"
              onClick={() => void liberarPedidoActivo()}
              className="shrink-0 rounded-md border border-slate-200 bg-white px-2.5 py-1 text-xs text-slate-600 hover:bg-slate-50"
              title="Devuelve el pedido al vendedor y vacía el carrito"
            >
              Liberar
            </button>
          </div>
        )}
        <div className="grid gap-4 lg:grid-cols-[1fr_460px] lg:min-h-[540px]">
          {/* PANEL IZQUIERDO: buscador + carrito */}
          <div className="flex flex-col rounded-2xl border border-slate-200 bg-white shadow-sm">
            <div className="border-b border-slate-100 p-4">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
                <input
                  ref={inputRef}
                  type="text"
                  value={q}
                  onChange={(e) => setQ(e.target.value)}
                  onKeyDown={onKeyDownBuscar}
                  placeholder="Escaneá el código o buscá por nombre/SKU…"
                  className="w-full rounded-xl border border-slate-200 bg-slate-50 py-3 pl-10 pr-10 text-base outline-none focus:border-[#4FAEB2] focus:bg-white focus:ring-2 focus:ring-[#4FAEB2]/20"
                  autoComplete="off"
                />
                {buscando && <Loader2 className="absolute right-3 top-1/2 h-5 w-5 -translate-y-1/2 animate-spin text-slate-400" />}
              </div>

              {hits.length > 0 && (
                <ul className="mt-2 max-h-56 divide-y divide-slate-100 overflow-auto rounded-xl border border-slate-200 bg-white shadow-inner">
                  {hits.map((p) => (
                    <li
                      key={p.id}
                      onClick={() => addToCart(p)}
                      className="flex cursor-pointer items-center gap-3 px-3 py-2 text-sm hover:bg-[#4FAEB2]/[0.08]"
                    >
                      <div className="h-10 w-10 shrink-0 overflow-hidden rounded-lg border border-slate-200 bg-slate-50">
                        {p.imagen_url ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={p.imagen_url} alt={p.nombre} className="h-full w-full object-cover" />
                        ) : (
                          <div className="flex h-full w-full items-center justify-center text-slate-300">
                            <Package className="h-4 w-4" />
                          </div>
                        )}
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="truncate font-medium text-slate-900">{p.nombre}</p>
                        <p className="font-mono text-[11px] text-slate-500">
                          {p.sku}
                          {p.cantidad_minima_mayorista != null && p.cantidad_minima_mayorista > 0 && p.precio_mayorista > 0 && p.precio_mayorista !== p.precio_venta && (
                            <span className="ml-2 text-indigo-600">
                              · desde {p.cantidad_minima_mayorista} u {formatGs(p.precio_mayorista)}
                            </span>
                          )}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className={`text-[11px] font-medium ${p.stock_actual <= 0 ? "text-rose-600" : "text-emerald-700"}`}>
                          {p.stock_actual <= 0 ? "Sin stock" : `${p.stock_actual} u`}
                        </p>
                        <p className="text-sm font-semibold tabular-nums text-slate-900">{formatGs(p.precio_venta)}</p>
                      </div>
                    </li>
                  ))}
                </ul>
              )}

              {/* Sin resultados + oferta para asociar código */}
              {!buscando && q.trim().length >= 2 && hits.length === 0 && (
                <div className="mt-2 rounded-xl border border-amber-200 bg-amber-50/70 p-3 text-sm">
                  <p className="font-medium text-amber-900">
                    Ningún producto encontrado con <span className="font-mono">«{q.trim()}»</span>.
                  </p>
                  {/^[0-9]{6,}$/.test(q.trim()) && (
                    <>
                      <p className="mt-1 text-xs text-amber-800">
                        Parece un código de barras. ¿Querés asociarlo a un producto para que la próxima vez el scanner lo levante?
                      </p>
                      <button
                        type="button"
                        onClick={() => abrirAsociarCodigo(q.trim())}
                        className="mt-2 inline-flex items-center rounded-lg bg-amber-500 px-3 py-1.5 text-xs font-semibold text-white shadow-sm hover:bg-amber-600"
                      >
                        Asociar código a un producto
                      </button>
                    </>
                  )}
                </div>
              )}
            </div>

            {/* Carrito */}
            <div className="flex-1 overflow-auto p-4">
              {cart.length === 0 ? (
                <div className="flex h-full flex-col items-center justify-center gap-2 text-sm text-slate-400">
                  <Package className="h-8 w-8 text-slate-300" />
                  <p>Todavía no cargaste productos.</p>
                  <p className="text-xs">Escaneá o buscá arriba.</p>
                </div>
              ) : (
                <ul className="space-y-2">
                  {cart.map((it) => {
                    const esPeso = it.controlado_por_peso === true && !!it.modalidad;
                    const pesoLabel = esPeso
                      ? `${it.cantidad.toLocaleString("es-PY", { minimumFractionDigits: 0, maximumFractionDigits: 3 })} kg`
                      : null;
                    return (
                    <li key={it.cart_line_id} className="rounded-xl border border-slate-200 bg-slate-50/40 p-3">
                      <div className="flex items-start gap-3">
                        <div className="h-12 w-12 shrink-0 overflow-hidden rounded-lg border border-slate-200 bg-white">
                          {it.imagen_url ? (
                            // eslint-disable-next-line @next/next/no-img-element
                            <img src={it.imagen_url} alt={it.producto_nombre} className="h-full w-full object-cover" />
                          ) : (
                            <div className="flex h-full w-full items-center justify-center text-slate-300">
                              <Package className="h-5 w-5" />
                            </div>
                          )}
                        </div>
                        <div className="min-w-0 flex-1">
                          <div className="flex flex-wrap items-center gap-1.5">
                            <p className="min-w-0 flex-1 truncate text-sm font-medium text-slate-900">
                              {it.producto_nombre}
                              {esPeso && it.modalidad && (
                                <span className="ml-1 text-slate-600 font-normal">· {MODALIDAD_LABEL[it.modalidad]}</span>
                              )}
                            </p>
                            {!esPeso && esMayoristaAplicado(it) && (
                              <span className="rounded-full border border-indigo-200 bg-indigo-50 px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-indigo-700">
                                Mayorista
                              </span>
                            )}
                            {esPeso && (
                              <span className="rounded-full border border-emerald-200 bg-emerald-50 px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-emerald-700">
                                Por peso
                              </span>
                            )}
                          </div>
                          <p className="font-mono text-[11px] text-slate-500">
                            {it.sku}
                            {" · "}
                            {esPeso
                              ? `${pesoLabel} × ${formatGs(it.precio_venta)}/kg`
                              : `${formatGs(precioEfectivo(it))} c/u`}
                            {!esPeso && !esMayoristaAplicado(it) && it.precio_mayorista > 0 && it.precio_mayorista !== it.precio_venta && it.cantidad_minima_mayorista != null && it.cantidad_minima_mayorista > 0 && (
                              <span className="ml-1 text-indigo-500">
                                (desde {it.cantidad_minima_mayorista} u → {formatGs(it.precio_mayorista)})
                              </span>
                            )}
                          </p>
                          <div className="mt-2 flex items-center gap-2">
                            {esPeso ? (
                              // Item por peso: no se edita cantidad desde el
                              // carrito (perdería el sentido del peso pesado).
                              // Para cambiar, se quita y se pesa de nuevo.
                              <span className="text-xs text-slate-500">
                                Peso fijado al agregar. Quitar y pesar de nuevo para cambiarlo.
                              </span>
                            ) : (
                              <>
                                <button
                                  type="button"
                                  onClick={() => updateCant(it.cart_line_id, it.cantidad - 1)}
                                  className="h-7 w-7 rounded-md border border-slate-200 bg-white text-slate-700 hover:bg-slate-50"
                                  aria-label="Menos"
                                >−</button>
                                <input
                                  type="number"
                                  min={1}
                                  value={it.cantidad}
                                  onChange={(e) => updateCant(it.cart_line_id, parseInt(e.target.value) || 1)}
                                  className="h-7 w-14 rounded-md border border-slate-200 bg-white text-center text-sm tabular-nums"
                                />
                                <button
                                  type="button"
                                  onClick={() => updateCant(it.cart_line_id, it.cantidad + 1)}
                                  className="h-7 w-7 rounded-md border border-slate-200 bg-white text-slate-700 hover:bg-slate-50"
                                  aria-label="Más"
                                >+</button>
                              </>
                            )}
                            <span className="ml-auto text-sm font-semibold tabular-nums text-slate-900">
                              {formatGs(it.cantidad * precioEfectivo(it))}
                            </span>
                          </div>
                        </div>
                        <button
                          type="button"
                          onClick={() => removeFromCart(it.cart_line_id)}
                          className="text-slate-400 hover:text-rose-500"
                          aria-label="Quitar"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </li>
                    );
                  })}
                </ul>
              )}
            </div>
          </div>

          {/* PANEL DERECHO: producto destacado + totales */}
          <div className="flex flex-col rounded-2xl border border-slate-200 bg-white shadow-sm">
            {/* Fondo de marca. El logo va como background y no como <img> para
                que el recorte quede en el contenedor y la foto del producto se
                superponga sin pelear por el espacio. Se atenúa cuando hay un
                producto cargado: ahí el protagonista es la mercadería. */}
            <div
              className="relative min-h-[280px] flex-1 overflow-hidden rounded-t-2xl bg-black bg-contain bg-center bg-no-repeat transition-[background-size]"
              style={{ backgroundImage: "url('/logo.jpeg')" }}
            >
              {ultimoAgregado ? (
                <div className="relative z-10 flex h-full items-center justify-center bg-black/60 p-6">
                  <div className="rounded-2xl border-2 border-white/20 bg-white/95 p-3 shadow-2xl">
                    {ultimoAgregado.imagen_url ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={ultimoAgregado.imagen_url}
                        alt={ultimoAgregado.producto_nombre}
                        className="h-56 w-56 object-contain"
                      />
                    ) : (
                      <div className="flex h-56 w-56 items-center justify-center text-slate-300">
                        <Package className="h-24 w-24" />
                      </div>
                    )}
                    <p className="mt-2 max-w-[224px] truncate text-center text-sm font-semibold text-slate-800">
                      {ultimoAgregado.producto_nombre}
                    </p>
                    <p className="text-center font-mono text-[10px] text-slate-400">{ultimoAgregado.sku}</p>
                  </div>
                </div>
              ) : (
                <div className="absolute inset-x-0 bottom-0 p-4 text-center">
                  <p className="text-[11px] text-white/50">
                    El último producto cargado se muestra acá.
                  </p>
                </div>
              )}
            </div>

            {/* Totales + botón */}
            <div className="space-y-3 border-t border-slate-100 p-5">
              <div className="flex items-baseline justify-between text-sm text-slate-500">
                <span>Ítems</span>
                <span className="font-medium tabular-nums text-slate-800">{cantTotal}</span>
              </div>
              <div className="flex items-baseline justify-between border-t border-dashed border-slate-200 pt-3">
                <span className="text-sm font-medium text-slate-600">Total a cobrar</span>
                <span className="text-3xl font-bold tabular-nums text-slate-900">{formatGs(total)}</span>
              </div>
              <button
                type="button"
                onClick={abrirCobro}
                disabled={cart.length === 0}
                className="w-full rounded-xl bg-[#4FAEB2] px-5 py-4 text-lg font-semibold text-white shadow-sm shadow-[#4FAEB2]/25 transition-colors hover:bg-[#3F8E91] disabled:cursor-not-allowed disabled:bg-slate-200 disabled:text-slate-400 disabled:shadow-none"
              >
                Aceptar y cobrar
              </button>
              {cart.length > 0 && (
                <button
                  type="button"
                  onClick={vaciarCarrito}
                  className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs font-medium text-slate-500 hover:bg-slate-50"
                >
                  Vaciar carrito
                </button>
              )}
            </div>
          </div>
        </div>
        </>
      )}

      {/* Modal de cobro */}
      {cobroOpen && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
          onClick={() => { if (!cobrando) setCobroOpen(false); }}
        >
          <div
            role="dialog"
            aria-modal="true"
            className="w-full max-w-md space-y-4 rounded-2xl bg-white p-6 shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div>
              <h3 className="text-lg font-semibold text-slate-900">Cobrar</h3>
              <p className="mt-1 text-sm text-slate-500">
                Total: <strong className="text-slate-900">{formatGs(total)}</strong> · {cantTotal} ítem{cantTotal === 1 ? "" : "s"}
              </p>
            </div>

            <div className="grid grid-cols-3 gap-2">
              {(["efectivo", "transferencia", "tarjeta"] as MetodoPago[]).map((m) => (
                <button
                  key={m}
                  type="button"
                  onClick={() => setMetodo(m)}
                  className={`rounded-lg border px-3 py-3 text-sm font-medium capitalize transition-colors ${
                    metodo === m
                      ? "border-[#4FAEB2] bg-[#4FAEB2]/10 text-[#3F8E91]"
                      : "border-slate-200 bg-white text-slate-700 hover:bg-slate-50"
                  }`}
                >
                  {m}
                </button>
              ))}
            </div>

            {metodo === "efectivo" && (
              <>
                <label className="block text-sm">
                  <span className="mb-1 block font-medium text-slate-700">Efectivo recibido</span>
                  <MontoInput
                    value={efectivoRecibido}
                    onChange={(n) => setEfectivoRecibido(String(n))}
                    placeholder="0"
                    decimals={false}
                    className="w-full rounded-md border border-slate-200 px-3 py-2 text-lg tabular-nums outline-none focus:border-[#4FAEB2] focus:ring-2 focus:ring-[#4FAEB2]/20"
                    autoFocus
                  />
                </label>
                {efectivoIngresado && faltaEfectivo > 0 ? (
                  <div className="flex items-baseline justify-between rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm">
                    <span className="font-medium text-rose-700">Falta</span>
                    <span className="text-xl font-bold tabular-nums text-rose-700">{formatGs(faltaEfectivo)}</span>
                  </div>
                ) : (
                  <div className={`flex items-baseline justify-between rounded-lg border px-3 py-2 text-sm ${
                    vuelto > 0 ? "border-emerald-200 bg-emerald-50" : "border-slate-200 bg-slate-50"
                  }`}>
                    <span className={vuelto > 0 ? "font-medium text-emerald-700" : "text-slate-600"}>Vuelto</span>
                    <span className={`text-xl font-bold tabular-nums ${vuelto > 0 ? "text-emerald-700" : "text-slate-900"}`}>
                      {formatGs(vuelto)}
                    </span>
                  </div>
                )}
              </>
            )}

            {(metodo === "transferencia" || metodo === "tarjeta") && (
              <div className="space-y-3">
                <label className="block text-sm">
                  <span className="mb-1 block font-medium text-slate-700">
                    {metodo === "tarjeta" ? "Tarjeta / banco" : "Entidad / banco"}
                  </span>
                  <select
                    value={entidadId}
                    onChange={(e) => setEntidadId(e.target.value)}
                    className="w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-[#4FAEB2] focus:ring-2 focus:ring-[#4FAEB2]/20"
                  >
                    <option value="">— Seleccionar —</option>
                    {entidadesFiltradas.map((en) => (
                      <option key={en.id} value={en.id}>
                        {en.nombre}{en.codigo ? ` (${en.codigo})` : ""}
                      </option>
                    ))}
                  </select>
                  {entidadesFiltradas.length === 0 && (
                    <p className="mt-1 text-[11px] text-slate-400">
                      Sin entidades cargadas. Configuralas en Configuración → Entidades bancarias.
                    </p>
                  )}
                </label>

                <div className="grid grid-cols-2 gap-3">
                  <label className="block text-sm">
                    <span className="mb-1 block font-medium text-slate-700">
                      {metodo === "tarjeta" ? "N° de comprobante / últimos 4" : "N° de operación"}
                    </span>
                    <input
                      type="text"
                      value={referencia}
                      onChange={(e) => setReferencia(e.target.value)}
                      placeholder={metodo === "tarjeta" ? "1234" : "Ej. 78912345"}
                      className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none focus:border-[#4FAEB2] focus:ring-2 focus:ring-[#4FAEB2]/20"
                    />
                  </label>
                  <label className="block text-sm">
                    <span className="mb-1 block font-medium text-slate-700">Fecha acreditación</span>
                    <input
                      type="date"
                      value={fechaAcreditacion}
                      onChange={(e) => setFechaAcreditacion(e.target.value)}
                      className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none focus:border-[#4FAEB2] focus:ring-2 focus:ring-[#4FAEB2]/20"
                    />
                  </label>
                </div>

                {metodo === "transferencia" && (
                  <label className="block text-sm">
                    <span className="mb-1 block font-medium text-slate-700">Titular (opcional)</span>
                    <input
                      type="text"
                      value={titular}
                      onChange={(e) => setTitular(e.target.value)}
                      placeholder="Nombre del que hizo la transferencia"
                      className="w-full rounded-md border border-slate-200 px-3 py-2 text-sm outline-none focus:border-[#4FAEB2] focus:ring-2 focus:ring-[#4FAEB2]/20"
                    />
                  </label>
                )}
              </div>
            )}

            {cobroError && (
              <div className="rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-700">{cobroError}</div>
            )}

            <div className="flex justify-end gap-2 pt-1">
              <button
                type="button"
                onClick={() => setCobroOpen(false)}
                disabled={cobrando}
                className="rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50"
              >
                Cancelar
              </button>
              <button
                type="button"
                onClick={() => void confirmarCobro()}
                disabled={cobrando}
                className="rounded-lg bg-[#4FAEB2] px-5 py-2 text-sm font-semibold text-white hover:bg-[#3F8E91] disabled:opacity-50"
              >
                {cobrando ? "Cobrando…" : "Confirmar e imprimir"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal: asociar código de barras a un producto existente */}
      {asociarOpen && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
          onClick={() => { if (!asociarGuardando) setAsociarOpen(false); }}
        >
          <div
            role="dialog"
            aria-modal="true"
            className="w-full max-w-lg space-y-4 rounded-2xl bg-white p-6 shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div>
              <h3 className="text-lg font-semibold text-slate-900">Asociar código a un producto</h3>
              <p className="mt-1 text-sm text-slate-500">
                Código escaneado: <span className="font-mono text-slate-800">{asociarCode}</span>
              </p>
              <p className="mt-1 text-xs text-slate-400">
                Buscá el producto y hacé click para guardarle este código de barras.
              </p>
            </div>

            <div className="relative">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
              <input
                type="text"
                value={asociarQuery}
                onChange={(e) => setAsociarQuery(e.target.value)}
                placeholder="Buscar por nombre o SKU…"
                className="w-full rounded-lg border border-slate-200 py-2 pl-9 pr-9 text-sm outline-none focus:border-[#4FAEB2] focus:ring-2 focus:ring-[#4FAEB2]/20"
                autoFocus
                autoComplete="off"
              />
              {asociarBuscando && <Loader2 className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 animate-spin text-slate-400" />}
            </div>

            <div className="max-h-72 overflow-auto rounded-lg border border-slate-200">
              {asociarQuery.trim().length < 2 ? (
                <p className="p-4 text-center text-xs text-slate-400">Escribí al menos 2 caracteres para buscar.</p>
              ) : asociarHits.length === 0 && !asociarBuscando ? (
                <p className="p-4 text-center text-xs text-slate-400">Sin resultados.</p>
              ) : (
                <ul className="divide-y divide-slate-100">
                  {asociarHits.map((p) => (
                    <li
                      key={p.id}
                      onClick={() => void asociarYAgregar(p)}
                      className={`flex cursor-pointer items-center gap-3 px-3 py-2 text-sm hover:bg-[#4FAEB2]/[0.08] ${
                        asociarGuardando ? "pointer-events-none opacity-50" : ""
                      }`}
                    >
                      <div className="h-10 w-10 shrink-0 overflow-hidden rounded-lg border border-slate-200 bg-slate-50">
                        {p.imagen_url ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={p.imagen_url} alt={p.nombre} className="h-full w-full object-cover" />
                        ) : (
                          <div className="flex h-full w-full items-center justify-center text-slate-300">
                            <Package className="h-4 w-4" />
                          </div>
                        )}
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="truncate font-medium text-slate-900">{p.nombre}</p>
                        <p className="font-mono text-[11px] text-slate-500">
                          {p.sku}
                          {p.codigo_barras && (
                            <span className="ml-2 text-amber-600">· ya tiene código {p.codigo_barras}</span>
                          )}
                        </p>
                      </div>
                      <p className="text-sm font-semibold tabular-nums text-slate-900">{formatGs(p.precio_venta)}</p>
                    </li>
                  ))}
                </ul>
              )}
            </div>

            {asociarError && (
              <div className="rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-700">{asociarError}</div>
            )}

            <div className="flex justify-end gap-2 pt-1">
              <button
                type="button"
                onClick={() => setAsociarOpen(false)}
                disabled={asociarGuardando}
                className="rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50"
              >
                Cerrar
              </button>
            </div>
          </div>
        </div>
      )}

      <PesoModal
        producto={pesoProducto}
        onCancel={() => setPesoProducto(null)}
        onConfirm={agregarConPeso}
      />
    </div>
  );
}
