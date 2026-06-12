# Clearate Rates Proxy (Cloudflare Worker)

This Worker is the secure middleman between the Clearate app and the upstream rates provider.

## What it does

- Fetches official mid-rates from the upstream API using a secret API key stored on Cloudflare.
- Returns the full set of currency pairs the app uses:
  - `usd_zar`
  - `usd_zwg`
  - `zar_zwg`
  - `zwg_zar`
  - `usd_bwp`
  - `bwp_zar`
  - `bwp_zwg`
- Caches the JSON response at the edge to avoid upstream rate limits.
- Emits structured JSON error codes only:
  - `zimrate_timeout`
  - `incomplete_rates`
  - `rate_anomaly`
  - `worker_error`

## Environment / secrets

- `ZIMRATE_API_KEY` – upstream API key (Cloudflare secret)
- `ZIMRATE_BASE_URL` – optional override (default `https://zimrate.statotec.com/api/v1`)

## Endpoint

- `GET /`
- `GET /rates`

Response shape (example):

```json
{
  "rates": {
    "usd_zwg": 26.7782,
    "usd_zar": 16.5837,
    "zar_zwg": 1.6147,
    "zwg_zar": 0.6193,
    "usd_bwp": 13.6,
    "bwp_zar": 1.2194,
    "bwp_zwg": 1.969
  },
  "spreads": {
    "usd_zar_bid": 15.77,
    "usd_zar_ask": 17.43
  },
  "thresholds": {
    "upper_pct": 10.28,
    "lower_pct": 2.57,
    "spread_pct": 5.14,
    "is_volatile": false,
    "source": "dynamic_spread"
  },
  "meta": {
    "server_time": "2026-05-26T08:00:00Z",
    "rate_date": "26-05-2026",
    "rbz_updated": null,
    "change_pct": 0,
    "source": "RBZ interbank via ZimRate",
    "derived_pairs": ["usd_zar", "zar_zwg", "bwp_*", "usd_zar_spread"],
    "bwp_source": "Bank of Botswana reference - updated manually",
    "note": "bwp_* and cross rates derived mathematically"
  }
}
```

## Configure the app

Build/run with:

```bash
flutter run --dart-define=CLEARATE_PROXY_RATES_URL=https://<your-worker-domain>/rates
```
