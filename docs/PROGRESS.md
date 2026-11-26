# Project Progress

## PHASE 1: ENVIRONMENT AND PROJECT SETUP ✅
- [x] Inspect environment (Node v20.18.0, npm v10.8.2, Java 21)
- [x] Verify Flutter (installed via snap, Dart 3.13.2)
- [x] Create monorepo structure
- [x] Backend: package.json with all dependencies
- [x] Backend: tsconfig.json configured
- [x] Backend: .env.example with all variables
- [x] Backend: jest.config.js
- [x] Flutter: pubspec.yaml with all dependencies
- [x] Flutter: analysis_options.yaml
- [x] Documentation structure

## PHASE 2: BACKEND ARCHITECTURE, MONGODB & AUTH ✅
### Configuration (3 files)
- [x] src/config/env.ts - Centralized environment config
- [x] src/config/database.ts - MongoDB connection with retry
- [x] src/config/swagger.ts - OpenAPI/Swagger setup

### Constants (3 files)
- [x] src/constants/roles.ts - UserRole enum (6 roles)
- [x] src/constants/enums.ts - 21 game-related enums
- [x] src/constants/messages.ts - API response messages

### Utilities (6 files)
- [x] src/utils/apiResponse.ts - Standardized responses
- [x] src/utils/apiError.ts - Custom error class
- [x] src/utils/asyncHandler.ts - Async wrapper
- [x] src/utils/pagination.ts - Pagination helpers
- [x] src/utils/logger.ts - Color-coded logger
- [x] src/utils/otp.ts - OTP generation/validation

### MongoDB Models (15 files)
- [x] User, Player, Team, TeamMember, TeamInvitation
- [x] Tournament, TournamentTeam, Match, Innings, Delivery
- [x] Auction, AuctionPlayer, AuctionBid
- [x] Notification, RefreshToken

### Authentication System
- [x] src/middlewares/auth.middleware.ts - JWT protect
- [x] src/middlewares/authorize.middleware.ts - Role-based auth
- [x] src/middlewares/validate.middleware.ts - Joi validation
- [x] src/middlewares/upload.middleware.ts - Multer file upload
- [x] src/middlewares/rateLimiter.middleware.ts - Rate limiting
- [x] src/middlewares/error.middleware.ts - Global error handler
- [x] src/validators/auth.validator.ts - Auth Joi schemas
- [x] src/services/auth.service.ts - Auth business logic
- [x] src/controllers/auth.controller.ts - Auth endpoints
- [x] src/controllers/user.controller.ts - Admin user management
- [x] src/routes/auth.routes.ts - Auth routing
- [x] src/routes/user.routes.ts - User routing
- [x] src/routes/index.ts - Route aggregator
- [x] src/app.ts - Express app setup
- [x] src/server.ts - HTTP + Socket.IO server
- [x] src/types/express.d.ts - Type augmentation
- [x] TypeScript compilation: 0 errors

## PHASE 3: FLUTTER ARCHITECTURE, THEME & NAVIGATION ✅
### Core Architecture (19 files)
- [x] lib/core/constants/app_constants.dart
- [x] lib/core/constants/api_endpoints.dart
- [x] lib/core/config/app_config.dart
- [x] lib/core/theme/app_colors.dart - Orange/Navy design system
- [x] lib/core/theme/app_text_styles.dart - Poppins typography
- [x] lib/core/theme/app_theme.dart - Material 3 light/dark
- [x] lib/core/errors/exceptions.dart
- [x] lib/core/errors/failures.dart
- [x] lib/core/storage/secure_storage.dart
- [x] lib/core/api/api_client.dart - Dio with interceptors
- [x] lib/core/routing/app_router.dart - GoRouter 28+ routes
- [x] lib/core/widgets/ - 8 reusable widgets
- [x] lib/main.dart - ProviderScope + MaterialApp.router

## PHASE 4: AUTH SCREENS & API INTEGRATION ✅
### Flutter Auth Feature (16 files)
- [x] Domain: User entity, AuthResponse entity, AuthRepository interface
- [x] Data: UserModel, AuthRemoteDataSource, AuthRepositoryImpl
- [x] Providers: AuthNotifier, AuthState, auth providers
- [x] Screens: Splash, Onboarding, Login, Register, OTP, Forgot Password, Reset Password
- [x] Widgets: AuthHeader, PasswordStrengthIndicator, OTPInputField

## PHASE 4A: AUTHENTICATION HARDENING ✅
### Backend
- [x] Public registration always creates `NORMAL_USER`; privileged roles are rejected
- [x] Registration returns `{ user, userId }` and does not issue tokens before OTP verification
- [x] OTP values are bcrypt-hashed before storage and verified with `bcrypt.compare`
- [x] OTP records track purpose, attempts, resend count, and last sent time
- [x] Added `POST /auth/resend-otp` with attempt cooldown, resend limit, and rate limiting
- [x] OTP verification issues access/refresh tokens only after success
- [x] Refresh tokens are SHA-256 hashed in MongoDB and atomically rotated
- [x] Logout revokes the hashed refresh token
- [x] `protect` middleware rejects unverified users
- [x] Production config rejects placeholder JWT secrets and wildcard CORS origins
- [x] CORS uses credentials only for explicit allowlists

### Flutter
- [x] Pinned Riverpod 2.6.1 and removed unused Riverpod generator packages
- [x] Fixed Flutter/Dart API drift in theme, dashboard, match, and tournament screens
- [x] `SecureStorage` uses default `AndroidOptions()` and exposes generic secure string helpers
- [x] `AuthResponse` parses nested `{ data: { tokens: ... } }` payloads
- [x] `ApiClient` avoids refresh loops on public auth routes and parses rotated tokens correctly
- [x] Registration navigates to OTP with the real backend `userId`
- [x] OTP resend is wired to `POST /auth/resend-otp`
- [x] Forgot password returns the real backend `userId` for reset
- [x] Removed placeholder user IDs from OTP and password reset flows
- [x] Avatar upload uses `PUT /auth/avatar`

### Tests
- [x] Backend auth service unit tests (8 tests total, all passing)
- [x] Backend auth validator tests
- [x] Flutter auth response parsing tests
- [x] Flutter `AuthNotifier` registration, OTP, and password-reset tests
- [x] `npm run lint` passed
- [x] `npm test` passed: 2 suites, 8 tests
- [x] `flutter pub get` passed
- [x] `flutter analyze` has no errors (remaining lints/deprecation notices only)
- [x] `flutter test` passed: 6 tests

