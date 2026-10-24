# 15 — Testing Strategy & 13 Production Debugging Scenarios

---

## 🧪 Testing Architecture Summary

LEO OPUS includes automated unit, widget, and integration test coverage across models, providers, and workflows:
- **Unit Tests:** `test/unit/models/` and `test/unit/providers/` utilizing **Mockito** for dependency mocking.
- **Widget Tests:** `test/widget/` verifying UI card rendering, drawer navigation, and status badges.
- **Integration Tests:** `test/integration/` verifying complete authentication and application submission flows.

---

## 🛠️ 13 Realistic Debugging Case Studies

### Scenario 1: User Registration Fails with "PERMISSION_DENIED" in Firestore
- **Symptoms:** User completes registration, but immediately crashes or gets redirected back to the login screen with a permission error.
- **Possible Causes:** Firestore security rules check `/users/{uid}`, but registration wrote to `/employers/{uid}`; or asynchronous network latency caused the role document write to lag behind auth state changes.
- **Diagnostic Approach A (Console & Rules):** Inspect Firebase Console Firestore tab to check if `/users/{uid}` exists. Review `firestore.rules` simulator with the user's auth token.
- **Diagnostic Approach B (Code & Logs):** Trace `_getUserRole` in `lib/main.dart`. Check debug logs for `"Registry Check (users/$uid): exists=false"`.
- **Root Cause Isolation:** Asynchronous race condition: `FirebaseAuth.instance.authStateChanges()` fired before Firestore finished writing the profile document.
- **Fix:** Implemented an in-memory `targetRole` cache in `SessionService` and added a 10-attempt retry loop with 2-second backoff in `_getUserRole` (`lib/main.dart` lines 319–407). Updated `firestore.rules` so `isEmployer()` checks both `users` and `employers`.
- **Regression Test:** Write an integration test that logs in immediately after registration and asserts that `_getUserRole` returns a non-null role within 3 retries.
- **Prevention:** Always decouple auth creation from profile hydration using optimistic client caching or serverless cloud function triggers.

---

### Scenario 2: Node.js Backend Returns HTTP 500 on Payment Signature Verification
- **Symptoms:** Mobile checkout succeeds on Razorpay, but the app shows "Verification Failed" and the subscription remains inactive.
- **Possible Causes:** Secret key mismatch between `.env` and Razorpay Dashboard; malformed payload missing `razorpaySignature`; surrounding quotes in `.env` variable values.
- **Diagnostic Approach A (Server Logs):** Check Render server logs: `[VerifyPayment] Invalid Razorpay signature detected`. Compare computed HMAC against received signature.
- **Diagnostic Approach B (Code Inspection):** Check `cleanKeySecret` helper in `backend/routes/subscription.js` line 10.
- **Root Cause Isolation:** Surrounding quotes inside `.env` (e.g., `RAZORPAY_KEY_SECRET="secret"`) were being hashed as part of the key string.
- **Fix:** Added `.replace(/['"]/g, '').trim()` to sanitize environment variables upon loading (`backend/routes/subscription.js` line 10).
- **Regression Test:** Unit test HMAC computation against Razorpay's official test vectors.
- **Prevention:** Always sanitize and trim environment configuration strings on server startup.

---

### Scenario 3: Google Sign-In Fails Silently on Android Device
- **Symptoms:** User taps "Sign in with Google", selects their Google account, but the dialog dismisses and nothing happens.
- **Possible Causes:** Missing SHA-1 / SHA-256 fingerprint in Firebase Project Console; mismatched OAuth Web Client ID in `GoogleSignIn` constructor.
- **Diagnostic Approach A (Logcat):** Run `adb logcat | grep -i GoogleSignIn`. Look for `ApiException: 10` or `12500` (Developer Configuration Error).
- **Diagnostic Approach B (Fingerprint Audit):** Run `./gradlew signingReport` in `android/` directory and compare the SHA-1 fingerprint with Firebase Console settings.
- **Root Cause Isolation:** OAuth Web Client ID in Flutter code did not match the `client_id` with `client_type: 3` in `google-services.json`.
- **Fix:** Updated `serverClientId` in `EmployerAuthProvider` (`lib/providers/employer_auth_provider.dart` line 13) to match the Web Client ID from `google-services.json`.
- **Regression Test:** Manual physical device test verifying Google Sign-In token generation.
- **Prevention:** Maintain automated scripts to sync OAuth client IDs from `google-services.json` to environment configurations.

