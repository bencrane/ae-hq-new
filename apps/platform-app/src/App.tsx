import { useEffect, useState } from "react";

const API_URL = import.meta.env.VITE_API_URL ?? "http://localhost:8080";

type ApiStatus = {
  service: string;
  doppler: { configured: boolean; present: string[]; missing: string[] };
  supabase: { reachable: boolean; detail?: string };
  timestamp: string;
};

export function App() {
  const [status, setStatus] = useState<ApiStatus | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch(`${API_URL}/api/v1/status`)
      .then((r) => r.json())
      .then(setStatus)
      .catch((e) => setError(e instanceof Error ? e.message : "request failed"));
  }, []);

  return (
    <main style={{ fontFamily: "system-ui", maxWidth: 640, margin: "4rem auto", padding: "0 1rem" }}>
      <h1>AE HQ — Platform App</h1>
      <p>
        API target: <code>{API_URL}</code>
      </p>
      {error && <p style={{ color: "crimson" }}>API unreachable: {error}</p>}
      {status && (
        <ul>
          <li>API: ✅ {status.service}</li>
          <li>
            Doppler secrets: {status.doppler.configured ? "✅ configured" : `❌ missing: ${status.doppler.missing.join(", ")}`}
          </li>
          <li>
            Supabase: {status.supabase.reachable ? "✅ reachable" : `❌ ${status.supabase.detail}`}
          </li>
        </ul>
      )}
      {!status && !error && <p>Checking API…</p>}
    </main>
  );
}