## PHASE 5: TEAM, PLAYER & DASHBOARD INTEGRATION ✅
### Backend
- [x] Team CRUD, member management, invitation, stats, and match APIs verified against clients
- [x] Player CRUD, search, stats, teams, and match APIs verified against clients
- [x] Team/player Joi query and body validation aligned with Flutter requests
- [x] Fixed Express 5 read-only `req.query` handling in `validate.middleware.ts`
- [x] Added middleware, player validator, player controller, and team controller tests

### Flutter
- [x] Replaced dashboard mock data with real match/team/player/tournament API aggregation
- [x] Dashboard match parser handles populated teams, innings scores, results, and date fallback
- [x] Team endpoints corrected for invitations, role updates, stats, and matches
- [x] Team create uses JSON logo URL instead of unsupported multipart upload
- [x] Team detail renders real stats and match history
- [x] Team and player lists support pagination load-more
- [x] Player search uses `search`/`playingRole`; profile lookup verifies `user` across paginated results
- [x] Player detail merges nested career stats from `/players/:id/stats`
- [x] Player create/update payloads no longer send unsupported `user`/`name`
- [x] Added dashboard, team, and player parsing tests

### Tests
- [x] `npm run lint` passed
- [x] `npm test` passed: 6 suites, 20 tests
- [x] `flutter analyze` has no errors (remaining lints/deprecation notices only)
- [x] `flutter test` passed: 12 tests

## PHASE 6: TOURNAMENT MANAGEMENT ✅
### Backend
- [x] Added tournament list query validation for paging, sorting, status, city, format, organizer, and search
- [x] Registered tournament query validation on `GET /api/v1/tournaments`
- [x] Escaped regex inputs used by tournament city and search filters
- [x] Added tournament create, status, registration, and query validator tests

### Flutter
- [x] Replaced tournament mock/fallback data with real backend API calls
- [x] Corrected tournament management endpoint constants and fixture generation URL
- [x] Added tournament status updates, team approval/rejection, and draft deletion actions
- [x] Changed team registration to use real team IDs from `myTeamsProvider`
- [x] Aligned create payload with backend lifecycle by setting `REGISTRATION_OPEN` after create
- [x] Added tournament list search, status filtering, and pagination load-more
- [x] Parsed backend team counts and standings rank instead of deriving them locally
- [x] Parsed backend fixture titles, match numbers, and toss status
- [x] Added tournament endpoint, team count, and standings rank parsing tests

### Tests
- [x] `npm run lint` passed
- [x] `npm test` passed: 7 suites, 24 tests
- [x] `flutter analyze` has no errors (remaining lints/deprecation notices only)
- [x] `flutter test` passed: 15 tests

## PHASE 7: MATCH CREATION & TOSS ✅
### Backend
- [x] Added match list query validation for paging, sorting, status, format, tournament, team, city, and search
- [x] Registered match query validation on `GET /api/v1/matches`
- [x] Escaped regex inputs used by match city and search filters
- [x] Rejected duplicate team ObjectIds case-insensitively during match creation
- [x] Blocked match creation for draft, completed, and cancelled tournaments
- [x] Guarded null tournament organizer and team owner references in permission checks
- [x] Blocked toss updates after the toss stage and normalized winner comparison with ObjectIds
- [x] Blocked starting cancelled matches
- [x] Added match create, toss, and list query validator tests

### Flutter
- [x] Removed all match mock/fallback data from the repository
- [x] Replaced synthetic team names and IDs with real team selection from `myTeamsProvider`
- [x] Changed create payloads to send `teamA`/`teamB` ObjectIds and optional `tournamentId`
- [x] Removed unsupported `status` and `currentInnings` fields from create payloads
- [x] Changed toss to send the selected team ID as `winner`
- [x] Exposed team and tournament IDs from populated backend match payloads
- [x] Mapped backend `error` arrays to `ValidationException`
- [x] Removed the nonexistent innings endpoint by deriving innings from the scorecard response
- [x] Switched match list loading to backend status/search filters
- [x] Fixed match list error state clearing and action validation error messages
- [x] Added match endpoint, team ID, and validation error parsing tests

### Tests
- [x] `npm run lint` passed
- [x] `npm test` passed: 8 suites, 28 tests
- [x] `flutter analyze` has no errors (remaining lints/deprecation notices only)
- [x] `flutter test` passed: 18 tests

## PHASE 8: LIVE SCORING ENGINE & FLUTTER SCORING UI ✅
### Backend
- [x] Added authoritative ball-by-ball scoring engine with legal deliveries, extras, strike rotation, overs, wickets, fall of wickets, targets, and results
- [x] Added transactional scoring orchestration with `Idempotency-Key`, `If-Match` optimistic concurrency, `stateVersion`, and `ScoringAudit`
- [x] Added scoring routes for start-innings, ball, innings-end, complete, state, innings, commentary, undo, and correction
- [x] Added `ballsPerOver`, innings state-version tracking, populated scoring state responses, and CORS support for scoring headers
- [x] Fixed idempotent delivery replay, version increment on undo/correction, bowler rotation after an over, and same-bowler consecutive-over rejection

### Flutter
- [x] Replaced scoring placeholders with real live scoring and full scorecard screens
- [x] Added real scoring datasource/repository/provider calls for innings start, ball delivery, extras, wickets, correction, undo, and match completion
- [x] Added bowler selection, scoring controls, correction dialog, undo, commentary, fall of wickets, partnerships, and result rendering
- [x] Wired match detail scoring navigation and removed the mock playing XI card
- [x] Added `venue` parsing to scoring match state and added scoring data parsing tests

### Tests
- [x] `npm run lint` passed
- [x] `npm test` passed: 9 suites, 34 tests
- [x] `npm run test:integration` passed: 7 suites, 35 tests
- [x] `flutter analyze --no-fatal-infos --no-fatal-warnings` passed with 0 errors; 256 existing info/warning lints remain
- [x] `flutter test` passed: 21 tests
- [x] Host-run Flutter real-backend integration passed: 1 test
- [x] `git diff --check` passed

