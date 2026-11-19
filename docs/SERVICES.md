# Connecting the backend services

The app talks to seven Spring Boot services. This page says which screen uses which service, how each call is made and signed, and what to check when one of them does not answer.

<img src="assets/divider.svg" alt="" width="100%"/>

<img src="assets/services.svg" alt="The Flutter app on the left and the seven Premisave services on the right with their ports and the setting that holds each address." width="100%"/>

| Service | Repository | Port | App setting | Who it trusts | Used by |
| --- | --- | :---: | --- | --- | --- |
| [auth-service](https://github.com/peacemakerbill/premisave_auth_service) | `premisave_auth_service` | 8080 | `BASE_URL` | Issues the token | Sign in, profile, security, administration, places |
| [messenger](https://github.com/peacemakerbill/premisave-messenger-service) | `premisave-messenger-service` | 8081 | `MESSENGER_URL` | The auth token | Chats, calls, storage settings |
| [listing-service](https://github.com/peacemakerbill/premisave-listing-service) | `premisave-listing-service` | 8082 | `LISTING_URL` | The auth token | Explore, bookings, listings, moderation |
| [wallet-service](https://github.com/peacemakerbill/premisave-wallet-service) | `premisave-wallet-service` | 8084 | `WALLET_URL` | The auth token | Wallet, finance |
| [property-service](https://github.com/peacemakerbill/premisave-property-management-service) | `premisave-property-management-service` | 8085 | `PROPERTY_URL` | The auth token | Property management, my tenancy |
| [c2b-hakikisha](https://github.com/peacemakerbill/premisave-c2b-hakikisha-service-m-pesa) | `premisave-c2b-hakikisha-service-m-pesa` | 8090 | `C2B_URL` | The auth token, trading it for its own session | M-Pesa name lookup (staff) |
| [developer-service](https://github.com/peacemakerbill/premisave-developer-service) | `premisave-developer-service` | 8091 | `DEVELOPER_URL` | Its own login | Developer portal |

Start the services you need, run the app, and every address already points at `localhost` with the port above. On the Android emulator the host is `10.0.2.2` instead, and the app chooses it for you.

## How a call is made

There are two kinds of client, and a repository picks one.

**`ApiClient`** is for the services that trust the auth-service token (messenger, listing, wallet and property). A second `ApiClient` is created with a different base URL and **shares the same token store**, so one sign in covers all of them. It leaves out the `X-Client-Platform` and `X-Device-Token` headers, which only the auth-service understands. When a request gets a 401, the client asks the auth-service client to refresh, because the refresh token belongs to the auth-service, and then sends the request again.

**`ServiceClient`** is for the two services that do not accept that token. It is small on purpose: it sends `Accept` and, when it has one, `Authorization`, and it turns every failure into an `ApiException` with a readable message. It never refreshes anything.

```dart
// lib/src/state/providers.dart, one shared helper builds the secondary clients
final walletApiClientProvider = Provider<ApiClient>((ref) => _sharedSessionClient(ref, AppConfig.walletUrl));
final listingApiClientProvider = Provider<ApiClient>((ref) => _sharedSessionClient(ref, AppConfig.listingUrl));
final propertyApiClientProvider = Provider<ApiClient>((ref) => _sharedSessionClient(ref, AppConfig.propertyUrl));
```

### Two shapes of answer

The services do not all answer the same way, and the repositories hide it.

| Service | Shape | Helper |
| --- | --- | --- |
| Wallet, developer, C2B `/internal/accounts` | `{ "success": true, "message": "...", "data": ..., "timestamp": "..." }` | `unwrap`, `unwrapMap`, `unwrapList` in `data/repositories/envelope.dart` |
| Auth, listing, property, C2B lookup and token | The body itself. Bookings and interests come as a Spring `Page`, whose rows are in `content` | `asMap`, `mapList`, `pageContent` |

C2B reports an error as `{ "errorMessage": "..." }`, so `ApiException` reads that as well as `message`.

## Menus at a glance

Every part of the app that reads or writes a service has its own menu, a row of tabs under the title, so a feature is one tap away. A list shows its rows, a row opens its details, and the actions on a row (edit, delete and the rest) are buttons in that sheet. Lists refresh after every change.

| Route | Menu | Tabs | Who sees it |
| --- | --- | --- | --- |
| `/wallet` | Wallet | Overview, Money, History, Statement, Linked accounts, Requests, Merchant, Settings | clients, home owners |
| `/bookings` | Bookings | My bookings, Saved, Short stays, Rates | clients |
| `/listings` | Listings | My listings, Bookings, Leads, Promotions, Rates | home owners |
| `/property` | Property management | Overview, Properties, Leases, Tenants, Maintenance, Work orders, Inspections, Notices, Reports, Blacklist, Profile | home owners |
| `/tenancy` | My tenancy | Rent, Leases, Bills, Maintenance, Notices, Where I lived, Profile | clients |
| `/finance` | Finance | Overview, Wallets, Transactions, Deposits, Withdrawals, Payments, Transfers, Ledger, Adjustments, To resolve, M-Pesa, Gateways, Rates, Reports | administrators, finance, operations |
| `/moderation` | Moderation | To review, Live, Rejected, Archived, Deleted, Bookings, Rates | administrators, operations, finance |
| `/lookup` | M-Pesa name lookup | One screen, connects by itself | operations, finance, support, administrators |
| `/developers` | Developer portal | Overview, Apps, Businesses, Transfers, Profile, Admin | anyone, with a developer account |
| `/more` | More | Every other menu, for the roles that have too many for the bar | everyone |

The old routes under `/home` (`/home/payments`, `/home/properties` and the rest) still work and redirect to these.

## Wallet

Open `/wallet`. A person with no wallet sees **Open my wallet**, which calls `POST /wallet/create`. Amounts go through `parseAmount`, and money is shown by `formatMoney`.

| Tab | What it does | Calls |
| --- | --- | --- |
| Overview | Balance, deposit, send, withdraw, payment methods, latest activity. Deposit, Send and Withdraw each open a centred chooser that lists every gateway (M-Pesa, M-Pesa till, Pochi, card, PayPal, Flutterwave, crypto, bank and wallet to wallet) and continue into the matching form | `GET /wallet`, `POST /wallet/deposit`, `POST /wallet/transfer`, `POST /disbursements` |
| Money | Deposit by M-Pesa, M-Pesa till, card, PayPal, Flutterwave and crypto. Send to a wallet. Withdraw to M-Pesa, Pochi, PayPal, bank, Flutterwave and crypto. Confirm a payment made on a provider page | `POST /wallet/deposit`, `POST /wallet/transfer`, `POST /disbursements`, `POST /disbursements/b2pochi`, `POST /disbursements/nowpayments/{id}/verify`, `POST /wallet/deposit/stripe/confirm`, `.../paypal/confirm`, `.../flutterwave/confirm` |
| History | All activity, deposits, withdrawals, transfers and payments, with status and date filters | `GET /transactions/history`, `/deposits/history`, `/disbursements/history`, `/wallet/transfer/history`, `/payments/history` |
| Statement | Money in and out for a period | `POST /wallet/statement` |
| Linked accounts | Saved cards (list, default, remove, confirm), PayPal (link, confirm, disconnect), Flutterwave (link, confirm, unlink), bank through Stripe Connect (link, refresh, unlink) | `GET` and `DELETE /wallet/stripe/cards`, `PUT /wallet/stripe/cards/{id}/default`, `POST /wallet/stripe/setup-intent`, `POST /wallet/stripe/setup-intent/confirm`, `/wallet/paypal/*`, `/wallet/flutterwave/*`, `/wallet/stripe/connect/*` |
| Requests | Payment requests from businesses: approve, decline, revoke. The wallet service serves these only with `COMMERCIAL_PREMISAVE_ENABLED=true`; with it off the endpoint answers 404 and the tab shows an empty list | `GET /wallet/consents`, `POST /wallet/consents/{id}/approve`, `/decline`, `/revoke` |
| Merchant | Applications to accept payments and merchant numbers | `GET /wallet/merchant-applications`, `GET /wallet/merchant-numbers` |
| Settings | Freeze and unfreeze, the M-Pesa number, the Pochi number, the PayPal email | `GET /wallet/balance`, `PUT /wallet/freeze`, `/unfreeze`, `/mpesa-phone`, `/pochi-phone`, `/paypal-email` |

Every withdrawal and transfer carries a `reference` made when the form opens, so a retry after a dropped connection never moves the money twice. A provider that needs a payment on its own page (PayPal, Flutterwave) answers with a link, and the app opens it. Keep the reference shown and use **After you have paid** to confirm. Saving a new card needs the card form of Stripe, which the app does not include, so a card can be listed, made the default and removed, and a card saved elsewhere is confirmed with its setup id.

### Finance

Open `/finance`. Administrators, finance and operations see it.

| Tab | What it does | Calls |
| --- | --- | --- |
| Overview | Revenue, held money, latest deposits | `GET /admin/finance/reports/*`, `GET /admin/finance/deposits` |
| Wallets | Search and open any wallet. Credit, debit, freeze, unfreeze, and see its transactions, adjustments and ledger | `GET /admin/wallet/wallets`, `/search`, `/{userId}`, `POST .../credit`, `.../debit`, `PUT .../freeze`, `.../unfreeze` |
| Transactions, Adjustments | Every transaction and manual adjustment, with filters | `GET /admin/wallet/transactions`, `/transactions/{id}`, `/adjustments` |
| Deposits, Withdrawals, Payments, Transfers, Ledger | Company wide lists with filters | `GET /admin/finance/deposits`, `/disbursements`, `/payments`, `/transfers`, `/ledger` |
| To resolve | Everything pending, oldest first. Approve or reject deposits and withdrawals | `GET /admin/reconciliation/pending`, `POST .../deposits/{id}/approve`, `/reject`, `.../disbursements/{id}/approve`, `/reject` |
| M-Pesa | Operations run from the company account: balance, status query, reversal (approve, reject, close), pull transactions, Pochi and business payouts, organisation lookup, register C2B links, simulate a C2B payment | `GET /admin/reconciliation/mpesa-operations`, `/admin/wallet/mpesa/*`, `/admin/wallet/b2b/*`, `/payments/mpesa/c2b/*` |
| Gateways | What the company holds with each provider, live and saved, with history | `GET /admin/gateway-balances`, `/{provider}`, `/saved`, `/saved/{provider}` |
| Rates | Exchange rates, and a button to fetch the latest | `GET /admin/exchange-rates`, `POST /admin/exchange-rates/fetch` |
| Reports | Summary, finance summary, balances, one day | `GET /admin/wallet/reports/*`, `GET /admin/finance/reports/*` |

## Listings and bookings

| Menu | Tab | What it does | Calls |
| --- | --- | --- | --- |
| Explore (`/explore`) | Search | Search, filters, a detail page with availability, booking and interest | `GET /listings/search`, `/listings/{id}`, `/listings/{id}/availability`, `POST /bookings`, `POST /interests` |
| Listings | My listings | Status chips, create, edit, photos (add, remove, cover, order), calendar (block and unblock dates), promote, extend, archive, restore, delete | `GET /listings/me`, `POST /listings`, `PUT /listings/{id}`, `DELETE /listings/{id}`, `POST /listings/{id}/images`, `DELETE .../images/{fileId}`, `PUT .../images/cover`, `.../images/order`, `POST .../blocked-dates`, `DELETE .../blocked-dates/{id}`, `POST /listings/promote`, `/listings/{id}/extend`, `/archive`, `/unarchive` |
| Listings | Bookings, Leads | Bookings and interests an owner received | `GET /bookings/received`, `GET /interests/received` |
| Listings | Promotions | The owner's promotions | `GET /listings/promotions/my` |
| Bookings | My bookings | Bookings with a cancellation quote before cancelling | `GET /bookings/me`, `/bookings/{id}/cancellation-quote`, `POST /bookings/{id}/cancel` |
| Bookings | Saved | Interest shown in a listing, and removal | `GET /interests/me`, `DELETE /interests/{id}` |
| Bookings, Listings | Short stays | Short stay listings, nearby, in a city, in a map area | `GET /listings/short-term`, `/locations/nearby`, `/locations/city`, `/locations/bounds`, `GET /listings/owner/{ownerId}` |
| Bookings, Listings, Moderation | Rates | Currency rates, one rate, a converter, the supported currencies | `GET /currency/rates`, `/currency/rate`, `/currency/convert`, `/currency/supported` |
| Moderation | To review, Live, Rejected, Archived, Deleted | Every listing by status. Approve, reject with a reason, archive, restore, delete and delete for good | `GET /admin/listings`, `/admin/listings/{id}`, `PUT .../approve`, `/reject`, `/archive`, `/unarchive`, `/restore`, `DELETE .../admin/listings/{id}`, `.../hard-delete` |
| Moderation | Bookings | Bookings that need review. Retry a payout, resolve a payment | `GET /admin/bookings/needs-review`, `POST /admin/bookings/{id}/retry-payout`, `/resolve-payment` |

Creating a listing is a form (`listing_form.dart`) that asks for the category first and then only the fields that category needs. `ListingRepository.createListing` sends a multipart request with a `request` part that holds the details as JSON (content type `application/json`, which Spring needs for `@RequestPart`) and one `files` part per photo. Editing opens the same form filled from the listing and sends `PUT /listings/{id}` as multipart. The service accepts 20 photos, 10 MB each and 40 MB in all, so the form checks that before sending. A new or edited listing waits for review.

Booking sends an `Idempotency-Key` header (`newIdempotencyKey()` in `core/utils/ids.dart`). The key belongs to one listing and one set of dates, so a retry after a timeout or a second tap sends the same key and the service returns the first booking instead of making another.

The calendar can block dates and unblock a block by its code. The service only returns a block's code when it is created, so a block made in an earlier session is unblocked from the web console.

## Property management

Open `/property` as a home owner. A person with no owner profile is offered a one tap profile first (`POST /api/v1/owners/quick`).

| Tab | What it does | Calls |
| --- | --- | --- |
| Overview | Totals, revenue, occupancy by property | `GET /api/v1/dashboard/owner` |
| Properties | Create, edit, delete, open the units, see who lives there | `GET /api/v1/properties/me`, `POST /api/v1/properties`, `GET`, `PATCH` and `DELETE /api/v1/properties/{id}`, `GET /api/v1/occupancy/property/{id}` |
| Units (inside a property) | Create, edit, delete. A unit opens Details, Occupancy (move in and out), Rent, Meters, Bills, Maintenance and Inspections | `GET /api/v1/units/property/{id}`, `POST`, `PATCH` and `DELETE /api/v1/units/{id}`, `/occupancy/*`, `/rent/units/*`, `/security-deposits/*`, `/meter-readings/*`, `/utility-bills/*` |
| Leases | Create, edit, terminate, rent schedule, rent history, rent due, balance, security deposit (hold, check, refund), notices, move in, move out | `GET /api/v1/leases/owner`, `POST /api/v1/leases`, `PATCH .../{id}`, `POST .../{id}/terminate`, `/rent-schedules/lease/{id}`, `/rent/*`, `/security-deposits/lease/{id}`, `/notices/lease`, `/occupancy/move-in/lease`, `/move-out/lease` |
| Tenants | The people on your leases, find by id, register, their leases, balance, bills, notices, history, blacklist | `GET /api/v1/tenants/{id}`, `POST /api/v1/tenants/register`, `/leases/tenant/{id}`, `/rent/balance/tenant/{id}`, `/utility-bills/tenant/{id}`, `/notices/tenant/{id}`, `/occupancy/tenant/{id}` |
| Maintenance | By status. Log, start, complete, cancel, assign a work order | `GET /api/v1/maintenance`, `/maintenance/{id}`, `POST /api/v1/maintenance`, `PATCH .../{id}/status`, `/work-orders` |
| Work orders | By status. Start, complete, cancel | `GET /api/v1/work-orders`, `PATCH .../{id}/status` |
| Inspections | By status. Schedule, complete with findings, cancel | `GET /api/v1/inspections/me`, `/inspections/unit/{id}`, `POST /api/v1/inspections`, `.../{id}/complete`, `.../{id}/cancel` |
| Notices | Notices to many tenants at once, now or at a set time, and cancel | `POST /api/v1/notices/bulk`, `GET /notices/bulk/mine`, `GET /notices/bulk/{id}`, `POST .../cancel` |
| Reports | Occupancy and revenue for a period | `GET /api/v1/reports/owner/occupancy`, `/reports/owner/revenue` |
| Blacklist | See, add, remove | `GET`, `POST` and `DELETE /api/v1/blacklisted-tenants` |
| Profile | Edit the owner profile and bank details, sync, sync status, service health | `GET /api/v1/owners/me`, `PATCH /api/v1/owners/{id}`, `POST /api/v1/owners/me/sync`, `GET /system/dependencies` |

### My tenancy

Open `/tenancy` as a client. A person with no tenant profile is offered a one tap profile first.

| Tab | What it does | Calls |
| --- | --- | --- |
| Rent | Rent owed across every home, with a button to pay from the wallet | `GET /api/v1/rent/balance/me`, `POST /api/v1/rent/pay`, `POST /api/v1/rent/units/pay` |
| Leases | Each lease: pay rent, rent due, schedule, payments, balance, security deposit, notices | `GET /api/v1/leases/tenant/{id}`, `/rent/due/{id}`, `/rent-schedules/lease/{id}`, `/rent/history/{id}`, `/rent/balance/lease/{id}`, `/security-deposits/lease/{id}`, `/notices/lease/{id}` |
| Bills | Unpaid and all utility bills, pay a bill | `GET /api/v1/utility-bills/tenant/{id}`, `/outstanding`, `POST /api/v1/utility-bills/pay` |
| Maintenance | Requests and a form to raise one | `GET /api/v1/maintenance/tenant/{id}`, `POST /api/v1/maintenance` |
| Notices | Notices from the landlord | `GET /api/v1/notices/tenant/{id}` |
| Where I lived | Move in and move out history | `GET /api/v1/occupancy/tenant/{id}` |
| Profile | Edit, sync, sync status | `GET` and `PATCH /api/v1/tenants/me`, `POST /api/v1/tenants/me/sync`, `GET .../sync-status` |

Paying rent is a wallet to wallet transfer made by the property service, so a failed payment usually means the wallet or the auth-service is down, and the message says so. Rent and bill payments carry a `reference` so a retry is safe.

## Developer portal

Open `/developers`. It is linked from the first page and from the sign in page (the **Developers** switch above the form). A developer is not a Premisave user. The token is kept in secure storage under `ps_developer_token`, apart from the person sign in, and there is no refresh: when it expires the portal asks for the password again.

| Area | What it does | Calls |
| --- | --- | --- |
| Sign in and sign up | Email and password, social sign in (Google, Facebook, GitHub, as many as the service has switched on), forgot password, resend the confirmation email | `POST /api/v1/auth/login`, `/signup`, `/forgot-password`, `/resend-verification`, `/social/{provider}`, `GET /api/v1/auth/social/providers` |
| Email links | The link in the confirmation email opens `/developers/verify-email?token=`, the reset link opens `/developers/reset-password?token=` and the link that joins Facebook to an existing account opens `/developers/link-provider?token=` | `POST /api/v1/auth/verify-email`, `/reset-password`, `/social/link/confirm` |
| Sign in methods | Profile, Sign in methods: connect or disconnect Google, Facebook and GitHub for the signed in developer | `GET /api/v1/me/connections`, `POST` and `DELETE /api/v1/me/connections/{provider}` |
| Overview | Counts and quick actions | `GET /api/v1/me`, `/apps`, `/businesses` |
| Apps | Filter by environment. Create a **sandbox** app with no business, or a live app for a business. Edit, suspend, reactivate, transfer. API keys: create, rotate, revoke. The secret is shown once | `GET`, `POST` and `PUT /api/v1/apps`, `/apps/{id}/suspend`, `/reactivate`, `/apps/{id}/keys`, `.../rotate`, `DELETE .../keys/{key}` |
| Businesses | Add a business. Application form, directors, documents (upload, view, remove), submit, answer returned items, timeline | `GET` and `POST /api/v1/businesses`, `/businesses/{id}/application/**` |
| Transfers | Move an app to another developer, enter the code, resend, cancel, claim a business | `POST /api/v1/apps/{id}/transfer`, `GET /api/v1/transfers`, `POST .../confirm`, `/resend`, `/cancel` |
| Profile | Edit, username check, change password, picture, resend confirmation, test merchant numbers, sign out everywhere | `GET` and `PUT /api/v1/me`, `PUT /api/v1/me/picture`, `POST /api/v1/me/logout-all`, `GET /api/v1/test-merchants` |
| Admin | For developers with the ADMIN role: statistics, developers (create, edit, email, role, status, unlock, sign out, password reset, apps, businesses, share), administrators, all apps (edit, status, owner, keys), transfers, audit | `GET` and `POST /api/v1/admin/*` |

A key and its secret are shown **once**, with a copy button, because the service only keeps a hash.

Sandbox apps need no business. The developer service gives each developer a personal sandbox workspace the first time they create one, so a new developer can get test keys at once. Live apps still need an approved business.

## M-Pesa name lookup

| Screen | What it does | Calls |
| --- | --- | --- |
| M-Pesa name lookup (`name_lookup_screen.dart`) | Staff check which name belongs to an M-Pesa number, and browse the accounts the service holds | `GET /console/v1/session`, `POST /api/v1/c2b/hakikisha/name-lookup`, `GET /internal/accounts` |

The screen connects by itself. It sends the staff member's Premisave token to `GET /console/v1/session`, and the C2B service answers with its shortcode and a short lived access token. The service reads its own credentials from its `application.yml` (`HAKIKISHA_*` in `.env`), so the app never sees or stores them. The service must share the auth-service's `JWT_SECRET`. If the automatic connection fails, the screen shows why and falls back to the manual form (`POST /oauth2/v1/generate`), where the credentials can be remembered on the device if the person chooses. Who sees it: operations, finance, support and administrators (the `lookupAccounts` capability).

## Role dashboards

Each role's overview (`features/overview/`) reads its parts from separate providers (`state/overview_providers.dart` and `state/service_providers.dart`), so a part shows a skeleton while it loads and an error with a retry when its service is down, and the rest of the page still works. Pull down refreshes every part.

| Role | What the overview shows | Calls |
| --- | --- | --- |
| Client | Upcoming stays, saved places, total spent (from confirmed and completed bookings, in the currency paid), featured listings | `GET /bookings/me`, `GET /interests/me`, `GET /listings/search`, `GET /listings/{id}` |
| Home owner | Monthly rent, occupancy per property, maintenance requests, leases ending soon, the owner's listings and their review status. A person with no owner profile is offered a one tap profile | `GET /api/v1/owners/me/exists`, `GET /api/v1/dashboard/owner`, `GET /api/v1/leases/owner`, `GET /listings/me` |
| Operations | Live listings, newest listings and a count by category, today's deposits, withdrawals, transfers and payments, failed and waiting payments, payments per day for a week | `GET /listings/search`, `GET /admin/finance/reports/daily` (seven days) |
| Finance | Revenue today and for the week, money held for users (wallets plus escrow), largest wallets, latest deposits, frozen wallets, bookings that need review | `GET /admin/finance/reports/daily`, `/reports/balance-overview`, `GET /admin/finance/deposits`, `GET /admin/bookings/needs-review` |
| Support | Applications awaiting review, waiting on the applicant, unassigned, average decision time, the ones waiting longest and a count by status | `GET /staff/applications/stats`, `GET /staff/applications` |
| Administrator | People, applications, the 24 hour security summary, recent audit events and storage settings | auth-service and messenger admin endpoints |

The wallet's `/admin/finance` routes are open to administrators, finance and operations. The listing service's `/admin/bookings` routes are open to administrators and finance. A role that is refused a part sees that part's error and nothing else changes.

## Roles and screens

The Home screen builds its list from capabilities, so a person only sees what their role allows. The router refuses the same pages by capability, so typing a path does not get around it.

| Capability | Granted to | Opens |
| --- | --- | --- |
| `useClientWorkspace` | client | Bookings, Messages, My tenancy |
| `manageProperties` | home owner | Property management, Listings |
| `useWallet` | client, home owner | Wallet |
| `administerWallet` | administrator, finance, operations | Finance |
| `administerListings` | administrator, operations, finance | Moderation |
| `lookupAccounts` | operations, finance, support, administrator | M-Pesa name lookup |
| (none) | everyone, signed in or not | Developer portal |

Routes are guarded in `lib/src/router/guards.dart`. `/developers` and `/verify-email` are open to everyone because the developer portal has its own accounts. See [ROLES_AND_ACCESS.md](ROLES_AND_ACCESS.md) to change who gets what.

## Running it

Start the services you want, then the app. Nothing needs configuring when everything runs on this computer.

```bash
# the app on the port the backends already allow for browsers
flutter run -d chrome --web-port=3000 --dart-define-from-file=config/env/dev.local.json

# point one service somewhere else (empty means the default above)
#   config/env/dev.local.json
#   { "WALLET_URL": "http://192.168.1.20:8084", "LISTING_URL": "http://192.168.1.20:8082" }
```

Restart the app after changing a setting. Flutter reads them only at launch.

### Browser rules (CORS)

A phone or desktop app is not stopped by CORS. A browser is, so for the web build the service must allow the origin the app is served from (`http://localhost:3000` in development).

| Service | Setting | Default |
| --- | --- | --- |
| auth-service, messenger | none, any origin is allowed | `*` |
| listing-service | `CORS_ALLOWED_ORIGINS` | `http://localhost:3000` |
| wallet-service | `FRONTEND_URL` | `http://localhost:3000` |
| property-service | `CORS_ALLOWED_ORIGINS` | `http://localhost:3000`, `:4200`, `:5173` |
| c2b-hakikisha | `CORS_ALLOWED_ORIGINS` | `*` |
| developer-service | `DEVELOPER_PORTAL_ORIGINS` | empty, **set it** to `http://localhost:3000` for the web build |

### Links in emails

| Service | Setting | Set it to |
| --- | --- | --- |
| auth-service | `FRONTEND_URL` | where the app is served, for example `http://localhost:3000`. Links become `/verify/<token>` and `/reset-password?token=` |
| developer-service | `DEVELOPER_PORTAL_URL` | the app address plus `/developers`, for example `http://localhost:3000/developers`. Links become `/developers/verify-email?token=`, `/developers/reset-password?token=` and `/developers/link-provider?token=` |

A production host must serve `index.html` for every path that is not a file, or opening a link from an email shows "page not found". The app uses clean paths (no `#`).

The messenger, listing, wallet and property services check the token the auth-service signs, so each needs the same `JWT_SECRET` as the auth-service. The developer and C2B services keep their own secrets.

## When something does not work

| You see | Likely cause | Do this |
| --- | --- | --- |
| "Could not reach the server" on one screen only | That service is not running, or its setting points elsewhere | Start it, or fix the `*_URL` setting and restart the app |
| It works on Android, not in Chrome | The browser blocked the call | Allow `http://localhost:3000` in that service (table above) |
| 401 right after a good sign in | The service uses another `JWT_SECRET` | Use the auth-service value in that service's `.env` |
| A deposit or payment stays pending | The provider has not called back yet | Wait, then refresh the activity. The service matches the callback by reference |
| The developer portal asks for a password again | The developer token expired | Sign in again. It has no refresh |
| M-Pesa lookup falls back to a form | The C2B service cannot verify the Premisave token | Give it the same `JWT_SECRET` as the auth-service, and check `HAKIKISHA_*` in its `.env` |
| The email link says page not found | `FRONTEND_URL` or `DEVELOPER_PORTAL_URL` points at the wrong place, or the host has no fallback to `index.html` | See "Links in emails" above |
| A developer cannot create a sandbox app | An old developer service build that still asks for a business | Update the developer service, sandbox apps need no business |

## Adding a service

1. Add `_envXUrl` and a `xUrl` getter to `AppConfig`, and the empty key to the three JSON files in `config/env`.
2. Add models in `data/models`, a repository in `data/repositories` and a provider in `state/providers.dart`. Use `_sharedSessionClient` when the service trusts the auth token, `ServiceClient` when it does not.
3. Add `FutureProvider`s in `state/service_providers.dart`, the screen under `features/`, and a route in `app_router.dart`.
4. Add a capability if only some roles should see it, then list the route in `guards.dart`.

Redraw the map above after adding a row to `SERVICES` in [`tool/service_pictures.py`](../tool/service_pictures.py).
