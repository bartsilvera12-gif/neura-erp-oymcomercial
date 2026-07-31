-- ============================================================================
-- Permisos de las tablas del módulo Caja
-- ============================================================================
--
-- Arregla "permission denied for table cajas" al abrir caja.
--
-- La migración 20260731120000 creó `cajas` y `caja_movimientos` pero no otorgó
-- privilegios. PostgREST se conecta con los roles anon / authenticated /
-- service_role, y una tabla recién creada no le da acceso a ninguno: el dueño
-- del schema es el único que puede tocarla. De ahí el permission denied, que no
-- es de RLS sino de GRANT.
--
-- SOLO service_role, a diferencia del resto del schema.
-- El grueso de las tablas de `oymcomercial` está grantado también a anon y
-- authenticated, y se protege con RLS. La caja no la toca nunca el navegador:
-- todo pasa por /api/caja/*, que usa createServiceRoleClientWithDbSchema. Dar
-- acceso a anon sobre tablas sin políticas dejaría el arqueo —montos de
-- apertura, cierre, diferencias— legible y escribible con la anon key, que es
-- pública. Se otorga lo mínimo que hace falta.
--
-- RLS queda habilitada sin políticas: deny by default para todos los roles.
-- service_role no se ve afectado porque tiene BYPASSRLS. Es cinturón y
-- tirantes: si alguien más adelante granta anon o authenticated sobre estas
-- tablas, la ausencia de políticas lo sigue frenando.
-- ============================================================================

BEGIN;

GRANT SELECT, INSERT, UPDATE, DELETE ON "oymcomercial"."cajas" TO "service_role";
GRANT SELECT, INSERT, UPDATE, DELETE ON "oymcomercial"."caja_movimientos" TO "service_role";

ALTER TABLE "oymcomercial"."cajas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "oymcomercial"."caja_movimientos" ENABLE ROW LEVEL SECURITY;

COMMIT;
