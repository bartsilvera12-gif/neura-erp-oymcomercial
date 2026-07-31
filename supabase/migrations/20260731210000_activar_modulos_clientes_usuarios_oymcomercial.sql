-- =============================================================================
-- Activar módulos Clientes y Usuarios en el schema `oymcomercial`.
--
-- Corrige la migración previa 20260731200000, que apuntaba a `zentra_erp` y
-- `public` — schemas de la flota central que NO existen en esta instancia
-- monocliente. En este repo el schema operativo es `oymcomercial`
-- (ver src/lib/supabase/schema.ts, NEURA_CLIENT_SCHEMA).
--
-- Sidebar en modo `single_client` usa allowlist estricta: el slug debe existir
-- en `oymcomercial.modulos` y estar activo en `oymcomercial.empresa_modulos`
-- para que aparezca en el menú.
--
-- NO se insertan filas en `usuario_modulos`. El resolvedor trata "0 filas" como
-- acceso completo; agregar una sola fila deja al usuario restringido a esa
-- única entrada (ver comentario extenso en 20260721120000_transferencias_
-- inventario.sql:155). Los usuarios con acceso completo van a ver los nuevos
-- items automáticamente; a los que ya tienen lista explícita hay que
-- agregarles `clientes` / `usuarios` desde la pantalla de Usuarios.
--
-- Idempotente en catálogo y en empresa_modulos: no duplica filas ni pisa
-- desactivaciones manuales.
-- =============================================================================

INSERT INTO oymcomercial.modulos (slug, nombre)
SELECT 'clientes', 'Clientes'
WHERE NOT EXISTS (SELECT 1 FROM oymcomercial.modulos WHERE slug = 'clientes');

INSERT INTO oymcomercial.modulos (slug, nombre)
SELECT 'usuarios', 'Usuarios'
WHERE NOT EXISTS (SELECT 1 FROM oymcomercial.modulos WHERE slug = 'usuarios');

INSERT INTO oymcomercial.empresa_modulos (empresa_id, modulo_id, activo)
SELECT e.id, m.id, true
  FROM oymcomercial.empresas e
 CROSS JOIN oymcomercial.modulos m
 WHERE m.slug IN ('clientes', 'usuarios')
   AND NOT EXISTS (
     SELECT 1 FROM oymcomercial.empresa_modulos em
      WHERE em.empresa_id = e.id AND em.modulo_id = m.id
   );