## PHASE 9: REAL-TIME MATCH SYNCHRONIZATION ✅
### Backend
- [x] Added authenticated Socket.IO server configuration with shared CORS resolution and JWT handshake validation
- [x] Added match viewer/scorer rooms with fresh server-side access checks on join/sync and token-expiry disconnect handling
- [x] Added versioned realtime event envelope with `eventId`, `matchId`, `action`, `stateVersion`, `inningsNumber`, `occurredAt`, and `actorId`
- [x] Published `match:state`, `score:delivery`, `wicket:recorded`, `score:corrected`, `score:undone`, over/innings/match events only after scoring persistence succeeds
- [x] Suppressed duplicate-idempotency replays and de-duplicated repeated socket event emissions
- [x] Added `match:join`, `match:leave`, and `match:sync` handlers so clients recover authoritative state after reconnect
- [x] Kept all scoring rules in the scoring service; socket handlers only authorize, join rooms, and emit post-commit state

### Flutter
- [x] Added a single reusable Socket.IO client with secure-token authentication, room ref-counting, automatic reconnect joins, and ack-based state recovery
- [x] Added Riverpod realtime providers that join a match room only while an authenticated screen is mounted and leave it on dispose
- [x] Applied authoritative versioned state snapshots to the scoring provider with stale-version rejection and event-id de-duplication
- [x] Invalidated match detail, scorecard, commentary, and innings providers when realtime scoring events arrive
- [x] Wired live scoring, full scorecard, and match detail screens to realtime room lifecycle updates
- [x] Surfaced realtime error events in scoring UI state

### Tests
- [x] `npm run lint` passed
- [x] `npm test` passed: 9 suites, 34 tests
- [x] `npm run test:integration` passed: 8 suites, 40 tests
- [x] `flutter analyze --no-fatal-infos --no-fatal-warnings` passed with 0 errors; 256 existing info/warning lints remain
- [x] `flutter test` passed: 24 tests
- [x] Host-run Flutter real-backend integration passed: 1 test
- [x] `git diff --check` passed

## PHASE 10: LIVE PLAYER AUCTION SYSTEM ✅
### Backend
- [x] Added auction, auction team, auction player, auction bid, and auction audit models with indexed `auctionId`, team, player, idempotency, and version fields
- [x] Added auction constants for lifecycle, player/bid decisions, realtime actions, and result states
- [x] Implemented authoritative auction service for create/update/delete/list/detail/state, lifecycle, participant teams, player registration/import/removal/availability/bring-forward, bids, bid decisions, SOLD/UNSOLD, next player, purse, results, and history
- [x] Enforced transactional bid acceptance with team budgets, pending commitments, minimum increments, auction-wide `nextSequence`, unique indexes, `Idempotency-Key`, `If-Match`, and `stateVersion`
- [x] Finalized remaining available players as UNSOLD on auction completion and emitted SOLD/UNSOLD events after commit
- [x] Added REST routes and Joi validation for `/api/v1/auctions` lifecycle, players, teams, purse, state, history, results, bid, decision, sold, unsold, and next actions
- [x] Added authenticated auction Socket.IO rooms with `auction:join`, `auction:leave`, `auction:sync`, and `auction:bid`; access checks are repeated on every join/sync/bid
- [x] Published versioned post-commit auction state events and token-expiry disconnect handling
- [x] Fixed transactional array creates, session-aware `touchAuction`, retry detection, bid sequence `$set`, idempotency replay ordering, and forbidden bid ack error codes

### Flutter
- [x] Replaced auction placeholders with real auctions list, create, detail, and live bidding screens
- [x] Added auction domain entities, models, normalization helpers, REST datasource, repository, and Riverpod providers
- [x] Added authenticated Socket.IO auction client with room ref-counting, reconnect joins, state recovery, event-id de-duplication, stale-version rejection, and error surfacing
- [x] Added live auction UI with tabbed players/teams/bids/results views, bid panel, server sequence display, authoritative budget display, and manager actions
- [x] Wired create-auction team selection to real owned teams and validation; bid increments are parsed safely from numeric input
- [x] Removed placeholder auction screens and registered the real create route before `/auctions/:id`
- [x] Kept all bid validation, budget math, sequence assignment, and settlement on the backend; Flutter only renders server-provided values

### Tests
- [x] Backend auction validator unit tests
- [x] Backend real-MongoDB integration tests for lifecycle, budgets, idempotency, concurrency, bids, decisions, results, and Socket.IO flows
- [x] Flutter auction tests for endpoint constants, authoritative state parsing, envelope normalization, realtime event normalization, live-state versioning/de-duplication, and socket error surfacing
- [x] `npm test` passed: 10 suites, 40 tests
- [x] `npm run test:integration` equivalent passed: 10 suites, 51 tests
- [x] `flutter analyze --no-fatal-infos --no-fatal-warnings` passes with 0 errors; remaining 286 info/warning lints are non-fatal
- [x] Flutter unit suite excluding the host-run backend integration test passes with 28 tests

## Current Status
- Backend authentication hardened and covered by isolated unit tests
- Flutter auth/session flow aligned with backend payloads and Riverpod 2
- Backend query validation works under Express 5
- Dashboard, Teams, Players, Tournaments, and Matches use real backend APIs with no mock data
- Live scoring is implemented end-to-end with backend-authoritative rules and real Flutter screens
- Real-time match synchronization is implemented with authenticated Socket.IO rooms, versioned post-commit events, and reconnect recovery
- Live player auctions are implemented end-to-end with backend-authoritative bids, budgets, sequence numbers, lifecycle, and Socket.IO state events
- Notifications and FCM are implemented with REST, Socket.IO, preferences, retrying deliveries, and a Flutter notification center
- Player statistics and leaderboards are computed on the backend from authoritative persisted match, innings, and delivery data
- Backend: TypeScript compilation passes with 0 errors
- Flutter: analyzer passes with 0 errors; remaining notices are lints/deprecations
- Phases 1-12 complete
- MongoDB verification complete against isolated local databases; scoring tests use a single-node replica set for transactions

## Integration Verification Report

### 1. Integration Tests Added
- Backend Jest integration config: `backend/jest.integration.config.js`
- Backend integration helpers and safety guards:
  - `backend/tests/integration/env.ts`
  - `backend/tests/integration/setup.ts`
  - `backend/tests/integration/helpers.ts`
