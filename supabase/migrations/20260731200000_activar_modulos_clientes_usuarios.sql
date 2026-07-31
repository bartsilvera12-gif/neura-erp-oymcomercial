-- =============================================================================
-- Activar módulos Clientes y Usuarios para todas las empresas.
-- Los slugs ya existen en el catálogo (ver 20260331200000). Esta migración
-- garantiza que estén habilitados en empresa_modulos y otorga las asignaciones
-- correspondientes en usuario_modulos para usuarios no super_admin.
-- Idempotente: no duplica filas si ya existen; no se pisa activo=false manual.
-- =============================================================================

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'zentra_erp' AND table_name = 'modulos'
  ) THEN
    INSERT INTO zentra_erp.modulos (id, nombre, slug)
    SELECT gen_random_uuid(), 'Clientes', 'clientes'
    WHERE NOT EXISTS (SELECT 1 FROM zentra_erp.modulos WHERE slug = 'clientes');

    INSERT INTO zentra_erp.modulos (id, nombre, slug)
    SELECT gen_random_uuid(), 'Usuarios', 'usuarios'
    WHERE NOT EXISTS (SELECT 1 FROM zentra_erp.modulos WHERE slug = 'usuarios');

    INSERT INTO zentra_erp.empresa_modulos (empresa_id, modulo_id, activo)
    SELECT e.id, m.id, true
    FROM zentra_erp.empresas e
    CROSS JOIN zentra_erp.modulos m
    WHERE m.slug IN ('clientes', 'usuarios')
      AND NOT EXISTS (
        SELECT 1 FROM zentra_erp.empresa_modulos em
        WHERE em.empresa_id = e.id AND em.modulo_id = m.id
      );
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'modulos'
  ) THEN
    INSERT INTO public.modulos (id, nombre, slug)
    SELECT gen_random_uuid(), 'Clientes', 'clientes'
    WHERE NOT EXISTS (SELECT 1 FROM public.modulos WHERE slug = 'clientes');

    INSERT INTO public.modulos (id, nombre, slug)
    SELECT gen_random_uuid(), 'Usuarios', 'usuarios'
    WHERE NOT EXISTS (SELECT 1 FROM public.modulos WHERE slug = 'usuarios');

    INSERT INTO public.empresa_modulos (empresa_id, modulo_id, activo)
    SELECT e.id, m.id, true
    FROM public.empresas e
    CROSS JOIN public.modulos m
    WHERE m.slug IN ('clientes', 'usuarios')
      AND NOT EXISTS (
        SELECT 1 FROM public.empresa_modulos em
        WHERE em.empresa_id = e.id AND em.modulo_id = m.id
      );

    -- Backfill usuario_modulos: cada usuario no-super_admin recibe los nuevos
    -- slugs si su empresa los tiene activos y todavía no los tenía asignados.
    -- Necesario porque el trigger de coherencia (ver 20260331200000) bloquea
    -- futuras asignaciones si la fila de empresa_modulos no está activa, y sin
    -- backfill los usuarios existentes seguirían sin ver el ítem en el sidebar.
    INSERT INTO public.usuario_modulos (usuario_id, modulo_id)
    SELECT u.id, em.modulo_id
    FROM public.usuarios u
    JOIN public.empresa_modulos em
      ON em.empresa_id = u.empresa_id AND em.activo IS TRUE
    JOIN public.modulos m ON m.id = em.modulo_id
    WHERE u.empresa_id IS NOT NULL
      AND COALESCE(u.rol, '') <> 'super_admin'
      AND m.slug IN ('clientes', 'usuarios')
      AND NOT EXISTS (
        SELECT 1 FROM public.usuario_modulos um2
        WHERE um2.usuario_id = u.id AND um2.modulo_id = em.modulo_id
      )
    ON CONFLICT (usuario_id, modulo_id) DO NOTHING;
  END IF;
END $$;
