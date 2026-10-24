# 01 — System Architecture, Component Design & End-to-End Data Flows

---

## 🏛️ High-Level System Architecture

The LEO OPUS ecosystem follows a multi-tier, reactive client-server architecture. The mobile client communicates directly with **Firebase Cloud Services** for real-time operational data and authenticated file storage, while routing sensitive business transactions (Razorpay order creation, payment signature verification, and rate-limited AI resume evaluations) through a dedicated **Node.js/Express.js** micro-backend.

```mermaid
flowchart TD
    subgraph MobileClient ["📱 Flutter Mobile Client (Android / iOS)"]
        UI["Presentation Layer\n(Material Design 3 + Sizer)"]
        SM["State Management\n(Provider ChangeNotifier)"]
        SL["Service Layer\n(FirebaseService, ApiService, GeminiService)"]
        PDF["Local PDF Extractor\n(Syncfusion Flutter PDF)"]
        UI --> SM
        SM --> SL
        SM --> PDF
    end

    subgraph FirebaseCloud ["🔥 Firebase Cloud Infrastructure"]
        FAuth["Firebase Authentication\n(Email/Password, Google OAuth)"]
        Firestore["Cloud Firestore\n(NoSQL Real-time Snapshot Listeners)"]
        FStorage["Firebase Cloud Storage\n(Resumes, Profile Pictures, Portfolios)"]
        FHost["Firebase Hosting\n(Hosts Admin Web Panel)"]
    end

    subgraph BackendAPI ["⚙️ Node.js / Express Backend (Render)"]
        Express["Express Server\n(Port 3000 / Render)"]
        AuthMid["requireAuth Middleware\n(verifyIdToken)"]
        AdminMid["requireAdmin Middleware\n(Admin Custom Claim RBAC)"]
        RzpRoutes["Subscription & Payment Routes\n(Razorpay Orders & HMAC)"]
        AiQueue["Gemini AI Proxy &\nRate-Limit Queueing"]
        Express --> AuthMid
        AuthMid --> RzpRoutes
        AuthMid --> AiQueue
        AuthMid --> AdminMid
    end

    subgraph ExternalServices ["🌐 Third-Party External APIs"]
        Gemini["Google Gemini AI API\n(gemini-3.6-flash & 2.0-flash)"]
        RazorpayGateway["Razorpay Payment Gateway\n(Checkout & Webhooks)"]
    end

    subgraph AdminPortal ["💻 Flutter Web Administration Panel"]
        WebUI["Admin Dashboard Shell\n(Custom Token / Claims Auth)"]
        WebCtrl["Subscription & Coupon Controllers"]
        WebUI --> WebCtrl
    end

    %% Client Communication Paths
    SL -->|User Credentials & Tokens| FAuth
    SL -->|Real-time Snapshot Streams & Batch CRUD| Firestore
    SL -->|Multipart / Byte Uploads| FStorage
    SL -->|Bearer ID Token + HTTPS REST| Express
    SL -->|Direct Fallback Gemini Calls| Gemini
    UI -->|Checkout Modal / Razorpay SDK| RazorpayGateway

    %% Backend Communication Paths
    Express -->|Firebase Admin SDK Privileged Access| Firestore
    Express -->|Firebase Admin SDK Verify Tokens| FAuth
    RzpRoutes -->|Create Orders & Webhook Verify| RazorpayGateway
    AiQueue -->|HTTPS REST Prompts| Gemini

    %% Admin Portal Paths
    WebCtrl -->|Custom Admin Auth & API Calls| Express
    WebCtrl -->|Direct Admin Snapshot Queries| Firestore
    FHost -.->|Hosts Bundle| WebUI
```

---

## 🧩 Component-Level Architecture

The Flutter codebase is structured around a **layered architectural pattern with separation of concerns**:

