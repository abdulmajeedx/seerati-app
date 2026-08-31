# Seerati backend — deployment

Runs as a `systemd --user` service on the app server, behind nginx + Cloudflare.

## Service

```bash
systemctl --user status seerati-backend
systemctl --user restart seerati-backend
journalctl --user -u seerati-backend -f
```

Config lives in `~/seerati-keys/backend.env` (chmod 600, never committed):

| Variable | Purpose |
|---|---|
| `SEERATI_APP_KEY` | Shared key the app sends as `x-app-key`; requests without it get 401 |
| `ANTHROPIC_API_KEY` | Claude API key. Unset ⇒ the server runs in MOCK mode |
| `SEERATI_DB` | SQLite path (devices, daily usage, activation codes) |
| `PORT` | Listen port, default 8787 |
| `SEERATI_BIND` | `any` to bind all interfaces; default is loopback only |
| `SEERATI_JOBS_MODEL` | Model for job search only. Unset ⇒ `claude-opus-5` |
| `SEERATI_JOBS_ENABLED` | `0` switches job search off; the app reads this from `/v1/config` and hides the feature |

## Turning job search on or off

```bash
sed -i 's|^SEERATI_JOBS_ENABLED=.*|SEERATI_JOBS_ENABLED=1|' ~/seerati-keys/backend.env
systemctl --user restart seerati-backend
curl -s https://api.istx.io/v1/config -H "x-app-key: $SEERATI_APP_KEY"
```

Use `0` to switch it off. No app release is needed either way — clients pick
the flag up on their next launch.

## Spend ceilings

All limits are in credits, where **1 credit ≈ US$0.01** of AI spend. Costs:
text call 1, cover letter 2, job search 12.

| Ceiling | Default | Purpose |
|---|---|---|
| Device / day | 15 free, 150 Premium | Normal per-user allowance |
| Device / lifetime | 45 (free only) | Caps what one free install can ever spend |
| IP / day | 45 | Stops one person cycling devices to farm quota |
| Service / day | 300 (≈US$3) | Protects the account balance from abuse or a bug |

Checked outermost-first, so the error names the binding ceiling
(`service_busy`, `ip_limited`, `lifetime_exhausted`, `quota_exhausted`).
A refused or failed call moves no counter. Edit the defaults in
`ApiConfig` (`lib/src/handlers.dart`).

## Cost per call (measured, Claude Opus 5)

| Endpoint | Tokens in/out | Cost | Latency |
|---|---|---|---|
| `/v1/ai/summary` | ~0.5k / 0.2k | ~$0.007 | ~6 s |
| `/v1/ai/cover-letter` | ~1.5k / 0.4k | ~$0.018 | ~15 s |
| `/v1/ai/jobs` | ~19k / 1.1k | ~$0.124 | ~17 s |

Job search dominates the bill because each call runs several web searches whose
results re-enter the context. Identical queries are cached for 6 hours, and a
search costs 3 quota credits instead of 1. To stretch credit further, set
`SEERATI_JOBS_MODEL=claude-sonnet-5` (≈2.5x cheaper) and restart.

The server binds `127.0.0.1` by design — nginx is its only client, so the
`X-Forwarded-For` used for per-IP limiting cannot be spoofed from the internet.

## nginx vhost (needs root)

```bash
sudo install -D -m 644 /home/qlb/seerati-keys/api.istx.io.pem /etc/ssl/cloudflare/api.istx.io.pem
sudo install -D -m 600 /home/qlb/seerati-keys/api.istx.io.key /etc/ssl/cloudflare/api.istx.io.key
sudo cp /home/qlb/app/backend/deploy/api.istx.io.nginx /etc/nginx/sites-available/api.istx.io
sudo ln -sf /etc/nginx/sites-available/api.istx.io /etc/nginx/sites-enabled/api.istx.io
sudo nginx -t && sudo systemctl reload nginx
```

## Cloudflare DNS

Add a proxied (orange cloud) record: `A  api  37.60.226.120`.

## Activation codes

```bash
cd /home/qlb/app/backend
dart run bin/generate_codes.dart 20 /home/qlb/seerati-keys/seerati.db
```

Each printed code is single-use across all devices — the first device to redeem
it gets premium, everyone else gets `invalid_code`.

## Building the app against this backend

```bash
flutter build apk --release \
  --dart-define=SEERATI_API_BASE=https://api.istx.io \
  --dart-define=SEERATI_APP_KEY=<SEERATI_APP_KEY from backend.env>
```

Builds without those defines hide every AI feature and stay fully offline.
