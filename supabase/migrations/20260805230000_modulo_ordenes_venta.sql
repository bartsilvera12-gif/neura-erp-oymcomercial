-- Módulo "Órdenes de venta" separado del módulo "Ventas" (POS de Caja).
--
-- Motivación: hasta ahora tanto el POS (/ventas) como el historial de órdenes
-- (/ventas/ordenes) compartían el mismo slug `ventas`, así que no se podía
-- darle a un usuario acceso al historial sin abrirle el POS. Ahora son dos
-- slugs distintos:
--   `ventas`         → /ventas             (POS / Caja)
--   `ordenes_venta`  → /ventas/ordenes     (historial, anulaciones, reimpresión)
--
-- Compatibilidad: en route-slug-map.ts el resolvedor otorga `ordenes_venta`
-- automáticamente a quien tenga `ventas` (así los usuarios actuales no pierden
-- acceso). Para restringir, el admin da `ordenes_venta` sin `ventas`, o
-- desactiva el módulo en la ficha del usuario.
--
-- Idempotente en catálogo y en empresa_modulos. No toca usuario_modulos
-- (misma razón que la migración de Clientes/Usuarios: 0 filas = acceso total,
-- meter una lo restringe).

INSERT INTO oymcomercial.modulos (slug, nombre)
SELECT 'ordenes_venta', 'Órdenes de venta'
WHERE NOT EXISTS (SELECT 1 FROM oymcomercial.modulos WHERE slug = 'ordenes_venta');

INSERT INTO oymcomercial.empresa_modulos (empresa_id, modulo_id, activo)
SELECT e.id, m.id, true
  FROM oymcomercial.empresas e
 CROSS JOIN oymcomercial.modulos m
 WHERE m.slug = 'ordenes_venta'
   AND NOT EXISTS (
     SELECT 1 FROM oymcomercial.empresa_modulos em
      WHERE em.empresa_id = e.id AND em.modulo_id = m.id
   );