- Backend real-MongoDB suites:
  - `backend/tests/integration/auth.integration.test.ts`
  - `backend/tests/integration/teams.integration.test.ts`
  - `backend/tests/integration/players.integration.test.ts`
  - `backend/tests/integration/tournaments.integration.test.ts`
  - `backend/tests/integration/matches.integration.test.ts`
  - `backend/tests/integration/integrity.integration.test.ts`
   - `backend/tests/integration/scoring.integration.test.ts`
   - `backend/tests/integration/statistics.integration.test.ts`
- Flutter scoring parsing tests:
  - `mobile/test/scoring_data_test.dart`
- Flutter real-backend datasource integration:
  - `mobile/test/integration/backend_integration_test.dart`
   - Exercises registration, OTP verification, login, refresh rotation, profile, player create/search, statistics overview, player statistics, leaderboard, team create, tournament create/status/team registration/approval/fixtures, match create/list/toss/detail against the real backend.
  - Uses no hardcoded mock responses and no `SecureStorage` platform channels.

### 2. Tests Passed and Failed
- Final backend lint: `npm run lint` passed with 0 TypeScript errors.
- Final backend unit tests: `npm test` passed: 9 suites, 34 tests.
- Final backend MongoDB integration: `npm run test:integration` passed: 7 suites, 35 tests.
- Final Flutter analyzer: `flutter analyze --no-fatal-infos --no-fatal-warnings` passed with 0 errors; 256 existing info/warning lints remain.
- Final Flutter tests: `flutter test` passed: 21 tests, including scoring parsing and real-backend integration tests.
- Final host-run Flutter real-backend integration: `flutter test test/integration/backend_integration_test.dart` passed: 1 test.
- Final whitespace check: `git diff --check` passed.
- Final Phase 10 backend lint passed; unit tests passed: 10 suites, 40 tests; MongoDB integration tests passed: 10 suites, 51 tests.
- Final Phase 10 Flutter analyzer passed with 0 errors; 286 non-fatal info/warning lints remain.
- Final Phase 10 Flutter unit suite excluding the host-run backend integration test passed with 28 tests.
- Final Flutter auction tests passed: 5 tests.
- No tests failed in the final unit/analyzer runs. Failures found during development were fixed:
  - Invitation response assertion used the wrong nested field.
  - Match XI authorization test needed a non-participant ObjectId.
  - Integrity tests needed to account for automatic owner-player enrollment and use unique search prefixes.
  - Refresh tokens generated identical JWTs in the same second, causing a rotation conflict; fixed with unique `jwtid`.
  - Player tests needed to read populated `user._id` and use short names within Joi limits.
  - Default backend Jest config initially included integration suites; unit tests are now isolated with `testPathIgnorePatterns`.
  - `ts-node` initially failed to load the Express request augmentation; fixed with `ts-node.files` in `backend/tsconfig.json`.
  - Scoring wicket tests needed the current striker to verify replacement batter advancement.
  - Scoring innings-end tests needed to inspect innings 1 because ending it activates innings 2.

### 3. Database Issues Discovered
- Isolated MongoDB 7.0.24 was started locally on port 27019 with dbpath `/tmp/opencode/cricket-hub-mongo-it/db`.
- Scoring tests require multi-document transactions, so the isolated MongoDB runs as single-node replica set `rs0`; no Docker was introduced.
- Integration tests used `cricket_hub_integration_test`; Flutter backend integration used `cricket_hub_flutter_integration_test`.
- Destructive drops are limited to isolated local databases; setup rejects non-local hosts and non-test database names.
- Mongoose emits duplicate schema index warnings for:
  - `User.email`, `User.phone`
  - `RefreshToken.token`
  - `Team.name`, `Team.owner`
- Unique indexes were still created and exercised, but duplicate declarations should be cleaned up.
- Mongoose emits deprecation warnings for `findOneAndUpdate`/`findOneAndReplace` using `new` instead of `returnDocument: 'after'`.
- Jest initially hit a missing MongoDB client metadata error; integration setup now supplies the `os` runtime adapter.

### 4. API Issues Discovered
- Fixed: refresh token rotation collided when two JWTs were generated within the same second; refresh and access tokens now use unique `jwtid` values.
- Fixed: `ts-node` server startup now loads Express type augmentation through `ts-node.files`.
- Potential issue remains: login appears to issue tokens before verifying `isVerified`, while `protect` rejects unverified users.
- Potential issue remains: logout revokes the refresh token only; access tokens may remain valid until expiry.
- Potential issue remains: some team/player query filters use unescaped regex input; tournament and match filters have been escaped.
- OTP values are exposed in API responses only when `NODE_ENV=development` or `NODE_ENV=test`; production must never use those modes.

### 5. Files Changed
- Modified:
  - `backend/.env.example`
  - `backend/jest.config.js`
  - `backend/package.json`
  - `backend/src/config/database.ts`
  - `backend/src/config/env.ts`
  - `backend/src/services/auth.service.ts`
  - `backend/tsconfig.json`
  - `mobile/pubspec.yaml`
  - `mobile/pubspec.lock`
  - `docs/PROGRESS.md`
- Added:
  - `backend/jest.integration.config.js`
  - `backend/tests/integration/env.ts`
  - `backend/tests/integration/setup.ts`
  - `backend/tests/integration/helpers.ts`
  - `backend/tests/integration/auth.integration.test.ts`
  - `backend/tests/integration/teams.integration.test.ts`
  - `backend/tests/integration/players.integration.test.ts`
  - `backend/tests/integration/tournaments.integration.test.ts`
  - `backend/tests/integration/matches.integration.test.ts`
  - `backend/tests/integration/integrity.integration.test.ts`
  - `mobile/test/integration/backend_integration_test.dart`

