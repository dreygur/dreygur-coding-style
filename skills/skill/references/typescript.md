# TypeScript / JavaScript

## Structure
```
src/
├── index.ts        # barrel exports
├── types.ts
├── constants.ts
├── config.ts
├── errors.ts
├── services/       # *.service.ts
├── repositories/   # *.repository.ts
├── strategies/     # *.strategy.ts
├── middleware/     # *.middleware.ts
├── handlers/       # *.handler.ts
└── utils/
    ├── logger.ts
    └── mutex.ts
```

## Error Classes
```ts
export class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public recoverable = true,
    public userMessage?: string,
  ) {
    super(message);
    this.name = "AppError";
    Error.captureStackTrace(this, this.constructor);
  }
}
export class NetworkError extends AppError {
  constructor(message: string, userMessage?: string) {
    super(message, "NETWORK_ERROR", true, userMessage || "Network request failed.");
    this.name = "NetworkError";
  }
}
```

```ts
export function isRecoverableError(e: unknown): boolean {
  return e instanceof AppError ? e.recoverable : false;
}
export function getUserMessage(e: unknown): string {
  if (e instanceof AppError && e.userMessage) return e.userMessage;
  if (e instanceof Error) return e.message;
  return "An unexpected error occurred";
}
```

## Rules
- **Always semicolons**
- `import type` for type-only imports
- `async/await` everywhere, no `.then()/.catch()` chains
- `index.ts` re-exports everything (`export * from "./services/token.service.js"`)
- Classes: `PascalCase` + suffix, as in `TokenService`, `CredentialRepository`
- Instances: `camelCase`; Constants: `SCREAMING_SNAKE_CASE`

## Log Prefix (even without logger)
```ts
console.log(`[+] Waiting...`);
console.log(`[-] ${err.message}`);
```

## Graceful Shutdown
```ts
process.on('SIGINT', (signal) => { console.log(`[+] ${signal} Exiting...`); process.exit(0); });
process.on('SIGHUP', (signal) => { console.log(`[+] ${signal} Exiting...`); process.exit(0); });
```

## Script Entry (IIFE)
```ts
(async () => await main())();
```

## Branded Types for Entity IDs
One branded type per entity, defined in `shared/branded-types.ts`:

```ts
export type Brand<T, B extends string> = T & { __brand: B };
export function asBrand<T extends Brand<any, any>>(value: any): T { return value as T; }
export function assertValidId<T extends Brand<string, any>>(value: unknown, idType: string): T {
  if (!isValidUUID(value)) throw new Error(`Invalid ${idType}: expected UUID`);
  return value as T;
}
export type UserId = Brand<string, 'UserId'>;
export type OrganizationId = Brand<string, 'OrganizationId'>;
```

Use `assertValidId<T>` at HTTP boundaries (`req.params`), `asBrand<T>` only at trusted internal casting points:

```ts
// Validate at boundary
const userId = assertValidId<UserId>(req.params.id, 'UserId');

// Cast trusted internal value
const userId = asBrand<UserId>(dbRow.id);
```

Never use plain `string` for entity IDs. Always the specific branded type, including in service and repository signatures.

## Choosing the ORM
Drizzle or Kysely. In an existing repo, use the one it already has. For a new project, ask dreygur.

## Drizzle Schema
Every table file exports the table, `TEntity`, `TEntityInsert`, and three Zod schemas from drizzle-zod. Table and column names passed to Drizzle are SQL, so always snake_case: `createdAt: timestamp('created_at')`.

```ts
export const users = pgTable('user', {
  id: uuid('id').notNull().primaryKey().defaultRandom(),
  email: varchar('email').notNull().unique(),
  ...timestamps,
});
export type TUser = typeof users.$inferSelect;
export type TUserInsert = typeof users.$inferInsert;
export const ZUserCreate = createInsertSchema(users);
export const ZUserUpdate = createUpdateSchema(users);
export const ZUserSelect = createSelectSchema(users);
```