---

### Scenario 4: AI Resume Matcher Returns 429 "Rate Limit Exceeded"
- **Symptoms:** Candidate uploads resume, but analysis fails with a rate limit message during peak usage.
- **Possible Causes:** Free-tier Gemini API quota exceeded (15 RPM limit).
- **Diagnostic Approach A (Server Response):** Inspect HTTP status code returned from `generativelanguage.googleapis.com` (HTTP 429).
- **Diagnostic Approach B (Provider Logs):** Trace `_getUserFriendlyAIError` in `AIResumeMatcherProvider`.
- **Root Cause Isolation:** Gemini Flash free tier hit per-minute token or request ceilings.
- **Fix:** In `backend/routes/subscription.js`, intercept status 429, write to Firestore `pending_matches` collection, and return HTTP 202 Accepted. On client side, fall back to secondary model (`gemini-2.0-flash`).
- **Regression Test:** Mock an HTTP 429 response in `test/unit/providers/ai_resume_matcher_provider_test.dart` and assert that the provider returns a friendly queue message without crashing.
- **Prevention:** Implement Redis-based request throttling and upgrade to paid tier for production scale.

---

### Scenario 5: Duplicate Payment Processing on Network Retry
- **Symptoms:** User experiences a network stutter during checkout, taps "Verify" twice, and concerns arise over duplicate subscription extensions.
- **Possible Causes:** Non-idempotent payment verification endpoint.
- **Diagnostic Approach A (Database Inspection):** Check `payments` collection in Firestore for duplicate payment documents.
- **Diagnostic Approach B (Code Trace):** Trace `backend/routes/subscription.js` line 324.
- **Root Cause Isolation:** Verified that `payments` collection uses `razorpayPaymentId` as the unique document ID (`db.collection('payments').doc(razorpayPaymentId).set(...)`).
- **Fix:** Enforced idempotency by keying documents directly on the Razorpay Payment ID and setting subscriptions under `${userId}_${role}` with absolute date recalculation.
- **Regression Test:** Send two identical POST requests with the same `razorpayPaymentId` and assert that the subscription duration is updated exactly once.
- **Prevention:** Always key transaction documents on external gateway IDs rather than auto-generated random keys.

---

### Scenarios 6–13 (Summary Matrix)
| Scenario | Primary Symptom | Root Cause | Verified Resolution |
|---|---|---|---|
| **6. Slow Job Query** | List takes 2+ seconds to load | Missing composite index causing table scan | Created compound index in `firestore.indexes.json` |
| **7. PDF Text Extraction Empty** | "No text extracted from PDF" | Scanned image-only PDF | Prompted user to paste text directly; handled empty string |
| **8. Flutter Test Deprecation** | Compilation failure in `testWidgets` | `window.physicalSize` deprecated in Flutter 3.10+ | Authored `fix_tests.dart` migration script |
| **9. Silent Failure on Job Post** | Button clicks but nothing happens | Uncaught exception swallowed in provider | Added `rethrow` and error UI alert banner |
| **10. Memory Leak in Dashboards** | App memory climbs over time | Active stream listeners not cancelled | Implemented `_stopListeners()` in provider `dispose()` |
| **11. Render Free-Tier Cold Start** | First API request takes 50 seconds | Render spins down free containers after inactivity | Implemented 5-minute timeout in `ApiService` with user retry prompt |
| **12. Web Admin Login Access Denied** | Valid credentials rejected | User lacks `admin: true` custom claim | Implemented PBKDF2 credential verification in `backend/grant-admin.js` |
| **13. Network Drop During Flow** | App hangs on loading spinner | Missing network timeout | Added `NetworkIndicator` and 5-min timeout handling in `StorageService` |