### 6. Phase 8 Files Changed
- Added:
  - `backend/src/models/ScoringAudit.ts`
  - `backend/src/services/scoringEngine.ts`
  - `backend/src/services/scoring.service.ts`
  - `backend/src/controllers/scoring.controller.ts`
  - `backend/src/routes/scoring.routes.ts`
  - `backend/src/validators/scoring.validator.ts`
  - `backend/src/services/__tests__/scoringEngine.test.ts`
  - `backend/tests/integration/scoring.integration.test.ts`
  - `mobile/lib/features/matches/domain/entities/scoring.dart`
  - `mobile/lib/features/matches/data/models/scoring_model.dart`
  - `mobile/lib/features/matches/data/datasources/scoring_remote_datasource.dart`
  - `mobile/lib/features/matches/data/repositories/scoring_repository_impl.dart`
  - `mobile/lib/features/matches/presentation/providers/scoring_provider.dart`
  - `mobile/lib/features/matches/presentation/screens/live_scoring_screen.dart`
  - `mobile/lib/features/matches/presentation/screens/full_scorecard_screen.dart`
  - `mobile/test/scoring_data_test.dart`
- Modified:
  - `backend/src/models/Match.ts`
  - `backend/src/models/Innings.ts`
  - `backend/src/routes/index.ts`
  - `backend/src/app.ts`
  - `backend/src/services/match.service.ts`
  - `backend/src/validators/match.validator.ts`
  - `mobile/lib/core/constants/api_endpoints.dart`
  - `mobile/lib/core/routing/app_router.dart`
  - `mobile/lib/features/matches/data/models/innings_model.dart`
  - `mobile/lib/features/matches/domain/entities/innings.dart`
  - `mobile/lib/features/matches/presentation/screens/match_detail_screen.dart`
  - `docs/PROGRESS.md`

### 7. Phase 9 Files Changed
- Added:
  - `backend/src/config/cors.ts`
  - `backend/src/config/socket.ts`
  - `backend/src/sockets/auth.ts`
  - `backend/src/sockets/matchHandlers.ts`
  - `backend/src/sockets/publisher.ts`
  - `backend/src/sockets/types.ts`
  - `backend/tests/integration/socket.integration.test.ts`
  - `mobile/lib/features/matches/data/realtime/match_realtime_client.dart`
  - `mobile/lib/features/matches/data/realtime/match_realtime_event.dart`
  - `mobile/lib/features/matches/presentation/providers/realtime_provider.dart`
  - `mobile/test/match_realtime_test.dart`
- Modified:
  - `backend/package.json`
  - `backend/package-lock.json`
  - `backend/src/app.ts`
  - `backend/src/server.ts`
  - `backend/src/controllers/scoring.controller.ts`
  - `backend/src/services/match.service.ts`
  - `backend/src/services/scoring.service.ts`
  - `mobile/lib/features/matches/presentation/providers/scoring_provider.dart`
  - `mobile/lib/features/matches/presentation/screens/live_scoring_screen.dart`
  - `mobile/lib/features/matches/presentation/screens/full_scorecard_screen.dart`
  - `mobile/lib/features/matches/presentation/screens/match_detail_screen.dart`
  - `docs/PROGRESS.md`

### 8. Phase 10 Files Changed
- Added:
  - `backend/src/controllers/auction.controller.ts`
  - `backend/src/models/AuctionAudit.ts`
  - `backend/src/models/AuctionTeam.ts`
  - `backend/src/routes/auction.routes.ts`
  - `backend/src/services/auction.service.ts`
  - `backend/src/sockets/auctionHandlers.ts`
  - `backend/src/validators/auction.validator.ts`
  - `backend/src/validators/__tests__/auction.validator.test.ts`
  - `backend/tests/integration/auction.integration.test.ts`
  - `backend/tests/integration/auction_socket.integration.test.ts`
  - `mobile/lib/features/auction/data/datasources/auction_remote_datasource.dart`
  - `mobile/lib/features/auction/data/models/auction_json.dart`
  - `mobile/lib/features/auction/data/models/auction_bid_model.dart`
  - `mobile/lib/features/auction/data/models/auction_model.dart`
  - `mobile/lib/features/auction/data/models/auction_player_model.dart`
  - `mobile/lib/features/auction/data/models/auction_state_model.dart`
  - `mobile/lib/features/auction/data/models/auction_team_model.dart`
  - `mobile/lib/features/auction/data/realtime/auction_realtime_client.dart`
  - `mobile/lib/features/auction/data/realtime/auction_realtime_event.dart`
  - `mobile/lib/features/auction/data/repositories/auction_repository_impl.dart`
  - `mobile/lib/features/auction/domain/entities/auction.dart`
  - `mobile/lib/features/auction/domain/entities/auction_bid.dart`
  - `mobile/lib/features/auction/domain/entities/auction_player.dart`
  - `mobile/lib/features/auction/domain/entities/auction_state.dart`
  - `mobile/lib/features/auction/domain/entities/auction_team.dart`
  - `mobile/lib/features/auction/domain/repositories/auction_repository.dart`
  - `mobile/lib/features/auction/presentation/providers/auction_provider.dart`
  - `mobile/lib/features/auction/presentation/screens/auctions_screen.dart`
  - `mobile/lib/features/auction/presentation/screens/create_auction_screen.dart`
  - `mobile/lib/features/auction/presentation/screens/auction_detail_screen.dart`
  - `mobile/lib/features/auction/presentation/screens/auction_bidding_screen.dart`
  - `mobile/lib/features/auction/presentation/widgets/auction_bid_tile.dart`
  - `mobile/lib/features/auction/presentation/widgets/auction_card.dart`
  - `mobile/lib/features/auction/presentation/widgets/auction_live_view.dart`
  - `mobile/lib/features/auction/presentation/widgets/auction_player_tile.dart`
  - `mobile/test/features/auction/auction_feature_test.dart`
- Modified:
  - `backend/src/config/socket.ts`
  - `backend/src/constants/enums.ts`
  - `backend/src/models/Auction.ts`
  - `backend/src/models/AuctionBid.ts`
  - `backend/src/models/AuctionPlayer.ts`
  - `backend/src/routes/index.ts`
  - `backend/src/sockets/auth.ts`
  - `backend/src/sockets/publisher.ts`
  - `backend/src/sockets/types.ts`
  - `backend/tests/integration/setup.ts`
  - `mobile/lib/core/constants/api_endpoints.dart`
  - `mobile/lib/core/routing/app_router.dart`
  - `docs/PROGRESS.md`

