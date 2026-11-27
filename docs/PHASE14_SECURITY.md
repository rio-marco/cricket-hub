# Phase 14 Security Notes

## Scope (current pass)
- Backend authorization, IDOR, sensitive-data exposure, and API input hardening pass.
- No new product features. No Docker/system installs/production DB access/Git commits.
- Integration tests not run (blocked: no safe local Mongo `mongodb://127.0.0.1:27019/cricket_hub_integration_test`, Docker unavailable).

## Route Inventory Summary
- **Total routes inventoried**: 171 (including `/health`, `/api/v1/health`, all `/api/v1/*` route files).
- **Audited at code level**: 171 route declarations across auth/users/teams/players/tournaments/matches/scoring/auctions/notifications/statistics/leaderboards/admin + app health/uploads/static.
- **Param validation hardening (this pass)**: added explicit ObjectId param schemas for auction/team/player/tournament/match/scoring/user/statistics/leaderboard id routes where missing; team/tournament nested member/invitation/tournament-team params validated. Notification routes already had ObjectId param validation.
- **Not fully runtime-audited**: socket reconnect/concurrency under real multi-client load; integration DB flows; production/staging proxy behavior; anonymous auction read compatibility remains a product/client compatibility risk (intentional auth protection preserved).

## Authorization Matrix
| Method | Route | Auth | Role/Permission | Ownership/Access | Validation | Rate Limit | Classification | Notes |
|---|---|---|---|---|---|---|---|---|
| GET | /health | No | - | - | - | apiLimiter | Public ops | DB readiness 200/503; no secrets |
| GET | /api/v1/health | No | - | - | - | apiLimiter | Public ops | Simple health |
| POST | /api/v1/auth/register | No | - | N/A | Yes | authLimiter | Public | No privileged self-registration; OTP/token hashing; lockout |
| POST | /api/v1/auth/login | No | - | N/A | Yes | otpLimiter | Public | No privileged self-registration; OTP/token hashing; lockout |
| POST | /api/v1/auth/verify-otp | No | - | N/A | Yes | authLimiter | Public | No privileged self-registration; OTP/token hashing; lockout |
| POST | /api/v1/auth/resend-otp | No | - | N/A | Yes | otpLimiter | Public | No privileged self-registration; OTP/token hashing; lockout |
| POST | /api/v1/auth/forgot-password | No | - | N/A | Yes | authLimiter | Public | No privileged self-registration; OTP/token hashing; lockout |
| POST | /api/v1/auth/reset-password | No | - | N/A | Yes | authLimiter | Public | No privileged self-registration; OTP/token hashing; lockout |
| POST | /api/v1/auth/refresh-token | No | - | N/A | Yes | authLimiter | Public | No privileged self-registration; OTP/token hashing; lockout |
| POST | /api/v1/auth/logout | Yes | - | N/A | Partial/none | authLimiter on auth endpoints | Authenticated | No privileged self-registration; OTP/token hashing; lockout |
| GET | /api/v1/auth/me | Yes | - | N/A | Partial/none | authLimiter on auth endpoints | Authenticated | No privileged self-registration; OTP/token hashing; lockout |
| GET | /api/v1/auth/profile | Yes | - | N/A | Partial/none | authLimiter on auth endpoints | Authenticated | No privileged self-registration; OTP/token hashing; lockout |
| PUT | /api/v1/auth/profile | Yes | - | N/A | Yes | authLimiter on auth endpoints | Authenticated | No privileged self-registration; OTP/token hashing; lockout |
| PUT | /api/v1/auth/change-password | Yes | - | N/A | Yes | authLimiter on auth endpoints | Authenticated | No privileged self-registration; OTP/token hashing; lockout |
| PUT | /api/v1/auth/avatar | Yes | - | N/A | Partial/none | authLimiter on auth endpoints | Authenticated | No privileged self-registration; OTP/token hashing; lockout |
| GET | /api/v1/users/dashboard/stats | Yes | ADMIN | Admin-managed; target-level checks in service/controller | Partial/none | adminLimiter | Private/admin | Legacy admin user mgmt; self-block/delete guarded |
| GET | /api/v1/users | Yes | ADMIN | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Legacy admin user mgmt; self-block/delete guarded |
| GET | /api/v1/users/:id | Yes | ADMIN | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Legacy admin user mgmt; self-block/delete guarded |
| PUT | /api/v1/users/:id | Yes | ADMIN | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Legacy admin user mgmt; self-block/delete guarded |
| PUT | /api/v1/users/:id/block | Yes | ADMIN | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Legacy admin user mgmt; self-block/delete guarded |
| DELETE | /api/v1/users/:id | Yes | ADMIN | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Legacy admin user mgmt; self-block/delete guarded |
| POST | /api/v1/teams | Yes | - | N/A | Yes | apiLimiter on list; none on some reads | Authenticated | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| GET | /api/v1/teams | No | - | N/A | Partial/none | apiLimiter | Public | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| GET | /api/v1/teams/user/invitations | Yes | - | Team owner / invited user as applicable | Partial/none | apiLimiter on list; none on some reads | Authenticated | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| PUT | /api/v1/teams/invitations/:invitationId | Yes | - | Team owner / invited user as applicable | Yes | apiLimiter on list; none on some reads | Authenticated | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| GET | /api/v1/teams/:id | No | - | N/A | Partial/none | apiLimiter on list; none on some reads | Public | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| PUT | /api/v1/teams/:id | Yes | - | Team owner / invited user as applicable | Yes | apiLimiter on list; none on some reads | Authenticated | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| DELETE | /api/v1/teams/:id | Yes | - | Team owner / invited user as applicable | Partial/none | apiLimiter on list; none on some reads | Authenticated | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| GET | /api/v1/teams/:id/members | No | - | Team owner / invited user as applicable | Partial/none | apiLimiter on list; none on some reads | Public | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| POST | /api/v1/teams/:id/members | Yes | - | Team owner / invited user as applicable | Yes | apiLimiter on list; none on some reads | Authenticated | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| DELETE | /api/v1/teams/:id/members/:playerId | Yes | - | Team owner / invited user as applicable | Partial/none | apiLimiter on list; none on some reads | Authenticated | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| PUT | /api/v1/teams/:id/members/:memberId/role | Yes | - | Team owner / invited user as applicable | Yes | apiLimiter on list; none on some reads | Authenticated | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| POST | /api/v1/teams/:id/invite | Yes | - | Team owner / invited user as applicable | Yes | apiLimiter on list; none on some reads | Authenticated | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| POST | /api/v1/teams/:id/join | Yes | - | N/A | Partial/none | apiLimiter on list; none on some reads | Authenticated | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| GET | /api/v1/teams/:id/invitations | Yes | - | Team owner / invited user as applicable | Partial/none | apiLimiter on list; none on some reads | Authenticated | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| GET | /api/v1/teams/:id/stats | No | - | N/A | Partial/none | apiLimiter on list; none on some reads | Public | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| GET | /api/v1/teams/:id/matches | No | - | N/A | Partial/none | apiLimiter on list; none on some reads | Public | Public reads expose name/avatar/logo/stats; owner checks on mutations |
| POST | /api/v1/players | Yes | - | N/A | Yes | apiLimiter on list/search | Authenticated | Public reads expose profile/stats; owner checks on mutations |
| GET | /api/v1/players | No | - | N/A | Yes | apiLimiter | Public | Public reads expose profile/stats; owner checks on mutations |
| GET | /api/v1/players/search | No | - | N/A | Yes | apiLimiter | Public | Public reads expose profile/stats; owner checks on mutations |
| GET | /api/v1/players/:id | No | - | N/A | Partial/none | apiLimiter on list/search | Public | Public reads expose profile/stats; owner checks on mutations |
| PUT | /api/v1/players/:id | Yes | - | Player profile owner | Yes | apiLimiter on list/search | Authenticated | Public reads expose profile/stats; owner checks on mutations |
| DELETE | /api/v1/players/:id | Yes | - | Player profile owner | Partial/none | apiLimiter on list/search | Authenticated | Public reads expose profile/stats; owner checks on mutations |
| GET | /api/v1/players/:id/stats | No | - | N/A | Yes | apiLimiter on list/search | Public | Public reads expose profile/stats; owner checks on mutations |
| GET | /api/v1/players/:id/teams | No | - | N/A | Partial/none | apiLimiter on list/search | Public | Public reads expose profile/stats; owner checks on mutations |
| GET | /api/v1/players/:id/matches | No | - | N/A | Partial/none | apiLimiter on list/search | Public | Public reads expose profile/stats; owner checks on mutations |
| GET | /api/v1/tournaments | No | - | N/A | Yes | apiLimiter | Public | Public reads; organizer/admin checks on mutations |
| GET | /api/v1/tournaments/:id | No | - | N/A | Partial/none | apiLimiter on list | Public | Public reads; organizer/admin checks on mutations |
| GET | /api/v1/tournaments/:id/teams | No | - | N/A | Partial/none | apiLimiter on list | Public | Public reads; organizer/admin checks on mutations |
| GET | /api/v1/tournaments/:id/fixtures | No | - | N/A | Partial/none | apiLimiter on list | Public | Public reads; organizer/admin checks on mutations |
| GET | /api/v1/tournaments/:id/standings | No | - | N/A | Partial/none | apiLimiter on list | Public | Public reads; organizer/admin checks on mutations |
| GET | /api/v1/tournaments/:id/stats | No | - | N/A | Partial/none | apiLimiter on list | Public | Public reads; organizer/admin checks on mutations |
| POST | /api/v1/tournaments | Yes | - | Organizer/admin as applicable | Yes | apiLimiter on list | Authenticated | Public reads; organizer/admin checks on mutations |
| PUT | /api/v1/tournaments/:id | Yes | - | Organizer/admin as applicable | Yes | apiLimiter on list | Authenticated | Public reads; organizer/admin checks on mutations |
| DELETE | /api/v1/tournaments/:id | Yes | - | Organizer/admin as applicable | Partial/none | apiLimiter on list | Authenticated | Public reads; organizer/admin checks on mutations |
| PUT | /api/v1/tournaments/:id/status | Yes | - | Organizer/admin as applicable | Yes | apiLimiter on list | Authenticated | Public reads; organizer/admin checks on mutations |
| POST | /api/v1/tournaments/:id/teams | Yes | - | Organizer/admin as applicable | Yes | apiLimiter on list | Authenticated | Public reads; organizer/admin checks on mutations |
| PUT | /api/v1/tournaments/:id/teams/:tournamentTeamId/approve | Yes | - | Organizer/admin as applicable | Partial/none | apiLimiter on list | Authenticated | Public reads; organizer/admin checks on mutations |
| PUT | /api/v1/tournaments/:id/teams/:tournamentTeamId/reject | Yes | - | Organizer/admin as applicable | Partial/none | apiLimiter on list | Authenticated | Public reads; organizer/admin checks on mutations |
| POST | /api/v1/tournaments/:id/fixtures | Yes | - | Organizer/admin as applicable | Partial/none | apiLimiter on list | Authenticated | Public reads; organizer/admin checks on mutations |
| GET | /api/v1/matches | No | - | N/A | Yes | apiLimiter | Public | Public reads; manage checks on mutations |
| GET | /api/v1/matches/live | No | - | N/A | Partial/none | apiLimiter | Public | Public reads; manage checks on mutations |
| GET | /api/v1/matches/upcoming | No | - | N/A | Partial/none | apiLimiter | Public | Public reads; manage checks on mutations |
| GET | /api/v1/matches/completed | No | - | N/A | Partial/none | apiLimiter | Public | Public reads; manage checks on mutations |
| GET | /api/v1/matches/:id | No | - | N/A | Partial/none | apiLimiter | Public | Public reads; manage checks on mutations |
| GET | /api/v1/matches/:id/scorecard | No | - | N/A | Partial/none | apiLimiter | Public | Public reads; manage checks on mutations |
| POST | /api/v1/matches | Yes | - | Organizer/team owner/scorer/admin as applicable | Yes | apiLimiter on reads | Authenticated | Public reads; manage checks on mutations |
| PUT | /api/v1/matches/:id | Yes | - | Organizer/team owner/scorer/admin as applicable | Yes | apiLimiter on reads | Authenticated | Public reads; manage checks on mutations |
| DELETE | /api/v1/matches/:id | Yes | - | Organizer/team owner/scorer/admin as applicable | Partial/none | apiLimiter on reads | Authenticated | Public reads; manage checks on mutations |
| POST | /api/v1/matches/:id/toss | Yes | - | Organizer/team owner/scorer/admin as applicable | Yes | apiLimiter on reads | Authenticated | Public reads; manage checks on mutations |
| POST | /api/v1/matches/:id/playing-xi | Yes | - | Organizer/team owner/scorer/admin as applicable | Yes | apiLimiter on reads | Authenticated | Public reads; manage checks on mutations |
| POST | /api/v1/matches/:id/scorer | Yes | - | Organizer/team owner/scorer/admin as applicable | Yes | apiLimiter on reads | Authenticated | Public reads; manage checks on mutations |
| POST | /api/v1/matches/:id/start | Yes | - | Organizer/team owner/scorer/admin as applicable | Partial/none | apiLimiter on reads | Authenticated | Public reads; manage checks on mutations |
| GET | /api/v1/scoring/:matchId | No | - | N/A | Yes | apiLimiter | Public | Public read state/commentary; manage+version guard on mutations |
| GET | /api/v1/scoring/:matchId/state | No | - | N/A | Yes | apiLimiter | Public | Public read state/commentary; manage+version guard on mutations |
| GET | /api/v1/scoring/:matchId/innings/:inningsNumber | No | - | N/A | Partial/none | apiLimiter | Public | Public read state/commentary; manage+version guard on mutations |
| GET | /api/v1/scoring/:matchId/commentary | No | - | N/A | Yes | apiLimiter | Public | Public read state/commentary; manage+version guard on mutations |
| POST | /api/v1/scoring/:matchId/start-innings | Yes | - | canManageMatch + expectedVersion | Yes | scoringLimiter | Authenticated | Public read state/commentary; manage+version guard on mutations |
| POST | /api/v1/scoring/:matchId/ball | Yes | - | canManageMatch + expectedVersion | Yes | scoringLimiter | Authenticated | Public read state/commentary; manage+version guard on mutations |
| POST | /api/v1/scoring/:matchId/undo | Yes | - | canManageMatch + expectedVersion | Yes | scoringLimiter | Authenticated | Public read state/commentary; manage+version guard on mutations |
| POST | /api/v1/scoring/:matchId/ball/:deliveryId/correct | Yes | - | canManageMatch + expectedVersion | Yes | scoringLimiter | Authenticated | Public read state/commentary; manage+version guard on mutations |
| POST | /api/v1/scoring/:matchId/innings-end | Yes | - | canManageMatch + expectedVersion | Yes | scoringLimiter | Authenticated | Public read state/commentary; manage+version guard on mutations |
| POST | /api/v1/scoring/:matchId/complete | Yes | - | canManageMatch + expectedVersion | Yes | scoringLimiter | Authenticated | Public read state/commentary; manage+version guard on mutations |
| GET | /api/v1/auctions | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| GET | /api/v1/auctions/upcoming | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| GET | /api/v1/auctions/live | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| GET | /api/v1/auctions/completed | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| GET | /api/v1/auctions/:id | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Partial/none | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| GET | /api/v1/auctions/:id/state | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| GET | /api/v1/auctions/:id/players | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| GET | /api/v1/auctions/:id/history | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| GET | /api/v1/auctions/:id/results | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Partial/none | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| GET | /api/v1/auctions/:id/teams/:teamId/purse | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Partial/none | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| POST | /api/v1/auctions | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| PUT | /api/v1/auctions/:id | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| DELETE | /api/v1/auctions/:id | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Partial/none | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| POST | /api/v1/auctions/:id/players | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| DELETE | /api/v1/auctions/:id/players/:auctionPlayerId | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| PATCH | /api/v1/auctions/:id/players/:auctionPlayerId/availability | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| POST | /api/v1/auctions/:id/players/:auctionPlayerId/forward | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| POST | /api/v1/auctions/:id/teams | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| DELETE | /api/v1/auctions/:id/teams/:teamId | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter on some mutations | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| POST | /api/v1/auctions/:id/start | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| POST | /api/v1/auctions/:id/pause | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| POST | /api/v1/auctions/:id/resume | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| POST | /api/v1/auctions/:id/complete | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| POST | /api/v1/auctions/:id/bid | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| POST | /api/v1/auctions/:id/bids/:bidId/decision | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| POST | /api/v1/auctions/:id/sold | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| POST | /api/v1/auctions/:id/unsold | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| POST | /api/v1/auctions/:id/next | Yes | - | Manager for mutations; owner for own purse; auth required for reads | Yes | scoringLimiter | Authenticated (financial fields policy unresolved) | All reads now require auth; purse requires manager/owned team; bidBy removed from responses |
| GET | /api/v1/notifications | Yes | - | Authenticated user owns resource | Yes | none explicit | Authenticated | User-scoped queries; ObjectId validation on id routes |
| GET | /api/v1/notifications/unread-count | Yes | - | Authenticated user owns resource | Partial/none | none explicit | Authenticated | User-scoped queries; ObjectId validation on id routes |
| GET | /api/v1/notifications/preferences | Yes | - | Authenticated user owns resource | Partial/none | none explicit | Authenticated | User-scoped queries; ObjectId validation on id routes |
| PUT | /api/v1/notifications/preferences | Yes | - | Authenticated user owns resource | Yes | none explicit | Authenticated | User-scoped queries; ObjectId validation on id routes |
| GET | /api/v1/notifications/device-tokens | Yes | - | Authenticated user owns resource | Partial/none | none explicit | Authenticated | User-scoped queries; ObjectId validation on id routes |
| POST | /api/v1/notifications/device-token | Yes | - | Authenticated user owns resource | Yes | none explicit | Authenticated | User-scoped queries; ObjectId validation on id routes |
| DELETE | /api/v1/notifications/device-token | Yes | - | Authenticated user owns resource | Yes | none explicit | Authenticated | User-scoped queries; ObjectId validation on id routes |
| POST | /api/v1/notifications/read-all | Yes | - | Authenticated user owns resource | Partial/none | none explicit | Authenticated | User-scoped queries; ObjectId validation on id routes |
| GET | /api/v1/notifications/:id | Yes | - | Authenticated user owns resource | Yes | none explicit | Authenticated | User-scoped queries; ObjectId validation on id routes |
| PATCH | /api/v1/notifications/:id/read | Yes | - | Authenticated user owns resource | Yes | none explicit | Authenticated | User-scoped queries; ObjectId validation on id routes |
| DELETE | /api/v1/notifications/:id | Yes | - | Authenticated user owns resource | Yes | none explicit | Authenticated | User-scoped queries; ObjectId validation on id routes |
| GET | /api/v1/statistics | No | - | N/A | Yes | apiLimiter | Public | Public aggregated stats |
| GET | /api/v1/statistics/top-batsmen | No | - | N/A | Yes | apiLimiter | Public | Public aggregated stats |
| GET | /api/v1/statistics/top-bowlers | No | - | N/A | Yes | apiLimiter | Public | Public aggregated stats |
| GET | /api/v1/statistics/tournament/:id | No | - | N/A | Yes | apiLimiter | Public | Public aggregated stats |
| GET | /api/v1/statistics/players/:id/overall | No | - | N/A | Yes | apiLimiter | Public | Public aggregated stats |
| GET | /api/v1/statistics/players/:id/batting | No | - | N/A | Yes | apiLimiter | Public | Public aggregated stats |
| GET | /api/v1/statistics/players/:id/bowling | No | - | N/A | Yes | apiLimiter | Public | Public aggregated stats |
| GET | /api/v1/statistics/players/:id/fielding | No | - | N/A | Yes | apiLimiter | Public | Public aggregated stats |
| GET | /api/v1/statistics/players/:id/recent | No | - | N/A | Yes | apiLimiter | Public | Public aggregated stats |
| GET | /api/v1/statistics/players/:id/tournaments | No | - | N/A | Yes | apiLimiter | Public | Public aggregated stats |
| GET | /api/v1/statistics/players/:id/seasons | No | - | N/A | Yes | apiLimiter | Public | Public aggregated stats |
| GET | /api/v1/statistics/players/:id/formats | No | - | N/A | Yes | apiLimiter | Public | Public aggregated stats |
| GET | /api/v1/leaderboards | No | - | N/A | Yes | apiLimiter | Public | Public aggregated stats |
| GET | /api/v1/leaderboards/:type | No | - | N/A | Yes | apiLimiter | Public | Public aggregated stats |
| POST | /api/v1/admin/auth/login | Yes | ADMIN (per-route permission) | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/dashboard | Yes | DASHBOARD_READ | Admin-managed; target-level checks in service/controller | Partial/none | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/users | Yes | USERS_MANAGE | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/users/:id | Yes | USERS_MANAGE | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| PATCH | /api/v1/admin/users/:id/status | Yes | USERS_MANAGE | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| PATCH | /api/v1/admin/users/:id/role | Yes | USERS_MANAGE | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/teams | Yes | TEAMS_MANAGE | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/teams/:id | Yes | TEAMS_MANAGE | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| PATCH | /api/v1/admin/teams/:id/status | Yes | TEAMS_MANAGE | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/players | Yes | PLAYERS_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/players/:id | Yes | PLAYERS_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/tournaments | Yes | TOURNAMENTS_MANAGE | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/tournaments/:id | Yes | TOURNAMENTS_MANAGE | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| PATCH | /api/v1/admin/tournaments/:id/status | Yes | TOURNAMENTS_MANAGE | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| PATCH | /api/v1/admin/tournaments/:id/teams/:teamId/decision | Yes | TOURNAMENTS_MANAGE | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/matches | Yes | MATCHES_MANAGE | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/matches/:id/scorecard | Yes | MATCHES_MANAGE | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/matches/:id/events | Yes | SCORING_AUDIT_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/matches/:id | Yes | MATCHES_MANAGE | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| PATCH | /api/v1/admin/matches/:id/status | Yes | MATCHES_MANAGE | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| POST | /api/v1/admin/matches/:id/corrections | Yes | SCORING_AUDIT_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/auctions/suspicious-bids | Yes | AUCTIONS_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/auctions | Yes | AUCTIONS_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/auctions/:id/bids | Yes | AUCTIONS_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/auctions/:id/audit | Yes | AUCTIONS_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/auctions/:id | Yes | AUCTIONS_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| POST | /api/v1/admin/notifications/broadcast | Yes | NOTIFICATIONS_SEND | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| POST | /api/v1/admin/notifications/users | Yes | NOTIFICATIONS_SEND | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/notifications/deliveries | Yes | NOTIFICATIONS_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/reports/export | Yes | REPORTS_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/reports | Yes | REPORTS_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/audits/scoring | Yes | AUDITS_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/audits/results | Yes | AUDITS_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/audits/auction | Yes | AUDITS_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |
| GET | /api/v1/admin/audits | Yes | AUDITS_READ | Admin-managed; target-level checks in service/controller | Yes | adminLimiter | Private/admin | Admin read/write separated by permission constants; single ADMIN role |

