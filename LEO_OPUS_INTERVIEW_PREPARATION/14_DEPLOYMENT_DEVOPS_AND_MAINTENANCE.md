# 14 — Deployment, DevOps & Store Release Engineering

---

## 🚀 Release Configuration & Deployment Architecture

LEO OPUS was built, signed, and configured for release across **Google Play Store**, **Apple App Store**, **Render**, and **Firebase Hosting**.

| Platform | Deployment Target | Configuration & Build Files | Key Settings / Identifiers |
|---|---|---|---|
| **Android** | Google Play Store (AAB / APK) | `android/app/build.gradle.kts`, `key.properties` | `applicationId = "com.leoengineer.leox"`, `minSdk = 24`, `targetSdk = 36`, `compileSdk = 36` |
| **iOS** | Apple App Store (IPA) | `ios/Runner.xcodeproj/project.pbxproj`, `Info.plist` | `PRODUCT_BUNDLE_IDENTIFIER = com.shinnovation.leox` |
| **Backend API** | Render Cloud Platform | `backend/server.js`, `backend/package.json` | URL: `https://leox-kfsm.onrender.com/api`, Node 18, Port 3000 |
| **Admin Web** | Firebase Hosting | `firebase.json`, `.firebaserc`, `web_admin/build/web` | Host: `studio-7488920972-4ef9c.web.app` |

---

## ❓ Category 14 Interview Questions: Deployment & DevOps

### Q34: How did you prepare and sign the Android and iOS release builds for production deployment?
- **Interviewer Focus:** Mobile release engineering, keystore signing, bundle identifiers, and store guidelines.
- **Answer A (Concise):**  
  For Android, we generated a cryptographic upload keystore using Java `keytool`, configured release signing in `key.properties` (kept out of version control), and configured `build.gradle.kts` to build optimized Android App Bundles (`.aab`) with `minSdk 24` and `targetSdk 36`. For iOS, we configured the bundle identifier `com.shinnovation.leox` in Xcode, generated distribution certificates and provisioning profiles via Apple Developer Connect, and prepared an App Store test demo account (`googletest@leoengineer.com`) to pass store review.
- **Answer B (Technical Deep-Dive):**  
  **Android Release Workflow:**
  1. Keystore generated via `keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000`.
  2. `android/key.properties` maps `storePassword`, `keyPassword`, `keyAlias`, and `storeFile`.
  3. In [`android/app/build.gradle.kts`](file:///d:/Shinnovation/leox/android/app/build.gradle.kts#L19-L40), configured `namespace = "com.leoengineer.leox"`, `minSdk = 24` (Android 7.0), `targetSdk = 36`, and `versionCode = flutter.versionCode`.
  4. Built release bundle via `flutter build appbundle --release`.
  
  **App Store Review Accommodation:**
  - In [`lib/main.dart`](file:///d:/Shinnovation/leox/lib/main.dart#L194,L410) and [`EmployerAuthProvider`](file:///d:/Shinnovation/leox/lib/providers/employer_auth_provider.dart#L71), we implemented a dedicated bypass for reviewer email `googletest@leoengineer.com`. This ensures Google Play and Apple App Store review teams can immediately test full application functionality without being blocked by SMS OTPs or unverified email links.
- **Verified Evidence:** `android/app/build.gradle.kts`; `lib/main.dart` lines 194, 410; `ios/Runner.xcodeproj/project.pbxproj` line 373.
- **Likely Follow-up:** *"What is the advantage of an Android App Bundle (.aab) over an APK (.apk)?"*
- **Follow-up Answer:** *"An APK contains compiled binaries, native C++ libraries, and screen density assets for all device architectures (arm64, armeabi-v7a, x86_64, hdpi, xxhdpi). Google Play uses the App Bundle to dynamically generate split APKs containing only the specific CPU architecture and screen density needed by the user's device, reducing download size by up to 50%."*
- **Common Mistakes to Avoid:** Never commit raw keystores or signing passwords into public Git repositories.
