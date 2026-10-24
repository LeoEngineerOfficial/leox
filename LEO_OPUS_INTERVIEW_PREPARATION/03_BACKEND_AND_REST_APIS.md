# 03 — Backend Architecture, REST API Design & Express.js Internals

---

## ⚙️ Backend Overview & Technology Choice

The LEO OPUS backend is a lightweight, high-performance micro-service built with **Node.js** and **Express.js** (`backend/package.json`), deployed on **Render** (`https://leox-kfsm.onrender.com/api`).

### Why Node.js and Express.js Were Selected
1. **Asynchronous Non-Blocking I/O:** Node.js uses libuv's single-threaded event loop and asynchronous worker threads, making it exceptionally well-suited for I/O-heavy operations (proxied Gemini AI calls, Firebase Admin Firestore writes, and Razorpay HTTPS webhooks) without thread-pool starvation.
2. **Unified JavaScript/TypeScript Ecosystem:** Shared JSON data models and validation structures across backend services and Flutter Web admin clients.
3. **First-Class Firebase & Fintech SDKs:** Native support for the official `firebase-admin` (v11.10.1) and `razorpay` (v2.9.8) SDKs, allowing rapid integration and secure server-side cryptographic operations.

---

## 📋 Verified API Endpoint Catalog

| Method | Endpoint Route | Middleware Applied | Purpose & Functionality | Request Body / Query | Success Response Code | Error Handling | File & Line Reference |
|---|---|---|---|---|---|---|---|
| `GET` | `/api/health` | None | Service liveness probe | None | `200 OK` | N/A | `backend/server.js` lines 199–205 |
| `POST` | `/api/parse-resume` | `upload.single('resume')` | Multipart resume upload & parsing | Multipart file (PDF/DOCX, max 5MB) | `200 OK` | `400` No file; `500` Failure | `backend/server.js` lines 66–144 |
| `POST` | `/api/match-resume` | `upload.single('resume')` | Matching resume against job description | Multipart file + `jobDescription` | `200 OK` | `400` Missing params; `500` Failure | `backend/server.js` lines 146–196 |
| `POST` | `/api/subscription/create-order` | `requireAuth` | Generates Razorpay Order ID with coupon discount | `{ planId, billingCycle, couponCode, gstNumber }` | `200 OK` | `400` Active sub / invalid cycle; `404` Plan not found; `500` Rzp error | `backend/routes/subscription.js` lines 57–240 |
| `POST` | `/api/subscription/verify-payment` | `requireAuth` | Cryptographically verifies HMAC-SHA256 signature and activates plan | `{ razorpayOrderId, razorpayPaymentId, razorpaySignature, planId, billingCycle }` | `200 OK` | `400` Tampered signature / missing params; `500` Verification failure | `backend/routes/subscription.js` lines 246–358 |
| `POST` | `/api/subscription/webhook` | `express.raw` | Razorpay webhook receiver for failed charges and refunds | Razorpay Webhook Event Payload | `200 OK` ('OK') | `400` Invalid webhook signature; `500` Processing error | `backend/routes/subscription.js` lines 409–472 |
| `GET` | `/api/subscription/admin/setup-status` | None | Checks if zero admins exist (bootstrap mode) | None | `200 OK` (`{ bootstrapMode: bool }`) | `500` DB error | `backend/routes/subscription.js` lines 535–545 |
| `POST` | `/api/subscription/admin/login` | None | Verifies PBKDF2 salt/hash credentials & returns Custom Token | `{ email, password }` | `200 OK` (`{ customToken }`) | `400` Missing credentials; `401` Invalid pass; `500` Token failure | `backend/routes/subscription.js` lines 551–591 |
| `POST` | `/api/subscription/admin/register` | Conditional (`requireAdmin` if admins exist) | Bootstraps initial owner or creates secondary admin | `{ email, password }` | `200 OK` | `400` Missing params; `403` Unauthorized; `500` Storage failure | `backend/routes/subscription.js` lines 597–663 |
| `POST` | `/api/subscription/admin/modify` | `requireAdmin` | Admin manual override (grant complimentary, extend, cancel, suspend, reset trial) | `{ userId, action, extensionDays, planId, reason }` | `200 OK` | `400` Invalid action / missing params; `403` Forbidden; `404` Sub not found | `backend/routes/subscription.js` lines 669–786 |
| `POST` | `/api/subscription/ai/match-resume` | `requireAuth` | Proxies resume evaluation to Google Gemini with rate-limit queueing | `{ resumeText, jobDescription }` | `200 OK` / `202 Accepted` | `400` Missing text; `202` Rate limited (queued); `500` Gemini failure | `backend/routes/subscription.js` lines 942–1044 |