Total routes inventoried: 171


## IDOR / Authorization Findings & Fixes
- **Auction reads were public**: `GET /api/v1/auctions*`, state/players/history/results exposed auction/bid/team budget data without auth. **Fix**: added `protect` on all auction read routes; services require authenticated `userId`; controller passes `currentUserId`.
- **Auction team purse IDOR/PII**: `GET /auctions/:id/teams/:teamId/purse` allowed unauth access and populated team owner. **Fix**: route requires `protect`; service requires auth and allows only auction manager or owner of requested team; response populates team `name` only.
- **Auction bid history PII**: bid responses populated `bidBy` user name. **Fix**: removed `bidBy` populate/field from auction state/history responses (`select('-bidBy -__v')`).
- **Team/player/tournament/match public populates leaked email/phone**: multiple services populated `owner/user/scorer/organizer` with `email phone`. **Fix**: removed email/phone from public/non-admin populates; kept name/avatar/role where needed.
- **Admin sanitize incomplete**: `authLockout` not removed by admin sanitize helper. **Fix**: sanitize removes `password, otp, fcmToken, authLockout, __v`.
- **Legacy admin user controller**: selected/sanitized only password/otp. **Fix**: excludes `fcmToken, authLockout, __v`; added self-block/delete guards.
- **Notification ownership**: already scoped by `user` in notification service queries for read/mark/delete/list. Added regression tests.
- **Scoring mutations**: already require `canManageMatch` before idempotency replay and expectedVersion; preserved.
- **Match/tournament management**: existing owner/organizer/scorer/admin checks preserved; no change to product behavior except safer populates.

