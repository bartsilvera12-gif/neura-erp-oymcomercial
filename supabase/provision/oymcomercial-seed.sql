-- =====================================================================
-- Seed 'oymcomercial': catálogos genéricos (allowlist explícita) + empresa base.
-- Sin datos productivos, fiscales ni de clientes del origen.
-- empresa_id generado en runtime (gen_random_uuid). Idempotente.
-- Moneda PYG y TZ America/Asuncion son defaults de aplicación
-- (la tabla empresas no tiene columnas de moneda/timezone).
-- =====================================================================
BEGIN;

-- Catálogo global de módulos (29)
INSERT INTO oymcomercial.modulos (id,created_at,nombre,descripcion,slug) VALUES
  ('d6e12622-7178-4d19-8277-bb974e238faf','2026-05-18T10:53:21.462Z','Campañas WhatsApp',NULL,'campanas'),
  ('3b6391bb-e77a-464b-84ea-1f95884cffc3','2026-05-18T10:53:21.462Z','Clientes',NULL,'clientes'),
  ('3bcaff06-0785-47fd-bf7a-a3721d421b10','2026-06-10T12:40:16.154Z','Cobros','Cuentas por cobrar y cobros de clientes','cobros'),
  ('e09e242b-2975-47d5-a4d5-42398e013641','2026-05-18T10:53:21.462Z','Comisiones',NULL,'comisiones'),
  ('aea02686-46a2-4448-a9b3-fe83b4a03491','2026-05-18T10:53:21.462Z','Compras',NULL,'compras'),
  ('96f10ea8-a801-41a6-951f-83b7fcf5a0ab','2026-05-18T10:53:21.462Z','Configuración',NULL,'configuracion'),
  ('3cb40f93-1aed-4bcc-a800-a1b4ecabc0fe','2026-05-18T10:53:21.462Z','Conversaciones',NULL,'conversaciones'),
  ('914f9f31-b968-4de6-907f-2a1281a8d5fc','2026-05-18T10:53:21.462Z','Conversaciones finalizadas',NULL,'conversaciones-finalizadas'),
  ('e59cc5a3-5f7c-4a6c-afe2-d7f1a67fe602','2026-05-18T10:53:21.462Z','CRM Funnel',NULL,'crm'),
  ('7cb297a1-b49b-4ef5-9777-09f4518402a1','2026-05-18T10:53:21.462Z','Dashboard',NULL,'dashboard'),
  ('f497bf2a-d650-460a-b5ab-f72018fed47b','2026-05-18T10:53:21.462Z','Gastos',NULL,'gastos'),
  ('63025c6b-8417-4b9a-8f1c-034002279778','2026-05-18T10:53:21.462Z','Gestión Clientes',NULL,'gestion-clientes'),
  ('4b6bdaf2-1790-424d-bb80-b404235ddd49','2026-05-18T10:53:21.462Z','Historial omnicanal',NULL,'historial-omnicanal'),
  ('569781c8-7e1d-4ac9-b240-e7bb82a0b83b','2026-05-18T10:53:21.462Z','Inventario',NULL,'inventario'),
  ('98d53199-0259-4ade-9dbc-e8f67918305c','2026-05-18T10:53:21.462Z','Marketing Ops',NULL,'marketing'),
  ('49abab54-4d2b-40a3-8feb-131e2430e764','2026-05-18T10:53:21.462Z','Marketing Ops',NULL,'marketing_ops'),
  ('ea66f279-2861-4835-8cec-1228e12f64ff','2026-05-18T10:53:21.462Z','Monitoreo',NULL,'monitoreo'),
  ('1d917292-2e2e-4c9f-9615-4565b3b51dd9','2026-05-18T10:53:21.462Z','Notas de crédito',NULL,'notas_credito'),
  ('80b7c821-5b12-4802-a7ed-2dd2c3d972d3','2026-05-18T10:53:21.462Z','Omnicanal (paquete)',NULL,'omnicanal'),
  ('de613097-35c8-4b05-be53-bc6bde5d5f0b','2026-05-18T10:53:21.462Z','Pagos',NULL,'pagos'),
  ('2f0b9c7b-965b-4c70-8480-53442cdd41fc','2026-05-18T10:53:21.462Z','Planes',NULL,'planes'),
  ('3f4b07ed-668d-4f86-917f-d354329b5fc3','2026-06-09T19:57:15.590Z','Presupuestos','Presupuestos / cotizaciones comerciales','presupuestos'),
  ('dc402405-7428-4770-9573-2a45321aaaba','2026-05-18T10:53:21.462Z','Proyectos',NULL,'proyectos'),
  ('19f4f4cd-ee2a-41cf-a8a9-5930e8703fd2','2026-05-18T17:09:48.306Z','Recetas','Recetas y costeo de productos','recetas'),
  ('e22671a3-2a8d-4478-9916-3b037f87c592','2026-06-07T17:35:51.651Z','Reportes','Reportería operativa (estado de cuenta, proveedores)','reportes'),
  ('0c41bd3f-f4a2-4914-b98c-e976b51a270e','2026-07-23T18:57:03.474Z','Reposición entre sucursales',NULL,'reposicion'),
  ('c0f676ac-d879-48b2-a78a-6db59fabb100','2026-05-18T10:53:21.462Z','Sorteos',NULL,'sorteos'),
  ('1a9717b9-8a8e-42f3-b46b-a9e559543d8b','2026-05-18T10:53:21.462Z','Usuarios',NULL,'usuarios'),
  ('3a1a6701-f6c5-48fd-b599-c6f88bc48374','2026-05-18T10:53:21.462Z','Ventas',NULL,'ventas')
