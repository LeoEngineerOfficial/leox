# 20 — Implementation Audit, Integrity Boundaries & Clarifications

---

## ⚖️ Project Integrity & Fact-Checking Guide

To ensure you speak with absolute honesty and confidence in your interview, this document outlines the exact boundary between **verified existing implementations** and **theoretical / proposed features**. Never claim something was implemented if the code does not support it.

### Verified Facts vs Common Traps

| Feature / Claim | Verified Status | What the Repository Code Actually Shows | How to Answer Honestly in an Interview |
|---|---|---|---|
| **Razorpay Payments** | `[VERIFIED]` for Subscriptions; `[PROPOSED]` for Milestone Escrow | Razorpay is fully integrated for role-based subscription plans in `lib/widgets/premium_paywall.dart` and `backend/routes/subscription.js`. Milestone escrow contracts for individual maintenance bookings are described in project documentation, but in code, payments are handled via the subscription tier. | *"I implemented Razorpay for our role-based subscription engine. For maintenance contracts, our current version uses subscriptions to gate service catalog access; per-booking milestone escrow was designed in our roadmap."* |
| **AI Resume Matching** | `[VERIFIED IMPLEMENTATION]` | Client-side PDF text extraction via `syncfusion_flutter_pdf`, Gemini 3.6 Flash / 2.0 Flash prompt flows, and backend rate-limit queueing (`pending_matches`). | Explain the dual-tier architecture: local PDF parsing + server-side prompt engineering with fallback. |
| **Database Compound Indexes** | `[VERIFIED IMPLEMENTATION]` | Defined in `firestore.indexes.json` (jobs by postedBy/postedOn; applications by employeeId/appliedAt). | Confidently explain how composite B-trees eliminated in-memory sorting overhead. |
| **Web Administration Panel** | `[VERIFIED IMPLEMENTATION]` | Flutter Web app in `web_admin/`, deployed on Firebase Hosting (`studio-7488920972-4ef9c.web.app`), enforcing custom claims `{ admin: true }`. | Explain that it shares models with the mobile app and manages plans/coupons. |
| **Automated Testing** | `[VERIFIED IMPLEMENTATION]` | Unit tests for models & providers in `test/unit/`, widget tests in `test/widget/`, Mockito mocking, and `fix_tests.dart` migration script. | Highlight that you wrote unit and widget tests and solved Flutter 3.10+ deprecations. |
| **Custom Matching Algorithm** | `[NOT IMPLEMENTED]` (Handled by Gemini AI) | The repository does NOT contain a custom proprietary TF-IDF or vector embedding matching algorithm; it leverages Google Gemini Generative AI prompts. | Do NOT claim you wrote a machine learning algorithm from scratch. State that you engineered the prompt pipeline, local text extraction, and response parsing. |
| **Microservices Infrastructure** | `[NOT IMPLEMENTED]` (Modular Monolith) | The backend is a clean, single-process Express.js modular monolith on Render. | Do NOT claim you built a Kubernetes microservices mesh. State that you built a modular monolith, and explain how you would scale it to microservices when needed. |

---

## ❓ Clarification Questions for Personal Practice

1. *Have you tested the Render backend cold start recently?* (Render free tier sleeps after 15 mins of inactivity; the first request takes ~45 seconds to wake up).
2. *Can you explain why `googletest@leoengineer.com` was hardcoded?* (It is the standard App Store / Google Play review demo user required by store review guidelines to bypass manual verification).
3. *What is your favorite part of the project?* (Practice speaking passionately about the local PDF text extraction pipeline and server-side HMAC signature verification).