## Sensitive Data / DTO Findings
- **User model sensitive fields**: `password` select:false, `otp`, `fcmToken`, `authLockout` present. Auth service `sanitizeUser` now uses centralized `backend/src/utils/sanitizeUser.ts` allowlist.
- **Public DTO policy applied**: public/user-facing populates limited to name/avatar/role where needed; no email/phone/fcmToken/authLockout/otp/password/refreshToken.
- **Admin DTOs**: admin user management retains email/phone/role/status/verification as legitimate admin fields; secrets still stripped.
- **Auction financial data**: authenticated users can view auction state/history/results including budgets, bids, sold prices. This is a **product policy decision** (see unresolved). Purse endpoint now restricted to manager/owned team.

## Input / Query / Pagination Hardening
- `sanitizeRequest` strips `$`/dotted keys from body/params/query (Express 5-safe query handling).
- `getPaginationParams` now supports optional `allowedSortFields` whitelist; applied to major list services and admin audit pagination. Invalid sort falls back to default.
- Regex search inputs escaped in audited services (`escapeRegExp`).
- Joi validation present on most mutating and many read routes; `stripUnknown: true` in validate middleware.
- **ObjectId param validation coverage**: added `backend/src/validators/params.validator.ts` and applied explicit `validate(...,'params')` schemas for auction, team, player, tournament, match, scoring, user, statistics, leaderboard routes with `:id`/nested ObjectId params. Notification routes already validated. Remaining routes without ObjectId params are covered by existing query/body schemas or have no path params.

