# SM Royal Circle — build notes

## Run it

```
flutter clean
flutter pub get
flutter run
```

That's it. **Do not run `flutter create .`** (see below).

## Never run `flutter create .`

It regenerates the whole Android folder from Flutter's default template and
destroys the branded native splash. Specifically it:

- drops a default `android/app/src/main/res/drawable-v21/launch_background.xml`,
  which **overrides** our `drawable/launch_background.xml` on every device
  running API 21+ (i.e. all of them) — the splash silently reverts to a blank
  screen
- resets `styles.xml`, `AndroidManifest.xml` and `MainActivity.kt`
- resets the `applicationId` back to `com.example.sm_royal_circle`

The `android/` folder is committed in full precisely so this command is never
needed. If the iOS folder is ever missing, generate **only** that:

```
flutter create --platforms=ios .
```

If `drawable-v21/` ever reappears, delete that folder — nothing in this
project should have one.

## The `:jni` build failure

```
A problem occurred evaluating project ':jni'.
> Could not find method kotlin() ... on project ':jni'
```

`package:jni` (pulled in transitively) uses the Kotlin DSL in its own
`android/build.gradle`, so a modern Kotlin Gradle plugin has to be resolvable
from the root build. Flutter's older pinned default (1.8.x) doesn't provide
one. Fixed in `android/settings.gradle.kts`:

```kotlin
id("org.jetbrains.kotlin.android") version "2.1.0" apply false
```

`android/build.gradle.kts` additionally pins every subproject to Java 17, so a
plugin built against a different JVM target can't fail the build.

## Things that are deliberate, don't "fix" them

- **`minSdk = 23`** — the native splash positions the brand mark using
  `android:width/height/gravity` on plain layer-list `<item>` elements, which
  only works from API 23. Lowering it breaks the splash layout silently.
- **`assets/icons/` is not listed under `assets:` in pubspec.yaml** — those
  PNGs (~720 KB) are only read at build time by `flutter_launcher_icons` via
  its own `image_path`. No Dart code loads them, so listing them shipped
  720 KB of dead weight in every APK/IPA. The files stay on disk; icon
  regeneration still works.
- **The Android splash drawables are hand-maintained**, not generated. Don't
  run `dart run flutter_native_splash:create` for Android.
- **`SplashScreen` (lib/screens/splash/splash_screen.dart) draws nothing** —
  it is an invisible ink-coloured logic step that restores the session and
  routes. The OS-level native splash is the branding moment. Both use
  `#0A0A0B`, so the handoff is seamless.

## Before shipping

- `lib/main.dart` — replace `_oneSignalAppId` (`YOUR_ONESIGNAL_APP_ID`) with
  the real OneSignal App ID. Push is skipped while it's the placeholder.
- `android/app/build.gradle.kts` — the release build currently signs with the
  **debug** key so `flutter build apk --release` works out of the box. Swap in
  a real signing config before any Play Store upload.