## PHASE 11: NOTIFICATIONS & FIREBASE CLOUD MESSAGING ✅
### 1. Backend Notification System
- [x] Added notification, device-token, delivery, and preference models with safe indexes
- [x] Added notification REST APIs for list, unread count, read, read-all, delete, preferences, and device-token registration/removal
- [x] Added Joi validators and standardized API response/error handling
- [x] Added user-scoped notification queries with unread/read/category/type/entity filters
- [x] Added expiration filtering so expired notifications are hidden from list/detail/unread APIs
- [x] Added dedupe keys and preference checks before fanout
- [x] Added notification hooks to team, tournament, match, scoring, and auction flows

### 2. FCM Delivery Pipeline
- [x] Added Firebase Admin initialization with environment-based credentials
- [x] Added `FcmSender`/`FirebaseFcmSender` abstraction for testable delivery
- [x] Added persisted delivery records with attempts, retry timing, failure codes, and status
- [x] Added scheduled retry worker and batch size/interval configuration
- [x] Added invalid-token deactivation and cancellation handling
- [x] Included `notificationId`, `type`, `category`, `relatedEntityType`, and `relatedEntityId` in FCM data payloads for deep links
- [x] Added graceful no-op behavior when Firebase credentials are not configured

### 3. Socket.IO Notification Events
- [x] Added authenticated user rooms for realtime notification delivery
- [x] Published `notification:new`, `notification:read`, and `notification:unread-count` events
- [x] Added event IDs for client-side de-duplication
- [x] Added socket integration coverage for authenticated notification rooms

### 4. Flutter Notification Center
- [x] Added Firebase initialization with platform-specific options
- [x] Added Android manifest permission/metadata and iOS notification capability configuration
- [x] Added `PushNotificationService` for permissions, token registration, refresh, and tap handling
- [x] Added post-auth automatic push token registration and logout unregistration
- [x] Added notification data source, repository, models, and Riverpod providers
- [x] Added notification list, detail, preferences, and unread badge UI
- [x] Added GoRouter notification routes and dashboard unread badge wiring
- [x] Added realtime notification event handling and unread count refresh
- [x] Fixed read endpoint mismatch and iOS `iosBundleId` Firebase option drift

### 5. Phase 11 Tests
- [x] Added backend notification validator unit tests
- [x] Added FCM delivery unit tests with mocked sender and invalid-token/retry cases
- [x] Added backend notification REST integration tests
- [x] Added backend notification Socket.IO integration tests
- [x] Added Flutter notification parsing, preferences, providers, realtime, and push-service tests
- [x] Extended the host-backend Flutter integration test with notification list, unread count, mark-read, preferences, and device-token registration/removal

### 6. Phase 11 Verification
- [x] `npm run lint` passed
- [x] `npm test` passed: 12 suites, 48 tests
- [x] `npm run test:integration` passed: 12 suites, 57 tests (local MongoDB replica set)
- [x] `flutter analyze --no-fatal-infos --no-fatal-warnings` has no errors (remaining lints/deprecations only)
- [x] `flutter test` passed: 37 tests, including the real host-backend integration flow on port 5001
- [x] `git diff --check` passed

### 7. Phase 11 Files Changed
- Added:
  - `backend/src/config/firebase.ts`
  - `backend/src/controllers/notification.controller.ts`
  - `backend/src/models/DeviceToken.ts`
  - `backend/src/models/NotificationDelivery.ts`
  - `backend/src/models/NotificationPreference.ts`
  - `backend/src/routes/notification.routes.ts`
  - `backend/src/services/fcmSender.service.ts`
  - `backend/src/services/notification.service.ts`
  - `backend/src/services/notificationDelivery.service.ts`
  - `backend/src/services/notificationHooks.service.ts`
  - `backend/src/validators/notification.validator.ts`
  - `backend/src/validators/__tests__/notification.validator.test.ts`
  - `backend/src/services/__tests__/notificationDelivery.service.test.ts`
  - `backend/tests/integration/notification.integration.test.ts`
  - `backend/tests/integration/notification_socket.integration.test.ts`
  - `mobile/lib/core/config/firebase_initializer.dart`
  - `mobile/lib/core/config/firebase_options.dart`
  - `mobile/lib/features/notifications/`
  - `mobile/test/features/notifications/`
- Modified:
  - `backend/.env.example`
  - `backend/package.json`
  - `backend/package-lock.json`
  - `backend/src/config/env.ts`
  - `backend/src/config/socket.ts`
  - `backend/src/constants/enums.ts`
  - `backend/src/constants/messages.ts`
  - `backend/src/models/Notification.ts`
  - `backend/src/routes/index.ts`
  - `backend/src/server.ts`
  - `backend/src/services/auction.service.ts`
  - `backend/src/services/match.service.ts`
  - `backend/src/services/scoring.service.ts`
  - `backend/src/services/team.service.ts`
  - `backend/src/services/tournament.service.ts`
  - `backend/src/sockets/auth.ts`
  - `backend/src/sockets/publisher.ts`
  - `backend/src/sockets/types.ts`
  - `backend/tests/integration/setup.ts`
  - `mobile/android/app/src/main/AndroidManifest.xml`
  - `mobile/ios/Runner/Info.plist`
  - `mobile/lib/core/constants/api_endpoints.dart`
  - `mobile/lib/core/routing/app_router.dart`
  - `mobile/lib/core/storage/secure_storage.dart`
  - `mobile/lib/features/dashboard/presentation/screens/home_screen.dart`
  - `mobile/lib/main.dart`
  - `mobile/test/integration/backend_integration_test.dart`
  - `docs/PROGRESS.md`