## Base Repository (Drizzle)
```ts
export abstract class BaseRepository<T extends AnyPgTable & { id: any }, TId extends string = string> {
  constructor(protected readonly db: NodePgDatabase, protected readonly table: T) {}

  async findById(id: TId): Promise<T['$inferSelect']> { ... }
  async create(data: Partial<T['$inferInsert']>): Promise<TId> { ... }
  async update(id: TId, values: Partial<T['$inferInsert']>): Promise<TId> { ... }

  async delete(id: TId, tx?: ConnectionType) {
    return (tx ?? this.db).update(this.table).set({ deleted: true } as any)
      .where(eq(this.table.id, id as string)).execute();
  }
  async restore(id: TId, tx?: ConnectionType) {
    return (tx ?? this.db).update(this.table).set({ deleted: false } as any)
      .where(eq(this.table.id, id as string)).execute();
  }
  async withTransaction<R>(fn: (tx: ConnectionType) => Promise<R>): Promise<R> {
    return this.db.transaction(fn as any);
  }
}
```
Always soft delete (`deleted: true`). Optional `tx?` on mutating methods.

## Kysely Client
`db/client.ts` is the one place a driver pool and a `Kysely` instance get built. One pool per process. Driver type parsing (TINYINT(1) as boolean, int8 as number) goes on that pool, never on the global driver.

```ts
export type Db = Kysely<Tables>;

export function openDatabase(config: DbConfig): Database {
  const pool = createPool({ ...config, timezone: TIMEZONE, connectionLimit: DB_POOL_SIZE, typeCast });
  const db = new Kysely<Tables>({ dialect: new MysqlDialect({ pool: pool.pool }) });
  return { pool, db };
}
```

`Transaction<Tables>` extends `Kysely<Tables>`, so a repository typed on `Db` runs inside a transaction unchanged. The service owns the transaction boundary.

## Kysely Schema
`db/schema.ts` holds one interface per table and a `Tables` map. Table and column names are SQL, so they stay snake_case exactly as in the database; no `CamelCasePlugin`. Columns the database fills get `Generated<T>`. Row types are exported as `TEntity`:

```ts
interface ProductsTable {
  id: string;
  name: string;
  created_at: Date;
  deleted: Generated<boolean>;
}

export interface Tables {
  haat_products: ProductsTable;
}

export type TProduct = Selectable<ProductsTable>;
```

Where the layers above want camelCase fields, the repository maps at its edge with a `columns` list that every read selects through (`"created_at as createdAt"`). Queries themselves always name the snake_case column.

## Kysely Repository
The repository takes the executor in its constructor and holds queries only. A predicate used by several queries becomes a helper above the class, typed on `ExpressionBuilder`:

```ts
type ProductsEb = ExpressionBuilder<Tables, "haat_products">;

function onSale(eb: ProductsEb) {
  return eb.and([eb("deleted", "=", false), eb("status", "=", ProductStatus.Active)]);
}

export class ProductsRepository {
  constructor(private readonly db: Db) {}

  async findById(id: ProductId): Promise<TProduct | null> {
    const row = await this.db.selectFrom("haat_products").selectAll().where("id", "=", id).where("deleted", "=", false).executeTakeFirst();
    return row ?? null;
  }

  async softDelete(id: ProductId): Promise<void> {
    await this.db.updateTable("haat_products").set({ deleted: true, updated_at: new Date() }).where("id", "=", id).execute();
  }
}
```

A missing row comes back as `null`, never `undefined`. On Postgres, an update or insert uses `returning(...)` in one statement instead of read then write.

## Kysely Migrations
Plain SQL, numbered, applied in order by the project's own runner. The runner keeps a journal table, takes a database lock (`GET_LOCK` on MySQL, `pg_advisory_lock` on Postgres) so two processes never migrate at once, and records a version only after all its steps ran. Every step is safe to rerun (`IF NOT EXISTS`, or a catalog check first). A shipped migration is never edited; add a new one.

## tRPC Setup
```ts
export const t = initTRPC.context<Context>().meta<OpenApiMeta>().create({
  transformer: superjson,
  errorFormatter: ({ shape }) => ({
    ...shape,
    data: { ...shape.data, stack: process.env.NODE_ENV === 'development' ? shape.data?.stack : undefined },
  }),
});
export const router = t.router;
export const middleware = t.middleware;
export const createCallerFactory = t.createCallerFactory;
```

## Project-Prefixed Errors
```ts
export class PoachApiError extends Error {
  constructor(message: string, public success = false, public operational = true, stack = '') {
    super(message);
    this.name = 'PoachApiError';
    if (stack) this.stack = stack;
    else Error.captureStackTrace(this, this.constructor);
  }
}
export class PTRPCError extends TRPCError {
  public timestamp = new Date();
  public requestId?: string;
  constructor(params: ConstructorParameters<typeof TRPCError>[0] & { requestId?: string }) {
    super(params);
    this.requestId = params.requestId;
  }
}
```

