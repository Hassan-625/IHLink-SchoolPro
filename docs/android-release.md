# IHLink SchoolPro Android delivery

App ID: com.ihlink.schoolpro. Capacitor 8.5.3, Node 22+, Java 21, Android SDK 36. Dependencies and lockfile are pinned. Web assets are bundled locally; no remote server URL or mixed-content exception is configured.

The Android preview APK workflow builds an installable DEBUG APK plus UNSIGNED release APK/AAB and SHA256SUMS. GitHub Actions artifacts expire after 30 days. The debug APK is for controlled testing and is not a production release. Its temporary debug signing key can change between CI runners; uninstall the earlier preview if Android reports an incompatible signing certificate. Do not publish it as a production app.

First launch offers Explore, Create account and Sign in. Existing customer roles and server permissions remain authoritative. Email/password sign-in uses the existing Supabase project. Once native OAuth is enabled, signup verification and recovery use the app callback too; recovery returns to the password-update screen. Signup and password-reset email links return to the public web site so they do not use localhost. Google login is disabled in native preview builds until the callback below is configured and verified. Web Google login retains its existing behavior.

## Native Google setup

Add the exact callback com.ihlink.schoolpro://auth/callback and com.ihlink.schoolpro://auth/callback?flow=recovery to Supabase Auth redirect URLs, verify the published provider configuration, then set VITE_NATIVE_OAUTH_ENABLED=true only for an Android build. PKCE exchanges and exact scheme/host/path validation are implemented; callbacks are handled at cold launch and while the app is running. Use a user-controlled account to verify sign-in; do not create artificial customers or grant roles to make tests pass.

## Release signing and launch

The unsigned APK/AAB cannot be installed or launched as a production release. The owner must supply or create the long-lived release signing identity through Android Studio or a secure CI secret workflow, retain the keystore and passwords, sign the candidate using Android's official tools, verify its certificate/checksum and complete distribution/store requirements. Never commit a keystore or password. No release identity, billing agreement or store publishing action has been fabricated.

## Required real-device acceptance

Test portrait widths 360/390/412, landscape, keyboard overlap, system back, safe-area insets, accessible text scaling, mobile drawer close/Escape, sign-in expiry, signup verification, role boundaries, data network/type separation, real balances and empty catalogue feedback. Verify receipt upload/download and SchoolPro reports/printing on a device: a successful build does not prove those native workflows. Confirm BillStack settlement/refund and data provisioning only with a real user-operated DataSub transaction. All other IHLink commercial payments remain bank transfer. School student fee payments retain school-owned receiving accounts.

## Owner signing workflow

Run the manual **Android signed release candidate** workflow after securely adding repository secrets ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS and ANDROID_KEY_PASSWORD. These are owner-managed release credentials: never paste them into chat, source files or an issue. Keep an offline backup of the signing identity. The workflow uses the supplied identity, verifies the APK/AAB signatures and records checksums; it does not publish to a store or automatically launch a release. It has not been run with an owner signing identity yet.

Google is currently disabled in the live Supabase Auth settings (verified 2026-10-07). Configure the Google OAuth client ID and client secret securely in Supabase, including the Google callback https://lnqsroyiybutkfngbyge.supabase.co/auth/v1/callback and the exact app callbacks above. After confirming those settings, set repository variable NATIVE_OAUTH_ENABLED=true for the signed candidate workflow and verify Google sign-in on a physical device. Existing preview artifacts have native Google disabled; enabling a server setting alone does not change an already-built APK.
