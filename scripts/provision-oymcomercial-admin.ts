/**
 * Crea el usuario ADMINISTRADOR inicial de O&M Comercial (paso DIFERIDO).
 *
 * NO copia usuarios del origen. Crea el usuario en Supabase Auth (auth.users)
 * y lo vincula a oymcomercial.usuarios con rol 'admin' y la empresa O&M Comercial.
 * Se cumple:  auth.users.id = oymcomercial.usuarios.auth_user_id
 *
 * Requiere en .env.local (NUNCA commitear):
 *   NEXT_PUBLIC_SUPABASE_URL
 *   SUPABASE_SERVICE_ROLE_KEY
 *   OYM_ADMIN_EMAIL
 *   OYM_ADMIN_NAME
 *   OYM_ADMIN_PASSWORD          (contraseña fuerte; el usuario debería cambiarla al primer login)
 *
 * Uso: npx tsx scripts/provision-oymcomercial-admin.ts
 */
import { config } from "dotenv";
import * as path from "path";
import { createClient } from "@supabase/supabase-js";
import { SUPABASE_APP_SCHEMA } from "../src/lib/supabase/schema";

config({ path: path.resolve(process.cwd(), ".env.local") });

const EMPRESA_NOMBRE = "O&M Comercial";

async function main() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();
  const email = process.env.OYM_ADMIN_EMAIL?.trim().toLowerCase();
  const nombre = process.env.OYM_ADMIN_NAME?.trim();
  const password = process.env.OYM_ADMIN_PASSWORD;

  if (!url || !key) { console.error("Faltan NEXT_PUBLIC_SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY"); process.exit(2); }
  if (!email || !nombre || !password) { console.error("Faltan OYM_ADMIN_EMAIL / OYM_ADMIN_NAME / OYM_ADMIN_PASSWORD"); process.exit(2); }

  const sb = createClient(url, key, {
    auth: { autoRefreshToken: false, persistSession: false },
    db: { schema: SUPABASE_APP_SCHEMA }, // oymcomercial
  });

  // 1) Resolver empresa (no hardcodear UUID)
  const { data: empresa, error: eErr } = await sb.from("empresas").select("id").eq("nombre_empresa", EMPRESA_NOMBRE).single();
  if (eErr || !empresa) { console.error("No se encontró la empresa O&M Comercial. Corré primero provision-oymcomercial.ts"); process.exit(1); }
  const empresaId = (empresa as { id: string }).id;

  // 2) Crear (o reutilizar) usuario en Supabase Auth
  let authUserId: string | undefined;
  const { data: created, error: aErr } = await sb.auth.admin.createUser({ email, password, email_confirm: true });
  if (aErr) {
    if (aErr.message?.includes("already been registered")) {
      const { data: list } = await sb.auth.admin.listUsers();
      authUserId = list?.users?.find((u) => u.email === email)?.id;
      if (authUserId) await sb.auth.admin.updateUserById(authUserId, { password });
      console.log("Usuario Auth ya existía; contraseña actualizada.");
    } else { console.error("Error Auth:", aErr.message); process.exit(1); }
  } else {
    authUserId = created?.user?.id;
    console.log("Usuario creado en Supabase Auth.");
  }
  if (!authUserId) { console.error("No se pudo resolver auth_user_id"); process.exit(1); }

  // 3) Upsert en oymcomercial.usuarios (rol admin, ligado a la empresa nueva)
  const { data: existing } = await sb.from("usuarios").select("id").eq("email", email).maybeSingle();
  const row = { email, nombre, rol: "admin", empresa_id: empresaId, auth_user_id: authUserId, activo: true, estado: "activo" };
  const { error: uErr } = existing
    ? await sb.from("usuarios").update(row).eq("email", email)
    : await sb.from("usuarios").insert(row);
  if (uErr) { console.error("Error usuarios:", uErr.message); process.exit(1); }

  console.log(`✅ Admin listo: ${email} (rol=admin, empresa=${EMPRESA_NOMBRE}/${empresaId}, auth_user_id=${authUserId})`);
}

main().catch((e) => { console.error("ERROR:", e.message); process.exit(1); });
