const APP_URL = import.meta.env.VITE_PLATFORM_APP_URL ?? "http://localhost:5173";

export function App() {
  return (
    <main style={{ fontFamily: "system-ui", maxWidth: 640, margin: "4rem auto", padding: "0 1rem" }}>
      <h1>AE HQ</h1>
      <p>Marketing site placeholder.</p>
      <a href={APP_URL}>Go to platform →</a>
    </main>
  );
}
