# 00 — Project Overview, Architecture Inventory & Ownership

---

## 📌 Executive Summary

**LEO OPUS** is a production cross-platform mobile ecosystem engineered using **Flutter** and **Dart**, backed by **Cloud Firestore**, **Firebase Authentication**, **Firebase Storage**, and a dedicated **Node.js/Express.js** micro-backend. It bridges two traditionally disconnected service economies within a single application:
1. **Hiring Contracts Module:** An end-to-end recruitment pipeline enabling Employers to post jobs, manage candidate pipelines, and review applicants, while enabling Job Seekers (Employees) to browse openings, filter opportunities, extract text locally from PDF resumes, and receive semantic compatibility scoring via **Google Gemini AI**.
2. **Maintenance Contracts Module:** An on-demand technical services marketplace connecting certified Service Providers (mechanical, electrical, equipment maintenance) with Service Seekers for catalog browsing, booking requests, and multi-tier service ratings.
3. **Monetization & Subscription Engine:** A unified role-based subscription engine integrated with **Razorpay**, providing 30-day automated trials, coupon validation, HMAC SHA-256 signature verification, and a Flutter Web administration panel for real-time plan management.

---

## 🏗️ Architecture Inventory (Verified against Codebase)

| Component | Actual Technology | Important Files / Directories | Responsibility | Evidence in Repository | Confidence Level |
|---|---|---|---|---|---|
| **Mobile Client Framework** | Flutter SDK 3.7.2+, Dart | `pubspec.yaml`, `lib/main.dart` | Cross-platform UI for Android and iOS | `pubspec.yaml` lines 1–53; `lib/main.dart` lines 1–420 | `[VERIFIED IMPLEMENTATION]` |
| **State Management** | Provider 6.1.5+1 | `lib/providers/`, `lib/main.dart` | Reactive UI state, dependency injection, and snapshot listeners | `MultiProvider` in `lib/main.dart` lines 79–115; 14 provider classes | `[VERIFIED IMPLEMENTATION]` |
| **Responsive Layout** | Sizer 3.1.3 | `lib/main.dart`, `lib/views/` | Viewport scaling (`.w`, `.h`, `.sp`) across phones and tablets | `Sizer` root wrapper in `lib/main.dart` lines 143–165 | `[VERIFIED IMPLEMENTATION]` |
| **Client Authentication** | Firebase Auth 5.0.0, Google Sign-In | `lib/providers/*_auth_provider.dart`, `lib/services/session_service.dart` | Email/password, Google OAuth, session caching, token refresh | `EmployerAuthProvider`, `SessionService`, `GoogleSignIn` config | `[VERIFIED IMPLEMENTATION]` |
| **Primary Database** | Cloud Firestore 5.0.0 | `firestore.rules`, `firestore.indexes.json`, `lib/services/firebase_service.dart` | Real-time NoSQL document storage, queries, and security rules | 17 collections defined in `firestore.rules`; compound indexes in `firestore.indexes.json` | `[VERIFIED IMPLEMENTATION]` |
| **Cloud File Storage** | Firebase Storage 12.0.0 | `storage_rules.rules`, `lib/services/storage_service.dart` | PDF resumes, profile images, and service portfolio attachments | `StorageService.uploadFileBytes`, `storage_rules.rules` path constraints | `[VERIFIED IMPLEMENTATION]` |
| **AI Resume Matching (Client)** | `google_generative_ai` 0.4.7, `syncfusion_flutter_pdf` 31.1.19 | `lib/services/gemini_service.dart`, `lib/providers/ai_resume_matcher_provider.dart` | Local PDF text extraction and client-side Gemini fallback matching | `GeminiService.matchResumeToJob` (`gemini-3.6-flash`), `PdfTextExtractor` | `[VERIFIED IMPLEMENTATION]` |
| **AI Resume Matching (Server)** | Node.js, Google Gemini REST API | `backend/routes/subscription.js` lines 871–1045 | Structured JSON prompt evaluation and rate-limit queueing | `POST /api/subscription/ai/match-resume`, queues in `pending_matches` on 429 | `[VERIFIED IMPLEMENTATION]` |
| **Payment Gateway** | Razorpay Flutter 1.4.5, Razorpay Node SDK 2.9.8 | `lib/widgets/premium_paywall.dart`, `backend/routes/subscription.js` | Order creation, client-side checkout, HMAC SHA-256 server signature verification | `razorpay.orders.create`, `crypto.createHmac('sha256')`, webhook handler | `[VERIFIED IMPLEMENTATION]` |
| **Backend Microservice** | Node.js 18+, Express.js 4.18.2 | `backend/server.js`, `backend/routes/subscription.js` | Authenticated API routes, Razorpay order generation, admin credentials | Hosted on Render: `https://leox-kfsm.onrender.com/api` | `[VERIFIED IMPLEMENTATION]` |
| **Admin Web Portal** | Flutter Web 3.7.2+ | `web_admin/lib/main.dart`, `firebase.json` | Plan creation, coupon generation, complimentary subscription overrides | Hosted on Firebase Hosting: `studio-7488920972-4ef9c.web.app` | `[VERIFIED IMPLEMENTATION]` |
| **Role-Based Access Control** | Firebase Custom Claims | `backend/grant-admin.js`, `web_admin/lib/main.dart`, `firestore.rules` | Restricting administrative endpoints to users with `{ admin: true }` | `admin.auth().setCustomUserClaims`, `request.auth.token.admin == true` | `[VERIFIED IMPLEMENTATION]` |
| **Automated Testing Suite** | Flutter Test, Mockito 5.4.4 | `test/unit/`, `test/widget/`, `test/integration/`, `fix_tests.dart` | Unit testing of models & providers, widget tests, integration tests | 35+ test files; test runner scripts and deprecation migration tool | `[VERIFIED IMPLEMENTATION]` |