## Upload / File Access
- Avatar upload: `PUT /api/v1/auth/avatar` requires `protect` + multer + extension allowlist + magic-byte signature validation; files stored under `UPLOAD_DIR` with random basename.
- `/uploads` is served as static public files via `express.static`. **Policy**: avatars are intentionally public profile images; existing public profile behavior preserved.
- **Controls**: random filename suffix, extension allowlist, magic-byte validation, basename sanitization. No upload deletion endpoint exists. No private media endpoints exist.
- **Risk**: public avatar files are readable by filename knowledge/guess; acceptable for public avatars but not suitable for private media. Any future private upload must use authenticated access control and non-public storage paths.

## Socket Security
- Socket auth uses JWT verification and user lookup; unverified/blocked users rejected at socket auth layer (existing).
- Match/auction join/sync check access via `matchService.getMatchAccess` / `auctionService.getAuctionAccess`; auction state returned with authenticated user.
- Auction bid socket uses `auctionService.placeBid` which enforces auth/ownership/version/idempotency rules.
- **Risk**: socket event payloads may include data already present in service state; auction state now auth-required but still includes financial fields for any authenticated participant - policy decision. No per-socket rate limit/multi-instance dedupe.

## Admin Authorization
- Single `ADMIN` role with permission constants in `backend/src/constants/admin.ts`; `authorizeAdmin` enforces per-route permission.
- Admin read endpoints generally use `*_READ` or `*_MANAGE` permissions as currently defined. With single ADMIN role this is acceptable; before adding non-admin staff roles, split read/manage permissions consistently.
- Admin login has rate limit + audit logging; sensitive actions audited.

