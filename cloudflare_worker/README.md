# Clearate Rates Proxy (Cloudflare Worker)

This Worker is the secure middleman between the Clearate app and the upstream rates provider.

## What it does

- Fetches official mid-rates from the upstream API using a secret API key stored on Cloudflare.
- Returns only the three currency pairs the app needs:
  - `usd_zar`
  - `usd_zwg`
  - `zar_zwg`
- Caches the JSON response at the edge to avoid upstream rate limits.

## Environment / secrets

- `ZIMRATE_API_KEY` – upstream API key (Cloudflare secret)
- `ZIMRATE_BASE_URL` – optional override (default `https://zimrate.statotec.com/api/v1`)

## Endpoint

- `GET /rates`

Response shape (example):

```json
{
  "usd_zar": 18.43,
  "usd_zwg": 13.6,
  "zar_zwg": 0.74,
  "server_time": "2026-05-26T08:00:00Z",
  "source": "RBZ interbank"
}
```

## Configure the app

Build/run with:

```bash
flutter run --dart-define=CLEARATE_PROXY_RATES_URL=https://<your-worker-domain>/rates
```