### 8. Remaining Production Risks
- Configure real Firebase credentials and web VAPID key before expecting device push delivery; current verification uses a mocked FCM sender.
- Use a shared adapter/store for Socket.IO rooms and notification event de-duplication before running multiple backend instances.
- Remove duplicate Mongoose index declarations and deprecated query options before production deployment.
- Decide whether login should reject unverified users before issuing tokens, and whether logout should revoke or shorten access-token validity.
- Escape all remaining user-controlled regex filters.
- Keep production `NODE_ENV=production`, use strong distinct JWT secrets, and keep OTP exposure disabled.
- Add device-based `integration_test` coverage when Linux desktop build tools or an Android/iOS emulator are available; the current Flutter integration test runs on the Flutter test host because this environment lacks CMake/GTK build tooling.
- Keep replica-set MongoDB or an equivalent transactional deployment in production so scoring and auction writes remain atomic.
- Remove duplicate Mongoose index declarations and deprecated query options before production deployment.
- Decide whether login should reject unverified users before issuing tokens, and whether logout should revoke or shorten access-token validity.
- Escape all remaining user-controlled regex filters.
- Keep production `NODE_ENV=production`, use strong distinct JWT secrets, and keep OTP exposure disabled.
- Add device-based `integration_test` coverage when Linux desktop build tools or an Android/iOS emulator are available; the current Flutter integration test runs on the Flutter test host because this environment lacks CMake/GTK build tooling.
- Keep replica-set MongoDB or an equivalent transactional deployment in production so scoring writes remain atomic.
- Socket.IO rooms and published-event de-duplication are process-local; use a Redis adapter and shared de-duplication before running multiple backend instances.

## PHASE 12: PLAYER STATISTICS & LEADERBOARDS ✅
### 1. Backend Statistics Engine
- [x] Added pure batting, bowling, fielding, leaderboard, and stat-formatting helpers in `backend/src/utils/statistics.ts`
- [x] Added backend-authoritative statistics service that derives career summaries from completed matches, eligible innings, persisted innings stats, and active deliveries
- [x] Excluded no-result, abandoned, and drawn matches and required all innings to be completed or declared before a match contributes to statistics
- [x] Calculated batting runs, balls, boundaries, dismissals, not-outs, highest score, thirties/fifties/hundreds, ducks, average, and strike rate
- [x] Calculated bowling balls, overs, maidens, runs conceded, wickets, dot balls, wides, no-balls, best figures, hauls, average, economy, and strike rate
- [x] Calculated fielding catches, run-outs, stumpings, and total dismissals from active non-undone deliveries with corrected-delivery de-duplication
- [x] Added recent form plus tournament-wise, season-wise, and format-wise breakdowns
- [x] Added leaderboard normalization for runs, wickets, averages, strike rates, economy, boundaries, and fielding dismissals with metric aliases
- [x] Added filter normalization and pagination for player statistics, overview, and leaderboard endpoints
- [x] Added indexed queries for match eligibility and statistics date/tournament/format filters

### 2. Backend APIs
- [x] Added `GET /api/v1/statistics/players/:playerId/overall`, `GET /api/v1/statistics/players/:playerId/form`, and player breakdown routes
- [x] Added `GET /api/v1/statistics` for filtered top batsmen, bowlers, and fielders
- [x] Added `GET /api/v1/leaderboards/:category` for paginated metric leaderboards
- [x] Added Joi validation and standardized statistics messages/responses
- [x] Updated legacy `GET /api/v1/players/:id/stats` to delegate to the new statistics service while retaining the old response shape

### 3. Flutter Statistics UI
- [x] Added statistics endpoint helpers to `mobile/lib/core/constants/api_endpoints.dart`
- [x] Added statistics domain entities for summaries, breakdowns, recent form, overview entries, and leaderboard entries
- [x] Added statistics remote data source, repository implementation, and Riverpod providers
- [x] Replaced statistics, leaderboard, and player-profile statistics placeholders with real backend-backed screens and widgets
- [x] Added filters for tournament, format, season, and leaderboard metric
- [x] Wired real statistics and leaderboard routes in `mobile/lib/core/routing/app_router.dart`

### 4. Phase 12 Tests
- [x] Added backend statistics calculator unit tests
- [x] Added backend real-MongoDB statistics integration tests covering eligibility, filtering, breakdowns, overview, leaderboards, validation, and legacy compatibility
- [x] Added Flutter statistics parsing, provider, widget, endpoint, and failure-handling tests
- [x] Extended the host-backend Flutter integration test with player statistics, overview, leaderboard, and tournament-scoped statistics calls

### 5. Phase 12 Verification
- [x] `npm run lint` passed
- [x] `npm test` passed: 13 suites, 54 tests
- [x] `npm run test:integration` passed: 13 suites, 62 tests (local MongoDB replica set)
- [x] `flutter analyze --no-fatal-infos --no-fatal-warnings` passed with 0 errors; remaining lints/deprecations are non-fatal
- [x] `flutter test test/integration/backend_integration_test.dart` passed
- [x] `flutter test` passed: 44 tests, including the real host-backend integration flow on port 5001
- [x] `git diff --check` passed

### 6. Phase 12 Files Changed
- Added:
  - `backend/src/controllers/statistics.controller.ts`
  - `backend/src/routes/leaderboard.routes.ts`
  - `backend/src/routes/statistics.routes.ts`
  - `backend/src/services/playerStatistics.service.ts`
  - `backend/src/utils/statistics.ts`
  - `backend/src/utils/__tests__/statistics.test.ts`
  - `backend/src/validators/statistics.validator.ts`
  - `backend/tests/integration/statistics.integration.test.ts`
  - `mobile/lib/features/statistics/`
  - `mobile/test/features/statistics/`
- Modified:
  - `backend/src/constants/messages.ts`
  - `backend/src/controllers/__tests__/player.controller.test.ts`
  - `backend/src/controllers/player.controller.ts`
  - `backend/src/models/Delivery.ts`
  - `backend/src/models/Innings.ts`
  - `backend/src/models/Match.ts`
  - `backend/src/routes/index.ts`
  - `backend/src/routes/player.routes.ts`
  - `backend/src/services/player.service.ts`
  - `backend/tests/integration/players.integration.test.ts`
  - `mobile/lib/core/constants/api_endpoints.dart`
  - `mobile/lib/core/routing/app_router.dart`
   - `mobile/lib/features/players/presentation/screens/player_detail_screen.dart`
   - `mobile/test/integration/backend_integration_test.dart`
   - `docs/PROGRESS.md`

