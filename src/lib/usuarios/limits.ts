/**
 * Tope de usuarios ACTIVOS de la instancia.
 *
 * Se cuenta al admin actual — el conteo es sobre usuarios con `estado='activo'`
 * en `usuarios`, sin excluir a nadie. Un usuario inactivo no ocupa cupo, así
 * que dar de baja libera un puesto.
 *
 * Server-only: solo se resuelve en el server (referencia a process.env). El
 * cliente lo recibe vía el endpoint GET /api/empresas/usuarios para renderizar
 * el contador "X/N activos" sin duplicar el default.
 */
export const MAX_USUARIOS_ACTIVOS = Number(process.env.NEURA_MAX_USUARIOS ?? 4) || 4;