## Regression Tests Added
- `backend/src/services/__tests__/security.authz.test.ts`: unauthenticated auction state read rejected; cross-team purse read rejected; authorized owner purse response excludes owner PII; non-manager/non-owner auction reads redact financial fields.
- `backend/src/services/__tests__/security.dto.test.ts`: `sanitizeUser` strips sensitive fields; `includeContact:false` excludes email/phone.
- `backend/src/services/__tests__/security.notification.test.ts`: notification read scoped by user; delete cannot delete another user's notification.
- `backend/src/validators/__tests__/params.validator.test.ts`: invalid ObjectId params rejected for auction/team/player/match/nested routes.

## Resolved Policy Decisions (Phase 14E continuation)
- **Auction financial visibility**: Implemented field-level shaping in `auction.service.ts`.
  - **Public users**: No access to auction read endpoints (routes require `protect`).
  - **Authenticated non-participants**: Can view auction state/players/history/results structure, but financial fields are redacted (`initialBudget`, `spent`, `pendingCommitment`, `remainingBudget`, `availableBudget`, `maxAffordableBid`, `basePrice`, `currentBid`, `soldPrice`, bid `amount`, `bidCount` -> `undefined` with `financialsRestricted:true` where applicable).
  - **Team members/owners (owned teams)**: Can view their own team purse details via `/auctions/:id/teams/:teamId/purse` and see financials in auction state because they have bid access for owned teams.
  - **Auction administrators/managers** (creator/tournament organizer/admin): Full financial visibility.
  - **Rationale**: preserves management/bidding workflows while preventing broad financial leakage to arbitrary authenticated users.