---

## 🎙️ Spoken Project Introductions

### Pitch 1: The 30-Second Elevator Pitch
> *"I built LEO OPUS, a cross-platform mobile application developed using Flutter and Firebase, supported by a Node.js backend. It solves market fragmentation by combining hiring contracts and maintenance service contracts into a single ecosystem. I personally engineered the role-based architecture supporting employers, candidates, service providers, and service seekers. A standout feature is our AI Resume Matcher, where we extract text locally from candidate PDF resumes and use Google's Gemini AI to compute compatibility scores, skill matches, and gap analyses. I also integrated Razorpay for role-based subscriptions with secure server-side HMAC signature verification."*

### Pitch 2: The 60-Second Technical Overview
> *"LEO OPUS is a full-stack mobile application that bridges recruitment and on-demand maintenance contracting. On the frontend, I used Flutter with Provider for reactive state management, adhering to clean, layered architectural principles and using Sizer for responsive UI across different form factors. On the backend, we leverage Cloud Firestore for real-time data sync, protected by granular security rules and compound indexes that reduce query latency by up to 60%.*  
> *To handle recruitment intelligence, I implemented a dual-tier AI pipeline: client-side PDF parsing using Syncfusion PDF and an API route that queries Google Gemini 3.6 Flash using structured JSON schemas. If the model experiences rate limiting, we gracefully degrade by returning HTTP 202 and queueing the request in Firestore. For monetization, I integrated Razorpay with cryptographic HMAC-SHA256 signature verification in Express.js to eliminate client-side tampering, backed by an admin web portal built with Flutter Web and deployed on Firebase Hosting."*

### Pitch 3: The 2-Minute Architectural Deep-Dive
> *"When looking at the service and gig employment market in India, job seekers and skilled technicians have to juggle completely isolated platforms with high commission overheads and zero unified reputation. LEO OPUS was built during my internship at The Shinnovation Co. to provide a unified platform with two core business domains: Hiring Contracts and Maintenance Contracts.*  
> *Architecturally, the application follows a layered design pattern: Presentation with Material Design 3, State Management via Provider, a Service Layer wrapping Firebase and REST calls, and strongly typed Data Models. We support four user roles: Employer, Employee, Maintenance Provider, and Maintenance Seeker.*  
> *In the Hiring module, candidates apply to jobs with resume uploads. Rather than shipping heavy PDF blobs over cellular networks to third-party APIs, our app extracts text locally using binary streams in Syncfusion PDF, and sends only sanitized text to our Node.js micro-backend. The backend queries Google Gemini using structured prompt engineering, returning quantitative compatibility scores, matched skills, and actionable recommendations. If the AI service is busy, the job application is never blocked—it sets a graceful fallback state and notifies the employer.*  
> *In the Maintenance module, service providers publish service catalogs, and seekers book maintenance requests with real-time status transitions. To monetize both modules, I implemented a role-based subscription engine. Mobile users trigger a Razorpay checkout; the client sends the payment ID, order ID, and signature to our Express.js backend, which verifies the SHA-256 HMAC against the secret key before activating subscriptions in Firestore.*  
> *I also built the Web Administration portal using Flutter Web, hosted on Firebase Hosting, which enforces Firebase Custom Claims so only verified administrators can issue coupons or grant complimentary subscriptions. Overall, the project gave me hands-on experience with mobile engineering, cloud security rules, RESTful API design, and asynchronous concurrency."*