### 1. Presentation Layer (`lib/views/` & `lib/widgets/`)
- **Views:** Structured by business domain:
  - `lib/views/general/`: `WelcomeView`, `RoleOptionView`, `McRoleOptionView`, `EmailVerificationView`, `SplashScreen`.
  - `lib/views/employer/`: `EmployerDashboardView`, `CreateJobView`, `EmployerJobsListView`, `CandidatesView`, `EmployerAiResumeMatcher`.
  - `lib/views/employee/`: `EmployeeDashboardView`, `EmployeeJobsListView`, `EmployeeJobDetailsView`, `JobApplicationView`, `MyApplicationsView`, `EmployeeAiResumeMatcher`.
  - `lib/maintenance_contracts/views/`: Provider views (`mc_provider_dashboard_view.dart`, `mc_add_service_view.dart`, `mc_request_management_view.dart`) and Seeker views (`mc_seeker_dashboard_view.dart`, `mc_seeker_catalog_view.dart`, `mc_seeker_bookings_view.dart`).
- **Widgets:** Modular reusable UI elements: `AnimatedSplashScreen`, `CustomPopup`, `NetworkIndicator`, `StatCard`, `SubscriptionGate`, `PremiumPaywall`, `EmployeeDrawer`, `EmployerDrawer`.
- **Responsive UI Engine:** Wrapped in [`Sizer`](file:///d:/Shinnovation/leox/lib/main.dart#L143-L165) (`sizer: ^3.1.3`), converting hardcoded layout pixels into proportional viewport units (`.w`, `.h`, `.sp`), ensuring pixel-perfect scaling across phones and tablets.

### 2. State Management Layer (`lib/providers/` & `lib/maintenance_contracts/controllers/`)
- Utilizes the **Provider** package (`provider: ^6.1.5+1`) with `ChangeNotifier`.
- 14 distinct providers configured in [`MultiProvider`](file:///d:/Shinnovation/leox/lib/main.dart#L79-L115) at the root widget tree:
  - Global: `ThemeProvider`, `ConnectivityProvider`, `SubscriptionProvider`.
  - Employer: `EmployerAuthProvider`, `EmployerDashboardProvider`, `EmployerJobsProvider`, `EmployerCandidatesProvider`, `EmployerProfileProvider`.
  - Employee: `EmployeeAuthProvider`, `EmployeeDashboardProvider`, `EmployeeJobsProvider`, `JobApplicationProvider`, `NotificationProvider`, `AIResumeMatcherProvider`.
  - Maintenance Contracts: `McProviderAuthController`, `McSeekerAuthController`, `McProviderDashboardController`, `McSeekerDashboardController`.
- **Reactivity Model:** Providers maintain live Firestore snapshot subscriptions (`StreamSubscription<QuerySnapshot>`). When documents are modified remotely, snapshot callbacks update private lists and invoke `notifyListeners()`, triggering targeted widget subtree rebuilds.

### 3. Business Logic & AI Layer (`lib/backend/ai_workflows.dart` & `lib/services/gemini_service.dart`)
- **PDF Extraction:** Uses `syncfusion_flutter_pdf` on the mobile device. `PdfDocument(inputBytes: bytes)` parses binary streams in-memory and extracts clean text strings via `PdfTextExtractor`, avoiding heavy cloud bandwidth usage.
- **AI Matching Pipeline:** Implements a dual-tier resilience strategy:
  1. *Primary Route:* Calls backend `POST /api/subscription/ai/match-resume` with user auth token.
  2. *Secondary Fallback:* If the backend is unreachable or times out, directly invokes client-side `GeminiService.matchResumeToJob` using `google_generative_ai` SDK (`gemini-3.6-flash`, falling back to `gemini-2.0-flash`).
  3. *Rate Limiting Graceful Degradation:* If rate limited (HTTP 429), the backend returns HTTP 202 Accepted and writes to the `pending_matches` collection in Firestore, informing the user that their analysis is queued.

### 4. Service & API Layer (`lib/services/`)
- [`ApiService`](file:///d:/Shinnovation/leox/lib/services/api_service.dart): Centralized HTTP client wrapping `package:http`. Implements static REST verbs (`get`, `post`, `put`, `delete`), timeout handling (5 minutes for heavy AI requests), and unified status-code exception parsing (`ApiException`).
- [`FirebaseService`](file:///d:/Shinnovation/leox/lib/services/firebase_service.dart): Encapsulates direct Firestore operations for jobs, applications, and profiles.
- [`SessionService`](file:///d:/Shinnovation/leox/lib/services/session_service.dart): In-memory session cache backed by `SharedPreferences` to eliminate asynchronous race conditions during login/logout.
- [`StorageService`](file:///d:/Shinnovation/leox/lib/services/storage_service.dart): Cross-platform file upload handler supporting web (`putData`) and mobile (`putFile`) with automatic content-type resolution.
- [`ConnectivityService`](file:///d:/Shinnovation/leox/lib/services/connectivity_service.dart): Background listener monitoring network availability with broadcast streams.

### 5. Backend Layer (`backend/server.js` & `backend/routes/subscription.js`)
- Express.js microservice hosted on Render (`https://leox-kfsm.onrender.com/api`).
- **Middleware:** CORS with white-listed origins, JSON parsing (`10mb` limit for resumes), Multer memory storage (`5MB` file limit).
- **Security Middleware:**
  - `requireAuth`: Verifies incoming Firebase Bearer ID tokens via `admin.auth().verifyIdToken(token)`.
  - `requireAdmin`: Enforces Firebase Custom Claims (`decodedToken.admin === true`).
- **Crypto & Webhooks:** Uses Node.js `crypto` module for HMAC-SHA256 signature verification (`orderId + '|' + paymentId`) and handles Razorpay webhooks for payment failures and refunds.

### 6. Administration Web Portal (`web_admin/`)
- Standalone Flutter Web project hosted on Firebase Hosting (`studio-7488920972-4ef9c.web.app`).
- Reuses parent models (`SubscriptionPlanModel`, `SubscriptionModel`).
- Requires Firebase Custom Claims (`claims['admin'] == true`). Includes bootstrap mode for initial owner setup when zero admins exist.

---

## 🔄 End-to-End Request Flows (Traced through Actual Code)

### Flow 1: User Registration, Login & Role-Based Navigation

```mermaid
sequenceDiagram
    autonumber
    actor User as User (Mobile Client)
    participant UI as Login / Welcome View
    participant Session as SessionService
    participant Auth as FirebaseAuth
    participant FStore as Cloud Firestore
    participant Main as Router (_MainAppContent)

    User->>UI: Selects Role (e.g., Employer) & enters credentials
    UI->>Session: saveTargetRole('employer')
    UI->>Auth: signInWithEmailAndPassword(email, password)
    Auth-->>UI: Returns UserCredential (FirebaseUser)
    Auth->>Main: authStateChanges() emits User
    Main->>Main: Check user.emailVerified (skip if test user)
    Main->>Main: Call _getUserRole(uid)
    Main->>Session: getTargetRole() -> Found 'employer'
    Note over Main,Session: Target role cached pre-login enables instant zero-latency routing
    Main->>Session: saveRoleOnly('employer')
    Main-->>UI: Renders EmployerDashboardView
    
    alt If Target Role Cache Misses
        Main->>FStore: Query collection('users').doc(uid)
        alt Doc exists & has role
            FStore-->>Main: Returns role ('employer')
        else Doc missing or slow network write
            loop Up to 10 retries with 2s delays
                Main->>FStore: Fallback check 'employers', 'employees', 'mc_providers', 'mc_seekers'
            end
        end
        Main->>Session: saveSession(role, uid, email, token)
        Main-->>UI: Navigates to appropriate Dashboard
    end
```

**Code Trace:**
1. User role selection in [`lib/views/general/role_option_view.dart`](file:///d:/Shinnovation/leox/lib/views/general/role_option_view.dart#L80-L86).
2. Credentials submitted to [`EmployerAuthProvider.signIn`](file:///d:/Shinnovation/leox/lib/providers/employer_auth_provider.dart).
3. Auth state stream observed in [`lib/main.dart`](file:///d:/Shinnovation/leox/lib/main.dart#L174-L281).
4. `_getUserRole` fast-path execution in `lib/main.dart` lines 287–312 using [`SessionService.getTargetRole()`](file:///d:/Shinnovation/leox/lib/services/session_service.dart#L34-L39).
5. 10-attempt retry loop with 2-second delays querying `users`, `employers`, `employees`, `mc_providers`, and `mc_seekers` collections (`lib/main.dart` lines 319–407).
6. Routing to `EmployerDashboardView`, `EmployeeDashboardView`, `McProviderDashboardView`, or `McSeekerDashboardView`.

---

### Flow 2: Creating and Managing a Hiring Job Posting

```mermaid
sequenceDiagram
    autonumber
    actor Emp as Employer
    participant UI as CreateJobView
    participant Prov as EmployerJobsProvider
    participant Gate as SubscriptionGate
    participant FServ as FirebaseService
    participant Rules as firestore.rules
    participant FStore as Cloud Firestore (jobs)

    Emp->>UI: Fills Title, Department, Category, Salary, Skills, Requirements
    UI->>Gate: Evaluates hasFeature('post_jobs')
    Gate-->>UI: Access Granted (Active subscription or 30-day trial)
    Emp->>UI: Clicks "Post Job"
    UI->>Prov: addJob(JobModel)
    Prov->>FServ: postJob(JobModel)
    FServ->>Rules: POST /jobs (Evaluate request.auth & isEmployer())
    Note over Rules: isEmployer() verifies UID exists in /users (role=='employer') or in /employers
    Rules-->>FStore: Allow write
    FStore-->>FServ: Job document created with Timestamp.now()
    FStore->>Prov: Real-time snapshots() stream triggers!
    Prov->>Prov: Sort jobs by postedOn DESC in-memory
    Prov->>UI: notifyListeners() updates EmployerJobsListView instantly
```

**Code Trace:**
1. Form validation and field capture in `lib/views/employer/create_job_view.dart`.
2. Feature authorization check in [`SubscriptionGate`](file:///d:/Shinnovation/leox/lib/widgets/subscription_gate.dart) querying [`SubscriptionProvider.hasFeature('post_jobs')`](file:///d:/Shinnovation/leox/lib/providers/subscription_provider.dart#L132-L193).
3. Call dispatched to [`EmployerJobsProvider.addJob`](file:///d:/Shinnovation/leox/lib/providers/employer_jobs_provider.dart#L91-L101).
4. Delegated to [`FirebaseService.postJob`](file:///d:/Shinnovation/leox/lib/services/firebase_service.dart#L18-L56).
5. Authorization enforced by `firestore.rules` lines 64–78 (`isEmployer()` rule).
6. Document stored with schema fields: `title`, `department`, `category`, `description`, `requirements`, `skills`, `postedBy`, `status: 'Open'`, `applicationCount: 0`.
7. Real-time snapshot listener in `EmployerJobsProvider.loadJobs()` lines 46–86 automatically updates list.

---

### Flow 3: Candidate Application & AI Resume Matching Workflow

```mermaid
sequenceDiagram
    autonumber
    actor Cand as Candidate (Employee)
    participant UI as JobApplicationView / AI Matcher
    participant Prov as JobApplicationService
    participant PDF as Syncfusion Flutter PDF
    participant FStorage as Firebase Storage
    participant Backend as Express Backend
    participant Gemini as Google Gemini AI
    participant FStore as Cloud Firestore

    Cand->>UI: Selects PDF Resume file
    UI->>Prov: pickResumeFile()
    Prov->>PDF: PdfDocument(inputBytes: file.bytes)
    PDF-->>Prov: PdfTextExtractor.extractText() (Clean ASCII text)
    Prov->>FStorage: uploadFileBytes() -> stores in /applications/
    Cand->>UI: Clicks "Submit Application"
    UI->>Prov: submitApplication(jobId, coverLetter, resumeFile)
    Prov->>FStore: Query /applications where employeeId == uid && jobId == jobId
    Note over Prov: Enforce rule: Max 2 applications per job by an employee
    
    rect rgb(240, 248, 255)
        Note over Prov,Gemini: AI Semantic Matching Step
        Prov->>Backend: POST /api/subscription/ai/match-resume {resumeText, jobDescription}
        alt Backend Success
            Backend->>Gemini: POST /v1beta/models/gemini-3.6-flash:generateContent
            Gemini-->>Backend: Structured JSON response
            Backend-->>Prov: {overallScore: 88, skillsMatch: 92, analysis, gaps, recommendations}
        else Backend Rate Limited (HTTP 429)
            Backend->>FStore: Queue into collection('pending_matches')
            Backend-->>Prov: HTTP 202 Accepted {rateLimited: true}
        else Backend Offline / Fallback
            Prov->>Gemini: Direct client-side GeminiService.matchResumeToJob()
        end
    end

    Prov->>FStore: Add document to collection('applications') with matchScore & matchReasoning
    Prov->>FStore: Increment collection('jobs').doc(jobId).applicationCount (+1)
    Prov->>FStore: Write notification to collection('notifications') for Employer
    Prov-->>UI: Application successfully submitted!
```

**Code Trace:**
1. User triggers upload in [`lib/providers/ai_resume_matcher_provider.dart`](file:///d:/Shinnovation/leox/lib/providers/ai_resume_matcher_provider.dart#L40-L101).
2. Binary extraction via `PdfDocument` and `PdfTextExtractor` (`ai_resume_matcher_provider.dart` lines 69–82).
3. Application submission initiated in [`lib/services/job_application_service.dart`](file:///d:/Shinnovation/leox/lib/services/job_application_service.dart#L36-L100).
4. Validation rule: `existingSnapshot.docs.length >= 2` prevents duplicate spam (`job_application_service.dart` lines 57–65).
5. Storage upload via [`StorageService.uploadPlatformFile`](file:///d:/Shinnovation/leox/lib/services/storage_service.dart) to path `applications/${uid}_${jobId}_resume.ext`.
6. AI evaluation in [`AIWorkflows.matchResumeToJob`](file:///d:/Shinnovation/leox/lib/backend/ai_workflows.dart#L53-L113) with primary backend call and client-side `GeminiService` fallback.
7. Express route in [`backend/routes/subscription.js`](file:///d:/Shinnovation/leox/backend/routes/subscription.js#L942-L1044). On HTTP 429, writes to Firestore `pending_matches` collection (`queueId = match_${userId}_${Date.now()}`).
8. Application written to `applications` collection in Firestore with `matchScore` and `matchReasoning` (`job_application_service.dart` lines 247–250).
9. Employer notification generated via [`NotificationService`](file:///d:/Shinnovation/leox/lib/services/notification_service.dart).

---

### Flow 4: Subscription Checkout, Razorpay Payment & Cryptographic Verification

```mermaid
sequenceDiagram
    autonumber
    actor User as Mobile App User
    participant Paywall as PremiumPaywall Widget
    participant SubProv as SubscriptionProvider
    participant Express as Node.js Backend (/api/subscription)
    participant Razorpay as Razorpay Gateway
    participant FStore as Cloud Firestore

    User->>Paywall: Selects Plan & enters Coupon Code
    Paywall->>FStore: Query /coupons/{code} (validates expiry, maxUses, role)
    Paywall->>SubProv: createCheckoutOrder(planId, billingCycle, couponCode)
    SubProv->>Express: POST /create-order (Bearer ID Token)
    Express->>Express: requireAuth middleware (decodes token)
    Express->>FStore: Fetch plan details & apply coupon discount
    Express->>Razorpay: razorpay.orders.create({amount: paise, currency: 'INR', notes})
    Razorpay-->>Express: Returns Razorpay Order Object (id: 'order_xxx')
    Express-->>SubProv: {success: true, orderId, amount, key}
    SubProv-->>Paywall: Opens Razorpay Checkout Native SDK
    
    User->>Razorpay: Completes payment (UPI / Card / NetBanking)
    Razorpay-->>Paywall: Returns {razorpay_order_id, razorpay_payment_id, razorpay_signature}
    
    rect rgb(255, 245, 238)
        Note over Paywall,Express: Server-Side Cryptographic Signature Verification
        Paywall->>SubProv: verifyPaymentSignature(orderId, paymentId, signature, planId)
        SubProv->>Express: POST /verify-payment
        Express->>Express: crypto.createHmac('sha256', secret).update(orderId + '|' + paymentId).digest('hex')
        alt Signature Matches
            Express->>FStore: Write to collection('payments').doc(paymentId) (status: 'captured')
            Express->>FStore: Update collection('subscriptions').doc(`${userId}_${role}`)
            Note over Express,FStore: Sets status: 'active', startDate, endDate (+1 month / +1 year)
            Express-->>SubProv: {success: true, message: 'Subscription active'}
            SubProv->>FStore: Real-time listener detects updated subscription
            SubProv-->>Paywall: Notifies listeners -> Dismisses paywall & unlocks feature!
        else Signature Mismatch
            Express-->>SubProv: HTTP 400 {error: 'Signature verification failed. Potential tampering.'}
            SubProv-->>Paywall: Shows Verification Failed Alert
        end
    end
```

**Code Trace:**
1. User enters coupon and initiates checkout in [`lib/widgets/premium_paywall.dart`](file:///d:/Shinnovation/leox/lib/widgets/premium_paywall.dart#L230-L280).
2. Coupon validated against Firestore `/coupons/{code}` rules (`premium_paywall.dart` lines 152–228).
3. Order creation requested via [`SubscriptionProvider.createCheckoutOrder`](file:///d:/Shinnovation/leox/lib/providers/subscription_provider.dart#L196-L233).
4. Backend route [`POST /api/subscription/create-order`](file:///d:/Shinnovation/leox/backend/routes/subscription.js#L57-L240):
   - Decodes token via `requireAuth`.
   - Computes base price and coupon discounts (percentage or fixed INR).
   - Generates Razorpay Order via `razorpay.orders.create({amount: amountInPaise, currency: 'INR', receipt, notes})`.
5. Mobile client opens Razorpay SDK via `_razorpay.open(options)` in `premium_paywall.dart` lines 349.
6. On success callback `_handlePaymentSuccess`, dispatches credentials to [`SubscriptionProvider.verifyPaymentSignature`](file:///d:/Shinnovation/leox/lib/providers/subscription_provider.dart#L236-L279).
7. Backend verification route [`POST /api/subscription/verify-payment`](file:///d:/Shinnovation/leox/backend/routes/subscription.js#L246-L358):
   - Computes HMAC SHA-256: `crypto.createHmac('sha256', keySecret).update(orderId + '|' + paymentId).digest('hex')`.
   - Compares with `razorpaySignature`.
   - Persists payment document in `payments` collection with status `'captured'`.
   - Activates subscription in Firestore collection `subscriptions` doc `${userId}_${role}` with updated `endDate`.
8. Firestore snapshot listener in `SubscriptionProvider.listenToSubscription()` automatically refreshes subscription state on the client, unlocking gated features.

---

### Flow 5: Web Admin Plan & Coupon Management

```mermaid
sequenceDiagram
    autonumber
    actor Admin as System Administrator
    participant Web as Flutter Web Admin (Firebase Hosting)
    participant Back as Express Backend
    participant FAuth as Firebase Auth
    participant FStore as Cloud Firestore

    Admin->>Web: Submits Admin Email & Password
    Web->>Back: POST /api/subscription/admin/login {email, password}
    Back->>FStore: Query collection('admins').doc(adminDocId)
    Back->>Back: verifyPassword(password, storedSaltHash) using PBKDF2
    Back->>FAuth: createCustomToken(docId, { admin: true })
    Back-->>Web: Returns customToken
    Web->>FAuth: signInWithCustomToken(customToken)
    Web->>Web: user.getIdTokenResult(true) -> verifies claims['admin'] == true
    Web-->>Admin: Displays AdminDashboardShell
    
    Admin->>Web: Creates New Coupon (CODE: 'OFF50', 50% discount)
    Web->>FStore: Direct write to collection('coupons').doc('OFF50')
    Note over FStore: firestore.rules checks request.auth.token.admin == true
    FStore-->>Web: Coupon successfully created
```

**Code Trace:**
1. Admin login screen in [`web_admin/lib/main.dart`](file:///d:/Shinnovation/leox/web_admin/lib/main.dart#L191-L250).
2. Verification endpoint [`POST /api/subscription/admin/login`](file:///d:/Shinnovation/leox/backend/routes/subscription.js#L551-L591):
   - Checks document in Firestore `admins` collection.
   - Verifies password using PBKDF2: `crypto.pbkdf2Sync(password, salt, 1000, 64, 'sha512')`.
   - Generates Firebase Custom Token with claim `{ admin: true }` via `admin.auth().createCustomToken(docId, { admin: true })`.
3. Web client authenticates via `FirebaseAuth.instance.signInWithCustomToken()`.
4. `AuthWrapper` inspects `getIdTokenResult()` claims (`web_admin/lib/main.dart` lines 161–184).
5. Authorized admin directly writes to `subscription_plans` and `coupons` collections, permitted by `firestore.rules` line 138 (`isAdmin()`).
