# Runbook — Clonación de O&M Comercial

Instancia ERP dedicada (monocliente) derivada de la base **Neura ERP** (origen:
Reserva Ecológica Caacupé). Este documento es la traza técnica de la clonación.
Las menciones al origen aquí son **solo para trazabilidad**; no forman parte de la
configuración operativa.

## 1. Identidad

| Ítem | Valor |
|------|-------|
| Nombre visible | **O&M Comercial** |
| Schema PostgreSQL | `oymcomercial` |
| Schema origen (traza) | `reservacaacupe` |
| Baseline origen (SHA) | `5f2453d218f9bcc78f3bd609522aba0ed5d087d3` |
| Instancia | `single_client` |
| Moneda / Zona horaria | PYG / America/Asuncion (defaults de aplicación; `empresas` no tiene columnas de moneda/TZ) |
| empresa_id | generado en runtime por PostgreSQL (`gen_random_uuid`), **no hardcodeado** en código |

## 2. Resolución de schema (arquitectura)

El schema operativo lo resuelve `NEURA_CLIENT_SCHEMA` (default en código:
`oymcomercial`, ver `src/lib/supabase/schema.ts`). **No hay fallback** a
`reservacaacupe`, `zentra_erp` ni `public` para datos operativos. Variables:

```
NEURA_CLIENT_SCHEMA=oymcomercial
NEURA_CLIENT_NAME=O&M Comercial
NEURA_INSTANCE_MODE=single_client
APP_DB_SCHEMA=oymcomercial            # compat futura (no usado hoy por el código)
NEXT_PUBLIC_APP_DB_SCHEMA=oymcomercial # compat futura
```

## 3. Artefactos versionados

| Archivo | Rol |
|---------|-----|
| `supabase/provision/oymcomercial-schema.sql` | Estructura completa (tablas, columnas, defaults, PK/UNIQUE/CHECK/FK, índices, funciones, triggers, RLS, policies, grants, comentarios) reescrita `reservacaacupe`/`enlodemari` → `oymcomercial`. |
| `supabase/provision/oymcomercial-seed.sql` | Catálogos genéricos (allowlist) + empresa base. Idempotente. `empresa_id` generado en runtime. |
| `supabase/provision/oymcomercial-rollback.sql` | `DROP SCHEMA oymcomercial CASCADE` — alcance limitado al schema nuevo. |
| `scripts/provision-oymcomercial.ts` | Aplica estructura (si falta) + seed. `--reset` recrea. |
| `scripts/verify-oymcomercial-schema.ts` | Verificación de objetos + aislamiento + empresa. |
| `scripts/provision-oymcomercial-admin.ts` | Alta del administrador (paso **diferido**). |

## 4. Provisionamiento

```bash
# Requiere SUPABASE_DB_URL en .env.local
npx tsx scripts/provision-oymcomercial.ts
npx tsx scripts/verify-oymcomercial-schema.ts
```

El schema se clonó por **introspección de catálogos** del origen (no `pg_dump`),
emitiendo DDL reescrito. Reglas de reescritura aplicadas a funciones, policies,
triggers, índices, constraints y defaults:

- `reservacaacupe` → `oymcomercial` (identificador whole-word)
- `enlodemari` → `oymcomercial` (fuga de schema hermano en `search_path`, resto de un clon previo del origen)

## 5. Qué se copió y qué NO

**Catálogos copiados (allowlist explícita, genéricos):**
`modulos` (global), `dashboard_views` (global), y por-empresa: `empresa_modulos`
(mismo set habilitado que el origen), `empresa_dashboard_views`,
`entidades_bancarias` (catálogo de bancos PY, sin cuentas), `crm_etapas`,
`proyecto_estados`, `proyecto_tipos`, `proyecto_prioridades_config`,
`cliente_tipos_servicio_catalogo`, `empresa_facturacion_modo` (modo neutral
`sin_factura_fiscal`).

**Deliberadamente EXCLUIDO (cero datos productivos/privados del origen):**
clientes, proveedores, productos, ventas, compras, pagos, facturas, cajas,
conversaciones/mensajes, comprobantes, sorteos/cupones/tickets, movimientos,
archivos, `empresa_sifen_config` (RUC/timbrado/CSC/certificado/contraseña/
dirección fiscal del origen), usuarios del origen, WhatsApp/phone_number_id/
verify tokens/canales/webhooks, cuentas bancarias, integraciones privadas.

**Funciones de plataforma excluidas** (tooling de provisión que referencia
`zentra_erp`/`enlodemari`/`public`, no usadas por app/policies/triggers):
`neura_clone_omnicanal_schema`, `neura_clone_zentra_erp_to_tenant`,
`neura_enlodemari_block_other_empresas`, `neura_fix_foreign_keys_retarget_from_public`,
`neura_install_nota_credito_tables`, `neura_provision_empresa_data_schema`,
`neura_teardown_provision_failed`, `neura_upgrade_factura_correlativo`,
`neura_upgrade_factura_estado_corregida_nc`, `neura_upgrade_nota_credito_fase2`.
`neura_inbox_awaiting_reply_since_batch` **sí** se incluye (la usa la app; está
parametrizada por schema).

## 6. Aislamiento (garantías verificadas)

- FKs de `oymcomercial` referencian **solo** `oymcomercial` (297) + `auth.users` (9, Supabase compartido).
- 0 funciones y 0 policies de `oymcomercial` referencian `reservacaacupe`/`enlodemari`/`zentra_erp`.
- Tablas operativas vacías; catálogos mínimos presentes.

## 7. Administrador (DIFERIDO)

No se creó admin todavía (a pedido). Para crearlo, completar en `.env.local`
`OYM_ADMIN_EMAIL`, `OYM_ADMIN_NAME`, `OYM_ADMIN_PASSWORD` (+ `NEXT_PUBLIC_SUPABASE_URL`,
`SUPABASE_SERVICE_ROLE_KEY`) y ejecutar:

```bash
npx tsx scripts/provision-oymcomercial-admin.ts
```

Crea el usuario en `auth.users` y lo vincula a `oymcomercial.usuarios`
(rol `admin`, `auth_user_id = auth.users.id`).

## 8. Exposición PostgREST

`oymcomercial` debe estar en `pgrst.db_schemas`. Procedimiento y verificación en
la sección correspondiente del informe de entrega. Verificación esperada:

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  -H "apikey: $NEXT_PUBLIC_SUPABASE_ANON_KEY" \
  -H "Accept-Profile: oymcomercial" \
  "$NEXT_PUBLIC_SUPABASE_URL/rest/v1/"
# → 200
```

## 9. Rollback

```bash
npx tsx scripts/provision-oymcomercial.ts --reset   # o aplicar oymcomercial-rollback.sql
```

`DROP SCHEMA oymcomercial CASCADE` afecta **solo** al schema nuevo (incluye sus
FKs internas hacia `auth.users`; las filas de `auth.users` no se tocan).
