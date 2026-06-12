const SUCCESS_CACHE_SECONDS = 3600;
const ERROR_CACHE_SECONDS = 60;
const UPSTREAM_TIMEOUT_MS = 8000;
const FALLBACK_SPREAD_PCT = 5.14;
const FALLBACK_UPPER_PCT = 10.28;
const FALLBACK_LOWER_PCT = 2.57;

function jsonResponse(body, status, cacheSeconds) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": `public, max-age=${cacheSeconds}, s-maxage=${cacheSeconds}`,
    },
  });
}

function errorResponse(errorCode, message, status = 503) {
  return jsonResponse(
    {
      error_code: errorCode,
      message,
      server_time: new Date().toISOString(),
    },
    status,
    ERROR_CACHE_SECONDS,
  );
}

async function fetchWithTimeout(url, init = {}, timeoutMs = UPSTREAM_TIMEOUT_MS) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort("timeout"), timeoutMs);

  try {
    return await fetch(url, {
      ...init,
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeout);
  }
}

function readRateEntry(json, pair) {
  const entry = json?.data?.rates?.[0];
  if (!entry) {
    throw new Error(`missing_entry:${pair}`);
  }

  const avg = Number(entry.avg);
  if (!Number.isFinite(avg) || avg <= 0) {
    throw new Error(`missing_avg:${pair}`);
  }

  const bidRaw = entry.bid ?? entry.buy ?? entry.low;
  const askRaw = entry.ask ?? entry.sell ?? entry.high;
  const bid = Number(bidRaw);
  const ask = Number(askRaw);

  return {
    avg,
    bid: Number.isFinite(bid) && bid > 0 ? bid : null,
    ask: Number.isFinite(ask) && ask > 0 ? ask : null,
  };
}

function formatUtcDate(date) {
  const year = date.getUTCFullYear();
  const month = `${date.getUTCMonth() + 1}`.padStart(2, "0");
  const day = `${date.getUTCDate()}`.padStart(2, "0");
  return `${day}-${month}-${year}`;
}

function deriveThresholds(usdZarQuote) {
  if (usdZarQuote.bid != null && usdZarQuote.ask != null) {
    const spread = usdZarQuote.ask - usdZarQuote.bid;
    const mid = usdZarQuote.avg;
    const spreadPct = mid > 0 ? (spread / mid) * 100 : FALLBACK_SPREAD_PCT;
    return {
      upper_pct: spreadPct * 2,
      lower_pct: spreadPct / 2,
      spread_pct: spreadPct,
      is_volatile: spreadPct >= 6,
      source: "dynamic_spread",
    };
  }

  return {
    upper_pct: FALLBACK_UPPER_PCT,
    lower_pct: FALLBACK_LOWER_PCT,
    spread_pct: FALLBACK_SPREAD_PCT,
    is_volatile: false,
    source: "fixed_fallback",
  };
}

function buildSpreadSection(quotes) {
  const spreads = {};
  for (const [key, quote] of Object.entries(quotes)) {
    if (quote.bid != null) spreads[`${key}_bid`] = quote.bid;
    if (quote.ask != null) spreads[`${key}_ask`] = quote.ask;
  }
  return spreads;
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (request.method !== "GET") {
      return errorResponse("worker_error", "Method not allowed", 405);
    }

    const isRatesEndpoint = url.pathname === "/" || url.pathname === "/rates";
    if (!isRatesEndpoint) {
      return errorResponse("worker_error", "Not found", 404);
    }

    const cache = caches.default;
    const cacheKey = new Request(`${url.origin}/rates`, { method: "GET" });
    const cached = await cache.match(cacheKey);
    if (cached) return cached;

    const base = env.ZIMRATE_BASE_URL || "https://zimrate.statotec.com/api/v1";
    const apiKey = env.ZIMRATE_API_KEY;
    if (!apiKey) {
      return errorResponse("worker_error", "Missing upstream API key", 500);
    }

    const pairs = [
      { key: "usd_zar", pair: "USD/ZAR" },
      { key: "usd_zwg", pair: "USD/ZWG" },
      { key: "usd_bwp", pair: "USD/BWP" },
    ];

    try {
      const entries = await Promise.all(
        pairs.map(async ({ key, pair }) => {
          const upstream = new URL(base + "/rates");
          upstream.searchParams.set("pair", pair);
          const res = await fetchWithTimeout(upstream.toString(), {
            headers: {
              Authorization: `Bearer ${apiKey}`,
              Accept: "application/json",
            },
          });

          if (!res.ok) {
            throw new Error(`upstream_status:${pair}:${res.status}`);
          }

          const json = await res.json();
          return [key, readRateEntry(json, pair)];
        }),
      );

      const quotes = Object.fromEntries(entries);
      const usdZarQuote = quotes.usd_zar;
      const usdZwgQuote = quotes.usd_zwg;
      const usdBwpQuote = quotes.usd_bwp;

      if (!(usdZarQuote.avg > 0 && usdZwgQuote.avg > 0 && usdBwpQuote.avg > 0)) {
        return errorResponse("incomplete_rates", "Upstream rates were incomplete.");
      }

      const usdZar = usdZarQuote.avg;
      const usdZwg = usdZwgQuote.avg;
      const usdBwp = usdBwpQuote.avg;
      const zarZwg = usdZwg / usdZar;
      const zwgZar = usdZar / usdZwg;
      const bwpZar = usdZar / usdBwp;
      const bwpZwg = usdZwg / usdBwp;

      if (
        !Number.isFinite(zarZwg) ||
        !Number.isFinite(zwgZar) ||
        !Number.isFinite(bwpZar) ||
        !Number.isFinite(bwpZwg)
      ) {
        return errorResponse("rate_anomaly", "Returned rates were not internally consistent.");
      }

      const now = new Date();
      const thresholds = deriveThresholds(usdZarQuote);
      const body = {
        rates: {
          usd_zwg: usdZwg,
          usd_zar: usdZar,
          zar_zwg: zarZwg,
          zwg_zar: zwgZar,
          usd_bwp: usdBwp,
          bwp_zar: bwpZar,
          bwp_zwg: bwpZwg,
        },
        spreads: buildSpreadSection(quotes),
        thresholds,
        meta: {
          server_time: now.toISOString(),
          rate_date: formatUtcDate(now),
          rbz_updated: null,
          change_pct: 0.0,
          source: "RBZ interbank via ZimRate",
          derived_pairs: ["usd_zar", "zar_zwg", "bwp_*", "usd_zar_spread"],
          bwp_source: "Bank of Botswana reference - updated manually",
          note: "bwp_* and cross rates derived mathematically",
        },
        server_time: now.toISOString(),
        source: "RBZ interbank via ZimRate",
      };

      const response = jsonResponse(body, 200, SUCCESS_CACHE_SECONDS);
      ctx.waitUntil(cache.put(cacheKey, response.clone()));
      return response;
    } catch (error) {
      const message = String(error && error.message ? error.message : error);
      const code = message.includes("timeout") || message.includes("AbortError")
        ? "zimrate_timeout"
        : message.startsWith("missing_entry:") || message.startsWith("missing_avg:")
            ? "incomplete_rates"
            : "worker_error";
      const response = errorResponse(
        code,
        code === "zimrate_timeout"
          ? "ZimRate took too long to reply."
          : code === "incomplete_rates"
              ? "Upstream rates were incomplete."
              : "Cloudflare worker could not produce rates.",
      );
      ctx.waitUntil(cache.put(cacheKey, response.clone()));
      return response;
    }
  },
};
