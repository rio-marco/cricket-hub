# Phase 14 Production & Operations Notes

## Environment Variables
See `backend/.env.example`. Key Phase 14 vars:
- `TRUST_PROXY` - enable when behind reverse proxy/load balancer.
- `ENABLE_API_DOCS` - keep `false` in production unless intentionally exposed.
- `AUTH_LOGIN_MAX_ATTEMPTS`, `AUTH_LOGIN_LOCK_MINUTES` - login lockout.
- `MONGODB_URI` - production MongoDB; use replica set for transaction guarantees.
- `FIREBASE_*` - required for push delivery.

## Backend Startup
- `npm run build` then `npm start` (or PM2/process manager).
- Validate env at startup; production rejects placeholder JWT secrets/wildcard CORS.
- Health: `GET /api/health` returns 200/ready or 503/degraded.

## Graceful Shutdown
- DB disconnect is idempotent; signal handlers should be process-owned (server lifecycle), not duplicated in low-level modules.

## MongoDB Backup/Restore
- Backup: `mongodump --uri="$MONGODB_URI" --out=/secure/backups/cricket-hub-$(date +%F)`
- Restore (staging/verified target only): `mongorestore --uri="$MONGODB_URI" --drop /secure/backups/...`
- Verify: restore to isolated staging DB, run smoke tests, compare critical counts.
- Retention: define policy per ops; encrypt backups; restrict access.
- **Never run restore/drop against production without approved window and backup.**

## MongoDB Transactions
- Scoring/auction services use transactions where available. Standalone MongoDB falls back to non-transactional execution only in test or explicit dev opt-in (`ALLOW_NON_TRANSACTIONAL_WRITES=true`).
- Production recommendation: MongoDB replica set; production should fail safely if transactions unavailable.

## Scoring Integrity (current pass)
- Scoring mutations require `expectedVersion`; clients must send latest version or `If-Match`.
- Version-guarded innings persistence and idempotency replay checks are in place.
- Integration scoring/socket concurrency tests remain blocked in this environment (no safe local Mongo replica-set test instance on `27019`, Docker unavailable).

## Auction Integrity (current pass)
- Auction mutations require replica-set transactions in production; no non-tx production fallback added.
- Current player cursor persisted via `Auction.currentPlayerOrder`; clients should treat socket/API state as authoritative after reconnect.
- Auction completion is intentionally strict: pending bids/current player must be finalized first.
- Integration auction concurrency/socket tests remain blocked in this environment (no safe local Mongo replica-set test instance on `27019`, Docker unavailable).

## Monitoring
- Monitor `/api/health` and DB readiness.
- Log application errors/slow queries; avoid logging secrets/OTP/tokens.
- Alert on auth lockout spikes, 5xx rates, socket disconnect spikes, notification delivery failures.

## Phase 14E Security/Compatibility Notes
- **Auction financial-data policy**: unauthenticated users cannot read auction endpoints; authenticated non-manager/non-owner users receive redacted financial fields; managers/owned-team users receive full financials needed for workflows. Clients must tolerate missing financial values.
- **Auction read auth compatibility**: mobile auction screens/providers use authenticated API client; anonymous auction access is not supported. No public auction DTO endpoint added to avoid financial/operational leakage.
- **Upload visibility**: avatars are public profile images in `/uploads` (randomized filenames, ext+magic validation). No private media endpoints; future private uploads require authenticated delivery.
- **ObjectId param validation**: explicit Joi param validation added across major routes with `:id` params to return consistent 400 validation errors.

## Phase 14G Flutter Production Audit (targeted)
- **Reliability fixes**: invalid deep-link IDs rejected before screen/API; router listener cleanup on dispose; duplicate scoring/auction mutation guard while saving; push unregister best-effort to avoid logout local-state inconsistency.
- **Performance/lifecycle**: realtime room providers autoDispose with disposed/recovery guards (14F.4 preserved); reconnect recovery guarded against duplicate in-flight sync.
- **Verification**: `dart format` PASS; targeted 29 Flutter tests PASS; `flutter analyze --no-fatal-infos --no-fatal-warnings` 319 issues/0 errors; `git diff --check` PASS. Full `flutter test` not rerun this pass (previous: 62 pass, 1 env-dependent backend integration failure at 127.0.0.1:5001). Integration/socket runtime blocked (no Mongo 27019/Docker).
- **Remaining**: exhaustive Flutter audit/tests across all features, real multi-client/reconnect/account-switch/FCM staging, full suite rerun in env with backend.

## Phase 14F.3 Realtime Regression Tests (targeted)
- Ran: `dart format` (touched files), `flutter test` for `match_realtime_test.dart`, `features/auction/auction_feature_test.dart`, `features/notifications/notifications_feature_test.dart`, `realtime_lifecycle_test.dart` (**23 passed**), `flutter analyze --no-fatal-infos --no-fatal-warnings` (**313 issues, 0 errors**), `git diff --check` (pass).
- Added deterministic fake-socket coverage for token refresh/rebuild, missing-token no reconnect, room rejoin, match/auction stale-version guards, auction redacted financial merge preservation, and notification payload route validation.
- Not run: full Flutter suite this pass; backend integration/socket multi-client tests (blocked by no safe local Mongo 27019 / Docker unavailable); real-device push tap/background/terminated flows; staging/manual multi-client reconnect.
- Defects fixed: auction redacted merge identity (`auctionPlayerId/_id/id`); injectable socket builders for deterministic tests.

## Phase 14H/14H.1 DB/Query Performance (code-level, targeted)
- **Fixed**: notification delivery retry worker batch-loads notifications/device tokens per batch (N+1 removed, cap 100). Match live/completed batch-load innings (N+1 removed); upcoming/completed capped at 100. `notifyUsers` fan-out now bounded-batch (100): batched preference/dedupe/token reads, `insertMany({ordered:false})`, duplicate dedupe preserved, partial failures reported via `failed/errors` (no silent success), batch unread-count aggregation. Admin reports paginated (`page/limit`, max 500); export uses 500-row batch reads to avoid full in-memory DB load while preserving CSV completeness.
- **Verification**: `cd backend && npm run lint` PASS; `cd backend && npm test -- --runInBand` PASS (**25 suites, 94 tests**); `git diff --check` PASS.
- **Not verified**: Mongo explain/query plans, index selectivity, aggregation performance on representative data, replica-set transaction behavior, production index migration impact, large-broadcast runtime behavior.
- **Remaining**: notifyUsers still does per-created-notification socket/delivery side effects and could need queue/outbox for very large broadcasts; admin export still assembles CSV string in memory; player-stats aggregations need explain on representative data; no production index migrations.

## Remaining Risks / Manual Testing
- Integration tests blocked in this environment (no MongoDB on 27019, no mongod, Docker unavailable).
- Flutter integration test requires running backend; failed in this env due connection refused.
- Manual staging tests needed: concurrent scoring, auction bidding concurrency, socket reconnect/recovery, push notification delivery on real devices, admin authorization matrix, backup/restore drill, mobile auction auth-flow verification, DB explain/index verification on safe staging-like data.
