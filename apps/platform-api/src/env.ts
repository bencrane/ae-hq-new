const REQUIRED = ["SUPABASE_URL", "SUPABASE_ANON_KEY", "SUPABASE_SERVICE_ROLE_KEY"] as const;

export type EnvReport = {
  present: string[];
  missing: string[];
};

export function envReport(): EnvReport {
  const present: string[] = [];
  const missing: string[] = [];
  for (const key of REQUIRED) {
    (process.env[key] ? present : missing).push(key);
  }
  return { present, missing };
}

export const config = {
  port: Number(process.env.PORT ?? 8080),
  appOrigin: process.env.PLATFORM_APP_ORIGIN ?? "http://localhost:5173",
  marketingOrigin: process.env.MARKETING_ORIGIN ?? "http://localhost:5174",
  supabaseUrl: process.env.SUPABASE_URL,
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY,
};