- **Upload visibility**: Current uploads are avatars only (`PUT /api/v1/auth/avatar`) served from `/uploads` via static middleware. Avatars are treated as **public profile images by design** (existing behavior preserved). No private media or upload deletion endpoint exists. Path safety relies on multer-generated random basenames; static serving remains public. Any future private media must use authenticated download endpoints with ownership checks, not public static paths.

## Unresolved Policy Decisions
- **Admin read/manage split**: current single ADMIN role acceptable; future roles require explicit read vs modify permission mapping.
- **Auction reads auth tightening compatibility**: mobile/web clients must handle 401 for anonymous auction reads; no safe public DTO endpoint added because auction data includes operational/financial context and product decision favors authenticated access.

## Phase 14G Flutter Audit (targeted)
- **Audited**: API client interceptors/logging/retry, auth session/logout/storage, router protected/param validation, realtime provider lifecycle, notification token/tap handling, scoring/auction mutation guards.
- **Fixed**: removed request/response body+header logging from debug LogInterceptor; limited 401 refresh retry to idempotent methods; validated ObjectId route params with safe invalid-link screen; removed router auth listener leak on dispose; guarded duplicate scoring/auction save actions while saving; made push token remote unregister best-effort.
- **Security/privacy**: no token/password/OTP logging added; push payload route validation remains ID/type constrained; client-side checks do not replace backend authz.
- **Remaining**: full file-by-file Flutter security review incomplete; no real-device FCM/account-switch/socket staging proof; pre-existing analyzer infos/warnings remain.

