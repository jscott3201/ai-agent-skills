---
name: migration-safety
description: >
  Analyze database migrations for unsafe operations: destructive changes,
  lock-heavy DDL, missing rollback plans, and backward compatibility.
  Use before applying migrations to production.
disable-model-invocation: true
argument-hint: "[migration file or directory]"
---

## Purpose

Catch dangerous database migrations before they reach production. Migrations
are high-risk, low-frequency operations where mistakes are expensive and
hard to reverse. This skill classifies each operation by risk, flags unsafe
patterns, and generates rollback plans.

Distinct from `migration-guide` which handles API breaking changes. This
skill is specifically about data layer safety.

This is an interactive skill. Present each risk finding one at a time with
the recommended safe alternative.

## Instructions

### 1. Locate migration files

Find pending or recent migrations in `$ARGUMENTS` or by scanning common
locations:

| Framework | Location |
|:--|:--|
| **Raw SQL** | `migrations/`, `db/migrate/`, `sql/` |
| **Diesel (Rust)** | `migrations/*/up.sql`, `migrations/*/down.sql` |
| **SQLx (Rust)** | `migrations/*.sql` |
| **SQLAlchemy/Alembic (Python)** | `alembic/versions/*.py` |
| **Django (Python)** | `*/migrations/*.py` |
| **Prisma (JS/TS)** | `prisma/migrations/*/migration.sql` |
| **Drizzle (JS/TS)** | `drizzle/*.sql`, `drizzle/meta/*.json` |
| **Knex (JS/TS)** | `migrations/*.js` or `*.ts` |
| **TypeORM (JS/TS)** | `src/migrations/*.ts` |

Present what was found:

> "Found N migration files in [location]. Analyzing [N new/pending]
> migrations. Which should I review?"

Wait for confirmation.

### 2. Classify each operation

Parse each migration and classify every DDL operation:

| Risk | Operations | Why |
|:--|:--|:--|
| **Safe** | `CREATE TABLE`, `CREATE INDEX CONCURRENTLY`, `ADD COLUMN` (nullable), `ADD COLUMN` (with default) | Additive, no lock on existing data |
| **Caution** | `ADD COLUMN NOT NULL` (with default), `CREATE INDEX` (non-concurrent), `ALTER COLUMN SET DEFAULT` | May lock briefly on large tables |
| **Dangerous** | `DROP COLUMN`, `DROP TABLE`, `ALTER COLUMN TYPE`, `ADD COLUMN NOT NULL` (no default), `RENAME COLUMN`, `RENAME TABLE` | Data loss, long locks, or breaks active queries |
| **Critical** | `TRUNCATE`, `DROP DATABASE`, `DELETE FROM` (without WHERE), bulk `UPDATE` (without WHERE) | Irreversible data destruction |

### 3. Check for unsafe patterns

For each migration, check against these known-dangerous patterns:

**Lock hazards:**
- `CREATE INDEX` without `CONCURRENTLY` on tables with >100K rows
  (locks writes for the duration)
- `ALTER TABLE ... ADD COLUMN ... DEFAULT` on PostgreSQL <11
  (rewrites the entire table)
- Multiple DDL statements in a single transaction on large tables
  (holds locks for the combined duration)

**Backward compatibility:**
- `DROP COLUMN` while the previous app version still reads that column
  (causes query failures during rolling deploy)
- `RENAME COLUMN` or `RENAME TABLE` without a transition period
  (breaks all queries using the old name)
- `ALTER COLUMN TYPE` that narrows the type (e.g., `TEXT` to `VARCHAR(50)`)
  without checking existing data fits

**Data safety:**
- `DROP TABLE` or `DROP COLUMN` without a preceding data backup or
  archival migration
- `NOT NULL` constraint added without a default value and without a
  preceding `UPDATE` to fill existing NULLs
- Foreign key added without an index on the referencing column
  (causes full table scans on joins and deletes)

**Missing rollback:**
- `up.sql` exists but `down.sql` is empty or missing
- Down migration uses `DROP TABLE` for a table that had data
  (rollback loses data permanently)
- Down migration does not restore dropped columns or constraints

### 4. Generate rollback plan

For each migration, produce a rollback strategy:

| Operation | Rollback | Reversibility |
|:--|:--|:--|
| `ADD COLUMN` | `ALTER TABLE DROP COLUMN` | Full |
| `CREATE TABLE` | `DROP TABLE` | Full |
| `CREATE INDEX` | `DROP INDEX` | Full |
| `DROP COLUMN` | Cannot restore data | Irreversible without backup |
| `DROP TABLE` | Cannot restore data | Irreversible without backup |
| `ALTER COLUMN TYPE` | `ALTER COLUMN TYPE` back | Possible if no data truncation |
| `RENAME COLUMN` | `RENAME COLUMN` back | Full |

Flag operations with no clean rollback. These require a backup or
archival step before the migration.

### 5. Present findings one at a time

Start with critical and dangerous findings:

> **Dangerous:** `DROP COLUMN users.legacy_role`
> **Migration:** `migrations/20260401_cleanup/up.sql:12`
> **Risk:** Active app version reads `legacy_role` in `UserQuery`.
> During rolling deploy, old instances will fail with column-not-found.
> **Rollback:** Irreversible without backup. Column data is lost.
>
> **Safe alternative:** Deploy in two phases:
> 1. First migration: stop reading the column in app code, deploy
> 2. Second migration: drop the column after all instances are updated
>
> Options:
> 1. **Split migration** - rewrite as two-phase deploy
> 2. **Add backup** - archive column data before dropping
> 3. **Accept risk** - proceed as-is (document why)
>
> I recommend splitting into two phases for zero-downtime safety.

Wait for the user's decision before presenting the next finding.

### 6. Produce safety report

Save to `_agentskills/reviews/YYYY-MM-DD-migration-safety.md`:

```markdown
# Migration Safety Review

**Date:** YYYY-MM-DD
**Migrations reviewed:** N files, N operations
**Framework:** [Diesel/Prisma/raw SQL/etc.]

## Risk Summary

| Risk Level | Count | Details |
|:--|:--|:--|
| Critical | N | [operations] |
| Dangerous | N | [operations] |
| Caution | N | [operations] |
| Safe | N | [operations] |

## Findings

### [Finding 1: operation description]

- **File:** [migration file:line]
- **Risk:** [what could go wrong]
- **Resolution:** [what was decided]

## Rollback Plan

| Migration | Rollback Command | Reversibility |
|-----------|-----------------|---------------|
| [migration name] | [SQL or command] | Full / Partial / Irreversible |

## Pre-deployment Checklist

- [ ] Backup taken for irreversible operations
- [ ] Tested on staging with production-sized data
- [ ] Rolling deploy compatibility verified
- [ ] Rollback tested and confirmed working
- [ ] Monitoring in place for lock duration and query errors
```

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Straightforward migration, skip classification" | "Straightforward" migrations that lock tables for 20 minutes aren't straightforward. Classify every operation. |
| "Lock hazards only matter on large tables" | You're testing on dev data. Production tables are 1000x larger. Always analyze lock behavior. |
| "Check up.sql, down.sql can come later" | Rollback plans written during an outage are written badly. Write them now. |
| "Zero-downtime deployment handles compatibility" | Deployment handles mechanics. Schema compatibility is your responsibility. |
| "DBA will test on production data" | Shifting responsibility is not risk mitigation. Test what you can test. |

## Guidance

**Deploy schema changes separately from code changes.** A migration and
a code deploy in the same release doubles the rollback complexity. Ship
the migration first, verify it works, then ship the code that uses it.

**Two-phase drops are always safer.** Phase 1: stop using the column/table.
Phase 2: drop it after all app instances are updated. This costs one extra
deploy but prevents all rolling-deploy failures.

**Test on production-sized data.** A migration that takes 2ms on a dev
database with 100 rows can lock a production table with 10M rows for
minutes. Always test timing on realistic data volumes.

**Index creation blocks writes unless concurrent.** On PostgreSQL, always
use `CREATE INDEX CONCURRENTLY`. On MySQL, `ALTER TABLE ... ADD INDEX`
locks the table. Check your database's DDL locking behavior before
assuming safety.

**Foreign keys need indexes on both sides.** A foreign key without an
index on the referencing column turns every `DELETE` on the referenced
table into a full table scan. This is the most common "migration looks
fine but kills production performance" issue.
