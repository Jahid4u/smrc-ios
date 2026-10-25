# SM Royal Circle — Flutter App

Native Flutter port of the 58-screen HTML simulator, using Riverpod + go_router + Dio,
wired to the WordPress REST API at `https://smr.apifeldigi.com/wp-json/smrc/v1/`.

## Status: Batch 1 of N

### ✅ Built (real, pixel-close screens)
- Splash
- Welcome
- Sign In
- Invitation Code
- Home Shell (5-tab bottom nav: Explore / Events / Society / Benefits / Cheer)
- Explore / Home
- Events Listing
- SM Society Hub
- Benefits
- Account / Member

### 🚧 Placeholder (routes work, real UI comes in next batches)
All other screens from the 58-screen catalog — see
`lib/core/router/screen_catalog.dart` for the full ordered list with titles.
Every route already navigates correctly today; placeholders just show the
screen title until they're replaced with pixel-matched implementations.

## Structure
```
lib/
  core/
    theme/        # AppColors, AppTextStyles, AppTheme — matches the HTML :root vars
    network/      # ApiClient (Dio) wired to smrc/v1
    router/       # GoRouter + full screen catalog
  models/         # Member, ClubEvent, MemberTier
  providers/      # Riverpod providers (session, events)
  screens/        # One folder per feature area
  widgets/        # Shared: TierBadge, RingAvatar, AppTopNav, AppBottomNav, PlaceholderScreen
```

## Design tokens (from the HTML simulator)
- Colors: `#0A0A0B` ink, `#C8A24A` gold, `#F1EDE4` paper — see `AppColors`.
- Type: Cormorant Garamond (serif/hero) + Inter (everything else), via `google_fonts`.
- Tiers: Silver / Gold / Black Diamond + Brand Ambassador / Admin roles — one shared
  palette, identity shown via ring/badge colour only (`MemberTier` + `TierBadge`/`RingAvatar`).

## Run it
```
flutter pub get
flutter run
```
Set your real OneSignal App ID in `lib/main.dart` before shipping.

## Production vs Staging backend

The backend URL is chosen at **build time**, not by editing code:

- No flag → production (`app.smroyalcircle.club`). This is the safe default:
  a normal `flutter build` always ships production correctly even if a flag
  is forgotten.
- Staging (`smr.apifeldigi.com`) — pass it explicitly:
  ```
  flutter run --dart-define=API_BASE_URL=https://smr.apifeldigi.com/wp-json/smrc/v1/
  flutter build apk --dart-define=API_BASE_URL=https://smr.apifeldigi.com/wp-json/smrc/v1/
  ```
- **VS Code**: open the Run and Debug panel, pick **"SM Royal Circle (Staging)"**
  from the dropdown (next to "SM Royal Circle (Production)") — see
  `.vscode/launch.json`. No command line needed.

Staging and production are separate WordPress installs with separate
databases — data entered on one never appears on the other, and each needs
its own Stripe test/live keys configured under Settings → Payments in its
own admin panel.

## Next batches
Reply with which screens to prioritize (e.g. "onboarding flow next" or
"events buy/RSVP flow next") and I'll build those out to full fidelity,
continuing straight down `screen_catalog.dart` if no preference is given.