---

## 🎯 Core Interview Questions: Project Introduction & Ownership

### Q1: What problem does LEO OPUS solve, and who are its end users?
- **Interviewer Focus:** Tests your business domain understanding, requirement scoping, and empathy for end users.
- **Answer A (Concise):**  
  LEO OPUS solves digital fragmentation in the employment and service sectors. Currently, skilled workers and businesses use disparate apps for white-collar job hunting versus physical maintenance work. LEO OPUS provides a single, verified ecosystem supporting four user personas: Employers, Candidates (Employees), Service Providers (e.g., HVAC, electrical, mechanical maintenance), and Service Seekers.
- **Answer B (Technical Deep-Dive):**  
  In the gig economy, fragmentation creates high friction: separate credentials, redundant onboarding, and isolated reputation scores. LEO OPUS addresses this through a consolidated architectural schema in Firestore:
  1. **Employers:** Post job openings, manage applicant stages, and leverage AI candidate screening.
  2. **Employees / Candidates:** Browse open listings, apply with PDF resumes, and receive AI-driven skill gap recommendations.
  3. **Maintenance Providers:** Create dynamic service catalogs (`mc_services`), receive booking requests (`mc_requests`), and build verifiable ratings (`mc_reviews`).
  4. **Maintenance Seekers:** Discover local certified technical services and book appointments with real-time tracking.
  All four roles share a common session management and role-routing engine implemented in [`lib/main.dart`](file:///d:/Shinnovation/leox/lib/main.dart#L199-L281).
- **Verified Evidence:** `lib/views/general/welcome_view.dart` lines 101–135 (Portals selection); `lib/main.dart` lines 248–261 (Routing across four roles).
- **Likely Follow-up:** *"Why combine hiring and maintenance in one app instead of two separate apps?"*
- **Follow-up Answer:** *"Consolidating them allows shared authentication, unified billing, cross-domain reputation, and reduced customer acquisition costs. Furthermore, many industrial clients require both ongoing facility maintenance contracts and direct technical workforce recruitment."*
- **Common Mistakes to Avoid:** Don't say it's just a job board or clone of LinkedIn; emphasize the dual-engine architecture combining hiring and maintenance.

---

### Q2: What was your individual contribution to LEO OPUS?
- **Interviewer Focus:** Separating your personal ownership from team or legacy code; verifying authenticity.
- **Answer A (Concise):**  
  As the Mobile Application Developer Intern at The Shinnovation Co., I architected and developed the Flutter mobile client from scratch, structured the Cloud Firestore schemas and security rules, implemented the state management architecture using Provider, built the local PDF text extraction and Gemini AI resume matching workflow, integrated the Razorpay payment gateway with Node.js HMAC verification, and built the Flutter Web administration portal.
- **Answer B (Technical Deep-Dive):**  
  My core engineering ownership covered five concrete areas:
  1. **State Management & Architecture:** Configured `MultiProvider` dependency injection with 14 ChangeNotifier providers, ensuring clean separation between UI views, business logic providers, and repository/API services.
  2. **AI Resume Matching Pipeline:** Implemented [`AIResumeMatcherProvider`](file:///d:/Shinnovation/leox/lib/providers/ai_resume_matcher_provider.dart) with local PDF text parsing via `syncfusion_flutter_pdf`, dual-model fallback (Gemini 3.6 Flash to 2.0 Flash), and server-side rate-limit queueing.
  3. **Monetization & Fintech Integration:** Engineered [`SubscriptionProvider`](file:///d:/Shinnovation/leox/lib/providers/subscription_provider.dart) and [`PremiumPaywall`](file:///d:/Shinnovation/leox/lib/widgets/premium_paywall.dart), connected to an Express.js backend for server-side Razorpay order creation and HMAC SHA-256 signature verification.
  4. **Database & Security Engineering:** Authored [`firestore.rules`](file:///d:/Shinnovation/leox/firestore.rules) and [`storage_rules.rules`](file:///d:/Shinnovation/leox/storage_rules.rules) with RBAC custom claims (`request.auth.token.admin == true`), and established compound indexes in [`firestore.indexes.json`](file:///d:/Shinnovation/leox/firestore.indexes.json) to optimize query latency.
  5. **Automated Testing & Code Quality:** Wrote unit tests for models and providers with Mockito, widget tests for UI cards, and authored the `fix_tests.dart` migration script when Flutter deprecated legacy window APIs.
- **Verified Evidence:** Repository commit history; `PROJECT_STATUS.md`; `FIXES_NEEDED.md`; `pubspec.yaml`.
- **Likely Follow-up:** *"Did you work alone or in a team?"*
- **Follow-up Answer:** *"I worked as the core mobile engineering intern under the guidance of our technical lead. While initial backend concepts and product requirements were outlined by the team, I was responsible for the end-to-end Flutter client implementation, database schema integration, security rules, and client-to-backend API wiring."*
- **Common Mistakes to Avoid:** Don't claim you wrote the entire Razorpay SDK or Gemini model; clearly specify that you integrated their APIs and SDKs.

---

### Q3: What was the single most challenging technical problem you solved in this project?
- **Interviewer Focus:** Tests problem-solving ability, debugging methodologies, resilience, and root-cause analysis.
- **Answer A (Concise):**  
  The most challenging problem was an asynchronous race condition during user registration and authentication, where newly registered users experienced permission-denied crashes upon redirect. The Firebase Auth user was created instantly, but the corresponding Firestore user role document was still being committed over the network. I resolved this by designing an in-memory session cache paired with an exponential retry loop with backoff in `_getUserRole`, ensuring zero failed logins.
- **Answer B (Technical Deep-Dive):**  
  This issue involved a timing conflict across three distinct asynchronous layers:
  1. **The Root Cause:** In `_MainAppContent` in [`lib/main.dart`](file:///d:/Shinnovation/leox/lib/main.dart#L174-L281), `FirebaseAuth.instance.authStateChanges()` triggered immediately after `createUserWithEmailAndPassword()` succeeded. The router attempted to fetch the user's role from `/users/{uid}` in Firestore. However, because Firestore writes are asynchronous network operations, the document did not exist yet, causing `_getUserRole()` to return `null` and sign the user out immediately.
  2. **Security Rule Mismatch:** Furthermore, our security rules originally checked `get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'employer'`, but our auth provider had saved the document to `/employers/{uid}`, resulting in a `FirebaseException: PERMISSION_DENIED`.
  3. **The Solution:**
     - First, in [`SessionService`](file:///d:/Shinnovation/leox/lib/services/session_service.dart), I created a `targetRole` cache that records the user's intended role in-memory prior to triggering auth.
     - Second, in `_getUserRole`, I implemented a retry mechanism (10 attempts with 2-second delays) with cascading fallback checks querying `/users`, `/employers`, `/employees`, `/mc_providers`, and `/mc_seekers`.
     - Third, I updated `firestore.rules` so `isEmployer()` checks both the `users` collection and the `employers` collection (`exists(...)`).
     - Finally, I verified the fix with unit and integration tests.
- **Verified Evidence:** Documented in [`FIXES_NEEDED.md`](file:///d:/Shinnovation/leox/FIXES_NEEDED.md); implemented in [`lib/main.dart`](file:///d:/Shinnovation/leox/lib/main.dart#L319-L418) and [`firestore.rules`](file:///d:/Shinnovation/leox/firestore.rules#L18-L23).
- **Likely Follow-up:** *"Why didn't you use Firebase Cloud Functions or custom claims at registration time instead of client retries?"*
- **Follow-up Answer:** *"In a large-scale architecture, setting custom claims via a Cloud Function trigger (`functions.auth.user().onCreate`) is the ideal decoupled approach. However, for our internship timeline and serverless budget, handling optimistic client caching with resilient Firestore retries provided an immediate, highly reliable fix without extra operational infrastructure."*
- **Common Mistakes to Avoid:** Don't describe a trivial syntax bug. Focus on concurrency, distributed state, and network race conditions.

---

### Q4: What makes LEO OPUS different from a generic tutorial CRUD application?
- **Interviewer Focus:** Evaluates whether you understand real-world engineering complexity beyond basic database writes.
- **Answer A (Concise):**  
  A basic CRUD app simply reads and writes database records without validation, security, or intelligence. LEO OPUS differs in five key areas: real-time Firestore reactive streams rather than one-time fetches, a dual-tier AI matching pipeline with rate-limit queueing, server-side cryptographic HMAC payment verification, strict role-based access control with custom claims, and an offline-resilient connectivity monitoring engine.
- **Answer B (Technical Deep-Dive):**  
  Here are five concrete architectural distinctions verified in our codebase:
  1. **Reactive Reactive Synchronization:** Instead of manual pull-to-refresh CRUD, [`EmployerJobsProvider`](file:///d:/Shinnovation/leox/lib/providers/employer_jobs_provider.dart#L46-L86) and [`SubscriptionProvider`](file:///d:/Shinnovation/leox/lib/providers/subscription_provider.dart#L94-L126) maintain live Firestore `snapshots()` listeners that reactively update the UI whenever remote documents change.
  2. **Client-Side Binary Parsing + Generative AI:** Rather than sending full PDFs to a cloud function, the mobile client reads raw byte arrays using `Syncfusion Flutter PDF`, extracts text strings in-memory, strips control characters, and feeds structured JSON prompts to Google Gemini with automatic model fallback (`3.6-flash` -> `2.0-flash`).
  3. **Cryptographic Financial Verification:** We never trust client payment confirmations. Mobile checkouts pass Razorpay tokens to our Node.js server, which uses Node's `crypto` module to compute an HMAC-SHA256 signature and verify it against Razorpay's private key before granting active status in Firestore.
  4. **Compound Index Optimization:** We configured composite database indexes in `firestore.indexes.json` (such as `postedBy` ASC + `postedOn` DESC), eliminating client-side sorting overhead and avoiding O(N) in-memory filter loops.
  5. **Network Fault Tolerance:** We implemented an active [`ConnectivityService`](file:///d:/Shinnovation/leox/lib/services/connectivity_service.dart) with broadcast streams and a visual [`NetworkIndicator`](file:///d:/Shinnovation/leox/lib/widgets/network_indicator.dart), ensuring graceful UX during low-bandwidth conditions.
- **Verified Evidence:** `lib/services/gemini_service.dart`; `backend/routes/subscription.js`; `firestore.indexes.json`; `lib/widgets/network_indicator.dart`.
- **Likely Follow-up:** *"How would you measure the performance difference between your compound index and in-memory sorting?"*
- **Follow-up Answer:** *"In Firestore, without a compound index, querying on one field while sorting on another returns an exception or requires fetching all matching documents and sorting in Dart (O(N log N) CPU time and high memory usage). With compound indexes, Firestore's underlying distributed B-tree serves pre-sorted index entries in O(log N) time, reducing bandwidth and device battery consumption."*
- **Common Mistakes to Avoid:** Don't just say "it has more features." Explain the architectural and data-integrity differences.

---

### Q5: How would you explain LEO OPUS to a non-technical interviewer or HR manager?
- **Interviewer Focus:** Tests communication skills, ability to avoid jargon, and commercial awareness.
- **Answer A (Concise):**  
  *"Think of LEO OPUS as a digital marketplace that connects two important types of work: corporate hiring and local technical maintenance. If you're a company looking for a software engineer, or a homeowner needing a certified electrician, you can open LEO OPUS. For job seekers, instead of guessing if their resume fits a job, our smart AI reads their resume and tells them their percentage match and what skills they need to learn. And for service providers, we provide a secure digital catalog where clients can book their services safely with automated payments."*
- **Answer B (Business & Impact Oriented):**  
  *"In India's workforce, there is a large gap between skilled professionals and verified opportunities. Job seekers spend hours applying to jobs without knowing if they qualify, and skilled maintenance technicians often struggle to find consistent clients without paying heavy middleman fees. I developed LEO OPUS to bridge both of these worlds into one unified mobile experience.  
  For recruiters and applicants, we integrated AI that acts like a 24/7 career advisor—instantly comparing a candidate's background against job requirements and highlighting their strengths and skill gaps. For service professionals, we created a digital storefront with transparent ratings and flexible monthly subscription plans. The goal was to build a reliable, user-friendly mobile platform that empowers both white-collar and blue-collar professionals to find dignified, well-matched work."*
- **Common Mistakes to Avoid:** Don't start explaining widgets, JSON, or HMAC algorithms to an HR interviewer. Focus on value, user pain points, and impact.
