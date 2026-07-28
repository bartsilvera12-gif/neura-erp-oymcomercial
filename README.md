# Neura ERP — O&M Comercial

Instancia ERP dedicada (monocliente) para **O&M Comercial**, derivada de la base estable de Neura ERP.

- **Schema PostgreSQL:** `oymcomercial` (aislado, sin dependencias a otros clientes)
- **Instancia:** monocliente (`NEURA_INSTANCE_MODE=single_client`)
- **Moneda:** PYG · **Zona horaria:** America/Asuncion
- **Stack:** Next.js (App Router) + Supabase (PostgREST + Auth + Storage)

## Configuración

1. Copiá `.env.example` a `.env.local` y completá los valores (nunca commitees `.env*` reales).
2. El schema operativo se resuelve por `NEURA_CLIENT_SCHEMA` (default en código: `oymcomercial`). No hay fallback a otros schemas.

```bash
npm ci
npm run dev
```

Abrí [http://localhost:3000](http://localhost:3000).

## Aprovisionamiento de base de datos

El schema `oymcomercial` se crea/clona con artefactos versionados en:

- `supabase/provision/oymcomercial-schema.sql` — estructura (tablas, índices, FKs, funciones, triggers, RLS, policies, grants)
- `supabase/provision/oymcomercial-seed.sql` — catálogos genéricos + empresa base (allowlist explícita)
- `scripts/provision-oymcomercial.ts` — generador reproducible desde `reservacaacupe` (solo estructura)
- `scripts/verify-oymcomercial-schema.ts` — verificación de objetos y aislamiento

Ver el runbook completo en [`docs/CLONACION_OYMCOMERCIAL.md`](docs/CLONACION_OYMCOMERCIAL.md).

## Scripts

```bash
npm run lint
npm run build
```
