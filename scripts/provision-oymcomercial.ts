/**
 * Aprovisiona el schema aislado `oymcomercial` aplicando los artefactos
 * versionados (estructura + seed). Reproducible e idempotente.
 *
 * Requiere en .env.local:  SUPABASE_DB_URL
 *
 * Uso:
 *   npx tsx scripts/provision-oymcomercial.ts          # aplica estructura (si falta) + seed
 *   npx tsx scripts/provision-oymcomercial.ts --reset  # DROP SCHEMA oymcomercial CASCADE y recrea
 *
 * NOTA: NO lee ni escribe en `reservacaacupe`. Los .sql son autocontenidos.
 */
import { config } from "dotenv";
import * as path from "path";
import * as fs from "fs";
import pg from "pg";

config({ path: path.resolve(process.cwd(), ".env.local") });

const SCHEMA = "oymcomercial";
const DIR = path.resolve(process.cwd(), "supabase/provision");
const RESET = process.argv.includes("--reset");

async function main() {
  const url = process.env.SUPABASE_DB_URL?.trim();
  if (!url) {
    console.error("Falta SUPABASE_DB_URL en .env.local");
    process.exit(2);
  }
  const c = new pg.Client({
    connectionString: url,
    ssl: url.includes("supabase") ? { rejectUnauthorized: false } : undefined,
  });
  await c.connect();
  try {
    if (RESET) {
      console.log(`⚠️  --reset: DROP SCHEMA ${SCHEMA} CASCADE (limitado al schema nuevo)`);
      await c.query(fs.readFileSync(path.join(DIR, `${SCHEMA}-rollback.sql`), "utf8"));
    }

    const exists =
      (await c.query(`select count(*)::int n from pg_namespace where nspname=$1`, [SCHEMA]))
        .rows[0].n > 0;

    if (!exists) {
      console.log("→ Aplicando estructura (oymcomercial-schema.sql)…");
      await c.query(fs.readFileSync(path.join(DIR, `${SCHEMA}-schema.sql`), "utf8"));
      console.log("  estructura OK");
    } else {
      console.log("→ Schema ya existe; se omite estructura (usá --reset para recrear).");
    }

    console.log("→ Aplicando seed idempotente (oymcomercial-seed.sql)…");
    await c.query(fs.readFileSync(path.join(DIR, `${SCHEMA}-seed.sql`), "utf8"));
    console.log("  seed OK");

    const emp = await c.query(
      `select id, nombre_empresa, estado, data_schema from ${SCHEMA}.empresas order by created_at limit 5`,
    );
    console.log("Empresas:", emp.rows);
    console.log("✅ Aprovisionamiento completo.");
  } finally {
    await c.end();
  }
}

main().catch((e) => {
  console.error("ERROR:", e.message);
  process.exit(1);
});