## PHASE 13: COMPREHENSIVE ADMIN MANAGEMENT ✅
### 1. Backend Authorization & Audit Foundation
- [x] Added centralized admin permissions, actions, role mapping, and role helpers in `backend/src/constants/admin.ts`
- [x] Added reusable `authorizeAdmin(permission?)` middleware with JWT authentication, admin-role enforcement, and granular permission checks
- [x] Added dedicated `adminLimiter` rate limiter for admin endpoints and reused `authLimiter` for admin login
- [x] Added `AdminAudit` MongoDB model with indexed admin/action/target/date queries
- [x] Added audit redaction for password, OTP, token, refresh token, FCM token, secret, JWT, authorization, cookie, and nested sensitive fields
- [x] Added audited admin service that records admin id, role, action, target, before/after values, reason, metadata, IP address, and user agent
- [x] Rejected unverified and non-admin users from admin login and all admin APIs on the backend, not only in the UI
- [x] Preserved the existing `ADMIN` role and kept the permission map extensible without adding an unused super-admin role

### 2. Backend Admin APIs
- [x] Added `POST /api/v1/admin/auth/login` for audited, rate-limited administrator login
- [x] Added `GET /api/v1/admin/dashboard` for platform counts, activity summaries, and recent audit entries
- [x] Added user management endpoints for paginated search, detail lookup, status changes, role changes, and audited updates
- [x] Added team management endpoints for list/detail views and active-status moderation using existing team data
- [x] Added player management endpoints for list/detail views and backend-authoritative player statistics lookup
- [x] Added tournament management endpoints for list/detail views, status changes, and tournament-team decisions
- [x] Added match management endpoints for list/detail views, scorecard/events inspection, status changes, and reasoned scoring corrections
- [x] Added auction monitoring endpoints for auctions, bids, audit history, and suspicious-activity heuristics without auction mutation
- [x] Added notification endpoints for broadcast delivery, per-user delivery inspection, and delivery-status monitoring
- [x] Added reporting endpoints for platform summaries and CSV export
- [x] Added audit endpoints for general admin actions, scoring corrections, and auction audit history
- [x] Added Joi validation for object IDs, booleans, dates, status values, pagination, search text, and correction reasons
- [x] Capped paginated admin queries at 100 records per request
- [x] Kept legacy `GET/PUT /api/v1/users` and related admin-only user routes working by delegating them to audited admin handlers
- [x] Ensured scoring corrections require a reason and delegate to the existing authoritative scoring path instead of silently rewriting historical data

### 3. Flutter Admin UI
- [x] Added admin endpoint helpers to `mobile/lib/core/constants/api_endpoints.dart`
- [x] Added `isBlocked` parsing to auth user entity/model and an `isAdminProvider` derived from authenticated user data
- [x] Added a complete role-gated admin feature under `mobile/lib/features/admin/` with datasource, repository, Riverpod providers, entities, screens, and widgets
- [x] Added admin shell, dashboard, users, teams, players, tournaments, matches, auctions, notifications, reports, and audits screens backed by real admin APIs
- [x] Added role-aware GoRouter admin routes and redirects so unauthenticated users go to login and non-admins cannot open admin pages
- [x] Added an Admin entry to the profile screen for admins and a role-aware Admin tab in bottom navigation
- [x] Preserved existing non-admin user screens and Flutter Riverpod 2.6.1 without adding dependencies

### 4. Phase 13 Tests
- [x] Added backend admin validator, middleware, and audit/redaction unit tests
- [x] Added real-MongoDB admin integration tests covering login denial, dashboard authorization, legacy audited user routes, scoring-correction validation, read-only auction monitoring, and audit redaction
- [x] Added Flutter admin feature tests covering authentication routing, dashboard loading, API failures, audited actions, and admin-only navigation
- [x] Extended auth parsing tests for blocked/admin user flags and admin provider behavior

### 5. Phase 13 Verification
- [x] `npm run lint` passed
- [x] `npm test` passed: 16 suites, 65 tests
- [x] `npm run test:integration` passed: 14 suites, 68 tests (local MongoDB replica set)
- [x] `flutter analyze --no-fatal-infos --no-fatal-warnings` passed with 0 errors; remaining lints/deprecations are non-fatal
- [x] `flutter test` passed: 51 tests, including the real host-backend integration flow on port 5001
- [x] `git diff --check` passed

### 6. Phase 13 Files Changed
- Added:
  - `backend/src/constants/admin.ts`
  - `backend/src/controllers/admin.controller.ts`
  - `backend/src/middlewares/admin.middleware.ts`
  - `backend/src/models/AdminAudit.ts`
  - `backend/src/routes/admin.routes.ts`
  - `backend/src/services/admin.service.ts`
  - `backend/src/services/adminAudit.service.ts`
  - `backend/src/validators/admin.validator.ts`
  - `backend/src/middlewares/__tests__/admin.middleware.test.ts`
  - `backend/src/services/__tests__/adminAudit.service.test.ts`
  - `backend/src/validators/__tests__/admin.validator.test.ts`
  - `backend/tests/integration/admin.integration.test.ts`
  - `mobile/lib/features/admin/`
  - `mobile/test/features/admin/admin_feature_test.dart`
- Modified:
  - `backend/src/middlewares/rateLimiter.middleware.ts`
  - `backend/src/routes/index.ts`
  - `backend/src/routes/user.routes.ts`
  - `backend/tests/integration/setup.ts`
  - `mobile/lib/core/constants/api_endpoints.dart`
  - `mobile/lib/core/routing/app_router.dart`
  - `mobile/lib/core/widgets/bottom_nav_bar.dart`
  - `mobile/lib/features/auth/data/models/user_model.dart`
  - `mobile/lib/features/auth/domain/entities/user.dart`
  - `mobile/lib/features/auth/presentation/providers/auth_provider.dart`
  - `mobile/lib/features/profile/presentation/screens/profile_screen.dart`
  - `docs/PROGRESS.md`

### 7. Remaining Production Risks & Limitations
- [x] Only the existing `ADMIN` role is supported; add role definitions and permission mappings before introducing super-admin or staff roles
- [x] There is no user-report or moderation case model yet, so report handling is limited to existing platform activity and status metadata
- [x] Team moderation can only activate/deactivate teams because no dedicated reported/inappropriate flag exists
- [x] Player profiles are admin-viewable but not mutable beyond data available through existing authoritative player and statistics flows
- [x] Match correction requires a reason and uses the existing authoritative scoring path; unsupported historical edits are rejected instead of silently applied
- [x] Auction monitoring is intentionally read-only and heuristic-based; do not add auction mutation without a separate audit and authorization design
- [x] Socket.IO rooms and published-event de-duplication remain process-local; use a Redis adapter and shared de-duplication before running multiple backend instances