## Logging
Services log through Winston with a custom `db` level:

```ts
declare module 'winston' { interface Logger { db(msg: string | Error, ...meta: any[]): Logger; } }

const customLevels = {
  levels: { error: 0, warn: 1, info: 2, db: 3, debug: 4 },
  colors: { error: 'red', warn: 'yellow', info: 'green', db: 'magenta', debug: 'blue' },
};
winston.addColors(customLevels.colors);

export const logger = winston.createLogger({
  levels: customLevels.levels,
  level: process.env.NODE_ENV === 'development' ? 'debug' : 'db',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.printf(({ timestamp, level, message }) => `[${level}] ${timestamp}: ${message}`),
  ),
  transports: [new winston.transports.Console({ stderrLevels: ['error'] })],
});
```

Where the host supplies its own log client (a plugin, an extension), wrap it in `utils/logger.ts` instead:

```ts
export const debugLog = (message: string, data?: Record<string, unknown>) =>
  client.app.log({ body: { level: "debug", message, extra: data } }).catch(() => {});
export const infoLog  = (message: string, data?: Record<string, unknown>) => ...;
export const warnLog  = (message: string, data?: Record<string, unknown>) => ...;
```

## Monorepo (Turborepo + pnpm)
```
project/
├── apps/api/           # Express + tRPC
├── apps/ui/            # Next.js App Router
├── packages/
│   ├── schema/         # Drizzle tables + drizzle-zod
│   ├── repository/     # BaseRepository + per-entity
│   ├── service/        # *.service.ts per entity
│   ├── trpc/           # router + context + middleware
│   ├── shared/         # branded-types, errors, constants
│   ├── validator/      # Zod validators
│   ├── logger/         # Winston
│   ├── email/          # provider pattern
│   └── telemetry/      # OpenTelemetry
├── cdk/                # AWS CDK (if cloud)
├── turbo.json
└── pnpm-workspace.yaml
```
Package naming: `@projectname/schema`, `@projectname/repository`, etc.

## Mutex for Concurrent Operations

Use a `Mutex` utility to prevent race conditions in async flows (e.g., token refresh):

```ts
// utils/mutex.ts
export class Mutex {
  private queue: Array<() => void> = [];
  private locked = false;

  isLocked(): boolean { return this.locked; }

  async runExclusive<T>(fn: () => Promise<T>): Promise<T> {
    await this.acquire();
    try { return await fn(); }
    finally { this.release(); }
  }
}
```

## Retry Middleware

Wrap fetch with retry logic in a dedicated middleware file, not inline:

```ts
// middleware/retry.middleware.ts
export async function fetchWithRetry(
  url: string,
  init: RequestInit,
  options: { maxRetries: number; baseDelay: number; timeout: number },
): Promise<Response> { ... }
```

## Soft Delete Pattern

Never hard delete. `BaseRepository.delete()` sets `{ deleted: true }`. Add a `restore()` that sets `{ deleted: false }`. All list queries must filter `where(eq(table.deleted, false))` in Drizzle, `.where("deleted", "=", false)` in Kysely.

## tRPC + Express Integration

Register two route namespaces: `/v1` for REST, `/trpc` for tRPC. Dev-only routes (swagger, trpc-playground) gated on `process.env.NODE_ENV === 'development'`:

```ts
app.use('/v1', routes);
app.use('/trpc', createExpressMiddleware({ router: appRouter, createContext: createTRPCContext }));
if (process.env.NODE_ENV === 'development') {
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));
}
```

## CORS from Env

Never hardcode CORS origins. Parse from env, support comma-separated list:

```ts
const corsOrigins = (process.env.CORS_ORIGIN || 'http://localhost:3000')
  .split(',').map(o => o.trim());
app.use(cors({ origin: corsOrigins, credentials: true }));
```

## Anti-Patterns to Avoid (TS/JS)

- `catch (e) {}`: never swallow
- `any` type without a comment explaining why
- Default exports except for plugin entry points
- Mixing `require()` and `import`
- Missing semicolons
- Hardcoded URLs, tokens, or secrets
- Business logic inside `index.ts`: it's only a barrel
- Plain `string` for entity IDs: use branded types
- Hard deletes: always soft delete with `deleted` flag
- camelCase table or column names in SQL, or `CamelCasePlugin`: columns are always snake_case
