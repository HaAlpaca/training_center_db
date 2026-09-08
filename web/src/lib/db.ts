import { Pool, QueryResult, QueryResultRow } from "pg";

// Singleton pattern to prevent multiple pool instances during Next.js Hot Module Replacement (HMR)
const globalForPg = globalThis as unknown as {
  pgPool: Pool | undefined;
};

export const pool =
  globalForPg.pgPool ??
  new Pool({
    host: process.env.DB_HOST || "localhost",
    port: parseInt(process.env.DB_PORT || "5432", 10),
    database: process.env.DB_NAME || "training_db",
    user: process.env.DB_USER || "admin",
    password: process.env.DB_PASSWORD || "admin_password",
    max: 20, // Maximum number of clients in the pool
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
  });

if (process.env.NODE_ENV !== "production") {
  globalForPg.pgPool = pool;
}

/**
 * Executes a raw SQL query using connection from the pool.
 * @example
 * const res = await query('SELECT * FROM fn_get_student_academic_transcript($1)', ['STU_001']);
 */
export async function query<T extends QueryResultRow = any>(
  text: string,
  params?: any[]
): Promise<QueryResult<T>> {
  const start = Date.now();
  try {
    const res = await pool.query<T>(text, params);
    const duration = Date.now() - start;
    if (process.env.NODE_ENV === "development") {
      console.log(`[SQL Query] (${duration}ms):`, text.trim().slice(0, 100));
    }
    return res;
  } catch (error) {
    console.error("[SQL Error]:", error);
    throw error;
  }
}

/**
 * Obtains a dedicated client from the pool for transactions.
 * Remember to call client.release() in a finally block!
 */
export async function getClient() {
  const client = await pool.connect();
  return client;
}
