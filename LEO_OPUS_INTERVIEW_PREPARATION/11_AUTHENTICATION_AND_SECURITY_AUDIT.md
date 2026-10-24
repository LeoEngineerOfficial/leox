# 11 — Authentication, Authorization & Security Audit

---

## 🔒 Security Architecture & Control Audit Matrix

This chapter audits the security controls implemented in LEO OPUS against production application security standards (OWASP Mobile Top 10 and API Security Top 10).

| Security Control | Implementation Status | Technical Mechanism in Codebase | File & Line Reference |
|---|---|---|---|
| **Client Authentication** | `[VERIFIED IMPLEMENTATION]` | Firebase Auth (Email/Password & Google OAuth) | `lib/providers/employer_auth_provider.dart` line 9 |
| **Backend Token Verification** | `[VERIFIED IMPLEMENTATION]` | `admin.auth().verifyIdToken(token)` checking RS256 signature, expiry | `backend/routes/subscription.js` lines 24–38 |
| **Role-Based Access Control (RBAC)** | `[VERIFIED IMPLEMENTATION]` | Firebase Custom Claims (`admin: true`) & Firestore collection roles | `backend/grant-admin.js` line 29; `firestore.rules` line 138 |
| **Database Access Control** | `[VERIFIED IMPLEMENTATION]` | `firestore.rules` enforcing `isOwner()`, `isEmployer()`, `isAdmin()` | `firestore.rules` lines 1–168 |
| **Storage Path Security** | `[VERIFIED IMPLEMENTATION]` | `storage_rules.rules` matching UID prefix on resume uploads | `storage_rules.rules` lines 13–51 |
| **Payment Signature Verification** | `[VERIFIED IMPLEMENTATION]` | HMAC SHA-256 server verification (`orderId + '\|' + paymentId`) | `backend/routes/subscription.js` lines 304–314 |
| **Webhook Signature Validation** | `[VERIFIED IMPLEMENTATION]` | HMAC SHA-256 check against `x-razorpay-signature` | `backend/routes/subscription.js` lines 414–423 |
| **Password Hashing (Admin)** | `[VERIFIED IMPLEMENTATION]` | PBKDF2 with unique salt, 1000 iterations, SHA-512 | `backend/routes/subscription.js` lines 477–488 |
| **CORS Origin Whitelisting** | `[VERIFIED IMPLEMENTATION]` | Express CORS restricting origins to Firebase Hosting and localhost | `backend/server.js` lines 48–60 |
| **File Upload Validation** | `[VERIFIED IMPLEMENTATION]` | Multer memory storage with 5MB limit and MIME type filter | `backend/server.js` lines 36–45 |
| **Rate Limiting (AI Requests)** | `[VERIFIED IMPLEMENTATION]` | Catches HTTP 429, writes to Firestore queue, returns HTTP 202 | `backend/routes/subscription.js` lines 1018–1037 |
| **Secret Management** | `[VERIFIED IMPLEMENTATION]` | Environment variables loaded via `dotenv`; keys omitted from VCS | `.env`, `backend/.env`, `lib/main.dart` line 51 |
| **Application Rate Limiting (DDoS)**| `[PROPOSED IMPROVEMENT]` | Recommended: `express-rate-limit` (100 req/min per IP) | Architectural recommendation |
| **SSL / Certificate Pinning** | `[PROPOSED IMPROVEMENT]` | Recommended for enterprise: HttpCertificatePinning | Architectural recommendation |

---

## ❓ Category 11 Interview Questions: Authentication & Security

### Q31: How do Firebase Security Rules enforce the Principle of Least Privilege in LEO OPUS?
- **Interviewer Focus:** Database-level security, preventing client-side data tampering, and RBAC rules syntax.
- **Answer A (Concise):**  
  The Principle of Least Privilege states that every user should possess only the minimum permissions necessary to perform their role. In `firestore.rules`, we enforce this by making all write operations conditional on authentication and ownership (`isOwner(userId)`). For sensitive collections like `payments` and `subscription_plans`, client-side writes are completely blocked (`allow write: if isAdmin();`), ensuring only our authenticated backend or administrative users with custom claims can modify financial and plan data.
- **Answer B (Technical Deep-Dive):**  
  In [`firestore.rules`](file:///d:/Shinnovation/leox/firestore.rules#L1-L168):
  1. **Strict Payment Protection:**
     ```javascript
     match /payments/{paymentId} {
       allow read: if isAuthenticated() && (resource.data.userId == request.auth.uid || isAdmin());
       allow write: if isAdmin(); // Strict backend write-only
     }
     ```
     Normal mobile clients cannot forge, create, or update payment records directly in Firestore. Writes require an admin token, ensuring all payment writes originate from the Node.js backend after cryptographic HMAC validation.
  2. **Subscription Manipulation Prevention:**
     ```javascript
     match /subscriptions/{userId} {
       allow read: if isAuthenticated() && (userId.split('_')[0] == request.auth.uid || isAdmin());
       allow create: if isAuthenticated() && userId.split('_')[0] == request.auth.uid && request.resource.data.status == 'trial';
       allow update, delete: if isAdmin();
     }
     ```
     Users are permitted to initialize their own 30-day free trial on first launch, but they CANNOT update their own document to change their status to `'active'` or extend their `endDate`. Only the backend or administrator can update subscription records.
  3. **Role Authorization in Job Posting:**
     ```javascript
     function isEmployer() {
       return isAuthenticated() && (
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'employer') ||
         (exists(/databases/$(database)/documents/employers/$(request.auth.uid)))
       );
     }
     match /jobs/{jobId} {
       allow read: if true;
       allow create: if isEmployer();
       allow update, delete: if isEmployer() && resource.data.postedBy == request.auth.uid;
     }
     ```
     Candidates and service seekers cannot post or delete job openings.
- **Verified Evidence:** `firestore.rules` lines 18–23, 64–78, 146–156.
- **Likely Follow-up:** *"What is the difference between `request.resource` and `resource` in Firebase rules?"*
- **Follow-up Answer:** *" `resource` refers to the existing document currently stored in the database before the operation. `request.resource` represents the incoming document data being written. For example, `request.resource.data.status == 'trial'` validates the incoming payload before allowing creation."*
- **Common Mistakes to Avoid:** Don't say security is handled only on the client. Emphasize that client validation is for UX, while Firestore Security Rules provide unbreakable database-level enforcement.
