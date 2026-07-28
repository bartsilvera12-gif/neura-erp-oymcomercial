/**
 * Verificación del schema aislado `oymcomercial`:
 *  - conteos de objetos (tablas, funciones, triggers, índices, policies, FKs)
 *  - aislamiento (FKs, funciones, policies no dependen de otros schemas de negocio)
 *  - empresa nueva única y distinta del origen
 *  - tablas operativas vacías / catálogos mínimos presentes
 *
 * Requiere en .env.local: SUPABASE_DB_URL
 * Uso: npx tsx scripts/verify-oymcomercial-schema.ts
 * Exit code != 0 si alguna aserción falla.
 */
import { config } from "dotenv";
import * as path from "path";
import pg from "pg";

config({ path: path.resolve(process.cwd(), ".env.local") });

const D = "oymcomercial";
const FOREIGN_BUSINESS = ["reservacaacupe", "zentra_erp", "enlodemari"];

let failures = 0;
function assert(name: string, cond: boolean, detail = "") {
  console.log(`${cond ? "✅" : "❌"} ${name}${detail ? " — " + detail : ""}`);
  if (!cond) failures++;
}

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
  const q = async (s: string, p: unknown[] = []) => (await c.query(s, p)).rows;
  await c.connect();
  try {
    const exists = (await q(`select count(*)::int n from pg_namespace where nspname=$1`, [D]))[0].n > 0;
    assert("schema oymcomercial existe", exists);
    if (!exists) return;

    const cnt = (
      await q(
        `select
          (select count(*) from pg_tables where schemaname=$1) tables,
          (select count(*) from pg_views where schemaname=$1) views,
          (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname=$1) functions,
          (select count(*) from pg_trigger t join pg_class cl on cl.oid=t.tgrelid join pg_namespace n on n.oid=cl.relnamespace where n.nspname=$1 and not t.tgisinternal) triggers,
          (select count(*) from pg_indexes where schemaname=$1) indexes,
          (select count(*) from pg_policies where schemaname=$1) policies,
          (select count(*) from pg_constraint con join pg_class c on c.oid=con.conrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname=$1 and con.contype='f') fks`,
        [D],
      )
    )[0];
    console.log("Conteos:", cnt);
    assert("126 tablas", Number(cnt.tables) === 126, `tables=${cnt.tables}`);
    assert("405 policies", Number(cnt.policies) === 405, `policies=${cnt.policies}`);

    // Aislamiento: FKs solo a oymcomercial + auth
    const fkSchemas = await q(
      `select distinct rn.nspname s from pg_constraint con
        join pg_class c on c.oid=con.conrelid join pg_namespace n on n.oid=c.relnamespace
        join pg_class rc on rc.oid=con.confrelid join pg_namespace rn on rn.oid=rc.relnamespace
       where con.contype='f' and n.nspname=$1`,
      [D],
    );
    const fkSet = fkSchemas.map((r) => r.s);
    assert(
      "FKs solo referencian oymcomercial + auth",
      fkSet.every((s) => s === D || s === "auth"),
      `refs=${fkSet.join(",")}`,
    );

    // Funciones/policies sin DEPENDENCIA (referencia schema-qualified: `schema.objeto`)
    // a schemas de negocio ajenos. Nota: un token suelto dentro de un literal
    // (p.ej. una regex de validación) NO es dependencia; por eso exigimos el punto.
    const badFns = await q(
      `select p.proname from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where n.nspname=$1 and (${FOREIGN_BUSINESS.map((s) => `pg_get_functiondef(p.oid) ~ '\\m${s}\\.'`).join(" or ")})`,
      [D],
    );
    assert("0 funciones dependen de schema de negocio ajeno", badFns.length === 0, badFns.map((r) => r.proname).join(","));

    const badPols = await q(
      `select count(*)::int n from pg_policies where schemaname=$1
        and (coalesce(qual,'')||coalesce(with_check,'')) ~ '\\m(${FOREIGN_BUSINESS.join("|")})\\.'`,
      [D],
    );
    assert("0 policies dependen de schema de negocio ajeno", Number(badPols[0].n) === 0);

    // Empresa nueva única y distinta del origen
    const emp = await q(`select id, nombre_empresa, estado from ${D}.empresas`);
    assert("empresa nueva existe exactamente 1 vez", emp.length === 1, `count=${emp.length}`);
    assert(
      "empresa_id distinto del origen",
      emp.every((e) => e.id !== "a9276529-bca9-418a-b014-375e68d667d2"),
    );

    // Catálogos mínimos
    const modAct = (await q(`select count(*)::int n from ${D}.empresa_modulos where activo`))[0].n;
    assert("empresa tiene módulos habilitados", Number(modAct) > 0, `activos=${modAct}`);
    const modCat = (await q(`select count(*)::int n from ${D}.modulos`))[0].n;
    assert("catálogo de módulos presente", Number(modCat) > 0, `modulos=${modCat}`);

    // Fiscal excluido / admin (informativo)
    const sifen = (await q(`select count(*)::int n from ${D}.empresa_sifen_config`))[0].n;
    assert("sin config fiscal (SIFEN) del origen", Number(sifen) === 0);

    // Tablas operativas vacías (excluye catálogos sembrados)
    const seeded = new Set([
      "empresas","modulos","empresa_modulos","dashboard_views","empresa_dashboard_views",
      "entidades_bancarias","crm_etapas","proyecto_estados","proyecto_tipos",
      "proyecto_prioridades_config","cliente_tipos_servicio_catalogo","empresa_facturacion_modo",
    ]);
    const tbls = await q(`select tablename from pg_tables where schemaname=$1`, [D]);
    let nonEmptyOps = 0;
    for (const t of tbls) {
      if (seeded.has(t.tablename)) continue;
      const n = (await q(`select count(*)::int n from ${D}."${t.tablename}"`))[0].n;
      if (Number(n) > 0) {
        console.log(`   ⚠️ tabla operativa no vacía: ${t.tablename} (${n})`);
        nonEmptyOps++;
      }
    }
    assert("tablas operativas vacías", nonEmptyOps === 0, `no-vacías=${nonEmptyOps}`);

    console.log(failures === 0 ? "\n✅ TODAS LAS VERIFICACIONES OK" : `\n❌ ${failures} verificación(es) fallida(s)`);
  } finally {
    await c.end();
  }
  if (failures > 0) process.exit(1);
}

main().catch((e) => {
  console.error("ERROR:", e.message);
  process.exit(1);
});