ON CONFLICT (id) DO NOTHING;

-- Catálogo global de vistas de dashboard (4)
INSERT INTO oymcomercial.dashboard_views (id,slug,nombre,orden,activo,created_at) VALUES
  ('2c64c937-5537-4550-b846-94345fbc8583','comercial','Comercial',10,true,'2026-06-05T13:43:52.061Z'),
  ('c53eec08-84a9-4e5e-a656-74b8a2fc8e44','financiero','Financiero',20,true,'2026-06-05T13:43:52.061Z'),
  ('87f0e8f7-7bda-4d72-9c51-8e45363fa5ba','inventario','Inventario',30,true,'2026-06-05T13:43:52.061Z'),
  ('76e2b19c-2f47-4306-a8ce-da9162910f1f','ventas','Ventas',40,true,'2026-06-05T13:43:52.061Z')
ON CONFLICT (id) DO NOTHING;

DO $seed$
DECLARE v_emp uuid;
BEGIN
  -- Empresa O&M Comercial (idempotente por nombre). UUID generado por PostgreSQL.
  SELECT id INTO v_emp FROM oymcomercial.empresas WHERE nombre_empresa = 'O&M Comercial' LIMIT 1;
  IF v_emp IS NULL THEN
    INSERT INTO oymcomercial.empresas (nombre_empresa, ruc, telefono, email, direccion, pais, plan, estado, data_schema, gestion_tributaria_clientes)
    VALUES ('O&M Comercial', NULL, NULL, NULL, NULL, 'PARAGUAY', NULL, 'ACTIVA', 'oymcomercial', false)
    RETURNING id INTO v_emp;
  END IF;

  -- Módulos habilitados: mismo set que el ERP origen (15 módulos)
  INSERT INTO oymcomercial.empresa_modulos (empresa_id, activo, modulo_id)
  SELECT v_emp, true, m.id FROM oymcomercial.modulos m
  WHERE m.slug IN ('clientes', 'compras', 'configuracion', 'dashboard', 'gastos', 'gestion-clientes', 'inventario', 'notas_credito', 'omnicanal', 'pagos', 'presupuestos', 'proyectos', 'recetas', 'reportes', 'ventas')
    AND NOT EXISTS (SELECT 1 FROM oymcomercial.empresa_modulos em WHERE em.empresa_id=v_emp AND em.modulo_id=m.id);

  -- Vistas de dashboard habilitadas (todas las globales)
  INSERT INTO oymcomercial.empresa_dashboard_views (empresa_id, dashboard_view_id, activo)
  SELECT v_emp, dv.id, true FROM oymcomercial.dashboard_views dv
    WHERE NOT EXISTS (SELECT 1 FROM oymcomercial.empresa_dashboard_views x WHERE x.empresa_id=v_emp AND x.dashboard_view_id=dv.id);

  -- Catálogo de entidades bancarias (genérico PY; sin cuentas ni titulares)
  INSERT INTO oymcomercial.entidades_bancarias (empresa_id, nombre, tipo, activo, orden, codigo)
  SELECT v_emp, x.nombre, x.tipo, x.activo, x.orden, x.codigo FROM (VALUES
    ('Banco BASA S.A.','banco',false,0,'001'),
    ('BANCO ITAU','banco',false,0,'002'),
    ('BANCO UENO','banco',false,0,'003'),
    ('BANCO FAMILIAR','banco',false,1,'004'),
    ('BANCO SUDAMERIS','banco',false,2,'005'),
    ('BANCO CONTINENTAL','banco',true,3,'006'),
    ('BANCO ATLAS','banco',false,4,'007'),
    ('Bancop (Banco para la Comercialización y la Producción S.A.)','banco',true,7,'008')
  ) AS x(nombre,tipo,activo,orden,codigo)
  WHERE NOT EXISTS (SELECT 1 FROM oymcomercial.entidades_bancarias e WHERE e.empresa_id=v_emp AND coalesce(e.codigo,'')=coalesce(x.codigo,'') AND e.nombre=x.nombre);

  -- CRM: etapas genéricas
  INSERT INTO oymcomercial.crm_etapas (empresa_id, codigo, nombre, color, orden, activo)
  SELECT v_emp, x.codigo, x.nombre, x.color, x.orden, x.activo FROM (VALUES
    ('LEAD','Lead','gray',1,true),
    ('CONTACTADO','Contactado','blue',2,true),
    ('NEGOCIACION','Negociación','amber',3,true),
    ('GANADO','Ganado','green',4,true),
    ('PERDIDO','Perdido','red',5,true)
  ) AS x(codigo,nombre,color,orden,activo)
  WHERE NOT EXISTS (SELECT 1 FROM oymcomercial.crm_etapas e WHERE e.empresa_id=v_emp AND e.codigo=x.codigo);

  -- Proyectos: estados genéricos
  INSERT INTO oymcomercial.proyecto_estados (empresa_id, nombre, codigo, descripcion, color, sort_order, cuenta_sla, tipo_sla, sla_horas_objetivo, es_estado_inicial, es_estado_final, activo)
  SELECT v_emp, x.nombre, x.codigo, x.descripcion, x.color, x.sort_order::int, x.cuenta_sla, x.tipo_sla, x.sla_horas_objetivo::int, x.es_estado_inicial, x.es_estado_final, x.activo FROM (VALUES
    ('Nuevo','nuevo',NULL,'#2563eb',10,true,'interno',NULL,true,false,true),
    ('En preparación','en_preparacion',NULL,'#f59e0b',20,true,'interno',NULL,false,false,true),
    ('Listo','listo',NULL,'#10b981',30,true,'interno',NULL,false,false,true),
    ('En camino','en_camino',NULL,'#8b5cf6',40,true,'interno',NULL,false,false,true),
    ('Entregado','entregado',NULL,'#16a34a',50,true,'final',NULL,false,true,true),
    ('Cancelado','cancelado',NULL,'#ef4444',60,true,'final',NULL,false,true,true)
  ) AS x(nombre,codigo,descripcion,color,sort_order,cuenta_sla,tipo_sla,sla_horas_objetivo,es_estado_inicial,es_estado_final,activo)
  WHERE NOT EXISTS (SELECT 1 FROM oymcomercial.proyecto_estados e WHERE e.empresa_id=v_emp AND e.codigo=x.codigo);

  -- Proyectos: tipos genéricos
  INSERT INTO oymcomercial.proyecto_tipos (empresa_id, nombre, codigo, descripcion, config, activo)
  SELECT v_emp, x.nombre, x.codigo, x.descripcion, x.config::jsonb, x.activo FROM (VALUES
    ('Pedido','pedido',NULL,'{}',true),
    ('SaaS / ERP','saas','Implementaciones SaaS y ERP para clientes','{}',true),
    ('Proyecto Web','web','Sitios y landings vendidos por comercial','{}',true)
  ) AS x(nombre,codigo,descripcion,config,activo)
  WHERE NOT EXISTS (SELECT 1 FROM oymcomercial.proyecto_tipos e WHERE e.empresa_id=v_emp AND e.codigo=x.codigo);

  -- Proyectos: prioridades genéricas
  INSERT INTO oymcomercial.proyecto_prioridades_config (empresa_id, codigo, nombre, color, bg_color, text_color, border_color, sort_order, activo)
  SELECT v_emp, x.codigo, x.nombre, x.color, x.bg_color, x.text_color, x.border_color, x.sort_order, x.activo FROM (VALUES
    ('baja','Baja','#64748b','#f1f5f9','#475569','#cbd5e1',10,true),
    ('normal','Media','#475569','#e2e8f0','#1e293b','#cbd5e1',20,true),
    ('alta','Alta','#f97316','#f97316','#ffffff','#ea580c',30,true),
    ('urgente','Urgente','#dc2626','#dc2626','#ffffff','#b91c1c',40,true)
  ) AS x(codigo,nombre,color,bg_color,text_color,border_color,sort_order,activo)
  WHERE NOT EXISTS (SELECT 1 FROM oymcomercial.proyecto_prioridades_config e WHERE e.empresa_id=v_emp AND e.codigo=x.codigo);

  -- Clientes: catálogo de tipos de servicio (defaults de sistema)
  INSERT INTO oymcomercial.cliente_tipos_servicio_catalogo (empresa_id, slug, nombre, activo, orden, es_sistema)
  SELECT v_emp, x.slug, x.nombre, x.activo, x.orden, x.es_sistema FROM (VALUES
    ('marketing','Marketing',true,10,true),
    ('saas','SaaS',true,20,true),
    ('branding','Branding',true,30,true),
    ('web','Web',true,40,true),
    ('otro','Otro',true,50,true)
  ) AS x(slug,nombre,activo,orden,es_sistema)
  WHERE NOT EXISTS (SELECT 1 FROM oymcomercial.cliente_tipos_servicio_catalogo e WHERE e.empresa_id=v_emp AND e.slug=x.slug);

  -- Modo de facturación NEUTRAL (sin SIFEN; O&M configura su fiscalidad luego)
  INSERT INTO oymcomercial.empresa_facturacion_modo (empresa_id, modo, impresion_tipo_default, imprimir_al_confirmar, preguntar_datos_al_confirmar, activo)
  VALUES (v_emp, 'sin_factura_fiscal', 'pdf_a4', false, false, true)
  ON CONFLICT (empresa_id) DO NOTHING;

  RAISE NOTICE 'Seed O&M Comercial aplicado. empresa_id=%', v_emp;
END $seed$;

COMMIT;