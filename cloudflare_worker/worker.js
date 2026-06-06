export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (url.pathname !== "/rates") {
      return new Response("Not found", { status: 404 });
    }

    // Edge cache: same response shared for all users.
    const cache = caches.default;
    const cacheKey = new Request(url.toString(), { method: "GET" });
    const cached = await cache.match(cacheKey);
    if (cached) return cached;

    const base = env.ZIMRATE_BASE_URL || "https://zimrate.statotec.com/api/v1";
    const apiKey = env.ZIMRATE_API_KEY;
    if (!apiKey) {
      return new Response("Missing ZIMRATE_API_KEY", { status: 500 });
    }

    const pairs = [
      { key: "usd_zar", pair: "USD/ZAR" },
      { key: "usd_zwg", pair: "USD/ZWG" },
      { key: "zar_zwg", pair: "ZAR/ZWG" },
    ];

    // Fetch in parallel.
    const results = await Promise.all(
      pairs.map(async ({ key, pair }) => {
        const upstream = new URL(base + "/rates");
        upstream.searchParams.set("pair", pair);
        const res = await fetch(upstream.toString(), {
          headers: {
            Authorization: `Bearer ${apiKey}`,
            Accept: "application/json",
          },
        });
        if (!res.ok) throw new Error(`Upstream ${pair} failed: ${res.status}`);
        const json = await res.json();
        const avg = json?.data?.rates?.[0]?.avg;
        if (typeof avg !== "number") throw new Error(`Upstream ${pair} missing avg`);
        return [key, avg];
      }),
    );

    const body = {
      ...Object.fromEntries(results),
      server_time: new Date().toISOString(),
      source: "RBZ interbank",
    };

    const response = new Response(JSON.stringify(body), {
      headers: {
        "content-type": "application/json; charset=utf-8",
        // Cache for 1 hour (matches app refresh interval).
        "cache-control": "public, max-age=3600",
      },
    });

    ctx.waitUntil(cache.put(cacheKey, response.clone()));
    return response;
  },
};