## Phase 14F.3 Regression Coverage (Flutter, targeted)
- Added `mobile/test/realtime_lifecycle_test.dart` (deterministic fake sockets/token providers; no live FCM/DB/network).
- Covered: current token usage, room rejoin on connect, TOKEN_EXPIRED same-token no rebuild, INVALID_TOKEN changed-token rebuild/rejoin, missing-token no connect/reconnect, match stale same-innings rejection, match different-innings newer update acceptance, auction stale stateVersion rejection, auction redacted financial merge preserving known values (not zeroed/erased).
- Added notification tap payload routing tests: valid match/auction/auction-bidding routes; invalid/malformed IDs rejected. Route helper validates 24-char hex IDs and supported types; no authorization bypass (routing only; backend still enforces access).
- Defect fixed: auction redacted merge matched current player by `auctionPlayerId/_id/id`, preventing financial-field loss when redacted payload omitted `auctionPlayerId`.
- Not covered: Riverpod provider disposal/account-switch leak tests with fake realtime clients; real socket.io server reconnect/recovery; multi-device push delivery; backend socket rate-limit behavior.

## Phase 14H/14H.1 Backend DB/Query/Performance Audit (code-level, targeted)
- **Audited**: hot models/indexes and query patterns for notifications/deliveries, matches/innings, scoring deliveries/audit, auctions/bids/players, admin lists/reports, device tokens, player statistics, populate chains. No safe DB for explain/measurement.
- **Fixed (14H)**: `NotificationDeliveryService.processPendingDeliveries` batch-loads notifications/device tokens for batch (`$in` maps), cap 100, removed per-delivery N+1. `match.service` live/completed batch-load innings; upcoming/completed capped at 100.
- **Fixed (14H.1)**: `NotificationService.notifyUsers` bounded batch fan-out (100 recipients/batch): batched preferences/dedupe/token lookups, `insertMany({ordered:false})`, duplicate-key treated as skip, non-duplicate write errors reported as `failed/errors` (not silent success), batch unread-count aggregation, per-user delivery errors captured. Admin reports paginated (`page/limit`, max 500) and export processed in 500-row batches to avoid full in-memory load while preserving completeness.
- **Indexes**: reviewed existing schema indexes; no index added/removed/migrated (no safe DB/explain verification; no speculative indexes).
- **Not verified**: query-plan/explain output, index hit rates, production migration safety, replica-set behavior, large-collection latency, FCM real-device delivery/retry behavior.
- **Remaining risks**: notifyUsers still emits per-created-notification socket events and per-notification delivery creation calls (bounded by batch but can be heavy for very large broadcasts); admin export builds CSV string in memory; player statistics aggregations need explain on representative data; integration tests still blocked.

## Remaining Risks / Manual Verification
- Integration tests blocked (no safe local Mongo on 27019; Docker unavailable).
- No runtime/manual verification of mobile app after auction read auth tightening.
- Socket multi-instance scaling needs Redis adapter/shared dedupe/rate limiting.
- `/uploads` static files are publicly readable by filename guess; random names reduce but do not eliminate exposure.
- DB performance claims are code-level only; no explain/benchmark/staging verification.
