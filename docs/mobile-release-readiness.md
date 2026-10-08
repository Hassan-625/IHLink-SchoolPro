# IHLink mobile release preparation — 8 October 2026

The screenshot review covered 65 images / 43 distinct capture filenames from the supplied Drive folder. DataSub and SchoolPro use IHLink branding, compact native navigation, rounded cards, readable controls and native-only dark surfaces. Full browser layouts are retained. Customer and school role permissions remain enforced by existing guards and database policies. Only actual supported services and real account records are displayed.

## Build outputs

Android identity: `com.ihlink.datasub` / `com.ihlink.schoolpro`. Capacitor 8.5.3 targets Android API 36 with a minimum API of 24. Preview workflow builds an installable debug APK and unsigned release APK/AAB. Preview APKs are for testing; an unsigned AAB cannot be uploaded as a production release. Existing Android release workflow needs the owner's protected signing secrets, preserving the established signing identity.

Icons use the supplied original high-resolution IHLink artwork. Legacy launcher resources and the centred 66dp adaptive foreground use separate bounds. The in-app emblem has reduced extra padding. iOS preparation generates an opaque 1024px App Store icon and a 512px Google Play listing icon from the original artwork, not an enlarged low-resolution thumbnail.

The new iOS workflow installs the matching native runtime, generates an Xcode project with Swift Package Manager, configures each app's callback URL scheme, and compiles an unsigned simulator application. The artifact also contains the native project and listing icons. Xcode 26+ / iOS 15+ are required by Capacitor 8. This is preparation, not an App Store signed archive or an iPhone installation package. Final archive, distribution certificate, provisioning profile and TestFlight validation require the owner's Apple Developer team.

## Release gates that remain

1. Owner Google Play Console and Apple Developer / App Store Connect accounts, legal organization details and stable signing credentials. Supply credentials only through protected account/secret interfaces.
2. Complete physical-device checks with ordinary customer and actual school roles: sign in, password recovery, logout, wallet funding, purchases, receipts, result access, record edits and payment proof. Emulator guest checks do not verify authenticated or real-money flows.
3. Complete customer payment/provider acceptance and confirm BillStack webhook reliability. Immediate wallet credit remains tied to independently verified successful DataSub payments, with merchant settlement tracked separately. Other platforms continue bank-transfer payment proof.
4. Enable and test Google sign-in only after the owner's OAuth configuration and callback allowlists are correct. Native social sign-in is currently disabled; Apple sign-in requirements must be assessed if social sign-in is enabled on iOS.
5. Complete actual account-deletion processing and confirm legally retained payment/school records are handled correctly. Both profiles offer a genuine deletion-request flow; request submission alone is not proof of completed deletion. Provide the public deletion URL required by Google Play.
6. Review and approve product-specific privacy disclosures (including SchoolPro student/guardian records), fill Google Data Safety and Apple privacy fields from the actual app and SDK behavior, and provide store review credentials, screenshots and support contact information.
7. Review SchoolPro subscription purchase presentation for each store/region. Apple's enterprise exception applies to qualifying organization-only classroom tools; individual/family digital subscriptions have different purchase requirements. Do not assume bank transfer for every digital subscription is store compliant.
8. Sign and validate the production Android AAB and iOS archive, test through Play's testing track and TestFlight, then submit for each store's review. Store approval cannot be guaranteed by a successful build.

The reference app's biometric/PIN login, withdrawals, referral rewards and gifting features were not added as decorative or nonfunctional controls. Existing IHLink purchase confirmation PIN remains in place; biometric session unlocking needs a secure native implementation and separate verification.

## Primary references checked

- Android adaptive icon layers and safe zone: https://developer.android.com/develop/ui/views/launch/icon_design_adaptive
- Current Google Play target API requirement (API 36 for new submissions since 31 August 2026): https://support.google.com/googleplay/android-developer/answer/11926878
- Capacitor iOS setup / Xcode requirements: https://capacitorjs.com/docs/ios
- Apple App Review Guidelines, including utility, deletion and purchase rules: https://developer.apple.com/app-store/review/guidelines/