---

## ❓ Category 3 Interview Questions: Backend & REST APIs

### Q14: Explain the request-response lifecycle in your Express.js backend. What happens between the mobile app firing a request and getting a response?
- **Interviewer Focus:** Deep understanding of the HTTP pipeline, middleware sequencing, and async handling in Node.js.
- **Answer A (Concise):**  
  When an HTTP request reaches our Node.js server, it passes sequentially through global middleware: CORS origin whitelisting, body parsing (`express.json`), and static routers. For protected routes, it enters `requireAuth`, which extracts the Bearer token from the `Authorization` header and validates it against Firebase Admin SDK. If valid, `req.user` is populated and `next()` passes control to the route controller. The controller executes business logic, interacts with Firestore or external APIs, and returns a JSON response with appropriate HTTP status codes.
- **Answer B (Technical Deep-Dive):**  
  Tracing `POST /api/subscription/create-order` step-by-step:
  1. **Transport & DNS Resolution:** Mobile app resolves `leox-kfsm.onrender.com` via DNS, establishes a TCP handshake, negotiates TLS 1.3, and transmits an HTTP POST request.
  2. **CORS Middleware:** [`backend/server.js`](file:///d:/Shinnovation/leox/backend/server.js#L48-L60) checks the `Origin` header against an approved list (`studio-7488920972-4ef9c.web.app`, `localhost:3000`). If valid, CORS headers (`Access-Control-Allow-Origin`, `Access-Control-Allow-Credentials`) are appended.
  3. **Body Parser:** `express.json({ limit: '10mb' })` reads the incoming TCP data stream chunks, concatenates buffers, parses JSON, and attaches the resulting JavaScript object to `req.body`.
  4. **Authentication Middleware (`requireAuth`):** In [`backend/routes/subscription.js`](file:///d:/Shinnovation/leox/backend/routes/subscription.js#L24-L38):
     - Extracts `req.headers.authorization`.
     - Validates format: `Bearer <token>`.
     - Calls `await admin.auth().verifyIdToken(token)`. This cryptographically verifies the token's RS256 signature using Google's public keys, validates expiration (`exp`), and attaches the decoded claims to `req.user`.
     - If invalid or expired, execution halts immediately: `return res.status(401).json({ error: 'Unauthorized: Invalid token' })`.
  5. **Route Handler:** Executes business logic:
     - Checks if the user already has an active subscription for the requested role in Firestore.
     - Fetches plan pricing from `subscription_plans`.
     - Validates optional coupon code against `coupons` collection.
     - Converts final INR amount to paise (`Math.round(finalPrice * 100)`).
     - Calls Razorpay API: `await razorpay.orders.create(options)`.
  6. **Response Generation:** Serializes response: `res.json({ success: true, orderId, amount, currency, key })`.
  7. **Centralized Error Handler:** If an unhandled exception occurs at any point, control drops to the 4-argument error middleware `app.use((err, req, res, next) => ...)` in `backend/server.js` line 208, returning HTTP 500 without leaking stack traces.
- **Verified Evidence:** `backend/server.js` lines 48–63, 208–215; `backend/routes/subscription.js` lines 24–38, 57–240.
- **Likely Follow-up:** *"Why does the error middleware in Express require exactly 4 arguments `(err, req, res, next)`?"*
- **Follow-up Answer:** *"Express uses `Function.prototype.length` (arity) to inspect middleware signatures at startup. Only functions with exactly 4 parameters are registered internally as error handlers; functions with 3 arguments are treated as standard request handlers."*
- **Common Mistakes to Avoid:** Don't forget the authentication middleware step. Explain how `req.user` is populated.

---

### Q15: How does your backend handle authentication and authorization? What is the difference between an ID token and a Custom Claim?
- **Interviewer Focus:** Evaluates comprehension of stateless token security, authentication vs authorization, and RBAC.
- **Answer A (Concise):**  
  **Authentication** verifies *who* the user is, handled by verifying Firebase Bearer ID tokens. **Authorization** determines *what* they are permitted to do. We implement Role-Based Access Control (RBAC) using **Firebase Custom Claims**. The backend assigns `{ admin: true }` to trusted users via `admin.auth().setCustomUserClaims()`. Our `requireAdmin` middleware inspects the decoded token claims; if `decodedToken.admin !== true`, it immediately returns HTTP 403 Forbidden.
- **Answer B (Technical Deep-Dive):**  
  **Authentication Pipeline (`requireAuth`):**
  - Mobile clients authenticate with Firebase Auth and obtain an encrypted JSON Web Token (JWT).
  - Every API request sends `Authorization: Bearer <ID_TOKEN>`.
  - The backend verifies this using `admin.auth().verifyIdToken(token)`. Because Firebase ID tokens are signed with Google's private key, the backend verifies the signature, issuer (`iss`), and expiration (`exp`) securely.
  
  **Authorization Pipeline (`requireAdmin`):**
  - Normal users have standard claims.
  - In [`backend/grant-admin.js`](file:///d:/Shinnovation/leox/backend/grant-admin.js#L23-L41), we grant administrative authority by running:
    ```javascript
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });
    ```
  - This embeds `admin: true` directly into the user's JWT payload.
  - In [`backend/routes/subscription.js`](file:///d:/Shinnovation/leox/backend/routes/subscription.js#L41-L49), `requireAdmin` runs:
    ```javascript
    const requireAdmin = async (req, res, next) => {
      await requireAuth(req, res, () => {
        if (req.user && req.user.admin === true) {
          next();
        } else {
          return res.status(403).json({ success: false, error: 'Forbidden: Admin access required' });
        }
      });
    };
    ```
  - **Difference:** An ID token proves user identity (Authentication); custom claims encode privileges and roles inside the token signature (Authorization), eliminating redundant database lookups on every request.
- **Verified Evidence:** `backend/grant-admin.js` line 29; `backend/routes/subscription.js` lines 41–49.
- **Likely Follow-up:** *"If you grant an admin claim, does the user have immediate access on the frontend?"*
- **Follow-up Answer:** *"No, because JWTs are immutable once issued and valid for 1 hour. The client must force-refresh their token via `user.getIdToken(true)` or sign out and log back in to receive a newly minted JWT containing the updated `{ admin: true }` claim."*
- **Common Mistakes to Avoid:** Don't confuse 401 Unauthorized (unauthenticated user) with 403 Forbidden (authenticated user lacking administrative permissions).

---

### Q16: How do you handle Google Gemini API rate limiting (HTTP 429) on the backend? Explain your queueing architecture.
- **Interviewer Focus:** Resilient API design, handling third-party service degradation, and asynchronous queue patterns.
- **Answer A (Concise):**  
  When Google Gemini's API experiences rate limits or quota exhaustion, it returns HTTP 429. Rather than failing the user's resume analysis with a crash or generic error, our Express backend catches the 429 status, writes the pending resume text and job description into a Firestore collection called `pending_matches`, and returns **HTTP 202 Accepted**. The mobile app displays a message informing the candidate that the analysis is queued and will complete in the background.
- **Answer B (Technical Deep-Dive):**  
  In [`backend/routes/subscription.js`](file:///d:/Shinnovation/leox/backend/routes/subscription.js#L910-L935,L1015-L1037):
  1. The backend dispatches prompt text to Gemini 3.6 Flash via an HTTPS POST request with generation configuration `responseMimeType: 'application/json'`.
  2. If Gemini returns status code 429:
     ```javascript
     if (res.statusCode === 429) {
       const error = new Error('Rate limit exceeded');
       error.statusCode = 429;
       return reject(error);
     }
     ```
  3. The route's `catch` block intercepts `error.statusCode === 429`:
     ```javascript
     if (error.statusCode === 429) {
       const queueId = `match_${userId}_${Date.now()}`;
       await db.collection('pending_matches').doc(queueId).set({
         userId: userId,
         resumeText: resumeText,
         jobDescription: jobDescription,
         status: 'pending',
         createdAt: admin.firestore.FieldValue.serverTimestamp(),
       });
       return res.status(202).json({
         success: false,
         rateLimited: true,
         message: 'AI matching is currently busy. We have queued your resume for processing...',
       });
     }
     ```
  4. **Why HTTP 202 Accepted?** HTTP 202 is the official RFC standard indicating that the request has been accepted for processing, but processing has not been completed.
  5. **Client Resilience:** On the Flutter client side in [`AIWorkflows.matchResumeToJob`](file:///d:/Shinnovation/leox/lib/backend/ai_workflows.dart#L78-L89), when `response['rateLimited'] == true` is received, it displays the message without marking the job application as failed.
- **Verified Evidence:** `backend/routes/subscription.js` lines 910–915, 1018–1037; `lib/backend/ai_workflows.dart` lines 78–89.
- **Likely Follow-up:** *"How would you process those queued items in production?"*
- **Follow-up Answer:** *"In a scaled production system, I would use a background worker process (or Google Cloud Task / BullMQ with Redis) consuming from `pending_matches` with an exponential backoff retry policy (e.g., 5s, 15s, 45s). Once processed, it writes the result to the user's `applications` document and triggers a Firebase Cloud Messaging push notification."*
- **Common Mistakes to Avoid:** Don't say you just retry in a while loop on the backend thread. That would block the Node.js event loop and cause timeouts.

---

### Q17: Compare two ways to design the Payment Verification API: Current Implementation vs Proposed Production Architecture.
- **Interviewer Focus:** Evaluates architectural maturity, distributed systems design, and understanding of webhooks vs direct RPC.
- **Answer A (Concise):**  
  Currently, we use a **synchronous client-initiated verification pattern**: the mobile app receives Razorpay's success callback and calls `POST /api/subscription/verify-payment` with the signature. The server verifies the HMAC and activates the subscription.  
  A superior production alternative is an **asynchronous webhook-first architecture**: the server relies strictly on Razorpay's server-to-server webhook (`payment.captured`), while the mobile client simply polls or listens to Firestore snapshot changes. This guarantees activation even if the user's phone dies or loses connection immediately after entering their UPI PIN.
- **Answer B (Technical Deep-Dive):**  
  **Approach 1: Current Implementation (Client-Initiated RPC)**
  - *Mechanism:* Mobile app opens native Razorpay checkout -> User completes payment -> Razorpay SDK returns `{ orderId, paymentId, signature }` to Flutter callback -> Flutter calls `POST /verify-payment` -> Express verifies HMAC SHA-256 and updates Firestore.
  - *Pros:* Immediate user feedback in the UI; easy to implement and debug during mobile development.
  - *Trade-off / Risk:* If the user's mobile app crashes, phone battery dies, or connectivity drops right as the banking OTP/UPI succeeds, the client-side callback never reaches our server. The user's account is debited by the bank, but their subscription in our database remains inactive until manual support intervention.
  
  **Approach 2: Proposed Production Architecture (Server-to-Server Webhook Driven)**
  - *Mechanism:* When payment succeeds, Razorpay's servers dispatch an authenticated webhook (`order.paid` or `payment.captured`) directly to `POST /api/subscription/webhook` with `x-razorpay-signature`. The backend verifies the signature, activates the subscription in Firestore, and records the invoice. The mobile app simply listens to its Firestore `subscriptions/{uid}_{role}` document via real-time snapshot listeners.
  - *Pros:* 100% resilient to client crashes, battery drops, or network loss. Guarantees eventual consistency.
  - *Cons:* Slightly higher infrastructure setup; requires public static webhook URLs and webhook replay protection.
- **Verified Evidence:** `backend/routes/subscription.js` lines 246–358 (verify-payment route) and lines 409–472 (webhook route).
- **Likely Follow-up:** *"How do you prevent duplicate activations if both the client RPC and the webhook trigger at the same time?"*
- **Follow-up Answer:** *"By enforcing idempotency. In Firestore, payment documents use the unique `razorpayPaymentId` as the document ID (`db.collection('payments').doc(razorpayPaymentId)`). Using Firestore transactions or checking if `payments.doc(paymentId).exists` ensures that whether the webhook or the client RPC arrives first, the payment is recorded and subscription extended exactly once."*
- **Common Mistakes to Avoid:** Never suggest trusting the mobile client without server-side verification. Always emphasize cryptographic signature validation and idempotency.

---

### Q18: What is Idempotency, and why is it critical in payment gateways and REST APIs?
- **Interviewer Focus:** Distributed systems reliability, preventing duplicate charges, and handling retries safely.
- **Answer A (Concise):**  
  An API endpoint is **idempotent** if making the same request multiple times produces the exact same system state as making it once. In payment processing, network timeouts often cause mobile apps to retry requests. Without idempotency, a network stutter could cause an order to be charged twice or a subscription period to be extended twice. We enforce idempotency using unique Razorpay order receipts and deterministic Firestore document IDs.
- **Answer B (Technical Deep-Dive):**  
  In LEO OPUS:
  1. **HTTP Verbs & Idempotency:**
     - `GET`, `PUT`, `DELETE`, and `HEAD` are idempotent by HTTP specification. Repeating `DELETE /jobs/job123` ten times leaves the job deleted.
     - `POST` is NOT idempotent by default; repeating `POST /create-order` could generate multiple orders and duplicate charges.
  2. **How We Ensure Idempotency in LEO OPUS:**
     - In [`create-order`](file:///d:/Shinnovation/leox/backend/routes/subscription.js#L81-L96), before generating a new Razorpay order, the backend checks if the user already has an active subscription in Firestore (`subDoc.exists && subData.status === 'active' && endDate > now`). If so, it rejects the request with HTTP 400 `'You already have an active subscription'`, preventing double billing.
     - In [`verify-payment`](file:///d:/Shinnovation/leox/backend/routes/subscription.js#L324), we store payment records using the deterministic Razorpay payment ID as the document key:
       ```javascript
       await db.collection('payments').doc(razorpayPaymentId).set({ ... });
       ```
       If a network retry causes the client or webhook to send the same `razorpayPaymentId` again, Firestore overwrites the identical record (`set` with idempotency) rather than creating a duplicate document.
     - Subscription documents use the deterministic compound key `${userId}_${role}` (`docId = `${userId}_${planData.role}``), preventing duplicate subscriptions for the same user and role.
- **Verified Evidence:** `backend/routes/subscription.js` lines 81–96, 324, 398.
- **Likely Follow-up:** *"What is an Idempotency Key in Stripe or Razorpay APIs?"*
- **Follow-up Answer:** *"An Idempotency Key is a unique UUID generated by the client and sent in an HTTP header (e.g., `Idempotency-Key: <UUID>`). The server caches the response for that UUID; if the client retries with the same key within 24 hours, the server returns the cached response immediately without re-executing the financial transaction."*
- **Common Mistakes to Avoid:** Don't say "POST is idempotent." Explain that POST is non-idempotent by default and must be explicitly designed for idempotency.
